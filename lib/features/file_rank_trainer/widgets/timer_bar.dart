import 'package:flutter/material.dart';
import 'package:calvinchesstrainer/l10n/app_localizations.dart';

import '../../../core/theme/app_theme.dart';

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
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    // Swells and settles back, so the bar is at rest between beats.
    _pulseAnimation =
        TweenSequence<double>([
          TweenSequenceItem(
            tween: Tween<double>(begin: 1.0, end: 1.06),
            weight: 1,
          ),
          TweenSequenceItem(
            tween: Tween<double>(begin: 1.06, end: 1.0),
            weight: 1,
          ),
        ]).animate(
          CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
        );
  }

  @override
  void didUpdateWidget(TimerBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // One beat per tick of the clock — not on every rebuild of the screen
    // (each answer in the last five seconds used to restart it).
    if (widget.remainingSeconds != oldWidget.remainingSeconds &&
        widget.remainingSeconds <= 5 &&
        widget.remainingSeconds > 0) {
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
    final l10n = AppLocalizations.of(context)!;
    final fraction = widget.totalSeconds > 0
        ? (widget.remainingSeconds / widget.totalSeconds).clamp(0.0, 1.0)
        : 0.0;
    final color = _timerColor(widget.remainingSeconds);
    final isUrgent = widget.remainingSeconds <= 5;
    final seconds = widget.remainingSeconds.clamp(0, 5999);
    final clock = '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';

    return ScaleTransition(
      scale: isUrgent ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  clock,
                  style: AppText.number.copyWith(
                    fontSize: 36,
                    height: 1.1,
                    color: isUrgent ? color : AppColors.ink,
                  ),
                ),
                const Spacer(),
                if (isUrgent)
                  Text(
                    l10n.hurry,
                    style: AppText.label.copyWith(color: color),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: fraction,
                backgroundColor: AppColors.well,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _timerColor(int seconds) {
    if (seconds > 10) return AppColors.brand;
    if (seconds > 5) return AppColors.amber;
    return AppColors.verm;
  }
}
