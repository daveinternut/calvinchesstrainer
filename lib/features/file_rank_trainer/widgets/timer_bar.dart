import 'package:flutter/material.dart';

class TimerBar extends StatefulWidget {
  final int remainingSeconds;
  final int totalSeconds;

  const TimerBar({
    super.key,
    required this.remainingSeconds,
    this.totalSeconds = 30,
  });

  @override
  State<TimerBar> createState() => _TimerBarState();
}

class _TimerBarState extends State<TimerBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(TimerBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.remainingSeconds <= 5 && widget.remainingSeconds > 0) {
      _pulseController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fraction = widget.remainingSeconds / widget.totalSeconds;
    final color = _timerColor(widget.remainingSeconds);
    final isUrgent = widget.remainingSeconds <= 5;

    return ScaleTransition(
      scale: isUrgent ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${widget.remainingSeconds}s',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              if (isUrgent)
                Text(
                  'Hurry!',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: fraction,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 10,
            ),
          ),
        ],
      ),
    );
  }

  Color _timerColor(int seconds) {
    if (seconds > 20) return const Color(0xFF4CAF50);
    if (seconds > 10) return const Color(0xFFFFC107);
    return const Color(0xFFE53935);
  }
}
