import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/audio/audio_service.dart';
import '../../../core/services/analytics_service.dart';
import '../models/letter_game_state.dart';

final letterGameProvider =
    NotifierProvider<LetterGameNotifier, LetterGameState>(
  LetterGameNotifier.new,
);

class LetterGameNotifier extends Notifier<LetterGameState> {
  final _random = Random();
  Timer? _advanceTimer;
  Timer? _countdownTimer;
  final Map<String, int> _personalBests = {};

  AudioService get _audio => ref.read(audioServiceProvider);
  AnalyticsService get _analytics => ref.read(analyticsServiceProvider);

  String get _bestKey => 'letters_${state.mode.name}_${state.isHardMode}';

  int get personalBest => _personalBests[_bestKey] ?? 0;

  @override
  LetterGameState build() {
    ref.onDispose(_dispose);
    return const LetterGameState(mode: LetterTrainerMode.explore);
  }

  void startGame(LetterTrainerMode mode, {bool isHardMode = false}) {
    _cancelTimers();
    state = LetterGameState(
      mode: mode,
      isHardMode: isHardMode,
      timeRemainingSeconds: mode == LetterTrainerMode.speed ? 30 : null,
    );

    _analytics.logLetterDrillStarted(
      mode: mode.name,
      hardMode: isHardMode,
    );

    if (mode != LetterTrainerMode.explore) {
      _generateNextQuestion();
    }
    if (mode == LetterTrainerMode.speed) {
      _startCountdown();
    }
  }

  void handleAnswer(LetterPiece tapped) {
    if (state.isGameOver || state.isWaitingForNext) return;

    if (state.mode == LetterTrainerMode.explore) {
      _handleExploreTap(tapped);
      return;
    }

    final question = state.currentQuestion;
    if (question == null) return;

    final isCorrect = tapped == question.target;
    final newStreak = isCorrect ? state.streak + 1 : 0;
    final newBestStreak = max(newStreak, state.bestStreak);

    state = state.copyWith(
      streak: newStreak,
      bestStreak: newBestStreak,
      totalCorrect: isCorrect ? state.totalCorrect + 1 : state.totalCorrect,
      totalAttempts: state.totalAttempts + 1,
      isWaitingForNext: true,
      lastFeedback: () => LetterFeedback(
        result: isCorrect ? AnswerResult.correct : AnswerResult.incorrect,
        tapped: tapped,
        correct: question.target,
      ),
    );

    if (isCorrect) {
      _audio.playCorrect();
    } else {
      _audio.playIncorrect();
    }
    // Reinforce the pairing: name the correct piece while its tile glows.
    _audio.speakPiece(question.target.audioName);

    final delay = state.mode == LetterTrainerMode.speed
        ? (isCorrect
            ? const Duration(milliseconds: 200)
            : const Duration(milliseconds: 600))
        : (isCorrect
            ? const Duration(milliseconds: 700)
            : const Duration(milliseconds: 1200));

    _scheduleAdvance(delay);
  }

  /// Explore is a free-play gallery: tap a piece to hear its name and see
  /// its letter + mnemonic. The card stays selected until the next tap so
  /// young readers can take their time (no auto-advance timer).
  void _handleExploreTap(LetterPiece piece) {
    state = state.copyWith(
      lastFeedback: () => LetterFeedback(
        result: AnswerResult.correct,
        tapped: piece,
        correct: piece,
      ),
    );
    _audio.speakPiece(piece.audioName);
  }

  void _generateNextQuestion() {
    final previousTarget = state.currentQuestion?.target;

    // Uniform over all six pieces: the pawn shows up ~1/6 of the time as
    // the "no letter" trick answer in both directions.
    LetterPiece target;
    do {
      target = LetterPiece.values[_random.nextInt(LetterPiece.values.length)];
    } while (target == previousTarget);

    final direction = _random.nextBool()
        ? LetterQuestionDirection.letterToPiece
        : LetterQuestionDirection.pieceToLetter;

    // Piece tiles shuffle so kids read shapes, not positions; letter tiles
    // keep a fixed K Q R B N – order so they read like a legend.
    final options = direction == LetterQuestionDirection.letterToPiece
        ? (List.of(LetterPiece.values)..shuffle(_random))
        : List.of(LetterPiece.values);

    state = state.copyWith(
      currentQuestion: () => LetterQuestion(
        direction: direction,
        target: target,
        options: options,
      ),
      lastFeedback: () => null,
      isWaitingForNext: false,
    );

    // Voice the piece name when the piece is the prompt (hear "Knight",
    // find N). Letter prompts stay silent — there are no letter clips.
    if (direction == LetterQuestionDirection.pieceToLetter) {
      _audio.speakPiece(target.audioName);
    }
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final remaining = (state.timeRemainingSeconds ?? 0) - 1;
      if (remaining <= 0) {
        _cancelTimers();
        state = state.copyWith(
          timeRemainingSeconds: () => 0,
          isGameOver: true,
          isWaitingForNext: true,
        );
        _checkAndUpdatePersonalBest();
        _audio.playGameOver();
      } else {
        state = state.copyWith(timeRemainingSeconds: () => remaining);
      }
    });
  }

  void _scheduleAdvance(Duration delay) {
    _advanceTimer?.cancel();
    _advanceTimer = Timer(delay, () {
      if (state.isGameOver) return;
      _generateNextQuestion();
    });
  }

  bool get isNewRecord {
    if (state.mode != LetterTrainerMode.speed) return false;
    final best = _personalBests[_bestKey] ?? 0;
    return state.totalCorrect > best && state.totalCorrect > 0;
  }

  void _checkAndUpdatePersonalBest() {
    if (state.mode != LetterTrainerMode.speed) return;
    final newRecord = state.totalCorrect > (_personalBests[_bestKey] ?? 0) &&
        state.totalCorrect > 0;
    if (newRecord) {
      _personalBests[_bestKey] = state.totalCorrect;
      _audio.playNewRecord();
    }
    _analytics.logLetterDrillCompleted(
      mode: state.mode.name,
      hardMode: state.isHardMode,
      totalCorrect: state.totalCorrect,
      totalAttempts: state.totalAttempts,
      bestStreak: state.bestStreak,
      isNewRecord: newRecord,
    );
  }

  void _cancelTimers() {
    _advanceTimer?.cancel();
    _countdownTimer?.cancel();
  }

  void _dispose() {
    _cancelTimers();
  }
}
