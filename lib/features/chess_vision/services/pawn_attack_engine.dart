import 'dart:collection';
import 'dart:math';
import 'package:dartchess/dartchess.dart';

class PawnAttackEngine {
  PawnAttackEngine._();

  /// Where the player's piece starts every board.
  static const Square startSquare = Square.a1;

  static Set<Square> pawnThreats(Set<Square> pawns) {
    final threats = <Square>{};
    for (final p in pawns) {
      final f = p.file.value;
      final r = p.rank.value;
      if (f > 0 && r > 0) {
        threats.add(Square.fromCoords(File(f - 1), Rank(r - 1)));
      }
      if (f < 7 && r > 0) {
        threats.add(Square.fromCoords(File(f + 1), Rank(r - 1)));
      }
    }
    return threats;
  }

  static Set<Square> validMoves({
    required Role role,
    required Square from,
    required Set<Square> remainingPawns,
  }) {
    final threats = pawnThreats(remainingPawns);

    switch (role) {
      case Role.knight:
        return _knightMoves(from, threats, remainingPawns);
      case Role.bishop:
        return _slidingMoves(from, _bishopDirs, threats, remainingPawns);
      case Role.rook:
        return _slidingMoves(from, _rookDirs, threats, remainingPawns);
      case Role.queen:
        return _slidingMoves(from, _allDirs, threats, remainingPawns);
      default:
        return {};
    }
  }

  static Set<Square> _knightMoves(
      Square from, Set<Square> threats, Set<Square> pawns) {
    final f = from.file.value;
    final r = from.rank.value;
    final result = <Square>{};
    for (final (df, dr) in _knightOffsets) {
      final nf = f + df;
      final nr = r + dr;
      if (nf < 0 || nf > 7 || nr < 0 || nr > 7) continue;
      final sq = Square.fromCoords(File(nf), Rank(nr));
      if (threats.contains(sq) && !pawns.contains(sq)) continue;
      result.add(sq);
    }
    return result;
  }

  static Set<Square> _slidingMoves(Square from, List<(int, int)> directions,
      Set<Square> threats, Set<Square> pawns) {
    final f = from.file.value;
    final r = from.rank.value;
    final result = <Square>{};
    for (final (df, dr) in directions) {
      var cf = f + df;
      var cr = r + dr;
      while (cf >= 0 && cf <= 7 && cr >= 0 && cr <= 7) {
        final sq = Square.fromCoords(File(cf), Rank(cr));
        if (pawns.contains(sq)) {
          result.add(sq);
          break;
        }
        if (!threats.contains(sq)) {
          result.add(sq);
        }
        cf += df;
        cr += dr;
      }
    }
    return result;
  }

  static bool isDarkSquare(Square sq) {
    return (sq.file.value + sq.rank.value) % 2 == 0;
  }

  /// Whether a [role] standing on [from] can still capture every pawn in
  /// [pawns] (breadth-first search over piece square × pawns left: at most
  /// 64 × 2⁸ states for the 8-pawn top level, so it is cheap).
  ///
  /// Line pieces always have a safe square to retreat to (ranks 7–8 are never
  /// attacked); a knight can be dealt a board with no safe first hop, or walk
  /// itself into a dead end.
  static bool isSolvable({
    required Role role,
    required Square from,
    required Set<Square> pawns,
  }) {
    if (pawns.isEmpty) return true;
    final pawnList = pawns.toList(growable: false);
    final pawnIndex = {
      for (var i = 0; i < pawnList.length; i++) pawnList[i]: i,
    };
    final allPawns = (1 << pawnList.length) - 1;
    final seen = <int>{(allPawns << 6) | from.value};
    final queue = Queue<(Square, int)>()..add((from, allPawns));

    while (queue.isNotEmpty) {
      final (square, mask) = queue.removeFirst();
      final remaining = {
        for (var i = 0; i < pawnList.length; i++)
          if (mask & (1 << i) != 0) pawnList[i],
      };
      for (final to in validMoves(
        role: role,
        from: square,
        remainingPawns: remaining,
      )) {
        final index = pawnIndex[to];
        final next = (index != null && mask & (1 << index) != 0)
            ? mask & ~(1 << index)
            : mask;
        if (next == 0) return true;
        if (seen.add((next << 6) | to.value)) queue.add((to, next));
      }
    }
    return false;
  }

  /// Deals [count] pawns for a [role] starting on [startSquare]: ranks 2–7,
  /// never attacking the start square, and always solvable for that piece
  /// (dark squares only for the bishop, which can never reach a light one).
  static Set<Square> generatePawns(
    int count,
    Random random, {
    required Role role,
    bool? darkSquaresOnly,
  }) {
    final darkOnly = darkSquaresOnly ?? role == Role.bishop;
    for (var attempt = 0; attempt < 500; attempt++) {
      final pawns = _tryGeneratePawns(count, random, darkSquaresOnly: darkOnly);
      if (pawns != null &&
          isSolvable(role: role, from: startSquare, pawns: pawns)) {
        return pawns;
      }
    }
    // Unreachable in practice (over 96% of random boards are solvable even
    // for the knight); a lone d4 pawn is solvable for every piece.
    return {Square.d4};
  }

  static Set<Square>? _tryGeneratePawns(
    int count,
    Random random, {
    bool darkSquaresOnly = false,
  }) {
    final candidates = Square.values.where((sq) {
      final r = sq.rank.value;
      if (r < 1 || r > 6) return false;
      if (sq == startSquare) return false;
      if (darkSquaresOnly && !isDarkSquare(sq)) return false;
      return true;
    }).toList();

    candidates.shuffle(random);

    final pawns = <Square>{};
    for (final sq in candidates) {
      if (pawns.length >= count) break;
      pawns.add(sq);
    }

    if (pawns.length < count) return null;

    final threats = pawnThreats(pawns);
    if (threats.contains(startSquare)) return null;

    return pawns;
  }

  static const _knightOffsets = [
    (1, 2), (2, 1), (2, -1), (1, -2),
    (-1, -2), (-2, -1), (-2, 1), (-1, 2),
  ];

  static const _bishopDirs = [(-1, -1), (-1, 1), (1, -1), (1, 1)];
  static const _rookDirs = [(-1, 0), (1, 0), (0, -1), (0, 1)];
  static const _allDirs = [
    (-1, -1), (-1, 1), (1, -1), (1, 1),
    (-1, 0), (1, 0), (0, -1), (0, 1),
  ];
}
