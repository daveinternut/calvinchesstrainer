import 'package:dartchess/dartchess.dart' show PieceKind;

enum PieceType {
  pawn(1, 'Pawn', PieceKind.whitePawn),
  knight(3, 'Knight', PieceKind.whiteKnight),
  bishop(3, 'Bishop', PieceKind.whiteBishop),
  rook(5, 'Rook', PieceKind.whiteRook),
  queen(9, 'Queen', PieceKind.whiteQueen);

  final int value;
  final String label;
  final PieceKind pieceKind;
  const PieceType(this.value, this.label, this.pieceKind);
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
    );
  }
}
