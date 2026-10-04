import 'package:dartchess/dartchess.dart' show PieceKind;

enum PieceType {
  pawn(1, PieceKind.whitePawn),
  knight(3, PieceKind.whiteKnight),
  bishop(3, PieceKind.whiteBishop),
  rook(5, PieceKind.whiteRook),
  queen(9, PieceKind.whiteQueen);

  final int value;
  final PieceKind pieceKind;
  const PieceType(this.value, this.pieceKind);
}

enum WhichSideWinsMode { practice, speed }

enum AnswerSide { left, right }

enum AnswerResult { correct, incorrect }

class PieceGroupPuzzle {
  final List<PieceType> leftGroup;
  final List<PieceType> rightGroup;
  final AnswerSide correctSide;
  final int difficulty;

  const PieceGroupPuzzle({
    required this.leftGroup,
    required this.rightGroup,
    required this.correctSide,
    required this.difficulty,
  });

  int get leftValue => leftGroup.fold(0, (sum, p) => sum + p.value);
  int get rightValue => rightGroup.fold(0, (sum, p) => sum + p.value);
}

class WhichSideWinsState {
  final WhichSideWinsMode mode;
  final PieceGroupPuzzle? currentPuzzle;
  final AnswerResult? lastResult;
  final AnswerSide? lastAnswerSide;
  final int streak;
  final int bestStreak;
  final int totalCorrect;
  final int totalAttempts;
  final int currentDifficulty;
  final int? timeRemainingSeconds;
  final bool isGameOver;
  final bool isWaitingForNext;

  /// Set at game over when the round beat the saved personal best.
  final bool isNewRecord;

  const WhichSideWinsState({
    required this.mode,
    this.currentPuzzle,
    this.lastResult,
    this.lastAnswerSide,
    this.streak = 0,
    this.bestStreak = 0,
    this.totalCorrect = 0,
    this.totalAttempts = 0,
    this.currentDifficulty = 1,
    this.timeRemainingSeconds,
    this.isGameOver = false,
    this.isWaitingForNext = false,
    this.isNewRecord = false,
  });

  WhichSideWinsState copyWith({
    WhichSideWinsMode? mode,
    PieceGroupPuzzle? Function()? currentPuzzle,
    AnswerResult? Function()? lastResult,
    AnswerSide? Function()? lastAnswerSide,
    int? streak,
    int? bestStreak,
    int? totalCorrect,
    int? totalAttempts,
    int? currentDifficulty,
    int? Function()? timeRemainingSeconds,
    bool? isGameOver,
    bool? isWaitingForNext,
    bool? isNewRecord,
  }) {
    return WhichSideWinsState(
      mode: mode ?? this.mode,
      currentPuzzle:
          currentPuzzle != null ? currentPuzzle() : this.currentPuzzle,
      lastResult: lastResult != null ? lastResult() : this.lastResult,
      lastAnswerSide:
          lastAnswerSide != null ? lastAnswerSide() : this.lastAnswerSide,
      streak: streak ?? this.streak,
      bestStreak: bestStreak ?? this.bestStreak,
      totalCorrect: totalCorrect ?? this.totalCorrect,
      totalAttempts: totalAttempts ?? this.totalAttempts,
      currentDifficulty: currentDifficulty ?? this.currentDifficulty,
      timeRemainingSeconds: timeRemainingSeconds != null
          ? timeRemainingSeconds()
          : this.timeRemainingSeconds,
      isGameOver: isGameOver ?? this.isGameOver,
      isWaitingForNext: isWaitingForNext ?? this.isWaitingForNext,
      isNewRecord: isNewRecord ?? this.isNewRecord,
    );
  }
}
