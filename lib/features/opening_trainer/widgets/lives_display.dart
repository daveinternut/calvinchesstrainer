import 'package:flutter/material.dart';

class LivesDisplay extends StatelessWidget {
  final int livesRemaining;
  final int maxLives;
  final bool lastMoveWasMistake;

  const LivesDisplay({
    super.key,
    required this.livesRemaining,
    required this.maxLives,
    this.lastMoveWasMistake = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxLives, (index) {
        final isFilled = index < livesRemaining;
        final justLost =
            lastMoveWasMistake && index == livesRemaining;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: justLost
              ? _PulsingHeart(filled: false)
              : Icon(
                  isFilled ? Icons.favorite : Icons.favorite_border,
                  color: isFilled
                      ? const Color(0xFFE53935)
                      : Colors.grey.shade400,
                  size: 22,
                ),
        );
      }),
    );
  }
}

class _PulsingHeart extends StatefulWidget {
  final bool filled;
  const _PulsingHeart({required this.filled});

  @override
  State<_PulsingHeart> createState() => _PulsingHeartState();
}

class _PulsingHeartState extends State<_PulsingHeart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scale = Tween(begin: 1.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Icon(
        Icons.favorite_border,
        color: Colors.grey.shade400,
        size: 22,
      ),
    );
  }
}
