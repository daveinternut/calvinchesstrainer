import 'package:flutter/material.dart';
import 'package:calvinchesstrainer/l10n/app_localizations.dart';
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
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  late final AnimationController _milestoneController;
  late final Animation<double> _milestoneAnimation;
  late final Animation<double> _glowAnimation;
  late int _previousStreak;
  bool _showMilestone = false;

  /// The streak the running milestone celebrates, captured when it starts so
  /// a change mid-animation can't relabel it (a big green "0 — Legendary!").
  int _milestoneStreak = 0;

  @override
  void initState() {
    super.initState();
    _previousStreak = widget.streak;

    // Both animations pop up and settle back, so the counter always returns
    // to its resting size between answers.
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _pulseAnimation = _popAndSettle(1.2).animate(_pulseController);

    _milestoneController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _milestoneAnimation = _popAndSettle(1.5).animate(_milestoneController);
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _milestoneController, curve: Curves.easeOut),
    );
    _milestoneController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _showMilestone = false);
      }
    });
  }

  static Animatable<double> _popAndSettle(double peak) {
    return TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: peak,
        ).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: peak,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 60,
      ),
    ]);
  }

  @override
  void didUpdateWidget(StreakCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    final streak = widget.streak;
    if (streak != _previousStreak && _showMilestone) {
      // The streak moved on (or broke) mid-celebration: end it so the label
      // always matches the number on screen.
      _milestoneController.stop();
      _showMilestone = false;
    }
    if (streak > _previousStreak && streak > 0) {
      if (streak % 5 == 0) {
        _milestoneStreak = streak;
        _showMilestone = true;
        _milestoneController.forward(from: 0.0);
      } else {
        _pulseController.forward(from: 0.0);
      }
    }
    _previousStreak = streak;
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _milestoneController.dispose();
    super.dispose();
  }

  String get _milestoneLabel {
    final l10n = AppLocalizations.of(context)!;
    return switch (_milestoneStreak) {
      5 => l10n.milestoneNice,
      10 => l10n.milestoneAmazing,
      15 => l10n.milestoneIncredible,
      20 => l10n.milestoneUnstoppable,
      _ when _milestoneStreak % 10 == 0 => l10n.milestoneLegendary,
      _ => l10n.milestoneGreat,
    };
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 70,
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
                    color: AppColors.brand.withValues(
                      alpha: 0.14 * (1 - _glowAnimation.value),
                    ),
                  ),
                );
              },
            ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
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
                        : AppLocalizations.of(
                            context,
                          )!.bestLabel(widget.bestStreak),
                    style: AppText.caption.copyWith(
                      fontWeight:
                          _showMilestone ? FontWeight.w700 : FontWeight.w500,
                      color: _showMilestone ? AppColors.brand : AppColors.ink3,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakText(bool isMilestone) {
    return Text(
      '${widget.streak}',
      style: AppText.number.copyWith(
        fontSize: isMilestone ? 42 : 36,
        height: 1.1,
        color: isMilestone ? AppColors.brand : AppColors.ink,
      ),
    );
  }
}
