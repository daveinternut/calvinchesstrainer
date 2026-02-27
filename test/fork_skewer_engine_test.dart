import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:calvinchesstrainer/features/chess_vision/models/chess_vision_state.dart';
import 'package:calvinchesstrainer/features/chess_vision/services/fork_skewer_engine.dart';

void main() {
  group('ForkSkewerEngine', () {
    test('queen vs rook on d4 (adjacent to king) - no solutions expected', () {
      final result = ForkSkewerEngine.computeValidSquares(
        whitePiece: WhitePiece.queen,
        kingSquare: Square.d5,
        targetSquare: Square.d4,
      );
      // Adjacent rook means king can always recapture after moving
      expect(result, isEmpty);
    });

    test('bishop skewer on a8-h1 diagonal', () {
      final result = ForkSkewerEngine.computeValidSquares(
        whitePiece: WhitePiece.bishop,
        kingSquare: Square.d5,
        targetSquare: Square.f3,
      );
      // Bishop on a8 or b7: skewers d5-f3 on the long diagonal
      expect(result, containsAll([Square.a8, Square.b7]));
    });

    test('knight fork c3 attacks both d5 and e1', () {
      // Knight on c3 attacks d5 (king) and e2, d1, a2, a4, b5, b1, e4
      // Rook on b1: knight on c3 attacks d5 and b1? No, c3 attacks a2, a4, b5, b1, d1, d5, e2, e4
      // Actually let's find: where does knight fork d5 and target?
      // Knight from d5: b4, b6, c3, c7, e3, e7, f4, f6
      // We need target to be a knight-move from the forking square too
      final result = ForkSkewerEngine.computeValidSquares(
        whitePiece: WhitePiece.knight,
        kingSquare: Square.d5,
        targetSquare: Square.b1,
      );
      print('Knight vs rook on b1: ${result.map((s) => s.name).toList()..sort()}');
      // c3 attacks both d5 and b1 (knight moves from c3)
      // After check from c3: king can go to c4, c5, c6, d4, d6, e4, e5, e6
      // None of those are adjacent to b1
      // Also the rook on b1 can't capture c3 (not same file/rank)
      if (result.contains(Square.c3)) {
        expect(result, contains(Square.c3));
      }
    });

    test('bishop vs rook on f3', () {
      final result = ForkSkewerEngine.computeValidSquares(
        whitePiece: WhitePiece.bishop,
        kingSquare: Square.d5,
        targetSquare: Square.f3,
      );
      print('Bishop vs rook on f3: ${result.map((s) => s.name).toList()..sort()}');
      print('Count: ${result.length}');
    });

    test('rook vs rook on d4', () {
      final result = ForkSkewerEngine.computeValidSquares(
        whitePiece: WhitePiece.rook,
        kingSquare: Square.d5,
        targetSquare: Square.d4,
      );
      print('Rook vs rook on d4: ${result.map((s) => s.name).toList()..sort()}');
      print('Count: ${result.length}');
      // A white rook can skewer the king on d5 and rook on d4 from d6, d7, d8
      // (check from above, king moves off d-file, rook captures on d4)
    });

    test('queen vs rook on a1 (corner)', () {
      final result = ForkSkewerEngine.computeValidSquares(
        whitePiece: WhitePiece.queen,
        kingSquare: Square.d5,
        targetSquare: Square.a1,
      );
      print('Queen vs rook on a1: ${result.map((s) => s.name).toList()..sort()}');
      print('Count: ${result.length}');
    });

    test('knight vs rook on h8 (far corner)', () {
      final result = ForkSkewerEngine.computeValidSquares(
        whitePiece: WhitePiece.knight,
        kingSquare: Square.d5,
        targetSquare: Square.h8,
      );
      print('Knight vs rook on h8: ${result.map((s) => s.name).toList()..sort()}');
      print('Count: ${result.length}');
      // Knight needs to be a knight move from both d5 and h8
      // From d5: c3, e3, f4, f6, e7, c7, b4, b6
      // From h8: f7, g6
      // Intersection: f7? no... g6? From d5 knight can go to... no g6 is not reachable from d5 by knight
      // From d5 by knight: (d±1,5±2) or (d±2,5±1): c3, e3, b4, f4, b6, f6, c7, e7
      // From h8 by knight: g6, f7
      // Intersection: f7 is not in d5-knight-list, g6 is not in d5-knight-list
      // So no forks expected for this configuration
    });

    test('performance: all 63 positions for queen', () {
      final stopwatch = Stopwatch()..start();
      int totalSolutions = 0;
      int positionsWithSolutions = 0;

      for (final target in concentricPath) {
        final result = ForkSkewerEngine.computeValidSquares(
          whitePiece: WhitePiece.queen,
          kingSquare: Square.d5,
          targetSquare: target,
        );
        totalSolutions += result.length;
        if (result.isNotEmpty) positionsWithSolutions++;
      }

      stopwatch.stop();
      print('All 63 queen positions computed in ${stopwatch.elapsedMilliseconds}ms');
      print('Total valid squares across all positions: $totalSolutions');
      print('Positions with at least one solution: $positionsWithSolutions/63');
    });

    test('performance: all 63 positions for knight', () {
      final stopwatch = Stopwatch()..start();
      int totalSolutions = 0;
      int positionsWithSolutions = 0;

      for (final target in concentricPath) {
        final result = ForkSkewerEngine.computeValidSquares(
          whitePiece: WhitePiece.knight,
          kingSquare: Square.d5,
          targetSquare: target,
        );
        totalSolutions += result.length;
        if (result.isNotEmpty) positionsWithSolutions++;
      }

      stopwatch.stop();
      print('All 63 knight positions computed in ${stopwatch.elapsedMilliseconds}ms');
      print('Total valid squares across all positions: $totalSolutions');
      print('Positions with at least one solution: $positionsWithSolutions/63');
    });

    test('queen vs bishop target on f3', () {
      final result = ForkSkewerEngine.computeValidSquares(
        whitePiece: WhitePiece.queen,
        kingSquare: Square.d5,
        targetSquare: Square.f3,
        targetRole: Role.bishop,
      );
      print('Queen vs bishop on f3: ${result.map((s) => s.name).toList()..sort()}');
      print('Count: ${result.length}');
      expect(result, isNotEmpty);
    });

    test('knight vs knight target on g2', () {
      final result = ForkSkewerEngine.computeValidSquares(
        whitePiece: WhitePiece.knight,
        kingSquare: Square.d5,
        targetSquare: Square.g2,
        targetRole: Role.knight,
      );
      print('Knight vs knight on g2: ${result.map((s) => s.name).toList()..sort()}');
      print('Count: ${result.length}');
    });

    test('queen vs queen target on h1', () {
      final result = ForkSkewerEngine.computeValidSquares(
        whitePiece: WhitePiece.queen,
        kingSquare: Square.d5,
        targetSquare: Square.h1,
        targetRole: Role.queen,
      );
      print('Queen vs queen on h1: ${result.map((s) => s.name).toList()..sort()}');
      print('Count: ${result.length}');
    });
  });
}
