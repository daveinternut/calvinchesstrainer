import 'dart:math';

import 'package:dartchess/dartchess.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import '../models/chess_vision_state.dart';

class ForkSkewerEngine {
  ForkSkewerEngine._();

  static Set<Square> computeValidSquares({
    required WhitePiece whitePiece,
    required Square kingSquare,
    required Square targetSquare,
    Role targetRole = Role.rook,
  }) {
    final result = <Square>{};

    for (final z in Square.values) {
      if (z == kingSquare || z == targetSquare) continue;

      final withoutWhiteKing = Board.empty
          .setPieceAt(z, Piece(color: Side.white, role: whitePiece.role))
          .setPieceAt(kingSquare, Piece.blackKing)
          .setPieceAt(targetSquare, Piece(color: Side.black, role: targetRole));

      final wkSquare = _findNeutralWhiteKingSquare(
        board: withoutWhiteKing,
        kingSquare: kingSquare,
        targetSquare: targetSquare,
        pieceSquare: z,
      );
      if (wkSquare == null) continue;

      final position = _buildPosition(
        withoutWhiteKing.setPieceAt(wkSquare, Piece.whiteKing),
      );
      if (position == null) continue;

      if (!position.isCheck) continue;

      final legalMoves = position.legalMoves;
      if (!position.hasSomeLegalMoves) continue;

      if (_allLinesWinTarget(
        position: position,
        legalMoves: legalMoves,
        pieceSquare: z,
        targetSquare: targetSquare,
      )) {
        result.add(z);
      }
    }

    return result;
  }

  static bool _allLinesWinTarget({
    required Position position,
    required IMap<Square, SquareSet> legalMoves,
    required Square pieceSquare,
    required Square targetSquare,
  }) {
    for (final entry in legalMoves.entries) {
      final fromSq = entry.key;
      for (final toSq in entry.value.squares) {
        final blackMove = NormalMove(from: fromSq, to: toSq);

        if (fromSq == targetSquare && toSq == pieceSquare) {
          return false;
        }

        final pos2 = position.playUnchecked(blackMove);

        final rookNow = (fromSq == targetSquare) ? toSq : targetSquare;

        final capture = NormalMove(from: pieceSquare, to: rookNow);
        if (!pos2.isLegal(capture)) return false;

        final pos3 = pos2.playUnchecked(capture);

        if (_canKingRecapture(pos3, rookNow)) return false;
      }
    }

    return true;
  }

  static bool _canKingRecapture(Position position, Square captureSquare) {
    final moves = position.legalMoves;
    for (final entry in moves.entries) {
      if (entry.value.has(captureSquare)) return true;
    }
    return false;
  }

  static Position? _buildPosition(Board board) {
    final setup = Setup(
      board: board,
      turn: Side.black,
      castlingRights: SquareSet.empty,
      halfmoves: 0,
      fullmoves: 1,
    );

    try {
      return Chess.fromSetup(setup, ignoreImpossibleCheck: true);
    } catch (_) {
      return null;
    }
  }

  static const _corners = [Square.h1, Square.a1, Square.h8, Square.a8];

  /// Corners first (where the king has always been parked), then every other
  /// square as a fallback.
  static final List<Square> _whiteKingCandidates = [
    ..._corners,
    ...Square.values.where((s) => !_corners.contains(s)),
  ];

  /// The white king never appears in the drill (the board shows only the
  /// black king and the target), so it must stand where it changes nothing:
  /// - not in check — real attacks, blockers included;
  /// - at least 3 squares from the black king, so it takes away none of the
  ///   king's escape squares;
  /// - not next to the white piece, the target, or a square where the target
  ///   could block the check (it would defend the white piece there and stop
  ///   the black king recapturing);
  /// - not between the white piece and the target (it would block the fork,
  ///   the skewer, or the target's own capture of the white piece).
  ///
  /// Any square that passes gives the same answer. Corners are tried first;
  /// a rook or queen target on a corner sees the other corners, so the
  /// fallback squares keep those positions from being silently skipped.
  static Square? _findNeutralWhiteKingSquare({
    required Board board,
    required Square kingSquare,
    required Square targetSquare,
    required Square pieceSquare,
  }) {
    final blockSquares = between(pieceSquare, kingSquare).squares.toList();
    final targetLine = between(pieceSquare, targetSquare);

    for (final square in _whiteKingCandidates) {
      if (square == kingSquare ||
          square == targetSquare ||
          square == pieceSquare) {
        continue;
      }
      if (_distance(square, kingSquare) < 3) continue;
      if (_distance(square, pieceSquare) < 2 ||
          _distance(square, targetSquare) < 2) {
        continue;
      }
      if (blockSquares.any((b) => _distance(square, b) < 2)) continue;
      if (targetLine.has(square)) continue;
      if (board.attacksTo(square, Side.black).isNotEmpty) continue;
      return square;
    }
    return null;
  }

  /// King-move distance between two squares.
  static int _distance(Square a, Square b) => max(
        (a.file.value - b.file.value).abs(),
        (a.rank.value - b.rank.value).abs(),
      );
}
