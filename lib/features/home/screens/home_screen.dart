import 'package:flutter/material.dart';
import 'package:calvinchesstrainer/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/stockfish_service.dart' show kEngineAvailable;
import '../../../core/theme/app_theme.dart';

/// The home screen ranks the trainers rather than listing them: Chess Vision
/// is the hero (eight drills, the deepest content in the app), Chess Notation
/// and Opening Explorer share a secondary row. Piece Value used to live here
/// as its own card; it is now a drill inside Chess Notation.
///
/// Opening Explorer is the one card that needs a chess engine. Every current
/// target has one (native Stockfish, or Stockfish WASM on web), but the card
/// stays gated on `kEngineAvailable`: on an engine-less target it would be
/// dropped and Chess Notation would take the whole secondary row.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.info_outline_rounded),
                    color: AppColors.textSecondary,
                    onPressed: () => context.push('/about'),
                    tooltip: l10n.about,
                  ),
                ],
              ),
            ),
            Flexible(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      flex: 4,
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(40),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(40),
                            child: Image.asset(
                              'assets/images/app_icon.png',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: AppColors.primary,
                                child: const Icon(
                                  Icons.castle_rounded,
                                  size: 72,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Bounded so the wordmark scales to the space left over
                    // rather than crowding out the icon and the hero card.
                    Flexible(
                      flex: 3,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          l10n.calvinChessTrainer,
                          style: const TextStyle(
                            fontFamily: 'BradBunR',
                            fontSize: 72,
                            color: AppColors.primary,
                            height: 1.1,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.masterTheFundamentals,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Flexible(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    Expanded(
                      flex: 5,
                      child: _HeroTrainingCard(
                        title: l10n.chessVision,
                        subtitle: l10n.seeTheBoard,
                        badge: l10n.startHere,
                        drillRows: [
                          [
                            l10n.forksAndSkewers,
                            l10n.knightSight,
                            l10n.knightFlight,
                            l10n.pawnAttack,
                          ],
                          [
                            l10n.scanDrillChecks,
                            l10n.scanDrillCaptures,
                            l10n.scanDrillHanging,
                            l10n.scanDrillMate,
                          ],
                        ],
                        icon: Icons.visibility_rounded,
                        color: const Color(0xFF6A1B9A),
                        imagePath: 'assets/images/card_vision.png',
                        onTap: () => context.push('/chess-vision'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      flex: 3,
                      child: Row(
                        children: [
                          Expanded(
                            child: _SecondaryTrainingCard(
                              title: l10n.chessNotation,
                              icon: Icons.grid_on_rounded,
                              color: AppColors.primary,
                              imagePath: 'assets/images/card_notation.png',
                              onTap: () => context.push('/file-rank-trainer'),
                            ),
                          ),
                          // Needs a chess engine — see kEngineAvailable in
                          // stockfish_service.dart.
                          if (kEngineAvailable) ...[
                            const SizedBox(width: 10),
                            Expanded(
                              child: _SecondaryTrainingCard(
                                title: l10n.openingFundamentals,
                                icon: Icons.castle_rounded,
                                color: const Color(0xFFE65100),
                                imagePath: 'assets/images/card_openings.png',
                                onTap: () => context.push('/opening-trainer'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

/// Card titles sit on top of the illustrations, so they carry a white glow
/// instead of a flat backdrop. Shared by both card sizes.
List<Shadow> _titleGlow() => [
      Shadow(color: Colors.white.withValues(alpha: 0.8), blurRadius: 12),
      Shadow(color: Colors.white.withValues(alpha: 0.8), blurRadius: 24),
    ];

/// The one card we want kids to tap first. Full width, badged, and it lists
/// the drills waiting inside (one line per row of [drillRows]) so the depth
/// of the feature is visible up front.
class _HeroTrainingCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String badge;
  final List<List<String>> drillRows;
  final IconData icon;
  final Color color;
  final String? imagePath;
  final VoidCallback onTap;

  const _HeroTrainingCard({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.drillRows,
    required this.icon,
    required this.color,
    required this.onTap,
    this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 8,
      shadowColor: color.withValues(alpha: 0.6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: color.withValues(alpha: 0.9), width: 3),
      ),
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color, color.withValues(alpha: 0.85)],
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (imagePath != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 34),
                  child: Image.asset(
                    imagePath!,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Icon(
                      icon,
                      size: 80,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                )
              else
                Center(
                  child: Icon(
                    icon,
                    size: 80,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 24, 12, 34),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontFamily: 'BradBunR',
                            color: AppColors.primary,
                            fontSize: 60,
                            height: 1.05,
                            shadows: _titleGlow(),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            shadows: _titleGlow(),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_rounded, size: 16, color: color),
                      const SizedBox(width: 4),
                      Text(
                        badge,
                        style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  color: Colors.white.withValues(alpha: 0.88),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final row in drillRows)
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            row.join('  •  '),
                            style: TextStyle(
                              color: color,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Half-width supporting card. The title lays out inside a fixed logical
/// width before being scaled down, so both cards in the row end up with the
/// same wrapping and the same effective font size in every locale.
class _SecondaryTrainingCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final String? imagePath;
  final VoidCallback onTap;

  const _SecondaryTrainingCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
    this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 3,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color, color.withValues(alpha: 0.85)],
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (imagePath != null)
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Image.asset(
                    imagePath!,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Icon(
                      icon,
                      size: 48,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                )
              else
                Center(
                  child: Icon(
                    icon,
                    size: 48,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: SizedBox(
                      width: 200,
                      child: Text(
                        title,
                        style: TextStyle(
                          fontFamily: 'BradBunR',
                          color: AppColors.primary,
                          fontSize: 44,
                          height: 1.05,
                          shadows: _titleGlow(),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
