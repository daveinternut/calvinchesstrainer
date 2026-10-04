import 'package:calvinchesstrainer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/ui/buttons.dart';
import '../../../core/ui/components.dart';
import '../../../core/ui/drill_glyph.dart';
import '../drill_catalog.dart';
import '../models/drill.dart';
import '../widgets/drill_setup_panel.dart';
import '../widgets/drill_widgets.dart';

/// A section's drills (Vision or Notation), grouped by skill.
///
/// Wide windows (an iPad) show the list beside the selected drill's setup
/// panel. Phones show the list; tapping a drill slides its setup up as a
/// sheet.
class DrillSectionScreen extends StatefulWidget {
  const DrillSectionScreen({
    super.key,
    required this.section,
    this.initialDrill,
  });

  final DrillSection section;
  final DrillId? initialDrill;

  /// Width from which the setup panel sits beside the list (a portrait iPad
  /// is just over it).
  static const double splitBreakpoint = 760;

  @override
  State<DrillSectionScreen> createState() => _DrillSectionScreenState();
}

class _DrillSectionScreenState extends State<DrillSectionScreen> {
  late DrillId _selected = widget.initialDrill != null &&
          widget.initialDrill!.section == widget.section
      ? widget.initialDrill!
      : DrillId.inSection(widget.section).first;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isVision = widget.section == DrillSection.vision;
    final title = isVision ? l10n.sectionVision : l10n.sectionNotation;
    final subtitle =
        isVision ? l10n.sectionVisionDesc : l10n.sectionNotationDesc;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final wide = width >= DrillSectionScreen.splitBreakpoint;
            final pad = width >= 1000 ? 40.0 : (wide ? 24.0 : 16.0);
            final panelWidth = (width * 0.48).clamp(360.0, 440.0);
            final header = Padding(
              padding: EdgeInsets.fromLTRB(pad, wide ? 24 : 8, pad, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _BackPill(
                    label: l10n.navHome,
                    onTap: () =>
                        context.canPop() ? context.pop() : context.go('/'),
                  ),
                  SizedBox(height: wide ? 18 : 12),
                  Text(
                    title,
                    style: AppText.display.copyWith(fontSize: wide ? 38 : 32),
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle, style: AppText.body.copyWith(fontSize: 16)),
                ],
              ),
            );

            if (!wide) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  header,
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.fromLTRB(pad - 6, 16, pad - 6, 24),
                      children: _groups(l10n, onTap: _openSheet),
                    ),
                  ),
                ],
              );
            }

            // The list (with the section title) scrolls on the left; the
            // setup panel takes the full height on the right, so Start stays
            // on screen even for drills with several options.
            return Padding(
              padding: EdgeInsets.only(right: pad),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.only(bottom: 24),
                      children: [
                        header,
                        const SizedBox(height: 20),
                        Padding(
                          padding: EdgeInsets.only(left: pad - 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: _groups(
                              l10n,
                              onTap: (d) => setState(() => _selected = d),
                              showSelection: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: width >= 1000 ? 28 : 20),
                  SizedBox(
                    width: panelWidth,
                    child: LayoutBuilder(
                      builder: (context, panel) => SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: SurfaceCard(
                          radius: 26,
                          padding: const EdgeInsets.all(24),
                          // The big preview only when there's room for it
                          // and every option below it.
                          child: DrillSetupPanel(
                            drill: _selected,
                            showPreview: panel.maxHeight >=
                                (_selected.usesPiece ? 940 : 760),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _groups(
    AppLocalizations l10n, {
    required ValueChanged<DrillId> onTap,
    bool showSelection = false,
  }) {
    final out = <Widget>[];
    for (final group in DrillCatalog.groups(widget.section)) {
      if (out.isNotEmpty) out.add(const SizedBox(height: 14));
      out.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(6, 0, 6, 6),
          child: FieldLabel(group.title(l10n)),
        ),
      );
      for (final drill in group.drills) {
        out.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: DrillRow(
              drill: drill,
              selected: showSelection && drill == _selected,
              onTap: () => onTap(drill),
            ),
          ),
        );
      }
    }
    return out;
  }

  Future<void> _openSheet(DrillId drill) {
    final l10n = AppLocalizations.of(context)!;
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: DrillSetupPanel(
            drill: drill,
            showPreview: false,
            onStarted: () => Navigator.of(sheetContext).pop(),
            header: Row(
              children: [
                DrillGlyph(spec: drill.glyph, size: 56),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        drill.title(l10n),
                        style: AppText.title.copyWith(fontSize: 23),
                      ),
                      const SizedBox(height: 2),
                      Text(drill.description(l10n), style: AppText.body),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                CircleIconButton(
                  icon: Icons.close_rounded,
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  onPressed: () => Navigator.of(sheetContext).pop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "‹ Home": the way back from a section, as a pill.
class _BackPill extends StatelessWidget {
  const _BackPill({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: const StadiumBorder(side: BorderSide(color: AppColors.line)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 44,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 16, 0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.chevron_left_rounded, color: AppColors.ink),
                const SizedBox(width: 2),
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: AppFonts.ui,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
