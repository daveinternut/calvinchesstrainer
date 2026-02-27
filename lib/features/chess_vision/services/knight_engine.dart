import 'dart:collection';
import 'package:dartchess/dartchess.dart';

class KnightEngine {
  KnightEngine._();

  static const _offsets = [
    (1, 2), (2, 1), (2, -1), (1, -2),
    (-1, -2), (-2, -1), (-2, 1), (-1, 2),
  ];

  static Set<Square> knightMoves(Square from) {
    final f = from.file.value;
    final r = from.rank.value;
    final result = <Square>{};
    for (final (df, dr) in _offsets) {
      final nf = f + df;
      final nr = r + dr;
      if (nf >= 0 && nf < 8 && nr >= 0 && nr < 8) {
        result.add(Square.fromCoords(File(nf), Rank(nr)));
      }
    }
    return result;
  }

  static bool isKnightMove(Square from, Square to) {
    final df = (from.file.value - to.file.value).abs();
    final dr = (from.rank.value - to.rank.value).abs();
    return (df == 1 && dr == 2) || (df == 2 && dr == 1);
  }

  static int shortestPath(Square from, Square to) {
    if (from == to) return 0;

    final visited = <int>{from.value};
    final queue = Queue<(Square, int)>();
    queue.add((from, 0));

    while (queue.isNotEmpty) {
      final (current, depth) = queue.removeFirst();
      for (final next in knightMoves(current)) {
        if (next == to) return depth + 1;
        if (visited.add(next.value)) {
          queue.add((next, depth + 1));
        }
      }
    }

    return -1;
  }
}
