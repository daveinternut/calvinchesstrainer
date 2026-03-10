import 'package:flutter/material.dart';

import '../models/opening_game_state.dart';

class MoveHistoryPanel extends StatefulWidget {
  final List<MoveRecord> moveHistory;
  final bool isReviewing;
  final int reviewIndex;
  final ValueChanged<int>? onTapMove;

  const MoveHistoryPanel({
    super.key,
    required this.moveHistory,
    this.isReviewing = false,
    this.reviewIndex = -1,
    this.onTapMove,
  });

  @override
  State<MoveHistoryPanel> createState() => _MoveHistoryPanelState();
}

class _MoveHistoryPanelState extends State<MoveHistoryPanel> {
  final _scrollController = ScrollController();

  @override
  void didUpdateWidget(MoveHistoryPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.moveHistory.length > oldWidget.moveHistory.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.moveHistory.isEmpty) {
      return const SizedBox(height: 36);
    }

    final movePairs = <_MovePair>[];
    for (int i = 0; i < widget.moveHistory.length; i += 2) {
      final whiteMove = widget.moveHistory[i];
      final blackMove =
          (i + 1 < widget.moveHistory.length) ? widget.moveHistory[i + 1] : null;
      movePairs.add(_MovePair(
        moveNumber: (i ~/ 2) + 1,
        whiteSan: whiteMove.san,
        whiteIndex: i,
        blackSan: blackMove?.san,
        blackIndex: blackMove != null ? i + 1 : null,
      ));
    }

    return SizedBox(
      height: 36,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: movePairs.length,
        itemBuilder: (context, index) {
          final pair = movePairs[index];
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 2),
                child: Text(
                  '${pair.moveNumber}.',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
              _MoveChip(
                san: pair.whiteSan,
                isHighlighted:
                    widget.isReviewing && widget.reviewIndex == pair.whiteIndex,
                onTap: widget.onTapMove != null
                    ? () => widget.onTapMove!(pair.whiteIndex)
                    : null,
              ),
              if (pair.blackSan != null) ...[
                const SizedBox(width: 2),
                _MoveChip(
                  san: pair.blackSan!,
                  isHighlighted: widget.isReviewing &&
                      widget.reviewIndex == pair.blackIndex,
                  onTap: widget.onTapMove != null && pair.blackIndex != null
                      ? () => widget.onTapMove!(pair.blackIndex!)
                      : null,
                ),
              ],
              const SizedBox(width: 8),
            ],
          );
        },
      ),
    );
  }
}

class _MovePair {
  final int moveNumber;
  final String whiteSan;
  final int whiteIndex;
  final String? blackSan;
  final int? blackIndex;

  const _MovePair({
    required this.moveNumber,
    required this.whiteSan,
    required this.whiteIndex,
    this.blackSan,
    this.blackIndex,
  });
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: isHighlighted
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)
              : null,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          san,
          style: TextStyle(
            fontSize: 13,
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
