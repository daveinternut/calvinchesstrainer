import 'package:flutter/material.dart';

class ThinkingIndicator extends StatelessWidget {
  /// Current wave index (0-based). -1 means idle (all done).
  final int currentWave;

  /// Total number of waves.
  final int totalWaves;

  const ThinkingIndicator({
    super.key,
    required this.currentWave,
    required this.totalWaves,
  });

  @override
  Widget build(BuildContext context) {
    if (totalWaves <= 0 || currentWave < 0) return const SizedBox.shrink();

    // How many waves have completed (results received)
    final completedWaves = currentWave;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _BrainIcon(isActive: currentWave < totalWaves),
        const SizedBox(width: 6),
        for (int i = 0; i < totalWaves; i++) ...[
          if (i > 0) const SizedBox(width: 3),
          _WaveDot(
            isCompleted: i < completedWaves,
            isActive: i == currentWave,
            index: i,
          ),
        ],
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

class _WaveDot extends StatelessWidget {
  final bool isCompleted;
  final bool isActive;
  final int index;

  const _WaveDot({
    required this.isCompleted,
    required this.isActive,
    required this.index,
  });

  static const _sizes = [5.0, 6.0, 7.0, 8.0];

  @override
  Widget build(BuildContext context) {
    final size = index < _sizes.length ? _sizes[index] : 8.0;
    final color = isCompleted
        ? const Color(0xFF4CAF50)
        : isActive
            ? const Color(0xFFFFB300)
            : Colors.grey.shade300;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: const Color(0xFFFFB300).withValues(alpha: 0.5),
                  blurRadius: 4,
                ),
              ]
            : null,
      ),
    );
  }
}
