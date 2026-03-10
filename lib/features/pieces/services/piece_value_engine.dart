import 'dart:math';

import '../models/which_side_wins_state.dart';

class PieceValueEngine {
  final Random _random;

  PieceValueEngine([Random? random]) : _random = random ?? Random();

  static const _allPieces = PieceType.values;

  PieceGroupPuzzle generate(int difficulty) {
    return switch (difficulty) {
      1 => _generateLevel1(),
      2 => _generateLevel2(),
      3 => _generateLevel3(),
      4 => _generateLevel4(),
      _ => _generateLevel5(),
    };
  }

  /// Level 1: single piece vs single piece, large gap (value diff >= 4)
  PieceGroupPuzzle _generateLevel1() {
    final pairs = <(PieceType, PieceType)>[];
    for (final a in _allPieces) {
      for (final b in _allPieces) {
        if ((a.value - b.value).abs() >= 4) {
          pairs.add((a, b));
        }
      }
    }
    final pair = pairs[_random.nextInt(pairs.length)];
    return _makePuzzle([pair.$1], [pair.$2], 1);
  }

  /// Level 2: single piece vs single piece, smaller gap (value diff 1-3)
  PieceGroupPuzzle _generateLevel2() {
    final pairs = <(PieceType, PieceType)>[];
    for (final a in _allPieces) {
      for (final b in _allPieces) {
        final diff = (a.value - b.value).abs();
        if (diff >= 1 && diff <= 3) {
          pairs.add((a, b));
        }
      }
    }
    final pair = pairs[_random.nextInt(pairs.length)];
    return _makePuzzle([pair.$1], [pair.$2], 2);
  }

  /// Level 3: 2-3 pieces per side, clear winner (value diff >= 3)
  PieceGroupPuzzle _generateLevel3() {
    return _generateGroup(
      minPieces: 2,
      maxPieces: 3,
      minDiff: 3,
      maxDiff: 99,
      difficulty: 3,
    );
  }

  /// Level 4: 2-3 pieces per side, close values (value diff 1-2)
  PieceGroupPuzzle _generateLevel4() {
    return _generateGroup(
      minPieces: 2,
      maxPieces: 3,
      minDiff: 1,
      maxDiff: 2,
      difficulty: 4,
    );
  }

  /// Level 5: 3-4 pieces per side, tricky (value diff 1-3)
  PieceGroupPuzzle _generateLevel5() {
    return _generateGroup(
      minPieces: 3,
      maxPieces: 4,
      minDiff: 1,
      maxDiff: 3,
      difficulty: 5,
    );
  }

  PieceGroupPuzzle _generateGroup({
    required int minPieces,
    required int maxPieces,
    required int minDiff,
    required int maxDiff,
    required int difficulty,
  }) {
    for (var attempt = 0; attempt < 100; attempt++) {
      final leftCount =
          minPieces + _random.nextInt(maxPieces - minPieces + 1);
      final rightCount =
          minPieces + _random.nextInt(maxPieces - minPieces + 1);

      final left = List.generate(
        leftCount,
        (_) => _allPieces[_random.nextInt(_allPieces.length)],
      );
      final right = List.generate(
        rightCount,
        (_) => _allPieces[_random.nextInt(_allPieces.length)],
      );

      final leftVal = left.fold(0, (sum, p) => sum + p.value);
      final rightVal = right.fold(0, (sum, p) => sum + p.value);
      final diff = (leftVal - rightVal).abs();

      if (diff >= minDiff && diff <= maxDiff) {
        return _makePuzzle(left, right, difficulty);
      }
    }

    // Fallback: guaranteed valid puzzle
    return _makePuzzle(
      [PieceType.rook, PieceType.pawn],
      [PieceType.bishop],
      difficulty,
    );
  }

  PieceGroupPuzzle _makePuzzle(
    List<PieceType> groupA,
    List<PieceType> groupB,
    int difficulty,
  ) {
    final valA = groupA.fold(0, (sum, p) => sum + p.value);
    final valB = groupB.fold(0, (sum, p) => sum + p.value);

    // Randomly assign which group goes left vs right
    final putAOnLeft = _random.nextBool();

    final left = putAOnLeft ? groupA : groupB;
    final right = putAOnLeft ? groupB : groupA;
    final leftVal = putAOnLeft ? valA : valB;
    final rightVal = putAOnLeft ? valB : valA;

    // Sort pieces within each group by value descending for nice display
    left.sort((a, b) => b.value.compareTo(a.value));
    right.sort((a, b) => b.value.compareTo(a.value));

    return PieceGroupPuzzle(
      leftGroup: left,
      rightGroup: right,
      correctSide: leftVal > rightVal ? AnswerSide.left : AnswerSide.right,
      difficulty: difficulty,
    );
  }
}
