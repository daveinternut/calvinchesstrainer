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

      final wkSquare = _findSafeWhiteKingSquare(targetSquare, z, targetRole);
      if (wkSquare == null) continue;

      final position = _buildPosition(
        whiteKing: wkSquare,
        whitePiece: whitePiece.role,
        pieceSquare: z,
        blackKing: kingSquare,
        blackTarget: targetSquare,
        targetRole: targetRole,
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

  static Position? _buildPosition({
    required Square whiteKing,
    required Role whitePiece,
    required Square pieceSquare,
    required Square blackKing,
    required Square blackTarget,
    required Role targetRole,
  }) {
    var board = Board.empty
        .setPieceAt(whiteKing, Piece.whiteKing)
        .setPieceAt(pieceSquare, Piece(color: Side.white, role: whitePiece))
        .setPieceAt(blackKing, Piece.blackKing)
        .setPieceAt(blackTarget, Piece(color: Side.black, role: targetRole));

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

  static const _cornerCandidates = [Square.h1, Square.a1, Square.h8, Square.a8];

  static Square? _findSafeWhiteKingSquare(
      Square target, Square candidate, Role targetRole) {
    for (final corner in _cornerCandidates) {
      if (corner == target || corner == candidate) continue;
      if (_isAttackedByPiece(corner, target, targetRole)) continue;
      if (_isAdjacent(corner, target)) continue;
      return corner;
    }
    return null;
  }

  static bool _isAttackedByPiece(Square square, Square pieceSquare, Role role) {
    switch (role) {
      case Role.rook:
        return square.file == pieceSquare.file ||
            square.rank == pieceSquare.rank;
      case Role.bishop:
        final fileDiff = (square.file.value - pieceSquare.file.value).abs();
        final rankDiff = (square.rank.value - pieceSquare.rank.value).abs();
        return fileDiff == rankDiff && fileDiff > 0;
      case Role.queen:
        return _isAttackedByPiece(square, pieceSquare, Role.rook) ||
            _isAttackedByPiece(square, pieceSquare, Role.bishop);
      case Role.knight:
        final fileDiff = (square.file.value - pieceSquare.file.value).abs();
        final rankDiff = (square.rank.value - pieceSquare.rank.value).abs();
        return (fileDiff == 1 && rankDiff == 2) ||
            (fileDiff == 2 && rankDiff == 1);
      default:
        return false;
    }
  }

  static bool _isAdjacent(Square a, Square b) {
    final fileDiff = (a.file.value - b.file.value).abs();
    final rankDiff = (a.rank.value - b.rank.value).abs();
    return fileDiff <= 1 && rankDiff <= 1;
  }
}
