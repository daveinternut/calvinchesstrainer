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
      final pawns = PawnAttackEngine.generatePawns(5, rng);
      expect(pawns.length, 5);
    });

    test('pawns are on ranks 2-7', () {
      final rng = Random(42);
      final pawns = PawnAttackEngine.generatePawns(8, rng);
      for (final p in pawns) {
        expect(p.rank.value, greaterThanOrEqualTo(1));
        expect(p.rank.value, lessThanOrEqualTo(6));
      }
    });

    test('a1 is never occupied by a pawn', () {
      final rng = Random(42);
      for (var i = 0; i < 20; i++) {
        final pawns = PawnAttackEngine.generatePawns(8, Random(i));
        expect(pawns, isNot(contains(Square.a1)));
      }
    });

    test('dark squares only mode for bishop', () {
      final rng = Random(42);
      final pawns =
          PawnAttackEngine.generatePawns(5, rng, darkSquaresOnly: true);
      for (final p in pawns) {
        expect(PawnAttackEngine.isDarkSquare(p), isTrue,
            reason: '${p.name} should be a dark square');
      }
    });

    test('a1 is not threatened by initial pawns', () {
      final rng = Random(42);
      for (var i = 0; i < 20; i++) {
        final pawns = PawnAttackEngine.generatePawns(5, Random(i));
        final threats = PawnAttackEngine.pawnThreats(pawns);
        expect(threats, isNot(contains(Square.a1)),
            reason: 'a1 should not be threatened');
      }
    });
  });
}
