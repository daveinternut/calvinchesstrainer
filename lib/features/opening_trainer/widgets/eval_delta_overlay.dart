import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

import '../models/opening_game_state.dart';

const _classificationStyles = {
  MoveClassification.brilliant: (
    color: Color(0xFF26A69A),
    icon: '!!',
  ),
  MoveClassification.best: (
    color: Color(0xFF66BB6A),
    icon: '!',
  ),
  MoveClassification.good: (
    color: Color(0xFFA5D6A7),
    icon: '✓',
  ),
  MoveClassification.book: (
    color: Color(0xFFB0A483),
    icon: '📖',
  ),
  MoveClassification.inaccuracy: (
    color: Color(0xFFFFCA28),
    icon: '?!',
  ),
  MoveClassification.mistake: (
    color: Color(0xFFFFA726),
    icon: '?',
  ),
  MoveClassification.blunder: (
    color: Color(0xFFEF5350),
    icon: '??',
  ),
};

Color colorForClassification(MoveClassification c) =>
    _classificationStyles[c]!.color;

({Color color, String icon}) classificationStyle(MoveClassification c) =>
    _classificationStyles[c]!;

/// Darken a classification color by how far the move falls behind the best
/// move, so arrow shade carries the "how much worse" signal even when score
/// badges are hidden. 0 loss = base color, ≥1.5 pawns = darkest.
Color shadeForDelta(Color base, double deltaPawns) {
  final t = (-deltaPawns).clamp(0.0, 1.5) / 1.5;
  if (t == 0) return base;
  final hsl = HSLColor.fromColor(base);
  return hsl
      .withLightness((hsl.lightness * (1 - 0.30 * t)).clamp(0.0, 1.0))
      .toColor();
}

class EvalDeltaOverlay extends StatelessWidget {
  final double boardSize;
  final Side orientation;
  final List<SuggestedMove> topMoves;
  final bool showScores;

  const EvalDeltaOverlay({
    super.key,
    required this.boardSize,
    required this.orientation,
    required this.topMoves,
    this.showScores = false,
  });

  double get _squareSize => boardSize / 8;

  Offset _squareCenter(Square square) {
    final file = square.file.value;
    final rank = square.rank.value;
    final x = orientation == Side.white ? file : 7 - file;
    final y = orientation == Side.white ? 7 - rank : rank;
    return Offset((x + 0.5) * _squareSize, (y + 0.5) * _squareSize);
  }

  @override
  Widget build(BuildContext context) {
    if (topMoves.isEmpty) return const SizedBox.shrink();

    // Badges sit on the arrow shaft (slightly past the midpoint, toward the
    // destination) so moves sharing a destination square — e.g. Qf3 and Nf3 —
    // get distinct badge positions instead of covering each other.
    final positions = <Offset>[];
    final moves = <SuggestedMove>[];
    for (final move in topMoves) {
      if (move.uci.length < 4) continue;
      final orig = _squareCenter(Square.fromName(move.uci.substring(0, 2)));
      final dest = _squareCenter(Square.fromName(move.uci.substring(2, 4)));
      var pos = Offset.lerp(orig, dest, 0.6)!;

      // Nudge along the arrow if still too close to an earlier badge.
      final minGap = _squareSize * 0.55;
      for (var t = 0.75; t <= 1.0; t += 0.15) {
        final collides = positions.any((p) => (p - pos).distance < minGap);
        if (!collides) break;
        pos = Offset.lerp(orig, dest, t)!;
      }

      positions.add(pos);
      moves.add(move);
    }

    return IgnorePointer(
      child: SizedBox.square(
        dimension: boardSize,
        child: Stack(
          children: [
            for (int i = 0; i < moves.length; i++)
              _buildLabel(moves[i], positions[i]),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(SuggestedMove move, Offset center) {
    final classification = move.classification;
    final style = _classificationStyles[classification]!;
    final fontSize = (_squareSize * 0.26).clamp(9.0, 15.0);

    // Badges show the ABSOLUTE post-move eval (white's perspective, like the
    // eval bar) — not the loss vs. best, which only drives the colors.
    final String label;
    if (!move.hasEval) {
      label = move.isBest ? '👑' : '📖';
    } else if (showScores) {
      final crown = move.isBest ? '👑 ' : '';
      label = '$crown${formatEval(move.centipawns, move.mateIn)}';
    } else {
      label = move.isBest ? '👑' : style.icon;
    }

    return Positioned(
      left: center.dx - _squareSize,
      top: center.dy - _squareSize * 0.25,
      width: _squareSize * 2,
      height: _squareSize * 0.5,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: style.color,
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
        ),
      ),
    );
  }
}
