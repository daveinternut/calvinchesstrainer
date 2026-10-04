import 'dart:math';
import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:calvinchesstrainer/features/chess_vision/services/pawn_attack_engine.dart';

void main() {
  group('PawnAttackEngine.pawnThreats', () {
    test('single pawn on e5 threatens d4 and f4', () {
      final threats = PawnAttackEngine.pawnThreats({Square.e5});
      expect(threats, containsAll([Square.d4, Square.f4]));
      expect(threats.length, 2);
    });

    test('pawn on a3 threatens only b2 (a-file has no left diagonal)', () {
      final threats = PawnAttackEngine.pawnThreats({Square.a3});
      expect(threats, contains(Square.b2));
      expect(threats.length, 1);
    });

    test('pawn on h4 threatens only g3', () {
      final threats = PawnAttackEngine.pawnThreats({Square.h4});
      expect(threats, contains(Square.g3));
      expect(threats.length, 1);
    });

    test('pawn on rank 1 has no threats (edge case)', () {
      final threats = PawnAttackEngine.pawnThreats({Square.e1});
      expect(threats, isEmpty);
    });
  });

  group('PawnAttackEngine.validMoves', () {
    test('knight on a1 with no pawns can move to b3 and c2', () {
      final moves = PawnAttackEngine.validMoves(
        role: Role.knight,
        from: Square.a1,
        remainingPawns: {},
      );
      expect(moves, containsAll([Square.b3, Square.c2]));
    });

    test('knight avoids pawn threat squares', () {
      final moves = PawnAttackEngine.validMoves(
        role: Role.knight,
        from: Square.a1,
        remainingPawns: {Square.c3},
      );
      expect(moves, isNot(contains(Square.b2)));
      expect(moves, contains(Square.c2));
    });

    test('rook blocked by pawn on same file', () {
      final moves = PawnAttackEngine.validMoves(
        role: Role.rook,
        from: Square.a1,
        remainingPawns: {Square.a4},
      );
      expect(moves, containsAll([Square.a2, Square.a3, Square.a4]));
      expect(moves, isNot(contains(Square.a5)));
    });

    test('rook passes through pawn threat but cannot land there', () {
      // Pawn on b4 threatens a3 and c3 — rook can pass through a3 but not land
      final moves = PawnAttackEngine.validMoves(
        role: Role.rook,
        from: Square.a1,
        remainingPawns: {Square.b4},
      );
      expect(moves, contains(Square.a2));
      expect(moves, isNot(contains(Square.a3)));
      expect(moves, contains(Square.a4));
      expect(moves, contains(Square.a5));
    });

    test('bishop moves along diagonals', () {
      final moves = PawnAttackEngine.validMoves(
        role: Role.bishop,
        from: Square.d4,
        remainingPawns: {},
      );
      expect(moves, contains(Square.e5));
      expect(moves, contains(Square.a1));
      expect(moves, contains(Square.g7));
    });

    test('knight can capture pawn (landing on pawn square)', () {
      final moves = PawnAttackEngine.validMoves(
        role: Role.knight,
        from: Square.a1,
        remainingPawns: {Square.b3},
      );
      expect(moves, contains(Square.b3));
    });
  });

  group('PawnAttackEngine.generatePawns', () {
    test('generates correct number of pawns', () {
      final rng = Random(42);
      final pawns = PawnAttackEngine.generatePawns(5, rng, role: Role.queen);
      expect(pawns.length, 5);
    });

    test('pawns are on ranks 2-7', () {
      final rng = Random(42);
      final pawns = PawnAttackEngine.generatePawns(8, rng, role: Role.rook);
      for (final p in pawns) {
        expect(p.rank.value, greaterThanOrEqualTo(1));
        expect(p.rank.value, lessThanOrEqualTo(6));
      }
    });

    test('a1 is never occupied by a pawn', () {
      for (var i = 0; i < 20; i++) {
        final pawns =
            PawnAttackEngine.generatePawns(8, Random(i), role: Role.knight);
        expect(pawns, isNot(contains(Square.a1)));
      }
    });

    test('dark squares only for the bishop (and on request)', () {
      final bishop =
          PawnAttackEngine.generatePawns(5, Random(42), role: Role.bishop);
      final forced = PawnAttackEngine.generatePawns(5, Random(42),
          role: Role.queen, darkSquaresOnly: true);
      for (final p in {...bishop, ...forced}) {
        expect(PawnAttackEngine.isDarkSquare(p), isTrue,
            reason: '${p.name} should be a dark square');
      }
    });

    test('a1 is not threatened by initial pawns', () {
      for (var i = 0; i < 20; i++) {
        final pawns =
            PawnAttackEngine.generatePawns(5, Random(i), role: Role.queen);
        final threats = PawnAttackEngine.pawnThreats(pawns);
        expect(threats, isNot(contains(Square.a1)),
            reason: 'a1 should not be threatened');
      }
    });

    test('every dealt board is solvable for the piece that plays it', () {
      // Without the solvability check, about 1 knight board in 30 at level 8
      // left the knight on a1 with no safe first hop (e.g. pawns c4 + d3).
      for (final role in [Role.knight, Role.bishop, Role.rook, Role.queen]) {
        for (var level = 3; level <= 8; level++) {
          for (var seed = 0; seed < 120; seed++) {
            final pawns = PawnAttackEngine.generatePawns(
                level, Random(seed * 31 + level),
                role: role);
            expect(pawns, hasLength(level));
            expect(_referenceSolvable(role, Square.a1, pawns), isTrue,
                reason: '$role level $level: ${pawns.map((s) => s.name)}');
          }
        }
      }
    });
  });

  group('PawnAttackEngine.isSolvable', () {
    test('a knight boxed in on a1 (b3 and c2 attacked) is not solvable', () {
      final pawns = {Square.c4, Square.d3};
      expect(
          PawnAttackEngine.validMoves(
              role: Role.knight, from: Square.a1, remainingPawns: pawns),
          isEmpty);
      expect(
          PawnAttackEngine.isSolvable(
              role: Role.knight, from: Square.a1, pawns: pawns),
          isFalse);
    });

    test('the same pawns are solvable for a queen', () {
      expect(
          PawnAttackEngine.isSolvable(
              role: Role.queen, from: Square.a1, pawns: {Square.c4, Square.d3}),
          isTrue);
    });

    test('no pawns left is solved', () {
      expect(
          PawnAttackEngine.isSolvable(
              role: Role.knight, from: Square.h8, pawns: const {}),
          isTrue);
    });

    test('agrees with an independent search on random boards', () {
      final rng = Random(5);
      for (final role in [Role.knight, Role.bishop, Role.rook, Role.queen]) {
        for (var i = 0; i < 150; i++) {
          final pawns = <Square>{};
          final count = 1 + rng.nextInt(7);
          while (pawns.length < count) {
            final sq = Square(8 + rng.nextInt(48)); // ranks 2–7
            if (sq != Square.a1) pawns.add(sq);
          }
          final from = Square(rng.nextInt(64));
          if (pawns.contains(from)) continue;
          expect(
            PawnAttackEngine.isSolvable(role: role, from: from, pawns: pawns),
            _referenceSolvable(role, from, pawns),
            reason: '$role from ${from.name}: ${pawns.map((s) => s.name)}',
          );
        }
      }
    });
  });
}

/// Independent breadth-first search over (square, pawns left).
bool _referenceSolvable(Role role, Square from, Set<Square> pawns) {
  final start = (from, pawns.map((s) => s.name).toSet());
  final seen = <String>{};
  final queue = <(Square, Set<String>)>[start];
  while (queue.isNotEmpty) {
    final (square, left) = queue.removeLast();
    if (left.isEmpty) return true;
    final key = '${square.name}:${(left.toList()..sort()).join()}';
    if (!seen.add(key)) continue;
    final remaining = left.map(Square.fromName).toSet();
    for (final to in PawnAttackEngine.validMoves(
        role: role, from: square, remainingPawns: remaining)) {
      queue.add((to, {...left}..remove(to.name)));
    }
  }
  return false;
}
