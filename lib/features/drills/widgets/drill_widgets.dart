import 'package:calvinchesstrainer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/personal_bests_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/ui/components.dart';
import '../../../core/ui/drill_glyph.dart';
import '../drill_catalog.dart';
import '../models/drill.dart';
import '../providers/drill_prefs_provider.dart';

/// The badge a drill shows: its personal best, if it has one.
Widget? drillBadge(WidgetRef ref, DrillId drill, AppLocalizations l10n) {
  final prefs = ref.watch(drillPrefsProvider);
  final bests = ref.watch(personalBestsProvider);
  if (!prefs.hasPlayed(drill)) return null;
  final scored = drill.scoredConfig(prefs.configFor(drill));
  if (scored == null) return null;
  final key = drill.bestKey(scored);
  final value = key == null ? null : bests[key];
  if (value == null) return null;
  return BestPill(
    text: l10n.drillBest(
      DrillCatalog.formatBest(value, isTime: drill.bestIsTime(scored)),
    ),
  );
}

/// A short summary of [config]'s choices: "Queen · Rook · Speed Round".
String drillConfigSummary(DrillConfig config, AppLocalizations l10n) {
  final d = config.drill;
  final c = d.normalize(config);
  return [
    if (d.usesPiece) c.piece.localizedLabel(l10n),
    if (d.usesTarget) c.target.localizedLabel(l10n),
    if (d.usesLines) c.lines == DrillLines.files ? l10n.files : l10n.ranks,
    d.modeLabel(c.mode, l10n),
    if (d.usesSide(c.mode) && c.blackSide) l10n.playAsBlack,
  ].join(' · ');
}

/// A drill on the home screen: glyph, badge, name, one-line description.
class DrillTile extends ConsumerWidget {
  const DrillTile({
    super.key,
    required this.drill,
    required this.onTap,
    this.width,
    this.height = 150,
    this.glyphSize = 60,
  });

  final DrillId drill;
  final VoidCallback onTap;
  final double? width;
  final double height;
  final double glyphSize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final badge = drillBadge(ref, drill, l10n);
    final title = Text(
      drill.title(l10n),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppText.cardTitle,
    );
    final description = Text(
      drill.description(l10n),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: AppText.caption,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        // A wide tile (two per row on a portrait iPad) reads better as a row.
        final horizontal = (width ?? constraints.maxWidth) >= 320;
        return SizedBox(
          width: width,
          height: horizontal ? 112 : height,
          child: SurfaceCard(
            onTap: onTap,
            radius: 20,
            semanticLabel: drill.title(l10n),
            child: horizontal
                ? Row(
                    children: [
                      DrillGlyph(spec: drill.glyph, size: 76),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            title,
                            const SizedBox(height: 2),
                            description,
                          ],
                        ),
                      ),
                      if (badge != null) ...[const SizedBox(width: 12), badge],
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DrillGlyph(spec: drill.glyph, size: glyphSize),
                          const Spacer(),
                          ?badge,
                        ],
                      ),
                      const Spacer(),
                      title,
                      const SizedBox(height: 2),
                      description,
                    ],
                  ),
          ),
        );
      },
    );
  }
}

/// A drill in a section list: glyph, name and description, best, chevron.
class DrillRow extends ConsumerWidget {
  const DrillRow({
    super.key,
    required this.drill,
    required this.onTap,
    this.selected = false,
  });

  final DrillId drill;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final badge = drillBadge(ref, drill, l10n);
    return Semantics(
      button: true,
      selected: selected,
      label: drill.title(l10n),
      excludeSemantics: true,
      child: Material(
        color: selected ? AppColors.brandSoft : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: selected
              ? const BorderSide(color: AppColors.brand, width: 1.5)
              : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 6, 10, 6),
            child: Row(
              children: [
                DrillGlyph(spec: drill.glyph, size: 50),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        drill.title(l10n),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.cardTitle.copyWith(fontSize: 16.5),
                      ),
                      Text(
                        drill.description(l10n),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.caption,
                      ),
                    ],
                  ),
                ),
                if (badge != null) ...[const SizedBox(width: 8), badge],
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: AppColors.ink3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
