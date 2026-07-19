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

/// Move classification. `best` is assigned by rank (the engine's #1 move),
/// `book` by opening-theory membership; the rest come from [classifyDelta].
enum MoveClassification {
  /// Reserved (not currently produced by [classifyDelta]).
  brilliant,
  /// The engine's top choice in this position.
  best,
  /// Keeps the eval close to the best move (loss ≤ 0.4 pawns)
  good,
  /// Part of established opening theory
  book,
  /// Loses 0.4 - 1.0 pawns vs. the best move
  inaccuracy,
  /// Loses 1.0 - 2.0 pawns vs. the best move
  mistake,
  /// Loses more than 2.0 pawns vs. the best move
  blunder,
}

/// Classify by centipawn loss vs. the best available move ([deltaPawns] ≤ 0
/// normally; small positives from search noise are treated as good).
/// Thresholds are deliberately forgiving: being 0.3 behind the engine's top
/// choice is a fine move, not an inaccuracy.
MoveClassification classifyDelta(double deltaPawns) {
  if (deltaPawns >= -0.4) return MoveClassification.good;
  if (deltaPawns >= -1.0) return MoveClassification.inaccuracy;
  if (deltaPawns >= -2.0) return MoveClassification.mistake;
  return MoveClassification.blunder;
}

/// Format a white-perspective eval for badge display: "+0.3", "-1.2", "M3".
String formatEval(int centipawns, int? mateIn) {
  if (mateIn != null) {
    return mateIn > 0 ? 'M$mateIn' : '-M${-mateIn}';
  }
  final pawns = centipawns / 100.0;
  return '${pawns >= 0 ? "+" : ""}${pawns.toStringAsFixed(1)}';
}

/// A dedicated single-move evaluation (selected-piece analysis).
class MoveEval {
  /// Position eval after the move, white's perspective.
  final int centipawns;
  final int? mateIn;

  /// Centipawn change vs. the current position's eval at the same depth,
  /// from the mover's perspective (negative = worsens their position).
  final int deltaCp;

  const MoveEval({
    required this.centipawns,
    this.mateIn,
    required this.deltaCp,
  });

  double get deltaPawns => deltaCp / 100.0;
}

class SuggestedMove {
  final String uci;
  final String san;

  /// Position eval after this move, white's perspective (only meaningful
  /// when [hasEval] is true).
  final int centipawns;
  final int? mateIn;

  /// Centipawn loss vs. the best move of the same search, from the mover's
  /// perspective (0 for the best move, negative for the rest). Drives color
  /// classification only — badges display the absolute [centipawns].
  final int evalDelta;

  /// Whether this move appears in established opening theory.
  final bool isBook;

  /// Whether this is the engine's #1 move (multipv 1).
  final bool isBest;

  /// False for book moves shown before/without an engine score.
  final bool hasEval;

  const SuggestedMove({
    required this.uci,
    required this.san,
    required this.centipawns,
    this.mateIn,
    this.evalDelta = 0,
    this.isBook = false,
    this.isBest = false,
    this.hasEval = true,
  });

  double get pawns => centipawns / 100.0;
  double get deltaPawns => evalDelta / 100.0;

  MoveClassification get classification {
    if (isBook) return MoveClassification.book;
    if (isBest) return MoveClassification.best;
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

  /// Depth the engine has reached in the current analysis (-1 = idle).
  final int engineDepth;
  /// Final depth the current analysis will run to (0 = no analysis running).
  final int engineTargetDepth;

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
    this.engineDepth = -1,
    this.engineTargetDepth = 0,
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
    int? engineDepth,
    int? engineTargetDepth,
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
      engineDepth: engineDepth ?? this.engineDepth,
      engineTargetDepth: engineTargetDepth ?? this.engineTargetDepth,
    );
  }
}
