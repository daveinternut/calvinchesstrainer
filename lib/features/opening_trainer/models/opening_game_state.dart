import 'package:dartchess/dartchess.dart';

import '../../../core/services/stockfish_service.dart';

enum OpeningDifficulty {
  easy(skillLevel: 3, moveTimeMs: 200, mistakeThresholdCp: 150, lives: 3),
  medium(skillLevel: 10, moveTimeMs: 350, mistakeThresholdCp: 100, lives: 2),
  hard(skillLevel: 18, moveTimeMs: 500, mistakeThresholdCp: 50, lives: 1);

  final int skillLevel;
  /// How long the CPU opponent thinks per move (milliseconds).
  final int moveTimeMs;
  final int mistakeThresholdCp;
  final int lives;

  const OpeningDifficulty({
    required this.skillLevel,
    required this.moveTimeMs,
    required this.mistakeThresholdCp,
    required this.lives,
  });
}

enum OpeningMode { practice, challenge }

enum MedalLevel { none, bronze, silver, gold }

MedalLevel medalForMoves(int userMoveCount) {
  if (userMoveCount >= 10) return MedalLevel.gold;
  if (userMoveCount >= 6) return MedalLevel.silver;
  if (userMoveCount >= 3) return MedalLevel.bronze;
  return MedalLevel.none;
}

class MoveRecord {
  final String fen;
  final String san;
  final String uci;
  final double eval;
  final bool isUserMove;
  final NormalMove move;

  /// The hint arrows that were visible when this move was made.
  /// Stored so undo can restore the exact same hints without recomputing.
  final List<SuggestedMove> hintsBeforeMove;

  const MoveRecord({
    required this.fen,
    required this.san,
    required this.uci,
    required this.eval,
    required this.isUserMove,
    required this.move,
    this.hintsBeforeMove = const [],
  });
}

/// Chess.com-style move classification based on how the move changes the game.
enum MoveClassification {
  /// Significantly improves position (gaining > 1.0 pawn)
  brilliant,
  /// Improves position (gaining 0.3 - 1.0 pawns)
  best,
  /// Maintains or slightly improves position (within +0.3 to -0.1)
  good,
  /// Part of established opening theory
  book,
  /// Slightly worsens position (losing 0.1 - 0.5 pawns)
  inaccuracy,
  /// Moderately worsens position (losing 0.5 - 1.5 pawns)
  mistake,
  /// Severely worsens position (losing > 1.5 pawns)
  blunder,
}

MoveClassification classifyDelta(double deltaPawns) {
  if (deltaPawns >= 1.0) return MoveClassification.brilliant;
  if (deltaPawns >= 0.3) return MoveClassification.best;
  if (deltaPawns >= -0.1) return MoveClassification.good;
  if (deltaPawns >= -0.5) return MoveClassification.inaccuracy;
  if (deltaPawns >= -1.5) return MoveClassification.mistake;
  return MoveClassification.blunder;
}

class SuggestedMove {
  final String uci;
  final String san;
  final int centipawns;
  final int? mateIn;

  /// Eval change in centipawns from the side-to-move's perspective.
  /// Compared to current position eval — positive = improves, negative = worsens.
  final int evalDelta;

  /// Whether this move appears in established opening theory.
  final bool isBook;

  const SuggestedMove({
    required this.uci,
    required this.san,
    required this.centipawns,
    this.mateIn,
    this.evalDelta = 0,
    this.isBook = false,
  });

  double get pawns => centipawns / 100.0;
  double get deltaPawns => evalDelta / 100.0;

  MoveClassification get classification {
    if (isBook) return MoveClassification.book;
    return classifyDelta(deltaPawns);
  }
}

class OpeningGameState {
  final OpeningMode mode;
  final OpeningDifficulty difficulty;
  final Side playerColor;

  final String currentFen;
  final List<MoveRecord> moveHistory;
  final List<String> sanMoves;
  final int userMoveCount;

  final EvalResult currentEval;
  final EvalResult? previousEval;

  final int livesRemaining;
  final int maxLives;
  final bool lastMoveWasMistake;

  final List<SuggestedMove> topMoves;

  final String? openingName;
  final String? openingEco;

  final bool isPlayerTurn;
  final bool isEngineThinking;
  final bool isGameOver;
  final bool showPrincipleCard;
  final String? principleText;

  final bool isReviewing;
  final int reviewIndex;

  final NormalMove? lastEngineMove;

  /// Which analysis wave is currently running (0-based), -1 = idle.
  final int thinkingWave;
  /// Total number of waves for this analysis pass.
  final int thinkingTotalWaves;

  const OpeningGameState({
    required this.mode,
    required this.difficulty,
    required this.playerColor,
    this.currentFen = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
    this.moveHistory = const [],
    this.sanMoves = const [],
    this.userMoveCount = 0,
    this.currentEval = const EvalResult(centipawns: 0),
    this.previousEval,
    this.livesRemaining = 3,
    this.maxLives = 3,
    this.lastMoveWasMistake = false,
    this.topMoves = const [],
    this.openingName,
    this.openingEco,
    this.isPlayerTurn = true,
    this.isEngineThinking = false,
    this.isGameOver = false,
    this.showPrincipleCard = false,
    this.principleText,
    this.isReviewing = false,
    this.reviewIndex = -1,
    this.lastEngineMove,
    this.thinkingWave = -1,
    this.thinkingTotalWaves = 0,
  });

  MedalLevel get currentMedal => medalForMoves(userMoveCount);

  double get evalForPlayer {
    final cp = currentEval.centipawns.toDouble();
    return playerColor == Side.white ? cp / 100.0 : -cp / 100.0;
  }

  OpeningGameState copyWith({
    OpeningMode? mode,
    OpeningDifficulty? difficulty,
    Side? playerColor,
    String? currentFen,
    List<MoveRecord>? moveHistory,
    List<String>? sanMoves,
    int? userMoveCount,
    EvalResult? currentEval,
    EvalResult? Function()? previousEval,
    int? livesRemaining,
    int? maxLives,
    bool? lastMoveWasMistake,
    List<SuggestedMove>? topMoves,
    String? Function()? openingName,
    String? Function()? openingEco,
    bool? isPlayerTurn,
    bool? isEngineThinking,
    bool? isGameOver,
    bool? showPrincipleCard,
    String? Function()? principleText,
    bool? isReviewing,
    int? reviewIndex,
    NormalMove? Function()? lastEngineMove,
    int? thinkingWave,
    int? thinkingTotalWaves,
  }) {
    return OpeningGameState(
      mode: mode ?? this.mode,
      difficulty: difficulty ?? this.difficulty,
      playerColor: playerColor ?? this.playerColor,
      currentFen: currentFen ?? this.currentFen,
      moveHistory: moveHistory ?? this.moveHistory,
      sanMoves: sanMoves ?? this.sanMoves,
      userMoveCount: userMoveCount ?? this.userMoveCount,
      currentEval: currentEval ?? this.currentEval,
      previousEval: previousEval != null ? previousEval() : this.previousEval,
      livesRemaining: livesRemaining ?? this.livesRemaining,
      maxLives: maxLives ?? this.maxLives,
      lastMoveWasMistake: lastMoveWasMistake ?? this.lastMoveWasMistake,
      topMoves: topMoves ?? this.topMoves,
      openingName: openingName != null ? openingName() : this.openingName,
      openingEco: openingEco != null ? openingEco() : this.openingEco,
      isPlayerTurn: isPlayerTurn ?? this.isPlayerTurn,
      isEngineThinking: isEngineThinking ?? this.isEngineThinking,
      isGameOver: isGameOver ?? this.isGameOver,
      showPrincipleCard: showPrincipleCard ?? this.showPrincipleCard,
      principleText: principleText != null ? principleText() : this.principleText,
      isReviewing: isReviewing ?? this.isReviewing,
      reviewIndex: reviewIndex ?? this.reviewIndex,
      lastEngineMove: lastEngineMove != null ? lastEngineMove() : this.lastEngineMove,
      thinkingWave: thinkingWave ?? this.thinkingWave,
      thinkingTotalWaves: thinkingTotalWaves ?? this.thinkingTotalWaves,
    );
  }
}
