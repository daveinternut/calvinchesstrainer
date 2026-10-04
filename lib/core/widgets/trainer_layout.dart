import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The page skeleton shared by the board trainers.
///
/// - **Portrait** (and any narrow window): `header`, then the board filling
///   the remaining space, then `footer` — the original phone layout.
/// - **Landscape** (an iPad on its side, a wide Stage Manager window): the
///   board on the left at full height, `header` and `footer` stacked in a
///   side panel on the right, instead of a small board with empty margins.
///
/// iPad ignores the app's portrait lock (the app supports multitasking, and
/// iPadOS 26 refuses programmatic orientation changes), so every trainer has
/// to work both ways.
///
/// Header and footer widgets must size themselves: no `Expanded` or `Spacer`,
/// because in landscape they sit in a scrollable column. Overlays (milestone
/// banner, results card) belong in a `Stack` around this widget, not in it.
class TrainerLayout extends StatelessWidget {
  const TrainerLayout({
    super.key,
    this.header = const [],
    required this.board,
    this.footer = const [],
    this.padding = defaultPadding,
  });

  /// Above the board in portrait; top of the side panel in landscape.
  final List<Widget> header;

  /// Builds the board as a square of side [size].
  final Widget Function(BuildContext context, double size) board;

  /// Below the board in portrait; bottom of the side panel in landscape.
  final List<Widget> footer;

  final EdgeInsets padding;

  static const EdgeInsets defaultPadding = EdgeInsets.symmetric(horizontal: 16);

  /// The narrowest side panel landscape will settle for.
  static const double minPanelWidth = 280;

  static const double _gap = 24;
  static const double _verticalPadding = 12;

  /// Whether [constraints] are wide enough (and wider than tall) to give the
  /// board its own column.
  static bool isLandscape(BoxConstraints constraints) =>
      constraints.maxWidth >= 600 &&
      constraints.maxWidth > constraints.maxHeight * 1.15;

  /// The board's side length in landscape, for a layout given [constraints]
  /// and [padding].
  static double landscapeBoardSize(
    BoxConstraints constraints, {
    EdgeInsets padding = defaultPadding,
  }) {
    return math.max(
      0.0,
      math.min(
        constraints.maxHeight - _verticalPadding * 2,
        constraints.maxWidth - padding.horizontal - _gap - minPanelWidth,
      ),
    );
  }

  /// Where the side panel starts in landscape, measured from the left edge.
  /// For overlays, like the milestone banner, that must stay off the board.
  static double landscapePanelLeft(
    BoxConstraints constraints, {
    EdgeInsets padding = defaultPadding,
  }) {
    return padding.left +
        landscapeBoardSize(constraints, padding: padding) +
        _gap;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (!isLandscape(constraints)) {
          return Padding(
            padding: padding,
            child: Column(
              children: [
                ...header,
                Expanded(
                  child: Center(
                    child: LayoutBuilder(
                      builder: (context, inner) => board(
                        context,
                        math.min(inner.maxWidth, inner.maxHeight),
                      ),
                    ),
                  ),
                ),
                ...footer,
              ],
            ),
          );
        }

        final boardSize = landscapeBoardSize(constraints, padding: padding);
        return Padding(
          padding: padding.add(
            const EdgeInsets.symmetric(vertical: _verticalPadding),
          ),
          child: Row(
            children: [
              SizedBox.square(
                dimension: boardSize,
                child: board(context, boardSize),
              ),
              const SizedBox(width: _gap),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ...header,
                        const SizedBox(height: 16),
                        ...footer,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
