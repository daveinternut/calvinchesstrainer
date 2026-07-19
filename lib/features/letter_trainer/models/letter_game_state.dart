import 'package:dartchess/dartchess.dart' show PieceKind;

/// The six piece identities as they appear in algebraic notation.
/// SAN letters are English everywhere (lichess, chess.com, books):
/// K, Q, R, B, N — and the pawn, which gets no letter at all.
enum LetterPiece {
  king('K', 'king', PieceKind.whiteKing, PieceKind.blackKing),
  queen('Q', 'queen', PieceKind.whiteQueen, PieceKind.blackQueen),
  rook('R', 'rook', PieceKind.whiteRook, PieceKind.blackRook),
  bishop('B', 'bishop', PieceKind.whiteBishop, PieceKind.blackBishop),
  knight('N', 'knight', PieceKind.whiteKnight, PieceKind.blackKnight),
  pawn('', 'pawn', PieceKind.whitePawn, PieceKind.blackPawn);

  /// SAN letter; empty for the pawn.
  final String letter;

  /// Matches the voice clip at `assets/sounds/piece_$audioName.mp3`.
  final String audioName;

  final PieceKind _whiteKind;
  final PieceKind _blackKind;

  const LetterPiece(
      this.letter, this.audioName, this._whiteKind, this._blackKind);

  bool get hasLetter => letter.isNotEmpty;

  /// Hard mode shows black piece art (the app-wide "black's perspective").
  PieceKind pieceKind({required bool black}) => black ? _blackKind : _whiteKind;
}

enum LetterTrainerMode { explore, practice, speed }

/// letterToPiece: shown a letter, tap the matching piece image.
/// pieceToLetter: shown a piece image, tap the matching letter tile.
enum LetterQuestionDirection { letterToPiece, pieceToLetter }

enum AnswerResult { correct, incorrect }

class LetterQuestion {
  final LetterQuestionDirection direction;
  final LetterPiece target;

  /// The six answer tiles: rendered as piece images for [letterToPiece]
  /// (shuffled), as letter tiles in fixed K Q R B N – order otherwise.
  final List<LetterPiece> options;

  const LetterQuestion({
    required this.direction,
    required this.target,
    required this.options,
  });

  /// Prompting "find the piece with no letter" — the pawn trick question.
  bool get isNoLetterPrompt =>
      direction == LetterQuestionDirection.letterToPiece && !target.hasLetter;
}

class LetterFeedback {
  final AnswerResult result;
  final LetterPiece tapped;
  final LetterPiece correct;

  const LetterFeedback({
    required this.result,
    required this.tapped,
    required this.correct,
  });
}

class LetterGameState {
  final LetterTrainerMode mode;
  final bool isHardMode;
  final LetterQuestion? currentQuestion;
  final int streak;
  final int bestStreak;
  final int totalCorrect;
  final int totalAttempts;
  final int? timeRemainingSeconds;
  final LetterFeedback? lastFeedback;
  final bool isGameOver;
  final bool isWaitingForNext;

  const LetterGameState({
    required this.mode,
    this.isHardMode = false,
    this.currentQuestion,
    this.streak = 0,
    this.bestStreak = 0,
    this.totalCorrect = 0,
    this.totalAttempts = 0,
    this.timeRemainingSeconds,
    this.lastFeedback,
    this.isGameOver = false,
    this.isWaitingForNext = false,
  });

  LetterGameState copyWith({
    LetterTrainerMode? mode,
    bool? isHardMode,
    LetterQuestion? Function()? currentQuestion,
    int? streak,
    int? bestStreak,
    int? totalCorrect,
    int? totalAttempts,
    int? Function()? timeRemainingSeconds,
    LetterFeedback? Function()? lastFeedback,
    bool? isGameOver,
    bool? isWaitingForNext,
  }) {
    return LetterGameState(
      mode: mode ?? this.mode,
      isHardMode: isHardMode ?? this.isHardMode,
      currentQuestion:
          currentQuestion != null ? currentQuestion() : this.currentQuestion,
      streak: streak ?? this.streak,
      bestStreak: bestStreak ?? this.bestStreak,
      totalCorrect: totalCorrect ?? this.totalCorrect,
      totalAttempts: totalAttempts ?? this.totalAttempts,
      timeRemainingSeconds: timeRemainingSeconds != null
          ? timeRemainingSeconds()
          : this.timeRemainingSeconds,
      lastFeedback: lastFeedback != null ? lastFeedback() : this.lastFeedback,
      isGameOver: isGameOver ?? this.isGameOver,
      isWaitingForNext: isWaitingForNext ?? this.isWaitingForNext,
    );
  }
}
