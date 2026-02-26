import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset(
                  'assets/images/internut_logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.castle_rounded,
                    size: 64,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Calvin Chess Trainer',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Version 1.0.0',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'by Internut Education',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            const SizedBox(height: 32),
            _buildSection(
              context,
              icon: Icons.school_rounded,
              title: 'What is Calvin Chess Trainer?',
              body: 'A fun, interactive app that teaches chess fundamentals '
                  'to kids. Learn files, ranks, squares, and piece moves '
                  'through drills, quizzes, and timed challenges — all with '
                  'audio feedback and streak tracking to keep you motivated!',
            ),
            const SizedBox(height: 16),
            _buildSection(
              context,
              icon: Icons.sports_esports_rounded,
              title: 'Training Modes',
              body: '• Explore — learn at your own pace\n'
                  '• Practice — quiz yourself and build streaks\n'
                  '• Speed Round — 30 seconds, how many can you get?\n'
                  '• Hard Mode — hide coordinates for a real challenge',
            ),
            const SizedBox(height: 16),
            _buildSection(
              context,
              icon: Icons.favorite_rounded,
              title: 'Credits & Acknowledgments',
              body: '• Chess puzzles from the Lichess database (CC0 license)\n'
                  '• Board UI powered by Lichess chessground\n'
                  '• Chess logic by Lichess dartchess\n'
                  '• Voice clips by ElevenLabs\n'
                  '• Built with Flutter & Dart',
            ),
            const SizedBox(height: 16),
            _buildSection(
              context,
              icon: Icons.info_outline_rounded,
              title: 'About Internut Education',
              body: 'Internut Education creates engaging learning apps '
                  'for kids. We believe the best way to learn is through '
                  'play, practice, and positive reinforcement.',
            ),
            const SizedBox(height: 32),
            Text(
              'Made with ❤️ for young chess players everywhere',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String body,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }
}
