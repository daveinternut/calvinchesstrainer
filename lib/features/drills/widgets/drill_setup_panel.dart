import 'package:calvinchesstrainer/l10n/app_localizations.dart';
import 'package:chessground/chessground.dart' show PieceSet;
import 'package:dartchess/dartchess.dart' show PieceKind;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/personal_bests_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/ui/buttons.dart';
import '../../../core/ui/components.dart';
import '../../../core/ui/drill_glyph.dart';
import '../../../core/ui/segmented_picker.dart';
import '../../chess_vision/models/chess_vision_state.dart';
import '../drill_catalog.dart';
import '../models/drill.dart';
import '../providers/drill_prefs_provider.dart';

/// A drill's setup: what it is, its options, its mode, your best, Start.
///
/// Opens on the setup used last time, so most visits are one tap on Start.
/// Starting remembers the setup (and makes it home's Continue card).
class DrillSetupPanel extends ConsumerStatefulWidget {
  const DrillSetupPanel({
    super.key,
    required this.drill,
    this.showPreview = true,
    this.header,
    this.onStarted,
  });

  final DrillId drill;

  /// A large glyph above the title (the iPad detail panel).
  final bool showPreview;

  /// Replaces the title block (the phone sheet puts a close button there).
  final Widget? header;

  /// Called after Start, e.g. to close a bottom sheet.
  final VoidCallback? onStarted;

  @override
  ConsumerState<DrillSetupPanel> createState() => _DrillSetupPanelState();
}

class _DrillSetupPanelState extends ConsumerState<DrillSetupPanel> {
  late DrillConfig _config;

  @override
  void initState() {
    super.initState();
    _config = ref.read(drillPrefsProvider).configFor(widget.drill);
  }

  @override
  void didUpdateWidget(DrillSetupPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.drill != widget.drill) {
      _config = ref.read(drillPrefsProvider).configFor(widget.drill);
    }
  }

  void _update(DrillConfig config) =>
      setState(() => _config = widget.drill.normalize(config));

  void _start() {
    final config = widget.drill.normalize(_config);
    ref.read(drillPrefsProvider.notifier).recordStart(config);
    widget.onStarted?.call();
    context.push(widget.drill.location(config));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final drill = widget.drill;
    final c = drill.normalize(_config);

    final children = <Widget>[
      if (widget.showPreview) ...[
        Center(child: DrillGlyph(spec: drill.glyph, size: 176)),
        const SizedBox(height: 20),
      ],
      widget.header ??
          Row(
            children: [
              // Without the big preview, a smaller glyph beside the title.
              if (!widget.showPreview) ...[
                DrillGlyph(spec: drill.glyph, size: 72),
                const SizedBox(width: 16),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      drill.title(l10n),
                      style: AppText.title.copyWith(fontSize: 26),
                    ),
                    const SizedBox(height: 6),
                    Text(drill.description(l10n), style: AppText.body),
                  ],
                ),
              ),
            ],
          ),
      if (drill.usesPiece) ...[
        const SizedBox(height: 18),
        FieldLabel(l10n.setupYourPiece),
        const SizedBox(height: 8),
        SegmentedPicker<WhitePiece>(
          height: 56,
          value: c.piece,
          onChanged: (p) => _update(c.copyWith(piece: p)),
          options: [
            for (final p in WhitePiece.values)
              SegmentOption(
                value: p,
                semanticLabel: p.localizedLabel(l10n),
                child: _pieceImage(p.pieceKind),
              ),
          ],
        ),
      ],
      if (drill.usesTarget) ...[
        const SizedBox(height: 16),
        FieldLabel(l10n.setupForkTarget),
        const SizedBox(height: 8),
        SegmentedPicker<TargetPiece>(
          height: 56,
          value: c.target,
          onChanged: (t) => _update(c.copyWith(target: t)),
          options: [
            for (final t in TargetPiece.values)
              SegmentOption(
                value: t,
                semanticLabel: t.localizedLabel(l10n),
                enabled: DrillCatalog.isTargetAllowed(t, c.piece),
                child: _pieceImage(t.pieceKind),
              ),
          ],
        ),
      ],
      if (drill.usesLines) ...[
        const SizedBox(height: 16),
        FieldLabel(l10n.setupLines),
        const SizedBox(height: 8),
        SegmentedPicker<DrillLines>(
          value: c.lines,
          onChanged: (lines) => _update(c.copyWith(lines: lines)),
          options: [
            SegmentOption(value: DrillLines.files, label: l10n.files),
            SegmentOption(value: DrillLines.ranks, label: l10n.ranks),
          ],
        ),
      ],
      const SizedBox(height: 16),
      FieldLabel(l10n.setupMode),
      const SizedBox(height: 8),
      if (drill.modes.length > 1)
        SegmentedPicker<DrillMode>(
          value: c.mode,
          onChanged: (m) => _update(c.copyWith(mode: m)),
          options: [
            for (final m in drill.modes)
              SegmentOption(value: m, label: drill.modeLabel(m, l10n)),
          ],
        )
      else
        Text(drill.modeLabel(c.mode, l10n), style: AppText.cardTitle),
      const SizedBox(height: 6),
      Text(drill.modeHelp(c.mode, l10n), style: AppText.caption),
      if (drill.usesSide(c.mode)) ...[
        const SizedBox(height: 16),
        FieldLabel(l10n.setupBoardSide),
        const SizedBox(height: 8),
        SegmentedPicker<bool>(
          value: c.blackSide,
          onChanged: (black) => _update(c.copyWith(blackSide: black)),
          options: [
            SegmentOption(value: false, label: l10n.playAsWhite),
            SegmentOption(value: true, label: l10n.playAsBlack),
          ],
        ),
      ],
      const SizedBox(height: 16),
      _BestRow(config: c),
      const SizedBox(height: 20),
      AppPrimaryButton(
        label: l10n.start,
        icon: Icons.play_arrow_rounded,
        expand: true,
        height: 56,
        onPressed: _start,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }

  Widget _pieceImage(PieceKind kind) {
    final asset = PieceSet.cburnett.assets[kind];
    return SizedBox.square(
      dimension: 36,
      child: asset == null ? null : Image(image: asset),
    );
  }
}

class _BestRow extends ConsumerWidget {
  const _BestRow({required this.config});

  final DrillConfig config;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final drill = config.drill;
    final key = drill.bestKey(config);
    final bests = ref.watch(personalBestsProvider);
    final value = key == null ? null : bests[key];
    // Explore and practice keep no records: say nothing rather than "none".
    if (key == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.ground,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              l10n.setupYourBest,
              style: AppText.body.copyWith(fontSize: 14.5),
            ),
          ),
          Text(
            value == null
                ? l10n.setupNoBest
                : DrillCatalog.formatBest(
                    value,
                    isTime: drill.bestIsTime(config),
                  ),
            style: value == null
                ? AppText.caption
                : AppText.number.copyWith(fontSize: 20),
          ),
        ],
      ),
    );
  }
}
