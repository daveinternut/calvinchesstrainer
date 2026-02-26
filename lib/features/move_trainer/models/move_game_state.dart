import 'dart:ui' show Color;

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';

import '../../../core/services/puzzle_service.dart';

enum MoveTrainerMode { practice, speed }

enum MoveFeedbackResult { correct, incorrect }

class MoveFeedback {
  final MoveFeedbackResult result;
  final NormalMove? attemptedMove;
  final NormalMove correctMove;

  const MoveFeedback({
    required this.result,
    this.attemptedMove,
    required this.correctMove,
  });
}

class MoveGameState {
  final MoveTrainerMode mode;
  final bool isHardMode;

  final ParsedPuzzle? currentPuzzle;
  final String? displayFen;
  final Side? sideToMove;
  final NormalMove? lastSetupMove;

  final int streak;
  final int bestStreak;
  final int totalCorrect;
  final int totalAttempts;
  final int? timeRemainingSeconds;

  final MoveFeedback? lastFeedback;
  final bool isGameOver;
  final bool isWaitingForNext;
  final bool isLoading;

  const MoveGameState({
    required this.mode,
    this.isHardMode = false,
    this.currentPuzzle,
    this.displayFen,
    this.sideToMove,
    this.lastSetupMove,
    this.streak = 0,
    this.bestStreak = 0,
    this.totalCorrect = 0,
    this.totalAttempts = 0,
    this.timeRemainingSeconds,
    this.lastFeedback,
    this.isGameOver = false,
    this.isWaitingForNext = false,
    this.isLoading = true,
  });

  MoveGameState copyWith({
    MoveTrainerMode? mode,
    bool? isHardMode,
    ParsedPuzzle? Function()? currentPuzzle,
    String? Function()? displayFen,
    Side? Function()? sideToMove,
    NormalMove? Function()? lastSetupMove,
    int? streak,
    int? bestStreak,
    int? totalCorrect,
    int? totalAttempts,
    int? Function()? timeRemainingSeconds,
    MoveFeedback? Function()? lastFeedback,
    bool? isGameOver,
    bool? isWaitingForNext,
    bool? isLoading,
  }) {
    return MoveGameState(
      mode: mode ?? this.mode,
      isHardMode: isHardMode ?? this.isHardMode,
      currentPuzzle:
          currentPuzzle != null ? currentPuzzle() : this.currentPuzzle,
      displayFen: displayFen != null ? displayFen() : this.displayFen,
      sideToMove: sideToMove != null ? sideToMove() : this.sideToMove,
      lastSetupMove:
          lastSetupMove != null ? lastSetupMove() : this.lastSetupMove,
      streak: streak ?? this.streak,
      bestStreak: bestStreak ?? this.bestStreak,
      totalCorrect: totalCorrect ?? this.totalCorrect,
      totalAttempts: totalAttempts ?? this.totalAttempts,
      timeRemainingSeconds: timeRemainingSeconds != null
          ? timeRemainingSeconds()
          : this.timeRemainingSeconds,
      lastFeedback:
          lastFeedback != null ? lastFeedback() : this.lastFeedback,
      isGameOver: isGameOver ?? this.isGameOver,
      isWaitingForNext: isWaitingForNext ?? this.isWaitingForNext,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  ISet<Shape> get feedbackShapes {
    final feedback = lastFeedback;
    if (feedback == null) return const ISetConst({});

    if (feedback.result == MoveFeedbackResult.incorrect) {
      return ISet({
        Arrow(
          color: const Color(0xCC4CAF50),
          orig: feedback.correctMove.from,
          dest: feedback.correctMove.to,
        ),
      });
    }

    return const ISetConst({});
  }

  IMap<Square, SquareHighlight> get squareHighlights {
    final feedback = lastFeedback;
    if (feedback == null) {
      return const IMapConst({});
    }

    if (feedback.result == MoveFeedbackResult.correct) {
      final highlight = SquareHighlight(
        details: HighlightDetails(
          solidColor: const Color(0x994CAF50),
        ),
      );
      return IMap({
        feedback.correctMove.from: highlight,
        feedback.correctMove.to: highlight,
      });
    }

    return const IMapConst({});
  }
}
