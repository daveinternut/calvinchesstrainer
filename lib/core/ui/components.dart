import 'package:chessground/chessground.dart' show PieceSet;
import 'package:dartchess/dartchess.dart' show PieceKind, Side;
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'buttons.dart';

/// A white card with a hairline border. Tappable when [onTap] is set.
class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.radius = 22,
    this.color = AppColors.surface,
    this.borderColor = AppColors.line,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color color;
  final Color borderColor;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: BorderSide(color: borderColor),
    );
    final card = Material(
      color: color,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: onTap == null
          ? Padding(padding: padding, child: child)
          : InkWell(
              onTap: onTap,
              child: Padding(padding: padding, child: child),
            ),
    );
    if (onTap == null || semanticLabel == null) return card;
    return Semantics(button: true, label: semanticLabel, child: card);
  }
}

/// "Best 12" in mono, on the ground colour.
class BestPill extends StatelessWidget {
  const BestPill({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.ground,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        maxLines: 1,
        style: AppText.number.copyWith(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
          color: AppColors.ink2,
        ),
      ),
    );
  }
}

/// "White to play" with a king image: real positions come with either side
/// to move, so the mover must be unmistakable.
class SideToMovePill extends StatelessWidget {
  const SideToMovePill({super.key, required this.side, required this.label});

  final Side side;
  final String label;

  @override
  Widget build(BuildContext context) {
    final king = PieceSet.cburnett.assets[
        side == Side.white ? PieceKind.whiteKing : PieceKind.blackKing];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 26,
          height: 26,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.line2),
          ),
          child: king == null ? null : Image(image: king),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: AppFonts.ui,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.ink2,
            ),
          ),
        ),
      ],
    );
  }
}

/// A small label over a big mono number ("Score / 6").
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.muted = false,
    this.valueSize = 26,
  });

  final String label;
  final String value;
  final bool muted;
  final double valueSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: AppText.caption, maxLines: 1),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: AppText.number.copyWith(
                fontSize: valueSize,
                color: muted ? AppColors.ink3 : AppColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A section title with an optional subtitle and a trailing link.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.titleSize = 24,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final double titleSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: 12,
            runSpacing: 2,
            children: [
              Text(
                title,
                style: AppText.title.copyWith(
                  fontSize: titleSize,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              if (subtitle != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    subtitle!,
                    style: AppText.caption.copyWith(fontSize: 15),
                  ),
                ),
            ],
          ),
        ),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              minimumSize: const Size(44, 44),
              padding: const EdgeInsets.only(left: 12, right: 4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(actionLabel!),
                const Icon(Icons.chevron_right_rounded, size: 20),
              ],
            ),
          ),
      ],
    );
  }
}

/// The bar across the top of every play screen: a close button, the drill's
/// name and a subtitle (the mode, or the warm-up step), an optional trailing
/// widget (the running score), and an optional [action] button at the end.
class PlayTopBar extends StatelessWidget {
  const PlayTopBar({
    super.key,
    required this.title,
    required this.onClose,
    required this.closeTooltip,
    this.subtitle,
    this.trailing,
    this.action,
  });

  final String title;
  final String? subtitle;
  final VoidCallback onClose;
  final String closeTooltip;
  final Widget? trailing;

  /// The button at the far end, opposite the close button. Drill screens put
  /// the sound switch here (`SoundButton`).
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          CircleIconButton(
            icon: Icons.close_rounded,
            onPressed: onClose,
            tooltip: closeTooltip,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Shrinks rather than truncating when trailing buttons crowd
                // it (the Opening Explorer's tools in a side panel).
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(title, maxLines: 1, style: AppText.cardTitle),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.caption.copyWith(fontSize: 13),
                  ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 12),
            DefaultTextStyle.merge(
              style: AppText.number.copyWith(fontSize: 18),
              child: trailing!,
            ),
          ],
          if (action != null) ...[const SizedBox(width: 8), action!],
        ],
      ),
    );
  }
}

/// A small grey section label ("Mode", "Your piece").
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Text(text, style: AppText.label);
}

/// A notation chip: a found move or square (green, with a tick), a miss
/// (vermilion), or an empty slot still to find (dashed).
class NotationChip extends StatelessWidget {
  const NotationChip.found(this.text, {super.key, this.height = 48})
      : _kind = _ChipKind.found;
  const NotationChip.missed(this.text, {super.key, this.height = 48})
      : _kind = _ChipKind.missed;
  const NotationChip.empty({super.key, this.height = 48})
      : text = '?',
        _kind = _ChipKind.empty;

  final String text;
  final _ChipKind _kind;
  final double height;

  @override
  Widget build(BuildContext context) {
    final kind = _kind;
    final (bg, fg, icon) = switch (kind) {
      _ChipKind.found => (
          AppColors.brandSoft,
          AppColors.brandDeep,
          Icons.check_rounded
        ),
      _ChipKind.missed => (
          AppColors.vermSoft,
          AppColors.vermInk,
          Icons.close_rounded
        ),
      _ChipKind.empty => (Colors.transparent, AppColors.ink3, null),
    };
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: kind == _ChipKind.empty
            ? Border.all(color: AppColors.line2, width: 1.5)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 16,
              color: kind == _ChipKind.found ? AppColors.brand : AppColors.verm,
            ),
            const SizedBox(width: 5),
          ],
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.fade,
              softWrap: false,
              style: AppText.mono.copyWith(fontSize: 17, color: fg),
            ),
          ),
        ],
      ),
    );
  }
}

enum _ChipKind { found, missed, empty }
