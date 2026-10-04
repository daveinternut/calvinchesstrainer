import 'package:calvinchesstrainer/l10n/app_localizations.dart';
import 'package:chessground/chessground.dart' show SquareHighlight, Shape, Arrow;
import 'package:dartchess/dartchess.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import '../../../core/board_utils.dart';
import '../../../core/services/puzzle_service.dart';
import '../../../core/theme/app_theme.dart';

enum VisionDrillType {
  forksAndSkewers,
  knightSight,
  knightFlight,
  pawnAttack,
  findChecks,
  findCaptures,
  hangingPieces,
  mateInOne;

  /// The four scanning drills (curated real positions).
  bool get isScanDrill => isTapScanDrill || this == mateInOne;

  /// Scanning drills played by tapping target squares on a fixed board.
  bool get isTapScanDrill =>
      this == findChecks || this == findCaptures || this == hangingPieces;

  /// Knight Sight and Knight Flight: practice only, no piece or mode choice.
  bool get isKnightDrill => this == knightSight || this == knightFlight;

  /// The mode a game of this drill actually runs in. Knight drills are
  /// practice-only, and concentric belongs to Forks & Skewers alone — Pawn
  /// Attack and the scanning drills run it as their timed mode. The menu,
  /// the provider and the game screen all go through this one rule.
  VisionMode effectiveMode(VisionMode requested) {
    if (isKnightDrill) return VisionMode.practice;
    if (this != forksAndSkewers && requested == VisionMode.concentric) {
      return VisionMode.speed;
    }
    return requested;
  }
}

enum VisionMode { practice, speed, concentric }

enum WhitePiece {
  queen(Role.queen, 'Queen', PieceKind.whiteQueen),
  rook(Role.rook, 'Rook', PieceKind.whiteRook),
  bishop(Role.bishop, 'Bishop', PieceKind.whiteBishop),
  knight(Role.knight, 'Knight', PieceKind.whiteKnight);

  final Role role;
  final String label;
  final PieceKind pieceKind;
  const WhitePiece(this.role, this.label, this.pieceKind);

  String localizedLabel(AppLocalizations l10n) => switch (this) {
        WhitePiece.queen => l10n.queen,
        WhitePiece.rook => l10n.rook,
        WhitePiece.bishop => l10n.bishop,
        WhitePiece.knight => l10n.knight,
      };
}

enum TargetPiece {
  rook(Role.rook, 'Rook', PieceKind.blackRook),
  bishop(Role.bishop, 'Bishop', PieceKind.blackBishop),
  knight(Role.knight, 'Knight', PieceKind.blackKnight),
  queen(Role.queen, 'Queen', PieceKind.blackQueen);

  final Role role;
  final String label;
  final PieceKind pieceKind;
  const TargetPiece(this.role, this.label, this.pieceKind);

  String localizedLabel(AppLocalizations l10n) => switch (this) {
        TargetPiece.rook => l10n.rook,
        TargetPiece.bishop => l10n.bishop,
        TargetPiece.knight => l10n.knight,
        TargetPiece.queen => l10n.queen,
      };
}

/// Outcome of a Mate in 1 attempt (mirrors the move trainer's feedback).
class ScanMateFeedback {
  final bool isCorrect;
  final NormalMove? attemptedMove;
  final NormalMove solutionMove;

  const ScanMateFeedback({
    required this.isCorrect,
    required this.attemptedMove,
    required this.solutionMove,
  });
}

class ChessVisionState {
  final VisionDrillType drillType;
  final VisionMode mode;
  final WhitePiece whitePiece;
  final TargetPiece targetPiece;
  final Square targetSquare;
  final Set<Square> correctSquares;
  final Set<Square> foundSquares;
  final Square? incorrectFlashSquare;
  final bool showingRevealedAnswer;
  final bool hadErrorThisRound;
  final int configurationsCompleted;
  final int totalErrors;
  final int streak;
  final int bestStreak;
  final int? timeRemainingSeconds;
  final int elapsedSeconds;
  final int concentricIndex;

  /// Targets on this game's concentric spiral (those with a solution).
  final int concentricTotal;
  final bool isGameOver;
  final bool isRoundComplete;

  /// Set at game over when this run beat the saved personal best.
  final bool isNewRecord;

  // Knight drill fields
  final Square? knightSquare;
  final Square? flightTargetSquare;
  final List<Square> flightPath;
  final int? minimumMoves;
  final bool flightComplete;

  // Pawn Attack fields
  final Square? pieceSquare;
  final Set<Square> remainingPawns;
  final Set<Square> pawnThreatSquares;
  final int pawnAttackDifficulty;
  final int pawnAttackMoves;

  /// The current board's pawns as dealt — what "Start over" restores.
  final Set<Square> pawnAttackStartPawns;

  /// The player has trapped themselves: the pawns left can no longer all be
  /// captured from here (the screen then highlights "Start over").
  final bool pawnAttackDeadEnd;

  // Scanning drill fields (findChecks / findCaptures / hangingPieces /
  // mateInOne). Curated real positions: `scanPosition` is the ground truth,
  // `scanDisplayFen` is what the board renders (differs only after a correct
  // mate, where the played move stays on the board).
  final Chess? scanPosition;
  final String? scanDisplayFen;
  final Side scanSideToMove;
  final Map<Square, Piece> checkGhosts;
  final ParsedPuzzle? currentMatePuzzle;
  final ScanMateFeedback? mateFeedback;

  /// Mate in 1 only: the checkmated position after a correct move, so the
  /// board can highlight the mated king.
  final Position? matedPosition;

  /// True while a scanning drill's curated set loads, and in the neutral
  /// state a fresh provider starts in (before the screen calls startGame).
  final bool isLoading;

  /// The scanning drill's curated set could not be loaded; the screen offers
  /// a retry instead of an endless spinner.
  final bool loadFailed;

  static const Square blackKingSquare = Square.d5;

  const ChessVisionState({
    required this.drillType,
    required this.mode,
    required this.whitePiece,
    this.targetPiece = TargetPiece.rook,
    this.targetSquare = Square.d4,
    this.correctSquares = const {},
    this.foundSquares = const {},
    this.incorrectFlashSquare,
    this.showingRevealedAnswer = false,
    this.hadErrorThisRound = false,
    this.configurationsCompleted = 0,
    this.totalErrors = 0,
    this.streak = 0,
    this.bestStreak = 0,
    this.timeRemainingSeconds,
    this.elapsedSeconds = 0,
    this.concentricIndex = 0,
    this.concentricTotal = 0,
    this.isGameOver = false,
    this.isRoundComplete = false,
    this.isNewRecord = false,
    this.knightSquare,
    this.flightTargetSquare,
    this.flightPath = const [],
    this.minimumMoves,
    this.flightComplete = false,
    this.pieceSquare,
    this.remainingPawns = const {},
    this.pawnThreatSquares = const {},
    this.pawnAttackDifficulty = 3,
    this.pawnAttackMoves = 0,
    this.pawnAttackStartPawns = const {},
    this.pawnAttackDeadEnd = false,
    this.scanPosition,
    this.scanDisplayFen,
    this.scanSideToMove = Side.white,
    this.checkGhosts = const {},
    this.currentMatePuzzle,
    this.mateFeedback,
    this.matedPosition,
    this.isLoading = false,
    this.loadFailed = false,
  });

  ChessVisionState copyWith({
    VisionDrillType? drillType,
    VisionMode? mode,
    WhitePiece? whitePiece,
    TargetPiece? targetPiece,
    Square? targetSquare,
    Set<Square>? correctSquares,
    Set<Square>? foundSquares,
    Square? Function()? incorrectFlashSquare,
    bool? showingRevealedAnswer,
    bool? hadErrorThisRound,
    int? configurationsCompleted,
    int? totalErrors,
    int? streak,
    int? bestStreak,
    int? Function()? timeRemainingSeconds,
    int? elapsedSeconds,
    int? concentricIndex,
    int? concentricTotal,
    bool? isGameOver,
    bool? isRoundComplete,
    bool? isNewRecord,
    Square? Function()? knightSquare,
    Square? Function()? flightTargetSquare,
    List<Square>? flightPath,
    int? Function()? minimumMoves,
    bool? flightComplete,
    Square? Function()? pieceSquare,
    Set<Square>? remainingPawns,
    Set<Square>? pawnThreatSquares,
    int? pawnAttackDifficulty,
    int? pawnAttackMoves,
    Set<Square>? pawnAttackStartPawns,
    bool? pawnAttackDeadEnd,
    Chess? Function()? scanPosition,
    String? Function()? scanDisplayFen,
    Side? scanSideToMove,
    Map<Square, Piece>? checkGhosts,
    ParsedPuzzle? Function()? currentMatePuzzle,
    ScanMateFeedback? Function()? mateFeedback,
    Position? Function()? matedPosition,
    bool? isLoading,
    bool? loadFailed,
  }) {
    return ChessVisionState(
      drillType: drillType ?? this.drillType,
      mode: mode ?? this.mode,
      whitePiece: whitePiece ?? this.whitePiece,
      targetPiece: targetPiece ?? this.targetPiece,
      targetSquare: targetSquare ?? this.targetSquare,
      correctSquares: correctSquares ?? this.correctSquares,
      foundSquares: foundSquares ?? this.foundSquares,
      incorrectFlashSquare: incorrectFlashSquare != null
          ? incorrectFlashSquare()
          : this.incorrectFlashSquare,
      showingRevealedAnswer:
          showingRevealedAnswer ?? this.showingRevealedAnswer,
      hadErrorThisRound: hadErrorThisRound ?? this.hadErrorThisRound,
      configurationsCompleted:
          configurationsCompleted ?? this.configurationsCompleted,
      totalErrors: totalErrors ?? this.totalErrors,
      streak: streak ?? this.streak,
      bestStreak: bestStreak ?? this.bestStreak,
      timeRemainingSeconds: timeRemainingSeconds != null
          ? timeRemainingSeconds()
          : this.timeRemainingSeconds,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      concentricIndex: concentricIndex ?? this.concentricIndex,
      concentricTotal: concentricTotal ?? this.concentricTotal,
      isGameOver: isGameOver ?? this.isGameOver,
      isRoundComplete: isRoundComplete ?? this.isRoundComplete,
      isNewRecord: isNewRecord ?? this.isNewRecord,
      knightSquare:
          knightSquare != null ? knightSquare() : this.knightSquare,
      flightTargetSquare: flightTargetSquare != null
          ? flightTargetSquare()
          : this.flightTargetSquare,
      flightPath: flightPath ?? this.flightPath,
      minimumMoves:
          minimumMoves != null ? minimumMoves() : this.minimumMoves,
      flightComplete: flightComplete ?? this.flightComplete,
      pieceSquare:
          pieceSquare != null ? pieceSquare() : this.pieceSquare,
      remainingPawns: remainingPawns ?? this.remainingPawns,
      pawnThreatSquares: pawnThreatSquares ?? this.pawnThreatSquares,
      pawnAttackDifficulty:
          pawnAttackDifficulty ?? this.pawnAttackDifficulty,
      pawnAttackMoves: pawnAttackMoves ?? this.pawnAttackMoves,
      pawnAttackStartPawns: pawnAttackStartPawns ?? this.pawnAttackStartPawns,
      pawnAttackDeadEnd: pawnAttackDeadEnd ?? this.pawnAttackDeadEnd,
      scanPosition:
          scanPosition != null ? scanPosition() : this.scanPosition,
      scanDisplayFen:
          scanDisplayFen != null ? scanDisplayFen() : this.scanDisplayFen,
      scanSideToMove: scanSideToMove ?? this.scanSideToMove,
      checkGhosts: checkGhosts ?? this.checkGhosts,
      currentMatePuzzle: currentMatePuzzle != null
          ? currentMatePuzzle()
          : this.currentMatePuzzle,
      mateFeedback: mateFeedback != null ? mateFeedback() : this.mateFeedback,
      matedPosition:
          matedPosition != null ? matedPosition() : this.matedPosition,
      isLoading: isLoading ?? this.isLoading,
      loadFailed: loadFailed ?? this.loadFailed,
    );
  }

  String get boardFen {
    switch (drillType) {
      case VisionDrillType.forksAndSkewers:
        var b = Board.empty
            .setPieceAt(blackKingSquare, Piece.blackKing)
            .setPieceAt(
                targetSquare, Piece(color: Side.black, role: targetPiece.role));
        return b.fen;
      case VisionDrillType.knightSight:
      case VisionDrillType.knightFlight:
        if (knightSquare == null) return Board.empty.fen;
        final currentPos =
            flightPath.isNotEmpty ? flightPath.last : knightSquare!;
        var b = Board.empty.setPieceAt(currentPos, Piece.whiteKnight);
        return b.fen;
      case VisionDrillType.pawnAttack:
        if (pieceSquare == null) return Board.empty.fen;
        var b = Board.empty.setPieceAt(
            pieceSquare!, Piece(color: Side.white, role: whitePiece.role));
        for (final pawn in remainingPawns) {
          b = b.setPieceAt(
              pawn, const Piece(color: Side.black, role: Role.pawn));
        }
        return b.fen;
      case VisionDrillType.findChecks:
      case VisionDrillType.findCaptures:
      case VisionDrillType.hangingPieces:
      case VisionDrillType.mateInOne:
        return scanDisplayFen ?? Board.empty.fen;
    }
  }

  /// Scanning drills orient the board to the side the kid is playing (real
  /// positions come with either side to move — flipped-board training).
  /// Every other drill keeps the fixed white orientation.
  Side get boardOrientation =>
      drillType.isScanDrill ? scanSideToMove : Side.white;

  int get totalFound => foundSquares.length;
  int get totalCorrect => correctSquares.length;
  bool get allFound =>
      correctSquares.isNotEmpty && foundSquares.length >= correctSquares.length;

  IMap<Square, SquareHighlight> get allHighlights {
    IMap<Square, SquareHighlight> highlights =
        const IMapConst<Square, SquareHighlight>({});

    switch (drillType) {
      case VisionDrillType.forksAndSkewers:
      case VisionDrillType.knightSight:
      case VisionDrillType.findChecks:
      case VisionDrillType.findCaptures:
      case VisionDrillType.hangingPieces:
        for (final sq in foundSquares) {
          highlights = highlights.addAll(highlightSquare(
            sq.file.value,
            sq.rank.value,
            AppColors.correctGreen.withValues(alpha: 0.6),
          ));
        }

        if (showingRevealedAnswer) {
          for (final sq in correctSquares) {
            if (!foundSquares.contains(sq)) {
              highlights = highlights.addAll(highlightSquare(
                sq.file.value,
                sq.rank.value,
                AppColors.highlightYellow.withValues(alpha: 0.6),
              ));
            }
          }
        }
      case VisionDrillType.knightFlight:
        // Landing-pad tint on the destination (paired with the amber goal ring
        // drawn as a shape). Added first so the green move-path overrides it
        // once the knight actually lands there.
        final target = flightTargetSquare;
        if (target != null) {
          highlights = highlights.addAll(highlightSquare(
            target.file.value,
            target.rank.value,
            AppColors.goalAmber.withValues(alpha: 0.30),
          ));
        }
        for (final sq in flightPath) {
          highlights = highlights.addAll(highlightSquare(
            sq.file.value,
            sq.rank.value,
            AppColors.correctGreen.withValues(alpha: 0.4),
          ));
        }
      case VisionDrillType.pawnAttack:
        final threats = pawnThreatSquares;
        for (final sq in threats) {
          if (!remainingPawns.contains(sq) && sq != pieceSquare) {
            highlights = highlights.addAll(highlightSquare(
              sq.file.value,
              sq.rank.value,
              AppColors.incorrectRed.withValues(alpha: 0.15),
            ));
          }
        }
      case VisionDrillType.mateInOne:
        // On a correct mate the played move stays highlighted (the wrong-move
        // case is carried by the solution arrow in [mateFeedbackShapes]).
        final feedback = mateFeedback;
        if (feedback != null && feedback.isCorrect) {
          final move = feedback.attemptedMove;
          if (move != null) {
            for (final sq in [move.from, move.to]) {
              highlights = highlights.addAll(highlightSquare(
                sq.file.value,
                sq.rank.value,
                AppColors.correctGreen.withValues(alpha: 0.6),
              ));
            }
          }
        }
    }

    final flash = incorrectFlashSquare;
    if (flash != null) {
      highlights = highlights.addAll(highlightSquare(
        flash.file.value,
        flash.rank.value,
        AppColors.incorrectRed.withValues(alpha: 0.6),
      ));
    }

    return highlights;
  }

  /// Mate in 1 only: a green arrow revealing the dataset's solution after a
  /// wrong attempt (move-trainer feedback pattern).
  ISet<Shape> get mateFeedbackShapes {
    final feedback = mateFeedback;
    if (drillType != VisionDrillType.mateInOne ||
        feedback == null ||
        feedback.isCorrect) {
      return const ISetConst({});
    }
    return ISet({
      Arrow(
        color: AppColors.correctGreen.withValues(alpha: 0.8),
        orig: feedback.solutionMove.from,
        dest: feedback.solutionMove.to,
      ),
    });
  }
}

const concentricPath = [
  Square.d4, Square.e4, Square.e5, Square.e6, Square.d6, Square.c6,
  Square.c5, Square.c4,
  Square.c3, Square.d3, Square.e3, Square.f3, Square.f4, Square.f5,
  Square.f6, Square.f7, Square.e7, Square.d7, Square.c7, Square.b7,
  Square.b6, Square.b5, Square.b4, Square.b3,
  Square.b2, Square.c2, Square.d2, Square.e2, Square.f2, Square.g2,
  Square.g3, Square.g4, Square.g5, Square.g6, Square.g7, Square.g8,
  Square.f8, Square.e8, Square.d8, Square.c8, Square.b8, Square.a8,
  Square.a7, Square.a6, Square.a5, Square.a4, Square.a3, Square.a2,
  Square.a1, Square.b1, Square.c1, Square.d1, Square.e1, Square.f1,
  Square.g1, Square.h1, Square.h2, Square.h3, Square.h4, Square.h5,
  Square.h6, Square.h7, Square.h8,
];
