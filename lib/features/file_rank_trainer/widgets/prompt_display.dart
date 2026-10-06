import 'package:flutter/material.dart';
import 'package:calvinchesstrainer/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/audio/sound_switch.dart';
import '../../../core/theme/app_theme.dart';
import '../models/file_rank_game_state.dart';

class PromptDisplay extends ConsumerWidget {
  final FileRankGameState gameState;

  const PromptDisplay({super.key, required this.gameState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (gameState.mode == TrainerMode.explore) {
      return _buildExploreHint(context, soundOn: ref.watch(soundOnProvider));
    }

    return _buildForwardPrompt(context);
  }

  /// Explore names the tapped line or square aloud and on the board; with
  /// the sound off, only on the board.
  Widget _buildExploreHint(BuildContext context, {required bool soundOn}) {
    final l10n = AppLocalizations.of(context)!;
    final subjectText = switch (gameState.subject) {
      TrainerSubject.files => soundOn ? l10n.tapFileToHear : l10n.tapFileToSee,
      TrainerSubject.ranks => soundOn ? l10n.tapRankToHear : l10n.tapRankToSee,
      TrainerSubject.squares =>
        soundOn ? l10n.tapSquareToHear : l10n.tapSquareToSee,
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
