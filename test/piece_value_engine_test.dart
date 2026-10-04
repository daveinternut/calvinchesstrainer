import 'dart:math';

import 'package:calvinchesstrainer/features/pieces/models/which_side_wins_state.dart';
import 'package:calvinchesstrainer/features/pieces/services/piece_value_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// Per level: pieces per side (min, max) and value gap (min, max).
  const levels = {
    1: (1, 1, 4, 99),
    2: (1, 1, 1, 3),
    3: (2, 3, 3, 99),
    4: (2, 3, 1, 2),
    5: (3, 4, 1, 3),
  };

  for (final MapEntry(key: level, value: rules) in levels.entries) {
    test('level $level stays inside its size and gap window, never a tie',
        () {
      final engine = PieceValueEngine(Random(level));
      final (minPieces, maxPieces, minGap, maxGap) = rules;
      for (var i = 0; i < 20000; i++) {
        final puzzle = engine.generate(level);
        final left = puzzle.leftValue;
        final right = puzzle.rightValue;
        final gap = (left - right).abs();

        expect(left, isNot(right));
        expect(puzzle.correctSide,
            left > right ? AnswerSide.left : AnswerSide.right);
        expect(gap, inInclusiveRange(minGap, maxGap));
        for (final group in [puzzle.leftGroup, puzzle.rightGroup]) {
          expect(group.length, inInclusiveRange(minPieces, maxPieces));
        }
        expect(puzzle.difficulty, level);
      }
    });
  }
}
