import 'package:flutter/material.dart';

import '../models/opening_game_state.dart';

/// The lines panel: main line first, each variation mounted directly beneath
/// the line it branched from (depth-first). Every row shows its complete
/// move sequence from move 1 so it's always clear where a variation came
/// from. The active line is highlighted and owns the only back/forward
/// buttons (every row reserves the same gutter so chips stay aligned);
/// every move chip is tappable; each line ends with the evaluation of its
/// final position.
class MoveHistoryPanel extends StatefulWidget {
  final List<GameLine> lines;
  final int activeLineIndex;

  /// Ply of the position on the board within the active line (-1 = start).
  final int cursorPly;

  /// When false (challenge mode / engine busy) the panel is display-only.
  final bool enabled;

  /// Rows beyond this height scroll.
  final double maxHeight;

  final void Function(int lineIndex, int ply)? onTapMove;
  final VoidCallback? onBack;
  final VoidCallback? onForward;

  const MoveHistoryPanel({
    super.key,
    required this.lines,
    required this.activeLineIndex,
    required this.cursorPly,
    this.enabled = true,
    this.maxHeight = rowExtent * 2.5,
    this.onTapMove,
    this.onBack,
    this.onForward,
  });

  /// Smallest comfortable touch target for small fingers (Apple's 44 pt).
  static const double touchTarget = 44;

  /// Height of one line row: the touch target + 2 × 1 vertical margin.
  static const double rowExtent = touchTarget + 2;

  @override
  State<MoveHistoryPanel> createState() => _MoveHistoryPanelState();
}

class _MoveHistoryPanelState extends State<MoveHistoryPanel> {
  /// Width reserved at the left of EVERY row for the nav buttons, so
  /// switching the active line doesn't shift the move chips sideways.
  static const _navGutterWidth = MoveHistoryPanel.touchTarget * 2;

  final _verticalController = ScrollController();
  final Map<int, ScrollController> _rowControllers = {};

  ScrollController _controllerFor(int row) =>
      _rowControllers.putIfAbsent(row, ScrollController.new);

  @override
  void didUpdateWidget(MoveHistoryPanel oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Keep a row's end in view when it grows; jump new rows straight to
    // their tip (they start with the full shared prefix).
    for (int i = 0; i < widget.lines.length; i++) {
      final isNewRow = i >= oldWidget.lines.length;
      final oldLen = isNewRow ? -1 : oldWidget.lines[i].moves.length;
      if (isNewRow || widget.lines[i].moves.length > oldLen) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final c = _rowControllers[i];
          if (c == null || !c.hasClients) return;
          if (isNewRow) {
            c.jumpTo(c.position.maxScrollExtent);
          } else {
            c.animateTo(
              c.position.maxScrollExtent,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
            );
          }
        });
      }
    }

    // Drop controllers for rows that no longer exist (e.g. new game).
    if (widget.lines.length < oldWidget.lines.length) {
      final stale = _rowControllers.keys
          .where((i) => i >= widget.lines.length)
          .toList();
      for (final i in stale) {
        _rowControllers.remove(i)?.dispose();
      }
    }

    // Keep the active row visible when the selection moves or a new
    // variation appears below the fold.
    if (widget.activeLineIndex != oldWidget.activeLineIndex ||
        widget.lines.length != oldWidget.lines.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _revealActiveRow());
    }
  }

  void _revealActiveRow() {
    if (!_verticalController.hasClients) return;
    final displayIndex = _displayOrder().indexOf(widget.activeLineIndex);
    if (displayIndex < 0) return;

    const rowExtent = MoveHistoryPanel.rowExtent;
    final rowTop = displayIndex * rowExtent;
    final rowBottom = rowTop + rowExtent;
    final viewport = _verticalController.position.viewportDimension;
    final offset = _verticalController.offset;

    double? target;
    if (rowTop < offset) {
      target = rowTop;
    } else if (rowBottom > offset + viewport) {
      target = rowBottom - viewport;
    }
    if (target != null) {
      _verticalController.animateTo(
        target.clamp(0.0, _verticalController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _verticalController.dispose();
    for (final c in _rowControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  /// Row order: depth-first from the main line, so every variation renders
  /// directly beneath the line it was spawned from (siblings in creation
  /// order).
  List<int> _displayOrder() {
    final children = <int, List<int>>{};
    final roots = <int>[];
    for (int i = 0; i < widget.lines.length; i++) {
      final p = widget.lines[i].parentIndex;
      if (p >= 0 && p < widget.lines.length && p != i) {
        children.putIfAbsent(p, () => []).add(i);
      } else {
        roots.add(i);
      }
    }

    final order = <int>[];
    void visit(int i) {
      order.add(i);
      for (final c in children[i] ?? const <int>[]) {
        visit(c);
      }
    }

    for (final r in roots) {
      visit(r);
    }
    // Backstop: never lose a row to a malformed parent link.
    if (order.length < widget.lines.length) {
      for (int i = 0; i < widget.lines.length; i++) {
        if (!order.contains(i)) order.add(i);
      }
    }
    return order;
  }

  @override
  Widget build(BuildContext context) {
    final hasMoves = widget.lines.any((l) => l.moves.isNotEmpty);
    if (!hasMoves) {
      return const SizedBox(height: MoveHistoryPanel.rowExtent);
    }

    final order = _displayOrder();

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: widget.maxHeight),
      child: Scrollbar(
        controller: _verticalController,
        thumbVisibility: true,
        child: ListView.builder(
          controller: _verticalController,
          shrinkWrap: true,
          padding: const EdgeInsets.only(right: 8),
          itemCount: order.length,
          itemBuilder: (context, index) =>
              _buildLineRow(context, order[index]),
        ),
      ),
    );
  }

  Widget _buildLineRow(BuildContext context, int lineIndex) {
    final line = widget.lines[lineIndex];
    final isActive = lineIndex == widget.activeLineIndex;
    final primary = Theme.of(context).colorScheme.primary;

    final canBack = widget.cursorPly > -1;
    final canForward = widget.cursorPly < line.moves.length - 1;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 1),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: isActive
          ? BoxDecoration(
              color: primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            )
          : null,
      child: Row(
        children: [
          if (widget.enabled)
            SizedBox(
              width: _navGutterWidth,
              child: isActive
                  ? Row(
                      children: [
                        _NavButton(
                          icon: Icons.chevron_left_rounded,
                          onTap: canBack ? widget.onBack : null,
                        ),
                        _NavButton(
                          icon: Icons.chevron_right_rounded,
                          onTap: canForward ? widget.onForward : null,
                        ),
                      ],
                    )
                  : null,
            ),
          Expanded(
            child: SizedBox(
              height: MoveHistoryPanel.touchTarget,
              child: SingleChildScrollView(
                controller: _controllerFor(lineIndex),
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _buildMoveChips(lineIndex),
                ),
              ),
            ),
          ),
          if (line.moves.isNotEmpty) ...[
            const SizedBox(width: 4),
            _EvalTag(
              evalPawns: line.moves.last.eval,
              mateIn: line.moves.last.mateIn,
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildMoveChips(int lineIndex) {
    final line = widget.lines[lineIndex];
    final isActive = lineIndex == widget.activeLineIndex;
    final chips = <Widget>[];

    // Full sequence from move 1 — variations repeat their shared prefix so
    // it's always visible how the line arose.
    for (int ply = 0; ply < line.moves.length; ply++) {
      if (ply.isEven) {
        chips.add(_numberLabel('${ply ~/ 2 + 1}.'));
      }

      final isCurrent = isActive && ply == widget.cursorPly;
      final targetPly = ply;
      chips.add(_MoveChip(
        san: line.moves[ply].san,
        isHighlighted: isCurrent,
        onTap: widget.enabled && widget.onTapMove != null
            ? () => widget.onTapMove!(lineIndex, targetPly)
            : null,
      ));
      chips.add(const SizedBox(width: 2));
    }

    return chips;
  }

  Widget _numberLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(right: 2),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _NavButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: MoveHistoryPanel.touchTarget,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Icon(
          icon,
          size: 28,
          color: onTap != null
              ? Theme.of(context).colorScheme.primary
              : Colors.grey.shade400,
        ),
      ),
    );
  }
}

class _EvalTag extends StatelessWidget {
  final double evalPawns;
  final int? mateIn;

  const _EvalTag({required this.evalPawns, this.mateIn});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        formatEval((evalPawns * 100).round(), mateIn),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          height: 1.1,
        ),
      ),
    );
  }
}

class _MoveChip extends StatelessWidget {
  final String san;
  final bool isHighlighted;
  final VoidCallback? onTap;

  const _MoveChip({
    required this.san,
    this.isHighlighted = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(8);

    return InkWell(
      onTap: onTap,
      borderRadius: radius,
      child: Container(
        constraints: const BoxConstraints(
          minWidth: MoveHistoryPanel.touchTarget,
          minHeight: MoveHistoryPanel.touchTarget,
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: isHighlighted
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)
              : null,
          borderRadius: radius,
        ),
        child: Text(
          san,
          style: TextStyle(
            fontSize: 15,
            fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w500,
            color: isHighlighted
                ? Theme.of(context).colorScheme.primary
                : Colors.black87,
          ),
        ),
      ),
    );
  }
}
