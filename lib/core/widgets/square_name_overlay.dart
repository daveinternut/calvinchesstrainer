import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

class SquareLabel {
  final int file;
  final int rank;
  final String name;
  final Color color;

  const SquareLabel({
    required this.file,
    required this.rank,
    required this.name,
    required this.color,
  });
}

/// Overlays square name labels on top of a chessboard.
///
/// Must be placed in a [Stack] alongside the board widget, both sharing
/// the same [boardSize] and [orientation].
class SquareNameOverlay extends StatelessWidget {
  final double boardSize;
  final Side orientation;
  final List<SquareLabel> labels;

  const SquareNameOverlay({
    super.key,
    required this.boardSize,
    required this.orientation,
    required this.labels,
  });

  double get _squareSize => boardSize / 8;

  Offset _squareOffset(int file, int rank) {
    final x = orientation == Side.white ? file : 7 - file;
    final y = orientation == Side.white ? 7 - rank : rank;
    return Offset(x * _squareSize, y * _squareSize);
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox.square(
        dimension: boardSize,
        child: Stack(
          children: [
            for (final label in labels) _buildLabel(label),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(SquareLabel label) {
    final offset = _squareOffset(label.file, label.rank);
    return Positioned(
      left: offset.dx,
      top: offset.dy,
      width: _squareSize,
      height: _squareSize,
      child: Container(
        alignment: Alignment.center,
        color: label.color,
        child: Text(
          label.name,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: _squareSize * 0.45,
            shadows: const [
              Shadow(blurRadius: 2, color: Color(0x73000000)),
            ],
          ),
        ),
      ),
    );
  }
}
