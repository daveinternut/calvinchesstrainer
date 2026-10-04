import 'package:dartchess/dartchess.dart';

/// [move] (legal in [position]) spelled the way Stockfish and the hint
/// arrows spell it — the one encoding used for every move key in the
/// Opening trainer:
///
/// - **Castling** as the king's two-square move (`e1g1`). dartchess's
///   legal-move sets and SAN parser encode it as king-takes-own-rook
///   (`e1h1`), which drew a second O-O arrow beside the engine's and an
///   arrow onto the rook.
/// - **Promotion** always explicit: a pawn reaching the last rank becomes a
///   queen, as the board auto-queens (`e7e8q`). Without it, analysis played
///   a pawn that stayed a pawn on the 8th rank.
NormalMove standardMove(Position position, NormalMove move) {
  final board = position.board;
  final mover = board.pieceAt(move.from);
  if (mover == null) return move;

  if (mover.role == Role.king) {
    final target = board.pieceAt(move.to);
    if (target != null &&
        target.color == mover.color &&
        target.role == Role.rook) {
      final side =
          move.to.file > move.from.file ? CastlingSide.king : CastlingSide.queen;
      return NormalMove(from: move.from, to: kingCastlesTo(mover.color, side));
    }
    return move;
  }

  if (mover.role == Role.pawn &&
      move.promotion == null &&
      (move.to.rank == Rank.first || move.to.rank == Rank.eighth)) {
    return move.withPromotion(Role.queen);
  }
  return move;
}

/// Standard UCI for [move] played from [position]: `e1g1`, `e7e8q`.
String toUci(Position position, NormalMove move) =>
    standardMove(position, move).uci;

/// Parses engine UCI (`e2e4`, `e7e8q`). Null for anything else — including
/// `(none)`, Stockfish's answer for a position with no legal move.
NormalMove? parseUci(String uci) {
  if (uci.length != 4 && uci.length != 5) return null;
  final move = Move.parse(uci);
  return move is NormalMove ? move : null;
}
