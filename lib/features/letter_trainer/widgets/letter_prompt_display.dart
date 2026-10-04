import 'package:chessground/chessground.dart';
import 'package:flutter/material.dart';
import 'package:calvinchesstrainer/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../models/letter_game_state.dart';
import 'letter_strings.dart';

/// The prompt area above the answer tiles. Fixed-height slots (label line +
/// value zone) so the layout never jumps between question and feedback.
class LetterPromptDisplay extends StatelessWidget {
  final LetterGameState gameState;

  const LetterPromptDisplay({super.key, required this.gameState});

  @override
  Widget build(BuildContext context) {
    if (gameState.mode == LetterTrainerMode.explore) {
      return _buildExploreHint(context);
    }
    return _buildQuestionPrompt(context);
  }

  Widget _buildExploreHint(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tapped = gameState.lastFeedback?.tapped;

    return SizedBox(
      height: 72,
      child: Center(
        child: tapped == null
            ? Text(
                l10n.tapPieceToLearnLetter,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                textAlign: TextAlign.center,
              )
            : Text(
                mnemonicFor(l10n, tapped),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                textAlign: TextAlign.center,
                maxLines: 3,
              ),
      ),
    );
  }

  Widget _buildQuestionPrompt(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final question = gameState.currentQuestion;
    if (question == null) return const SizedBox(height: 128);

    final feedback = gameState.lastFeedback;

    final String label;
    final Color labelColor;
    if (feedback != null) {
      label = revealLineFor(l10n, feedback.correct);
      labelColor = feedback.result == AnswerResult.correct
          ? AppColors.correctGreen
          : AppColors.textPrimary;
    } else {
      label = switch (question.direction) {
        LetterQuestionDirection.letterToPiece => question.isNoLetterPrompt
            ? l10n.tapPieceNoLetter
            : l10n.whichPieceForLetter,
        LetterQuestionDirection.pieceToLetter => l10n.whichLetterForPiece,
      };
      labelColor = AppColors.textSecondary;
    }

    return Column(
      children: [
        SizedBox(
          height: 44,
          child: Center(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: labelColor,
                    fontWeight:
                        feedback != null ? FontWeight.w700 : FontWeight.w400,
                  ),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ),
        ),
        SizedBox(
          height: 84,
          child: Center(child: _buildPromptValue(context, question)),
        ),
      ],
    );
  }

  Widget _buildPromptValue(BuildContext context, LetterQuestion question) {
    if (question.direction == LetterQuestionDirection.pieceToLetter) {
      final asset = PieceSet.cburnett
          .assets[question.target.pieceKind(black: gameState.isHardMode)];
      return SizedBox(
        width: 76,
        height: 76,
        child: asset != null ? Image(image: asset) : const SizedBox(),
      );
    }

    // Letter prompt: the big SAN letter, or a dash for the pawn trick.
    return Text(
      question.target.hasLetter ? question.target.letter : '–',
      style: AppText.mono.copyWith(fontSize: 72, height: 1.1),
    );
  }
}
