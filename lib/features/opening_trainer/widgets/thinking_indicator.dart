import 'package:flutter/material.dart';

/// Shows what the engine is doing: an animated brain plus a live
/// "depth 12/18" readout of the current search.
class ThinkingIndicator extends StatelessWidget {
  /// Depth the engine has reached so far (0 = search just started).
  final int depth;

  /// Depth the search will run to (<= 0 hides the indicator).
  final int targetDepth;

  const ThinkingIndicator({
    super.key,
    required this.depth,
    required this.targetDepth,
  });

  @override
  Widget build(BuildContext context) {
    if (targetDepth <= 0) return const SizedBox.shrink();

    final isActive = depth < targetDepth;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _BrainIcon(isActive: isActive),
        const SizedBox(width: 4),
        Text(
          depth > 0 ? 'd$depth/$targetDepth' : 'd–/$targetDepth',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            fontFeatures: const [FontFeature.tabularFigures()],
            color: isActive ? Colors.grey.shade600 : const Color(0xFF4CAF50),
          ),
        ),
      ],
    );
  }
}

class _BrainIcon extends StatefulWidget {
  final bool isActive;
  const _BrainIcon({required this.isActive});

  @override
  State<_BrainIcon> createState() => _BrainIconState();
}

class _BrainIconState extends State<_BrainIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    if (widget.isActive) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_BrainIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isActive && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: widget.isActive ? 0.5 + _controller.value * 0.5 : 0.4,
          child: Icon(
            Icons.psychology_rounded,
            size: 18,
            color: widget.isActive
                ? Color.lerp(
                    Colors.grey.shade500,
                    const Color(0xFF4CAF50),
                    _controller.value,
                  )
                : Colors.grey.shade400,
          ),
        );
      },
    );
  }
}
