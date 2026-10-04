import 'package:flutter/material.dart';
import 'package:calvinchesstrainer/l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context)!;
    final subjectText = switch (gameState.subject) {
      TrainerSubject.files => l10n.tapFileToHear,
      TrainerSubject.ranks => l10n.tapRankToHear,
      TrainerSubject.squares => l10n.tapSquareToHear,
      TrainerSubject.moves => '',
      TrainerSubject.letters => '',
      TrainerSubject.pieceValue => '',
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        subjectText,
        style: AppText.title.copyWith(fontSize: 20),
        textAlign: TextAlign.center,
      ),
    );
  }

  /// "Tap square" over the prompt itself, huge and in mono: the one thing
  /// the player has to read.
  Widget _buildForwardPrompt(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final prompt = gameState.currentPrompt;
    if (prompt == null) return const SizedBox(height: 108);

    final typeLabel = gameState.subject == TrainerSubject.squares
        ? l10n.tapSquare
        : (gameState.currentPromptIsFile ? l10n.tapFile : l10n.tapRank);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(typeLabel, style: AppText.label.copyWith(fontSize: 15)),
        Text(
          prompt,
          style: AppText.mono.copyWith(
            fontSize: 84,
            height: 1.05,
            letterSpacing: -3,
          ),
        ),
      ],
    );
  }
}
