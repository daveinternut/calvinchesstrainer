import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                    tooltip: 'About',
                  ),
                ],
              ),
            ),
            // App icon + title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Container(
                    width: 200,
                    height: 200,
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
                  const SizedBox(height: 16),
                  Text(
                    'Calvin Chess\nTrainer',
                    style: const TextStyle(
                      fontFamily: 'BradBunR',
                      fontSize: 72,
                      color: AppColors.primary,
                      height: 1.1,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Master the fundamentals!',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Training cards
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    Expanded(
                      flex: 3,
                      child: _BigTrainingCard(
                        title: 'Chess Notation',
                        subtitle: 'Learn the board!',
                        icon: Icons.grid_on_rounded,
                        secondaryIcon: Icons.abc_rounded,
                        color: AppColors.primary,
                        imagePath: 'assets/images/card_notation.png',
                        onTap: () => context.push('/file-rank-trainer'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      flex: 2,
                      child: _BigTrainingCard(
                        title: 'Opening Fundamentals',
                        subtitle: 'Coming soon!',
                        icon: Icons.castle_rounded,
                        secondaryIcon: Icons.auto_awesome_rounded,
                        color: const Color(0xFFE65100),
                        imagePath: 'assets/images/card_openings.png',
                        comingSoon: true,
                        onTap: null,
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

class _BigTrainingCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final IconData secondaryIcon;
  final Color color;
  final String? imagePath;
  final bool comingSoon;
  final VoidCallback? onTap;

  const _BigTrainingCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.secondaryIcon,
    required this.color,
    this.imagePath,
    this.comingSoon = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: comingSoon ? 1 : 4,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: comingSoon
                  ? [
                      color.withValues(alpha: 0.5),
                      color.withValues(alpha: 0.35),
                    ]
                  : [
                      color,
                      color.withValues(alpha: 0.85),
                    ],
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Image fills the card
              if (imagePath != null)
                Padding(
                  padding: const EdgeInsets.all(16),
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
              // Text overlay centered
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'BradBunR',
                        color: AppColors.primary,
                        fontSize: 56,
                        shadows: [
                          Shadow(
                            color: Colors.white.withValues(alpha: 0.8),
                            blurRadius: 12,
                          ),
                          Shadow(
                            color: Colors.white.withValues(alpha: 0.8),
                            blurRadius: 24,
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (comingSoon) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'COMING SOON',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
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
    );
  }
}
