import 'dart:math';

import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:calvinchesstrainer/features/chess_vision/models/chess_vision_state.dart';
import 'package:calvinchesstrainer/features/chess_vision/services/fork_skewer_engine.dart';

const _king = Square.d5;

Set<Square> _solve(WhitePiece piece, Square target,
        [Role targetRole = Role.rook]) =>
    ForkSkewerEngine.computeValidSquares(
      whitePiece: piece,
      kingSquare: _king,
      targetSquare: target,
      targetRole: targetRole,
    );

Set<Square> _squares(List<String> names) => names.map(Square.fromName).toSet();

int _distance(Square a, Square b) => max(
      (a.file.value - b.file.value).abs(),
      (a.rank.value - b.rank.value).abs(),
    );

/// Squares strictly between [a] and [b] when they share a line (hand-rolled,
/// independent of the engine's dartchess `between`).
List<Square> _lineBetween(Square a, Square b) {
  final df = b.file.value - a.file.value;
  final dr = b.rank.value - a.rank.value;
  if (!(df == 0 || dr == 0 || df.abs() == dr.abs())) return const [];
  final stepF = df.sign, stepR = dr.sign;
  final result = <Square>[];
  var f = a.file.value + stepF, r = a.rank.value + stepR;
  while (f != b.file.value || r != b.rank.value) {
    result.add(Square.fromCoords(File(f), Rank(r)));
    f += stepF;
    r += stepR;
  }
  return result;
}

/// First-principles verdict with an explicit white king on [whiteKing]: the
/// white piece on [z] gives check, and against EVERY black reply it can take
/// the target without the black king taking back.
bool _winsWithKing(
    Role piece, Square z, Square whiteKing, Square target, Role targetRole) {
  final board = Board.empty
      .setPieceAt(whiteKing, Piece.whiteKing)
      .setPieceAt(z, Piece(color: Side.white, role: piece))
      .setPieceAt(_king, Piece.blackKing)
      .setPieceAt(target, Piece(color: Side.black, role: targetRole));
  final Position position;
  try {
    position = Chess.fromSetup(
      Setup(
        board: board,
        turn: Side.black,
        castlingRights: SquareSet.empty,
        halfmoves: 0,
        fullmoves: 1,
      ),
      ignoreImpossibleCheck: true,
    );
  } catch (_) {
    return false; // e.g. the white king would be in check
  }
  if (!position.isCheck || !position.hasSomeLegalMoves) return false;
  for (final entry in position.legalMoves.entries) {
    for (final to in entry.value.squares) {
      if (entry.key == target && to == z) return false; // target takes back
      final afterBlack = position.playUnchecked(
        NormalMove(from: entry.key, to: to),
      );
      final targetNow = entry.key == target ? to : target;
      final capture = NormalMove(from: z, to: targetNow);
      if (!afterBlack.isLegal(capture)) return false;
      final afterCapture = afterBlack.playUnchecked(capture);
      for (final reply in afterCapture.legalMoves.values) {
        if (reply.has(targetNow)) return false; // black king takes back
      }
    }
  }
  return true;
}

/// Reference: [z] is a solution if SOME white-king square far from the
/// action proves it. "Far" = 3+ from the black king, 2+ from the white piece,
/// the target and every square where the target could block, and not on the
/// line between the white piece and the target.
Set<Square> _reference(Role piece, Square target, Role targetRole) {
  final result = <Square>{};
  for (final z in Square.values) {
    if (z == _king || z == target) continue;
    final blocks = _lineBetween(z, _king);
    final targetLine = _lineBetween(z, target);
    for (final whiteKing in Square.values) {
      if (whiteKing == z || whiteKing == target || whiteKing == _king) continue;
      if (_distance(whiteKing, _king) < 3 ||
          _distance(whiteKing, z) < 2 ||
          _distance(whiteKing, target) < 2) {
        continue;
      }
      if (blocks.any((b) => _distance(whiteKing, b) < 2)) continue;
      if (targetLine.contains(whiteKing)) continue;
      if (_winsWithKing(piece, z, whiteKing, target, targetRole)) {
        result.add(z);
        break;
      }
    }
  }
  return result;
}

/// Whether the white piece on [z] attacks the black king on [_king] with the
/// target on [target] (the first condition of every fork and skewer).
bool _givesCheck(WhitePiece piece, Square z, Square target) {
  final occupied = SquareSet.fromSquare(_king)
      .withSquare(target)
      .withSquare(z);
  return attacks(Piece(color: Side.white, role: piece.role), z, occupied)
      .has(_king);
}

void main() {
  group('ForkSkewerEngine — known positions', () {
    test('queen vs rook on d4 (next to the king): no solutions', () {
      // The king can always take the rook back after the queen captures.
      expect(_solve(WhitePiece.queen, Square.d4), isEmpty);
    });

    test('bishop skewers along the long diagonal (rook on f3)', () {
      expect(_solve(WhitePiece.bishop, Square.f3),
          containsAll(_squares(['a8', 'b7'])));
    });

    test('knight on c3 forks the king on d5 and the rook on b1', () {
      expect(_solve(WhitePiece.knight, Square.b1), contains(Square.c3));
    });

    test('knight vs rook on h8: no square is a knight jump from both', () {
      expect(_solve(WhitePiece.knight, Square.h8), isEmpty);
    });

    test('rook vs rook on d4: the king always defends its rook', () {
      expect(_solve(WhitePiece.rook, Square.d4), isEmpty);
    });

    test('queen vs bishop on f3 has solutions', () {
      expect(_solve(WhitePiece.queen, Square.f3, Role.bishop), isNotEmpty);
    });
  });

  group('ForkSkewerEngine — corner targets (white king placement)', () {
    test('rook on a8: Qh1 and Bh1 skewer it through the king', () {
      expect(_solve(WhitePiece.queen, Square.a8), contains(Square.h1));
      expect(_solve(WhitePiece.bishop, Square.a8), contains(Square.h1));
      // Hand-checked with the white king visibly out of the way on c1.
      expect(
          _winsWithKing(Role.queen, Square.h1, Square.c1, Square.a8, Role.rook),
          isTrue);
    });

    test('rook on h1: Qa8 and Ba8 skewer it through the king', () {
      expect(_solve(WhitePiece.queen, Square.h1), contains(Square.a8));
      expect(_solve(WhitePiece.bishop, Square.h1), contains(Square.a8));
    });

    test('queen on a8: Qf3, Qg2 and Qh1 skewer it', () {
      expect(_solve(WhitePiece.queen, Square.a8, Role.queen),
          containsAll(_squares(['f3', 'g2', 'h1'])));
    });

    test('queen on h1: Qb7 and Qa8 skewer it', () {
      expect(_solve(WhitePiece.queen, Square.h1, Role.queen),
          containsAll(_squares(['b7', 'a8'])));
    });

    test('queen on a8: Nb6 and Nc7 fork it with the king', () {
      expect(_solve(WhitePiece.knight, Square.a8, Role.queen),
          containsAll(_squares(['b6', 'c7'])));
    });
  });

  group('ForkSkewerEngine — every pairing', () {
    test('knight vs knight has no solution anywhere (they take each other)',
        () {
      for (final target in Square.values.where((s) => s != _king)) {
        expect(_solve(WhitePiece.knight, target, Role.knight), isEmpty,
            reason: target.name);
      }
    });

    test('every other pairing has targets with solutions', () {
      for (final piece in WhitePiece.values) {
        for (final target in TargetPiece.values) {
          if (piece == WhitePiece.knight && target == TargetPiece.knight) {
            continue;
          }
          final withSolutions = concentricPath
              .where((t) => _solve(piece, t, target.role).isNotEmpty)
              .length;
          expect(withSolutions, greaterThanOrEqualTo(6),
              reason: '${piece.name} vs ${target.name}');
        }
      }
    });

    test('every solution gives check, and bishops stay on the king\'s colour',
        () {
      for (final piece in WhitePiece.values) {
        for (final target in TargetPiece.values) {
          for (final targetSquare in concentricPath) {
            for (final z in _solve(piece, targetSquare, target.role)) {
              expect(z, isNot(anyOf(_king, targetSquare)));
              expect(_givesCheck(piece, z, targetSquare), isTrue,
                  reason: '${piece.name}@${z.name} vs '
                      '${target.name}@${targetSquare.name}');
              if (piece == WhitePiece.bishop) {
                // d5 is a light square: a checking bishop is on one too.
                expect((z.file.value + z.rank.value) % 2,
                    (_king.file.value + _king.rank.value) % 2);
              }
            }
          }
        }
      }
    });

    test('matches a brute-force neutral-king reference: 16 pairings × 63 '
        'targets', () {
      final mismatches = <String>[];
      for (final piece in WhitePiece.values) {
        for (final target in TargetPiece.values) {
          for (final targetSquare in concentricPath) {
            final engine = _solve(piece, targetSquare, target.role);
            final reference =
                _reference(piece.role, targetSquare, target.role);
            final missing = reference.difference(engine);
            final extra = engine.difference(reference);
            if (missing.isNotEmpty || extra.isNotEmpty) {
              mismatches.add('${piece.name} vs ${target.name}@'
                  '${targetSquare.name}: missing '
                  '${missing.map((s) => s.name).toList()} extra '
                  '${extra.map((s) => s.name).toList()}');
            }
          }
        }
      }
      expect(mismatches, isEmpty);
    });

    test('the concentric spiral covers all 63 squares around the king once',
        () {
      expect(concentricPath, hasLength(63));
      expect(concentricPath.toSet(), hasLength(63));
      expect(concentricPath, isNot(contains(_king)));
    });
  });
}
