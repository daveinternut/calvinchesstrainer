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

  Offset _squareOffset(Square square) {
    final file = square.file.value;
    final rank = square.rank.value;
    final x = orientation == Side.white ? file : 7 - file;
    final y = orientation == Side.white ? 7 - rank : rank;
    return Offset(x * _squareSize, y * _squareSize);
  }

  @override
  Widget build(BuildContext context) {
    if (topMoves.isEmpty) return const SizedBox.shrink();

    return IgnorePointer(
      child: SizedBox.square(
        dimension: boardSize,
        child: Stack(
          children: [
            for (final move in topMoves) _buildLabel(move),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(SuggestedMove move) {
    if (move.uci.length < 4) return const SizedBox.shrink();

    final destSquare = Square.fromName(move.uci.substring(2, 4));
    final offset = _squareOffset(destSquare);
    final classification = move.classification;
    final style = _classificationStyles[classification]!;
    final fontSize = (_squareSize * 0.28).clamp(9.0, 16.0);

    final label = showScores
        ? '${move.deltaPawns >= 0 ? "+" : ""}${move.deltaPawns.toStringAsFixed(1)}'
        : style.icon;

    return Positioned(
      left: offset.dx + _squareSize * 0.5,
      top: offset.dy,
      child: Transform.translate(
        offset: Offset(-_squareSize * 0.12, -fontSize * 0.2),
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
