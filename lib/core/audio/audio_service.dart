import 'dart:developer' as dev;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:just_audio/just_audio.dart';

final audioServiceProvider = Provider<AudioService>((ref) {
  final service = AudioService();
  ref.onDispose(() => service.dispose());
  return service;
});

class AudioService {
  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _voicePlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();
  bool _ttsInitialized = false;

  Future<void> _initTts() async {
    if (_ttsInitialized) return;
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.1);
    _ttsInitialized = true;
  }

  Future<void> _playAsset(AudioPlayer player, String assetPath, {bool awaitCompletion = false}) async {
    try {
      final duration = await player.setAsset(assetPath);
      player.play();
      if (awaitCompletion && duration != null) {
        await Future.delayed(duration);
      }
    } catch (e) {
      dev.log('AudioService: failed to play $assetPath: $e');
    }
  }

  Future<void> speakFile(String file) async {
    HapticFeedback.lightImpact();
    await _playAsset(_voicePlayer, 'assets/sounds/file_$file.mp3');
  }

  Future<void> speakRank(String rank) async {
    HapticFeedback.lightImpact();
    await _playAsset(_voicePlayer, 'assets/sounds/rank_$rank.mp3');
  }

  Future<void> speakSquare(String file, String rank) async {
    HapticFeedback.lightImpact();
    await _playAsset(_voicePlayer, 'assets/sounds/file_$file.mp3', awaitCompletion: true);
    await _playAsset(_voicePlayer, 'assets/sounds/rank_$rank.mp3');
  }

  /// Fallback for any dynamic text that doesn't have a pre-recorded clip
  Future<void> speak(String text) async {
    await _initTts();
    await _tts.speak(text);
  }

  Future<void> playCorrect() async {
    HapticFeedback.lightImpact();
    await _playAsset(_sfxPlayer, 'assets/sounds/correct.m4a');
  }

  Future<void> playIncorrect() async {
    HapticFeedback.mediumImpact();
    await _playAsset(_sfxPlayer, 'assets/sounds/incorrect.m4a');
  }

  Future<void> playStreakMilestone(int streak) async {
    HapticFeedback.heavyImpact();
    final clip = switch (streak) {
      5 => 'streak_5',
      10 => 'streak_10',
      15 => 'streak_15',
      20 => 'streak_20',
      _ when streak > 0 && streak % 10 == 0 => 'streak_20',
      _ => null,
    };
    if (clip != null) {
      await _playAsset(_voicePlayer, 'assets/sounds/$clip.mp3');
    }
  }

  Future<void> playNewRecord() async {
    HapticFeedback.heavyImpact();
    await _playAsset(_voicePlayer, 'assets/sounds/new_record.mp3');
  }

  Future<void> speakPiece(String pieceName) async {
    HapticFeedback.lightImpact();
    await _playAsset(_voicePlayer, 'assets/sounds/piece_$pieceName.mp3');
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
    await _playAsset(_voicePlayer, 'assets/sounds/piece_$pieceName.mp3', awaitCompletion: true);
    if (isCapture) {
      await _playAsset(_voicePlayer, 'assets/sounds/move_takes.mp3', awaitCompletion: true);
    }
    await _playAsset(_voicePlayer, 'assets/sounds/file_$file.mp3', awaitCompletion: true);
    await _playAsset(_voicePlayer, 'assets/sounds/rank_$rank.mp3', awaitCompletion: isCheck || isCheckmate);
    if (isCheckmate) {
      await _playAsset(_voicePlayer, 'assets/sounds/move_checkmate.mp3');
    } else if (isCheck) {
      await _playAsset(_voicePlayer, 'assets/sounds/move_check.mp3');
    }
  }

  Future<void> playGameOver() async {
    HapticFeedback.mediumImpact();
  }

  void dispose() {
    _tts.stop();
    _voicePlayer.dispose();
    _sfxPlayer.dispose();
  }
}
