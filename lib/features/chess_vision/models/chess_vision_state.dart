import 'package:chessground/chessground.dart' show SquareHighlight;
import 'package:dartchess/dartchess.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import '../../../core/board_utils.dart';
import '../../../core/theme/app_theme.dart';

enum VisionDrillType { forksAndSkewers, knightSight, knightFlight, pawnAttack }

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
  final bool isGameOver;
  final bool isRoundComplete;

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
    this.isGameOver = false,
    this.isRoundComplete = false,
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
    bool? isGameOver,
    bool? isRoundComplete,
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
      isGameOver: isGameOver ?? this.isGameOver,
      isRoundComplete: isRoundComplete ?? this.isRoundComplete,
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
    }
  }

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
