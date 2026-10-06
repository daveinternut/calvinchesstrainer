import 'dart:async';
import 'dart:developer' as dev;

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:just_audio/just_audio.dart';

import 'sound_switch.dart';

final audioServiceProvider = Provider<AudioService>((ref) {
  final service = AudioService();
  ref.listen(
    soundOnProvider,
    (_, on) => service.muted = !on,
    fireImmediately: true,
  );
  ref.onDispose(service.dispose);
  return service;
});

/// Voice clips, sound effects, haptics and the TTS fallback. **Owns all
/// haptics.**
///
/// Players are split by layer so one never cuts another off:
/// - [_voicePlayer]: spoken prompts and answers. One announcement at a time —
///   starting a new one (or [stop]) cancels the rest of the old one.
/// - [_correctPlayer] / [_incorrectPlayer]: the answer blips, each loaded once
///   and rewound, so rapid taps don't reload an asset every time.
/// - [_cheerPlayer]: milestone and new-record cheers, layered over the voice.
///
/// Multi-clip announcements ("knight… takes… e… 4… check") re-check
/// [_voiceSequence] after every await, so a stop or a newer announcement ends
/// them instead of splicing two sentences together on the shared player.
///
/// [muted] (the in-app Sound switch) silences every layer. Haptics still
/// fire: they aren't sound, and the system's haptics setting governs them.
class AudioService {
  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _voicePlayer = AudioPlayer();
  final AudioPlayer _correctPlayer = AudioPlayer();
  final AudioPlayer _incorrectPlayer = AudioPlayer();
  final AudioPlayer _cheerPlayer = AudioPlayer();

  bool _ttsInitialized = false;
  bool _muted = false;
  int _voiceSequence = 0;
  Future<void>? _sessionReady;
  final Map<AudioPlayer, String> _loadedAsset = {};

  /// Set from [soundOnProvider]. While muted nothing plays, and muting cuts
  /// off whatever is playing now.
  bool get muted => _muted;
  set muted(bool value) {
    if (value == _muted) return;
    _muted = value;
    if (value) unawaited(stop());
  }

  /// Configures the shared audio session once, before the first sound.
  ///
  /// Mixes with other apps (a parent's music keeps playing) and respects the
  /// silent switch, like a game. Unconfigured, just_audio falls back to the
  /// "music" session — playback, non-mixing — which stops other audio on the
  /// first sound effect and plays through Silent mode.
  Future<void> _ensureSession() => _sessionReady ??= _configureSession();

  Future<void> _configureSession() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(
        const AudioSessionConfiguration(
          avAudioSessionCategory: AVAudioSessionCategory.ambient,
          avAudioSessionCategoryOptions:
              AVAudioSessionCategoryOptions.mixWithOthers,
          avAudioSessionMode: AVAudioSessionMode.defaultMode,
          androidAudioAttributes: AndroidAudioAttributes(
            contentType: AndroidAudioContentType.sonification,
            usage: AndroidAudioUsage.game,
          ),
          androidAudioFocusGainType:
              AndroidAudioFocusGainType.gainTransientMayDuck,
          androidWillPauseWhenDucked: false,
        ),
      );
    } catch (e) {
      dev.log('AudioService: audio session not configured: $e');
    }
  }

  Future<void> _initTts() async {
    if (_ttsInitialized) return;
    _ttsInitialized = true;
    try {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
        await _tts.setIosAudioCategory(IosTextToSpeechAudioCategory.ambient, [
          IosTextToSpeechAudioCategoryOptions.mixWithOthers,
        ]);
      }
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.45);
      await _tts.setPitch(1.1);
    } catch (e) {
      dev.log('AudioService: TTS setup failed: $e');
    }
  }

  // --- Voice (one announcement at a time) ---

  /// Plays [assets] back to back on the voice player as one announcement,
  /// cancelling any announcement still in flight.
  Future<void> _announce(List<String> assets) async {
    if (_muted) return;
    final sequence = ++_voiceSequence;
    for (var i = 0; i < assets.length; i++) {
      if (sequence != _voiceSequence) return;
      final isLast = i == assets.length - 1;
      await _playVoice(sequence, assets[i], awaitCompletion: !isLast);
    }
  }

  Future<void> _playVoice(
    int sequence,
    String asset, {
    required bool awaitCompletion,
  }) async {
    await _ensureSession();
    if (sequence != _voiceSequence) return;
    try {
      final duration = await _voicePlayer.setAsset(asset);
      if (sequence != _voiceSequence) return;
      _start(_voicePlayer);
      if (awaitCompletion && duration != null) {
        await Future.delayed(duration);
      }
    } catch (e) {
      // A newer announcement interrupting this load lands here too.
      dev.log('AudioService: failed to play $asset: $e');
    }
  }

  // --- Single-layer players (blips and cheers) ---

  /// Plays [asset] on [player], loading it only when it isn't already the
  /// loaded source (then it just rewinds).
  Future<void> _playOn(AudioPlayer player, String asset) async {
    if (_muted) return;
    await _ensureSession();
    try {
      if (_loadedAsset[player] != asset) {
        _loadedAsset.remove(player);
        await player.setAsset(asset);
        _loadedAsset[player] = asset;
      } else {
        await player.seek(Duration.zero);
      }
      if (_muted) return; // switched off while it loaded
      _start(player);
    } catch (e) {
      _loadedAsset.remove(player);
      dev.log('AudioService: failed to play $asset: $e');
    }
  }

  /// Starts playback without awaiting it (`play()` completes only when the
  /// clip ends), keeping a late failure out of the zone's error handler.
  void _start(AudioPlayer player) {
    player.play().catchError((Object e) {
      dev.log('AudioService: playback error: $e');
    });
  }

  // --- Public API ---

  Future<void> speakFile(String file) async {
    HapticFeedback.lightImpact();
    await _announce(['assets/sounds/file_$file.mp3']);
  }

  Future<void> speakRank(String rank) async {
    HapticFeedback.lightImpact();
    await _announce(['assets/sounds/rank_$rank.mp3']);
  }

  Future<void> speakSquare(String file, String rank) async {
    HapticFeedback.lightImpact();
    await _announce([
      'assets/sounds/file_$file.mp3',
      'assets/sounds/rank_$rank.mp3',
    ]);
  }

  Future<void> speakPiece(String pieceName) async {
    HapticFeedback.lightImpact();
    await _announce(['assets/sounds/piece_$pieceName.mp3']);
  }

  Future<void> speakMove(
    String pieceName,
    String file,
    String rank, {
    bool isCapture = false,
    bool isCheck = false,
    bool isCheckmate = false,
  }) async {
    HapticFeedback.lightImpact();
    await _announce([
      'assets/sounds/piece_$pieceName.mp3',
      if (isCapture) 'assets/sounds/move_takes.mp3',
      'assets/sounds/file_$file.mp3',
      'assets/sounds/rank_$rank.mp3',
      if (isCheckmate)
        'assets/sounds/move_checkmate.mp3'
      else if (isCheck)
        'assets/sounds/move_check.mp3',
    ]);
  }

  /// "Check!" — layered over the correct-tap blip when a check square is
  /// found in the Find Checks drill. No haptic here: the paired playCorrect()
  /// already fires one.
  Future<void> playCheckCall() async {
    await _announce(['assets/sounds/move_check.mp3']);
  }

  /// "Checkmate!" — the Mate in 1 drill's crown moment.
  Future<void> playCheckmateCall() async {
    await _announce(['assets/sounds/move_checkmate.mp3']);
  }

  /// Fallback for dynamic text with no pre-recorded clip (e.g. castling).
  /// Counts as an announcement: it cancels any clip sequence in flight.
  Future<void> speak(String text) async {
    if (_muted) return;
    final sequence = ++_voiceSequence;
    try {
      await _voicePlayer.stop();
      await _initTts();
      // A stop (muting included) or a newer announcement while TTS set up.
      if (sequence != _voiceSequence) return;
      await _tts.speak(text);
    } catch (e) {
      dev.log('AudioService: TTS failed for "$text": $e');
    }
  }

  Future<void> playCorrect() async {
    HapticFeedback.lightImpact();
    await _playOn(_correctPlayer, 'assets/sounds/correct.m4a');
  }

  Future<void> playIncorrect() async {
    HapticFeedback.mediumImpact();
    await _playOn(_incorrectPlayer, 'assets/sounds/incorrect.m4a');
  }

  Future<void> playNewRecord() async {
    HapticFeedback.heavyImpact();
    await _playOn(_cheerPlayer, 'assets/sounds/new_record.mp3');
  }

  /// The streak celebration that goes with `MilestoneBanner`: a heavy haptic
  /// at every milestone, plus the recorded cheer at 5, 10, 15 and 20.
  Future<void> playMilestone(int streak) async {
    HapticFeedback.heavyImpact();
    if (streak == 5 || streak == 10 || streak == 15 || streak == 20) {
      await _playOn(_cheerPlayer, 'assets/sounds/streak_$streak.mp3');
    }
  }

  Future<void> playGameOver() async {
    HapticFeedback.mediumImpact();
  }

  /// Silences everything and cancels any announcement still in flight.
  /// Called by every game screen's `dispose`.
  Future<void> stop() async {
    ++_voiceSequence;
    // A stopped player releases its source; reload on the next play.
    _loadedAsset.clear();
    try {
      await Future.wait([
        _voicePlayer.stop(),
        _correctPlayer.stop(),
        _incorrectPlayer.stop(),
        _cheerPlayer.stop(),
      ]);
      await _tts.stop();
    } catch (e) {
      dev.log('AudioService: stop failed: $e');
    }
  }

  void dispose() {
    ++_voiceSequence;
    _tts.stop();
    _voicePlayer.dispose();
    _correctPlayer.dispose();
    _incorrectPlayer.dispose();
    _cheerPlayer.dispose();
  }
}
