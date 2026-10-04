import 'package:dartchess/dartchess.dart';

/// Ground-truth computation for the scanning drills (Find Checks, Find
/// Captures, Hanging Pieces, Mate in 1).
///
/// The curated assets under `assets/puzzles/scan_*.json` only carry a FEN and
/// a target count; the actual target squares are recomputed here at runtime.
/// These predicates MUST stay byte-equivalent to the python-chess mirrors in
/// `scripts/curate_scanning_positions.py` — the shared fixtures live in
/// `test/scan_engine_test.dart` and the script's `--self-test`.
class ScanEngine {
  ScanEngine._();

  /// Queen dominates rook/bishop lines, so trying queen + knight promotions
  /// is enough to decide whether SOME promotion on a destination gives check.
  static const List<Role> _checkPromotionRoles = [Role.queen, Role.knight];

  /// All four, for enumerating distinct mating moves.
  static const List<Role> _allPromotionRoles = [
    Role.queen,
    Role.knight,
    Role.rook,
    Role.bishop,
  ];

  static const Set<Role> defaultHangingRoles = {
    Role.knight,
    Role.bishop,
    Role.rook,
    Role.queen,
  };

  /// Destination squares of legal moves that give check.
  static Set<Square> checkTargets(Position position) =>
      checkTargetDetails(position).keys.toSet();

  /// Destination square -> the piece that delivers check by moving there
  /// (used for the faded ghost-piece feedback on found squares). For a
  /// promotion that's the promoted piece — the queen, or the knight when
  /// only a knight promotion checks — not the pawn.
  ///
  /// Castling is skipped on both sides of the cross-language contract
  /// (dartchess encodes it king->rook, python-chess king->g1/c1 — no sane
  /// shared tap square); curation rejects positions where castling gives
  /// check, so shipped sets never omit a real check. Promotion variants
  /// collapse onto their destination square. Curation also rejects positions
  /// where two checking moves from distinct origins share a destination, so
  /// the piece stored per square is unambiguous.
  static Map<Square, Piece> checkTargetDetails(Position position) {
    final result = <Square, Piece>{};
    final us = position.turn;
    final ownPieces = position.board.bySide(us);
    for (final entry in position.legalMoves.entries) {
      final from = entry.key;
      final piece = position.board.pieceAt(from);
      if (piece == null) continue;
      for (final to in entry.value.squares) {
        if (result.containsKey(to)) continue;
        // Castling is encoded as the king moving onto its own rook.
        if (piece.role == Role.king && ownPieces.has(to)) continue;
        final promotionRank = us == Side.white ? 7 : 0;
        final isPromotion =
            piece.role == Role.pawn && to.rank.value == promotionRank;
        if (isPromotion) {
          for (final promo in _checkPromotionRoles) {
            final move = NormalMove(from: from, to: to, promotion: promo);
            if (position.playUnchecked(move).isCheck) {
              result[to] = Piece(color: piece.color, role: promo);
              break;
            }
          }
        } else {
          final move = NormalMove(from: from, to: to);
          if (position.playUnchecked(move).isCheck) {
            result[to] = piece;
          }
        }
      }
    }
    return result;
  }

  /// Squares of enemy men that can be captured by a legal move, identified
  /// by destination occupancy. En passant is excluded automatically (its
  /// destination square is empty); promotion-captures are included
  /// automatically (their destination IS the victim's square).
  static Set<Square> captureTargets(Position position) {
    final enemy = position.board.bySide(position.turn.opposite);
    final result = <Square>{};
    for (final entry in position.legalMoves.entries) {
      for (final to in entry.value.squares) {
        if (enemy.has(to)) result.add(to);
      }
    }
    return result;
  }

  /// Enemy pieces (of [victimRoles]) with ZERO defenders — loose pieces in
  /// the LPDO sense. Whether the side to move can currently capture them is
  /// deliberately irrelevant: the drill trains spotting *looseness* anywhere
  /// on the board (loose pieces are what forks and double attacks farm).
  ///
  /// Defenders via [Board.attacksTo] are pseudo-attacks — pinned defenders
  /// and the king count.
  static Set<Square> hangingTargets(
    Position position, {
    Set<Role> victimRoles = defaultHangingRoles,
  }) {
    final owner = position.turn.opposite;
    final result = <Square>{};
    for (final (square, piece) in position.board.pieces) {
      if (piece.color != owner || !victimRoles.contains(piece.role)) continue;
      if (position.board.attacksTo(square, owner).isEmpty) {
        result.add(square);
      }
    }
    return result;
  }

  /// All legal moves that deliver checkmate (castling mates excluded here;
  /// [isMatingMove] still accepts one at judge time via `normalizeMove`).
  static Set<NormalMove> matingMoves(Position position) {
    final result = <NormalMove>{};
    final us = position.turn;
    final ownPieces = position.board.bySide(us);
    for (final entry in position.legalMoves.entries) {
      final from = entry.key;
      final piece = position.board.pieceAt(from);
      if (piece == null) continue;
      for (final to in entry.value.squares) {
        if (piece.role == Role.king && ownPieces.has(to)) continue;
        final promotionRank = us == Side.white ? 7 : 0;
        final isPromotion =
            piece.role == Role.pawn && to.rank.value == promotionRank;
        final candidates = isPromotion
            ? [
                for (final promo in _allPromotionRoles)
                  NormalMove(from: from, to: to, promotion: promo)
              ]
            : [NormalMove(from: from, to: to)];
        for (final move in candidates) {
          if (position.playUnchecked(move).isCheckmate) {
            result.add(move);
          }
        }
      }
    }
    return result;
  }

  /// Whether [move] is legal and delivers checkmate. This is the Mate in 1
  /// verdict: judged by RESULT, so any alternate mate counts — including a
  /// promotion mate (the board sends `promotion: Role.queen` under
  /// autoQueenPromotion) or, theoretically, a castling mate (normalized to
  /// dartchess's king->rook encoding first).
  static bool isMatingMove(Position position, NormalMove move) {
    final normalized = position.normalizeMove(move);
    if (!position.isLegal(normalized)) return false;
    return position.playUnchecked(normalized).isCheckmate;
  }
}
