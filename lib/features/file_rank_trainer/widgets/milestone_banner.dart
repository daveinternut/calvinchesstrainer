
import 'package:flutter/material.dart';
import 'package:calvinchesstrainer/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/audio/audio_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/trainer_layout.dart';

/// The streak celebration: a banner that rises at every multiple of 5, with
/// the milestone cheer and haptic from [AudioService.playMilestone].
///
/// Place it in the page's `Stack`, beside the trainer layout. It sits at the
/// bottom of the page — in landscape, at the bottom of the side panel — so it
/// never covers the prompt, which is exactly what the child needs to read
/// next. It takes no taps.
class MilestoneBanner extends ConsumerStatefulWidget {
  final int streak;

  /// Whether the page is a [TrainerLayout]: in landscape the banner then
  /// moves to the bottom of the side panel, clear of the board. Pages laid
  /// out as one centred column pass false to keep it bottom-centre.
  final bool alignToTrainerLayout;

  const MilestoneBanner({
    super.key,
    required this.streak,
    this.alignToTrainerLayout = true,
  });

  @override
  ConsumerState<MilestoneBanner> createState() => _MilestoneBannerState();
}

class _MilestoneBannerState extends ConsumerState<MilestoneBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late int _previousStreak;
  bool _visible = false;
  int _displayStreak = 0;

  static const _totalDuration = Duration(milliseconds: 2200);
  static const _enterEnd = 0.18;
  static const _holdEnd = 0.72;
  static const _maxWidth = 560.0;
  static const _bottomInset = 16.0;

  @override
  void initState() {
    super.initState();
    _previousStreak = widget.streak;
    _controller = AnimationController(duration: _totalDuration, vsync: this);
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _visible = false);
      }
    });
  }

  @override
  void didUpdateWidget(MilestoneBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.streak > _previousStreak &&
        widget.streak > 0 &&
        widget.streak % 5 == 0) {
      _displayStreak = widget.streak;
      _visible = true;
      ref.read(audioServiceProvider).playMilestone(widget.streak);
      _controller.forward(from: 0);
    }
    _previousStreak = widget.streak;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// The strip of the page the banner may use, as insets from the page edges.
  ///
  /// Portrait: the bottom of the page, under the board. Landscape: the bottom
  /// of [TrainerLayout]'s side panel (default padding), so the banner stays
  /// off the board too.
  EdgeInsets _bannerArea(BoxConstraints constraints) {
    if (!widget.alignToTrainerLayout ||
        !TrainerLayout.isLandscape(constraints)) {
      return const EdgeInsets.fromLTRB(24, 0, 24, _bottomInset);
    }
    return EdgeInsets.fromLTRB(
      TrainerLayout.landscapePanelLeft(constraints),
      0,
      TrainerLayout.defaultPadding.right,
      _bottomInset,
    );
  }

  String _milestoneLabel(AppLocalizations l10n) {
    return switch (_displayStreak) {
      5 => l10n.milestoneNice,
      10 => l10n.milestoneAmazing,
      15 => l10n.milestoneIncredible,
      20 => l10n.milestoneUnstoppable,
      _ when _displayStreak % 10 == 0 => l10n.milestoneLegendary,
      _ => l10n.milestoneGreat,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;

    return Positioned.fill(
      child: IgnorePointer(
        child: LayoutBuilder(
          builder: (context, constraints) => Padding(
            padding: _bannerArea(constraints),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _maxWidth),
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    final t = _controller.value;

                    double opacity;
                    double translateY;
                    double scale;

                    if (t < _enterEnd) {
                      // Rises into place from below.
                      final p = t / _enterEnd;
                      final curved = Curves.easeOutBack.transform(p);
                      translateY = 60 * (1 - curved);
                      opacity = p.clamp(0.0, 1.0);
                      scale = 0.6 + 0.4 * curved;
                    } else if (t < _holdEnd) {
                      translateY = 0;
                      opacity = 1.0;
                      scale = 1.0;
                    } else {
                      final p = (t - _holdEnd) / (1.0 - _holdEnd);
                      translateY = 0;
                      opacity = (1.0 - p).clamp(0.0, 1.0);
                      scale = 1.0 - 0.15 * p;
                    }

                    return Transform.translate(
                      offset: Offset(0, translateY),
                      child: Transform.scale(
                        scale: scale,
                        child: Opacity(opacity: opacity, child: child),
                      ),
                    );
                  },
                  child: _buildBanner(l10n),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBanner(AppLocalizations l10n) {
    // Deeper green as the streak grows.
    final color = _displayStreak >= 15 ? AppColors.brandDeep : AppColors.brand;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: AppColors.amber, size: 26),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.streakMilestone(_displayStreak),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: AppFonts.ui,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                Text(
                  _milestoneLabel(l10n),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppFonts.ui,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.88),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          const Icon(Icons.star_rounded, color: AppColors.amber, size: 26),
        ],
      ),
    );
  }
}
