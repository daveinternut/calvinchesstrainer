import 'dart:async';
import 'dart:math';

import 'package:dartchess/dartchess.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/audio/audio_service.dart';
import '../../../core/services/puzzle_service.dart';
import '../models/move_game_state.dart';

final moveGameProvider =
    NotifierProvider<MoveGameNotifier, MoveGameState>(MoveGameNotifier.new);

class MoveGameNotifier extends Notifier<MoveGameState> {
  Timer? _advanceTimer;
  Timer? _countdownTimer;
  final Map<String, int> _personalBests = {};

  PuzzleService get _puzzles => ref.read(puzzleServiceProvider);
  AudioService get _audio => ref.read(audioServiceProvider);

  String get _bestKey => '${state.mode.name}_${state.isHardMode}';
  int get personalBest => _personalBests[_bestKey] ?? 0;

  @override
  MoveGameState build() {
    ref.onDispose(_dispose);
    return const MoveGameState(mode: MoveTrainerMode.practice);
  }

  Future<void> startGame(MoveTrainerMode mode, {bool isHardMode = false}) async {
    _cancelTimers();
    state = MoveGameState(
      mode: mode,
      isHardMode: isHardMode,
      timeRemainingSeconds: mode == MoveTrainerMode.speed ? 30 : null,
      isLoading: true,
    );

    await _puzzles.loadPuzzles();

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
    final isCorrect = move.from == expected.from && move.to == expected.to;

    final newStreak = isCorrect ? state.streak + 1 : 0;
    final newBestStreak = max(newStreak, state.bestStreak);
    final isMilestone = isCorrect && newStreak > 0 && newStreak % 5 == 0;

    if (isCorrect) {
      final newPosition = puzzle.position.playUnchecked(move);
      state = state.copyWith(
        displayFen: () => newPosition.fen,
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
      if (isMilestone) {
        _audio.playStreakMilestone(newStreak);
      }
    } else {
      state = state.copyWith(
        streak: 0,
        bestStreak: newBestStreak,
        totalAttempts: state.totalAttempts + 1,
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
            ? const Duration(milliseconds: 400)
            : const Duration(milliseconds: 1200));

    _scheduleAdvance(delay);
  }

  void _loadNextPuzzle() {
    final puzzle = _puzzles.getRandomPuzzle(exclude: state.currentPuzzle);

    state = state.copyWith(
      currentPuzzle: () => puzzle,
      displayFen: () => puzzle.position.fen,
      sideToMove: () => puzzle.sideToMove,
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
      _loadNextPuzzle();
    });
  }

  bool get isNewRecord {
    if (state.mode != MoveTrainerMode.speed) return false;
    final best = _personalBests[_bestKey] ?? 0;
    return state.totalCorrect > best && state.totalCorrect > 0;
  }

  void _checkAndUpdatePersonalBest() {
    if (state.mode != MoveTrainerMode.speed) return;
    final current = _personalBests[_bestKey] ?? 0;
    if (state.totalCorrect > current) {
      _personalBests[_bestKey] = state.totalCorrect;
      _audio.playNewRecord();
    }
  }

  void _cancelTimers() {
    _advanceTimer?.cancel();
    _countdownTimer?.cancel();
  }

  void _dispose() {
    _cancelTimers();
  }
}
