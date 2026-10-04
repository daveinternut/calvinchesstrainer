import 'package:chessground/chessground.dart';
import 'package:flutter/material.dart';
import 'package:calvinchesstrainer/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../models/letter_game_state.dart';

/// The six answer tiles for practice/speed: piece images when the prompt is
/// a letter, letter tiles (K Q R B N –) when the prompt is a piece.
class LetterAnswerGrid extends StatelessWidget {
  final LetterGameState gameState;
  final ValueChanged<LetterPiece> onTap;

  const LetterAnswerGrid({
    super.key,
    required this.gameState,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final question = gameState.currentQuestion;
    if (question == null) return const SizedBox.shrink();

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.1,
        children: [
          for (final option in question.options)
            _AnswerTile(
              key: ValueKey('answer_${option.name}'),
              option: option,
              question: question,
              feedback: gameState.lastFeedback,
              isHardMode: gameState.isHardMode,
              onTap: () => onTap(option),
            ),
        ],
      ),
    );
  }
}

class _AnswerTile extends StatelessWidget {
  final LetterPiece option;
  final LetterQuestion question;
  final LetterFeedback? feedback;
  final bool isHardMode;
  final VoidCallback onTap;

  const _AnswerTile({
    super.key,
    required this.option,
    required this.question,
    required this.feedback,
    required this.isHardMode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fb = feedback;
    final isCorrectTile = fb != null && option == fb.correct;
    final isWrongTapped = fb != null &&
        fb.result == AnswerResult.incorrect &&
        option == fb.tapped;

    final Color background;
    final Color borderColor;
    if (isCorrectTile) {
      background = AppColors.correctGreen.withValues(alpha: 0.9);
      borderColor = AppColors.correctGreen;
    } else if (isWrongTapped) {
      background = AppColors.incorrectRed.withValues(alpha: 0.9);
      borderColor = AppColors.incorrectRed;
    } else {
      background = AppColors.surface;
      borderColor = AppColors.line;
    }
    final highlighted = isCorrectTile || isWrongTapped;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: highlighted ? 2 : 1),
          boxShadow: [
            BoxShadow(
              color: const Color(0x0F0E1B16),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: question.direction == LetterQuestionDirection.letterToPiece
              ? _buildPieceFace()
              : _buildLetterFace(context, highlighted),
        ),
      ),
    );
  }

  Widget _buildPieceFace() {
    final asset = PieceSet.cburnett.assets[option.pieceKind(black: isHardMode)];
    return SizedBox(
      width: 60,
      height: 60,
      child: asset != null ? Image(image: asset) : const SizedBox(),
    );
  }

  Widget _buildLetterFace(BuildContext context, bool highlighted) {
    final l10n = AppLocalizations.of(context)!;
    final textColor = highlighted ? Colors.white : AppColors.textPrimary;

    if (option.hasLetter) {
      return Text(
        option.letter,
        style: AppText.mono.copyWith(fontSize: 34, color: textColor),
      );
    }

    // The pawn's tile: a dash with a small caption, the "no letter" answer.
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '–',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              l10n.noLetter,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: highlighted
                    ? Colors.white.withValues(alpha: 0.9)
                    : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
