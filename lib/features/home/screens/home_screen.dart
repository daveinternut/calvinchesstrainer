import 'dart:math' as math;

import 'package:calvinchesstrainer/l10n/app_localizations.dart';
import 'package:dartchess/dartchess.dart' show PieceKind;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/audio/sound_switch.dart';
import '../../../core/services/stockfish_service.dart' show kEngineAvailable;
import '../../../core/theme/app_theme.dart';
import '../../../core/ui/buttons.dart';
import '../../../core/ui/components.dart';
import '../../../core/ui/drill_glyph.dart';
import '../../../core/ui/logo_mark.dart';
import '../../drills/drill_catalog.dart';
import '../../drills/models/drill.dart';
import '../../drills/providers/drill_prefs_provider.dart';
import '../../drills/providers/warmup_provider.dart';
import '../../drills/widgets/drill_widgets.dart';

/// Home: the daily warm-up, Continue, the Opening Explorer, and every drill
/// one tap away, grouped into Vision and Notation.
///
/// Three layouts from one tree: a landscape iPad puts the warm-up beside
/// Continue and Openings with four tiles per row; a portrait iPad stacks them
/// with two tiles per row; a phone scrolls each section sideways.
///
/// The Opening Explorer is the one feature that needs a chess engine. Every
/// current target has one (native Stockfish, or Stockfish WASM on web), but
/// its card stays gated on `kEngineAvailable`.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const double _wide = 1000;
  static const double _tablet = 700;

  /// The four drills each section previews on home.
  static const _visionTiles = [
    DrillId.findChecks,
    DrillId.hangingPieces,
    DrillId.forksAndSkewers,
    DrillId.knightFlight,
  ];
  static const _notationTiles = [
    DrillId.squares,
    DrillId.filesRanks,
    DrillId.readMoves,
    DrillId.pieceLetters,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            if (width < _tablet) return _PhoneHome(l10n: l10n);
            return _TabletHome(l10n: l10n, wide: width >= _wide);
          },
        ),
      ),
    );
  }

  static void openSection(BuildContext context, DrillSection section,
      [DrillId? drill]) {
    final base =
        section == DrillSection.vision ? '/chess-vision' : '/file-rank-trainer';
    context.push(drill == null ? base : '$base?drill=${drill.name}');
  }

  static void startWarmup(BuildContext context, WidgetRef ref) {
    final step = ref.read(warmupProvider.notifier).start();
    context.push(step.drill.location(step, warmup: true));
  }
}

// ------------------------------------------------------------------ layouts

class _TabletHome extends ConsumerWidget {
  const _TabletHome({required this.l10n, required this.wide});

  final AppLocalizations l10n;
  final bool wide;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final columns = wide ? 4 : 2;
    final side = Column(
      children: [
        const _ContinueCard(),
        if (kEngineAvailable) ...[
          const SizedBox(height: 16),
          const _OpeningsCard(),
        ],
      ],
    );
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(40, wide ? 26 : 20, 40, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(l10n: l10n, compact: false),
          const SizedBox(height: 24),
          if (wide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(flex: 62, child: _WarmupHero(tall: true)),
                const SizedBox(width: 20),
                Expanded(flex: 38, child: side),
              ],
            )
          else ...[
            const _WarmupHero(tall: true),
            const SizedBox(height: 16),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Expanded(child: _ContinueCard()),
                  if (kEngineAvailable) ...[
                    const SizedBox(width: 16),
                    const Expanded(child: _OpeningsCard()),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 28),
          _Section(
            section: DrillSection.vision,
            drills: HomeScreen._visionTiles,
            columns: columns,
          ),
          const SizedBox(height: 28),
          _Section(
            section: DrillSection.notation,
            drills: HomeScreen._notationTiles,
            columns: columns,
          ),
        ],
      ),
    );
  }
}

class _PhoneHome extends StatelessWidget {
  const _PhoneHome({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    // No side padding on the scroll view itself: the drill rows scroll edge
    // to edge, so the next card peeks in from the right.
    Widget padded(Widget child) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: child,
        );
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          padded(_Header(l10n: l10n, compact: true)),
          const SizedBox(height: 18),
          padded(const _WarmupHero(tall: false)),
          const SizedBox(height: 16),
          padded(const _ContinueCard()),
          const SizedBox(height: 26),
          const _Section(
            section: DrillSection.vision,
            drills: HomeScreen._visionTiles,
            scroller: true,
          ),
          const SizedBox(height: 26),
          const _Section(
            section: DrillSection.notation,
            drills: HomeScreen._notationTiles,
            scroller: true,
          ),
          if (kEngineAvailable) ...[
            const SizedBox(height: 26),
            padded(const _OpeningsCard()),
          ],
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------ pieces

class _Header extends StatelessWidget {
  const _Header({required this.l10n, required this.compact});

  final AppLocalizations l10n;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        LogoMark(size: compact ? 36 : 40),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            compact ? 'Calvin' : l10n.appTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.title.copyWith(
              fontSize: compact ? 25 : 21,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
        ),
        const SoundButton(),
        const SizedBox(width: 8),
        CircleIconButton(
          icon: Icons.info_outline_rounded,
          tooltip: l10n.about,
          onPressed: () => context.push('/about'),
        ),
      ],
    );
  }
}

/// The daily warm-up card: brand green, a faint checkerboard, and a tilted
/// board corner showing two checks being found.
class _WarmupHero extends ConsumerWidget {
  const _WarmupHero({required this.tall});

  final bool tall;

  /// b7–f3 of a real Find Checks position: Rf6+ and e5+ marked.
  static const _snippet = GlyphSpec(
    pieces: {
      (0, 0): PieceKind.blackPawn,
      (2, 1): PieceKind.blackKing,
      (1, 2): PieceKind.blackPawn,
      (2, 3): PieceKind.blackPawn,
      (3, 3): PieceKind.whitePawn,
      (4, 3): PieceKind.whiteRook,
      (2, 4): PieceKind.whitePawn,
    },
    arrows: [GlyphArrow((4, 3), (4, 1)), GlyphArrow((3, 3), (3, 2))],
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final snippetSize = tall ? 168.0 : 88.0;
    const onBrand = Color(0xE6FFFFFF);

    return Semantics(
      container: true,
      child: Container(
        constraints: BoxConstraints(minHeight: tall ? 232 : 0),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.brand,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Stack(
          children: [
            const Positioned(
              right: -40,
              top: -40,
              width: 320,
              height: 320,
              child: CustomPaint(painter: _CheckerPainter()),
            ),
            Positioned(
              right: tall ? 44 : 18,
              top: tall ? 30 : 16,
              child: Transform.rotate(
                angle: -6 * math.pi / 180,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x47000000),
                        blurRadius: 40,
                        offset: Offset(0, 18),
                      ),
                    ],
                    border: Border.all(
                      color: const Color(0x38FFFFFF),
                      width: 4,
                    ),
                  ),
                  child: DrillGlyph(spec: _snippet, size: snippetSize),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(tall ? 28 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.schedule_rounded, size: 18, color: onBrand),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          l10n.homeWarmupKicker,
                          style: const TextStyle(
                            fontFamily: AppFonts.ui,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: onBrand,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: tall ? 400 : 200),
                    child: Text(
                      l10n.homeWarmupTitle,
                      style: AppText.display.copyWith(
                        color: Colors.white,
                        fontSize: tall ? 33 : 28,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    // Clear of the board corner on a phone.
                    padding: EdgeInsets.only(top: tall ? 0 : 6),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: tall ? 400 : 560),
                      child: Text(
                        l10n.homeWarmupBody,
                        style: const TextStyle(
                          fontFamily: AppFonts.ui,
                          fontSize: 15,
                          height: 1.42,
                          color: onBrand,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: tall ? 22 : 16),
                  FilledButton.icon(
                    onPressed: () => HomeScreen.startWarmup(context, ref),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.brandDeep,
                      minimumSize: const Size(64, 48),
                      padding: const EdgeInsets.fromLTRB(16, 0, 22, 0),
                    ),
                    icon: const Icon(
                      Icons.play_arrow_rounded,
                      color: AppColors.brand,
                    ),
                    label: Text(l10n.homeWarmupStart),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A faint checkerboard in the warm-up card's corner.
class _CheckerPainter extends CustomPainter {
  const _CheckerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const cell = 64.0;
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.09);
    for (var y = 0.0; y < size.height; y += cell) {
      for (var x = 0.0; x < size.width; x += cell) {
        if (((x + y) / cell).round().isEven) {
          canvas.drawRect(Rect.fromLTWH(x, y, cell / 2, cell / 2), paint);
          canvas.drawRect(
            Rect.fromLTWH(x + cell / 2, y + cell / 2, cell / 2, cell / 2),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Continue: the last drill, one tap from where it was left. Before the
/// first drill it suggests one ("Start here").
class _ContinueCard extends ConsumerWidget {
  const _ContinueCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final last = ref.watch(drillPrefsProvider).lastPlayed;
    final config = last ?? DrillId.findChecks.defaultConfig;
    final drill = config.drill;

    void play() {
      ref.read(drillPrefsProvider.notifier).recordStart(config);
      context.push(drill.location(config));
    }

    return _SideCard(
      glyph: drill.glyph,
      kicker: last == null ? l10n.homeStartHere : l10n.homeContinue,
      title: drill.title(l10n),
      subtitle: last == null
          ? drill.description(l10n)
          : drillConfigSummary(config, l10n),
      onTap: play,
      action: CircleIconButton(
        icon: Icons.play_arrow_rounded,
        filled: true,
        size: 48,
        tooltip: l10n.homeResume(drill.title(l10n)),
        onPressed: play,
      ),
    );
  }
}

class _OpeningsCard extends StatelessWidget {
  const _OpeningsCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    void open() => context.push('/opening-trainer');
    return _SideCard(
      glyph: openingsGlyph,
      kicker: l10n.homeOpenings,
      title: l10n.openingExplorer,
      subtitle: l10n.homeOpeningExplorerDesc,
      onTap: open,
      action: CircleIconButton(
        icon: Icons.chevron_right_rounded,
        tooltip: l10n.openingExplorer,
        onPressed: open,
      ),
    );
  }
}

class _SideCard extends StatelessWidget {
  const _SideCard({
    required this.glyph,
    required this.kicker,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.action,
  });

  final GlyphSpec glyph;
  final String kicker;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Row(
        children: [
          DrillGlyph(spec: glyph, size: 60),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(kicker, style: AppText.label),
                const SizedBox(height: 2),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.cardTitle.copyWith(fontSize: 18),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.caption.copyWith(color: AppColors.ink2),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          action,
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.section,
    required this.drills,
    this.columns = 4,
    this.scroller = false,
  });

  final DrillSection section;
  final List<DrillId> drills;
  final int columns;

  /// Phones: one sideways-scrolling row instead of a grid.
  final bool scroller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isVision = section == DrillSection.vision;
    final total = DrillId.inSection(section).length;
    final header = SectionHeader(
      title: isVision ? l10n.sectionVision : l10n.sectionNotation,
      subtitle: scroller
          ? null
          : (isVision ? l10n.sectionVisionDesc : l10n.sectionNotationDesc),
      titleSize: scroller ? 22 : 24,
      actionLabel: l10n.sectionAllDrills(total),
      onAction: () => HomeScreen.openSection(context, section),
    );

    void open(DrillId d) => HomeScreen.openSection(context, section, d);

    if (scroller) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: header,
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 164,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: drills.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, i) => DrillTile(
                drill: drills[i],
                width: 170,
                height: 164,
                onTap: () => open(drills[i]),
              ),
            ),
          ),
        ],
      );
    }

    final rows = <Widget>[];
    for (var i = 0; i < drills.length; i += columns) {
      if (rows.isNotEmpty) rows.add(const SizedBox(height: 16));
      final row = drills.skip(i).take(columns).toList();
      rows.add(
        Row(
          children: [
            for (var j = 0; j < columns; j++) ...[
              if (j > 0) const SizedBox(width: 16),
              Expanded(
                child: j < row.length
                    ? DrillTile(drill: row[j], onTap: () => open(row[j]))
                    : const SizedBox.shrink(),
              ),
            ],
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [header, const SizedBox(height: 12), ...rows],
    );
  }
}
