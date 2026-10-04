import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The page skeleton shared by the board trainers.
///
/// - **Portrait** (and any narrow window): `topBar`, `header`, then the board
///   filling the remaining space, then `footer`.
/// - **Landscape** (a tablet or phone on its side, a wide Stage Manager
///   window): the board on the left at full height, and a side panel on the
///   right with `topBar` pinned at its top and `header` then `footer` below
///   it.
///
/// Tablets rotate (iPad, Android tablets), and Stage Manager, split-screen
/// and browser windows take any shape, so every trainer has to work both
/// ways. Phones stay portrait (Info.plist, MainActivity).
///
/// Header and footer widgets must size themselves: no `Expanded` or `Spacer`,
/// because in landscape they sit in a scrollable column. Overlays (milestone
/// banner, results) belong in a `Stack` around this widget, not in it.
class TrainerLayout extends StatelessWidget {
  const TrainerLayout({
    super.key,
    this.topBar,
    this.header = const [],
    required this.board,
    this.footer = const [],
    this.padding = defaultPadding,
  });

  /// The close button and title; top of the page, or of the side panel.
  final Widget? topBar;

  /// Above the board in portrait; under the top bar in landscape.
  final List<Widget> header;

  /// Builds the board as a square of side [size].
  final Widget Function(BuildContext context, double size) board;

  /// Below the board in portrait; after the header in landscape.
  final List<Widget> footer;

  final EdgeInsets padding;

  static const EdgeInsets defaultPadding = EdgeInsets.symmetric(horizontal: 16);

  /// The narrowest side panel landscape will settle for.
  static const double minPanelWidth = 300;

  static const double _gap = 28;
  static const double _verticalPadding = 16;

  /// Whether [constraints] are wide enough (and wider than tall) to give the
  /// board its own column. A short window qualifies even when it is narrower
  /// than 600 (the web app on a phone held sideways): under a 360 pt height,
  /// a column would squeeze the board between the header and the footer.
  static bool isLandscape(BoxConstraints constraints) =>
      constraints.maxWidth > constraints.maxHeight * 1.15 &&
      (constraints.maxWidth >= 600 || constraints.maxHeight < 360);

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
                if (topBar != null) ...[topBar!, const SizedBox(height: 4)],
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.center,
                child: SizedBox.square(
                  dimension: boardSize,
                  child: board(context, boardSize),
                ),
              ),
              const SizedBox(width: _gap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (topBar != null) ...[topBar!, const SizedBox(height: 12)],
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ...header,
                            const SizedBox(height: 16),
                            ...footer,
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
