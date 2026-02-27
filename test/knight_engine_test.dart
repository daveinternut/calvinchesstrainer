import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:calvinchesstrainer/features/chess_vision/services/knight_engine.dart';

void main() {
  group('KnightEngine.knightMoves', () {
    test('corner a1 has 2 moves', () {
      final moves = KnightEngine.knightMoves(Square.a1);
      expect(moves.length, 2);
      expect(moves, containsAll([Square.b3, Square.c2]));
    });

    test('corner h8 has 2 moves', () {
      final moves = KnightEngine.knightMoves(Square.h8);
      expect(moves.length, 2);
      expect(moves, containsAll([Square.f7, Square.g6]));
    });

    test('center d5 has 8 moves', () {
      final moves = KnightEngine.knightMoves(Square.d5);
      expect(moves.length, 8);
      expect(moves, containsAll([
        Square.b4, Square.b6, Square.c3, Square.c7,
        Square.e3, Square.e7, Square.f4, Square.f6,
      ]));
    });

    test('edge a4 has 4 moves', () {
      final moves = KnightEngine.knightMoves(Square.a4);
      expect(moves.length, 4);
      expect(moves, containsAll([Square.b2, Square.b6, Square.c3, Square.c5]));
    });

    test('b1 has 3 moves', () {
      final moves = KnightEngine.knightMoves(Square.b1);
      expect(moves.length, 3);
      expect(moves, containsAll([Square.a3, Square.c3, Square.d2]));
    });
  });

  group('KnightEngine.isKnightMove', () {
    test('valid knight moves', () {
      expect(KnightEngine.isKnightMove(Square.e4, Square.f6), true);
      expect(KnightEngine.isKnightMove(Square.e4, Square.d2), true);
      expect(KnightEngine.isKnightMove(Square.a1, Square.b3), true);
    });

    test('invalid moves', () {
      expect(KnightEngine.isKnightMove(Square.e4, Square.e5), false);
      expect(KnightEngine.isKnightMove(Square.e4, Square.e4), false);
      expect(KnightEngine.isKnightMove(Square.e4, Square.g4), false);
    });
  });

  group('KnightEngine.shortestPath', () {
    test('same square is 0', () {
      expect(KnightEngine.shortestPath(Square.e4, Square.e4), 0);
    });

    test('adjacent knight move is 1', () {
      expect(KnightEngine.shortestPath(Square.a1, Square.b3), 1);
      expect(KnightEngine.shortestPath(Square.d5, Square.f6), 1);
    });

    test('d5 to d4 takes 3 moves', () {
      // From the book: d5-c3-e2-d4 is one minimal path
      expect(KnightEngine.shortestPath(Square.d5, Square.d4), 3);
    });

    test('a1 to b1 takes 3 moves', () {
      // a1-c2-a3-b1 or similar
      expect(KnightEngine.shortestPath(Square.a1, Square.b1), 3);
    });

    test('a1 to h8 (opposite corners)', () {
      final dist = KnightEngine.shortestPath(Square.a1, Square.h8);
      expect(dist, 6);
    });

    test('a1 to b2 takes 4 moves', () {
      // Same color, adjacent diagonal — notoriously tricky for knights
      expect(KnightEngine.shortestPath(Square.a1, Square.b2), 4);
    });
  });
}
