import 'dart:math';
import 'package:dartchess/dartchess.dart';

class PawnAttackEngine {
  PawnAttackEngine._();

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

  static Set<Square> generatePawns(
    int count,
    Random random, {
    bool darkSquaresOnly = false,
  }) {
    for (var attempt = 0; attempt < 50; attempt++) {
      final pawns = _tryGeneratePawns(count, random,
          darkSquaresOnly: darkSquaresOnly);
      if (pawns != null) return pawns;
    }
    return _tryGeneratePawns(count, random,
            darkSquaresOnly: darkSquaresOnly) ??
        {Square.d4};
  }

  static Set<Square>? _tryGeneratePawns(
    int count,
    Random random, {
    bool darkSquaresOnly = false,
  }) {
    final candidates = Square.values.where((sq) {
      final r = sq.rank.value;
      if (r < 1 || r > 6) return false;
      if (sq == Square.a1) return false;
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
    if (threats.contains(Square.a1)) return null;

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
