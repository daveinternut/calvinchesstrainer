import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class StreakCounter extends StatefulWidget {
  final int streak;
  final int bestStreak;

  const StreakCounter({
    super.key,
    required this.streak,
    required this.bestStreak,
  });

  @override
  State<StreakCounter> createState() => _StreakCounterState();
}

class _StreakCounterState extends State<StreakCounter>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _milestoneController;
  late Animation<double> _milestoneAnimation;
  late Animation<double> _glowAnimation;
  int _previousStreak = 0;
  bool _showMilestone = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.elasticOut),
    );

    _milestoneController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _milestoneAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _milestoneController, curve: Curves.elasticOut),
    );
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _milestoneController, curve: Curves.easeOut),
    );
    _milestoneController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _showMilestone = false);
      }
    });
  }

  @override
  void didUpdateWidget(StreakCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.streak > _previousStreak && widget.streak > 0) {
      final isMilestone = widget.streak % 5 == 0;
      if (isMilestone) {
        setState(() => _showMilestone = true);
        _milestoneController.forward(from: 0.0);
      } else {
        _pulseController.forward(from: 0.0);
      }
    }
    _previousStreak = widget.streak;
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _milestoneController.dispose();
    super.dispose();
  }

  String get _milestoneLabel {
    return switch (widget.streak) {
      5 => 'Nice!',
      10 => 'Amazing!',
      15 => 'Incredible!',
      20 => 'Unstoppable!',
      _ when widget.streak % 10 == 0 => 'Legendary!',
      _ => 'Great!',
    };
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (_showMilestone)
            AnimatedBuilder(
              animation: _glowAnimation,
              builder: (context, child) {
                return Container(
                  width: 80 + _glowAnimation.value * 40,
                  height: 80 + _glowAnimation.value * 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.correctGreen
                        .withValues(alpha: 0.15 * (1 - _glowAnimation.value)),
                  ),
                );
              },
            ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _showMilestone
                  ? ScaleTransition(
                      scale: _milestoneAnimation,
                      child: _buildStreakText(true),
                    )
                  : ScaleTransition(
                      scale: _pulseAnimation,
                      child: _buildStreakText(false),
                    ),
              if (widget.bestStreak > 0)
                Text(
                  _showMilestone
                      ? _milestoneLabel
                      : 'Best: ${widget.bestStreak}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        _showMilestone ? FontWeight.bold : FontWeight.normal,
                    color: _showMilestone
                        ? AppColors.correctGreen
                        : AppColors.textSecondary.withValues(alpha: 0.7),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStreakText(bool isMilestone) {
    return Text(
      '${widget.streak}',
      style: TextStyle(
        fontSize: isMilestone ? 44 : 36,
        fontWeight: FontWeight.bold,
        color: isMilestone ? AppColors.correctGreen : AppColors.primary,
      ),
    );
  }
}
