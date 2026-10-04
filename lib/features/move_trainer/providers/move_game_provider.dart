import 'dart:async';
import 'dart:developer' as dev;
import 'dart:math';

import 'package:dartchess/dartchess.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/audio/audio_service.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/services/personal_bests_service.dart';
import '../../../core/services/puzzle_service.dart';
import '../models/move_game_state.dart';

/// Auto-disposed: a round never outlives its screen, so leaving mid-round
/// cancels both timers (no late prompts, buzzes or "new record" cheers).
final moveGameProvider =
    NotifierProvider.autoDispose<MoveGameNotifier, MoveGameState>(
  MoveGameNotifier.new,
);

class MoveGameNotifier extends Notifier<MoveGameState> {
  Timer? _advanceTimer;
  Timer? _countdownTimer;

  /// Bumped by every [startGame]. A start whose puzzle load finishes after a
  /// newer start (or after the screen closed) gives up instead of starting a
  /// second countdown.
  int _generation = 0;

  PuzzleService get _puzzles => ref.read(puzzleServiceProvider);
  AudioService get _audio => ref.read(audioServiceProvider);
  AnalyticsService get _analytics => ref.read(analyticsServiceProvider);

  /// Personal-best key, e.g. `move.speed_false`.
  static String bestKeyFor(MoveTrainerMode mode, bool isHardMode) =>
      'move.${mode.name}_$isHardMode';

  String get _bestKey => bestKeyFor(state.mode, state.isHardMode);

  @override
  MoveGameState build() {
    ref.onDispose(_cancelTimers);
    return const MoveGameState(mode: MoveTrainerMode.practice);
  }

  Future<void> startGame(MoveTrainerMode mode, {bool isHardMode = false}) async {
    final generation = ++_generation;
    _cancelTimers();
    state = MoveGameState(
      mode: mode,
      isHardMode: isHardMode,
      timeRemainingSeconds: mode == MoveTrainerMode.speed ? 30 : null,
      isLoading: true,
    );

    _analytics.logMoveDrillStarted(
      mode: mode.name,
      hardMode: isHardMode,
    );

    try {
      await _puzzles.loadPuzzles();
    } catch (e) {
      dev.log('MoveGame: puzzles failed to load: $e');
      return;
    }
    if (!ref.mounted || generation != _generation) return;

    state = state.copyWith(isLoading: false);
    _loadNextPuzzle();

    if (mode == MoveTrainerMode.speed) {
      _startCountdown();
    }
  }

  void handleMove(NormalMove move) {
    if (state.isGameOver || state.isWaitingForNext || state.isLoading) return;

    final puzzle = state.currentPuzzle;
    if (puzzle == null) return;

    final expected = puzzle.expectedMove;
    final isCorrect = puzzle.matches(move);

    final newStreak = isCorrect ? state.streak + 1 : 0;
    final newBestStreak = max(newStreak, state.bestStreak);

    if (isCorrect) {
      final newPosition = puzzle.position.playUnchecked(move);
      state = state.copyWith(
        displayFen: () => newPosition.fen,
        sideToMove: () => newPosition.turn,
        isCheck: newPosition.isCheck,
        streak: newStreak,
        bestStreak: newBestStreak,
        totalCorrect: state.totalCorrect + 1,
        totalAttempts: state.totalAttempts + 1,
        isWaitingForNext: true,
        lastFeedback: () => MoveFeedback(
          result: MoveFeedbackResult.correct,
          attemptedMove: move,
          correctMove: expected,
        ),
      );

      _audio.playCorrect();
    } else {
      state = state.copyWith(
        streak: 0,
        bestStreak: newBestStreak,
        totalAttempts: state.totalAttempts + 1,
        missed: [...state.missed, puzzle.san],
        isWaitingForNext: true,
        lastFeedback: () => MoveFeedback(
          result: MoveFeedbackResult.incorrect,
          attemptedMove: move,
          correctMove: expected,
        ),
      );

      _audio.playIncorrect();
    }

    final delay = state.mode == MoveTrainerMode.speed
        ? (isCorrect
            ? const Duration(milliseconds: 200)
            : const Duration(milliseconds: 600))
        : (isCorrect
            ? const Duration(milliseconds: 700)
            : const Duration(milliseconds: 1200));

    _scheduleAdvance(delay);
  }

  void _loadNextPuzzle() {
    final side = state.isHardMode ? Side.black : Side.white;
    final puzzle = _puzzles.getRandomPuzzle(
      exclude: state.currentPuzzle,
      sideToMove: side,
    );

    state = state.copyWith(
      currentPuzzle: () => puzzle,
      displayFen: () => puzzle.position.fen,
      sideToMove: () => puzzle.sideToMove,
      isCheck: puzzle.position.isCheck,
      lastSetupMove: () => puzzle.setupMove,
      lastFeedback: () => null,
      isWaitingForNext: false,
    );

    if (puzzle.isCastling) {
      final castleSide = puzzle.expectedMove.to.file.value > 4
          ? 'castle kingside'
          : 'castle queenside';
      _audio.speak(castleSide);
    } else {
      _audio.speakMove(
        puzzle.pieceName,
        puzzle.targetFile,
        puzzle.targetRank,
        isCapture: puzzle.isCapture,
        isCheck: puzzle.isCheck,
        isCheckmate: puzzle.isCheckmate,
      );
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final remaining = (state.timeRemainingSeconds ?? 0) - 1;
      if (remaining <= 0) {
        _endRound();
      } else {
        state = state.copyWith(timeRemainingSeconds: () => remaining);
      }
    });
  }

  void _endRound() {
    _cancelTimers();
    final isNewRecord = state.mode == MoveTrainerMode.speed &&
        ref.read(personalBestsProvider.notifier).submit(
              _bestKey,
              state.totalCorrect,
            );
    state = state.copyWith(
      timeRemainingSeconds: () => 0,
      isGameOver: true,
      isWaitingForNext: true,
      isNewRecord: isNewRecord,
    );
    if (isNewRecord) _audio.playNewRecord();
    _analytics.logMoveDrillCompleted(
      mode: state.mode.name,
      hardMode: state.isHardMode,
      totalCorrect: state.totalCorrect,
      totalAttempts: state.totalAttempts,
      bestStreak: state.bestStreak,
      isNewRecord: isNewRecord,
    );
    _audio.playGameOver();
  }

  void _scheduleAdvance(Duration delay) {
    _advanceTimer?.cancel();
    _advanceTimer = Timer(delay, () {
      if (state.isGameOver) return;
      _loadNextPuzzle();
    });
  }

  void _cancelTimers() {
    _advanceTimer?.cancel();
    _countdownTimer?.cancel();
  }
}
