import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../models/file_rank_game_state.dart';

class PromptDisplay extends StatelessWidget {
  final FileRankGameState gameState;

  const PromptDisplay({super.key, required this.gameState});

  @override
  Widget build(BuildContext context) {
    if (gameState.mode == TrainerMode.explore) {
      return _buildExploreHint(context);
    }

    return _buildForwardPrompt(context);
  }

  Widget _buildExploreHint(BuildContext context) {
    final subjectText = switch (gameState.subject) {
      TrainerSubject.files => 'Tap any file to hear its name',
      TrainerSubject.ranks => 'Tap any rank to hear its name',
      TrainerSubject.squares => 'Tap any square to hear its name',
      TrainerSubject.moves => '',
    };

    return Text(
      subjectText,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildForwardPrompt(BuildContext context) {
    final prompt = gameState.currentPrompt;
    if (prompt == null) return const SizedBox.shrink();

    final typeLabel = gameState.subject == TrainerSubject.squares
        ? 'square'
        : (gameState.currentPromptIsFile ? 'file' : 'rank');
    final displayValue = prompt;

    return Column(
      children: [
        Text(
          'Tap $typeLabel',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          displayValue,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
        ),
      ],
    );
  }

}
