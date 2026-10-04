import 'package:dartchess/dartchess.dart' show Side;
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A board with its coordinates outside it: rank numbers down the left,
/// file letters along the bottom, in mono.
///
/// The frame fills a [size] square; the board inside it is
/// [boardSizeFor] that size, which is what [builder] receives (overlays
/// drawn on the board must use it too). Drills that test coordinates turn
/// [showCoordinates] off, and the board then takes the whole square.
class BoardFrame extends StatelessWidget {
  const BoardFrame({
    super.key,
    required this.size,
    required this.orientation,
    required this.builder,
    this.showCoordinates = true,
  });

  final double size;
  final Side orientation;
  final bool showCoordinates;
  final Widget Function(BuildContext context, double boardSize) builder;

  /// Width of the coordinate gutter for a frame of [size].
  static double gutterFor(double size) => (size * 0.034).clamp(14.0, 22.0);

  /// The board's side inside a frame of [size].
  static double boardSizeFor(double size, {bool showCoordinates = true}) =>
      showCoordinates ? size - gutterFor(size) : size;

  @override
  Widget build(BuildContext context) {
    if (!showCoordinates) {
      return SizedBox.square(dimension: size, child: builder(context, size));
    }

    final gutter = gutterFor(size);
    final board = size - gutter;
    final square = board / 8;
    final style = AppText.mono.copyWith(
      fontSize: (gutter * 0.62).clamp(10.0, 13.0),
      fontWeight: FontWeight.w500,
      color: AppColors.ink3,
    );
    const files = 'abcdefgh';
    final fileLabels = orientation == Side.white
        ? files.split('')
        : files.split('').reversed.toList();
    final rankLabels = orientation == Side.white
        ? ['8', '7', '6', '5', '4', '3', '2', '1']
        : ['1', '2', '3', '4', '5', '6', '7', '8'];

    return SizedBox.square(
      dimension: size,
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: gutter,
                height: board,
                child: Column(
                  children: [
                    for (final r in rankLabels)
                      SizedBox(
                        height: square,
                        child: Center(child: Text(r, style: style)),
                      ),
                  ],
                ),
              ),
              SizedBox.square(dimension: board, child: builder(context, board)),
            ],
          ),
          Row(
            children: [
              SizedBox(width: gutter, height: gutter),
              for (final f in fileLabels)
                SizedBox(
                  width: square,
                  height: gutter,
                  child: Center(child: Text(f, style: style)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
