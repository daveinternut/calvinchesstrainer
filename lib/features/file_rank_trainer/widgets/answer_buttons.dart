import 'package:flutter/material.dart';
import '../../../core/constants.dart';
import '../../../core/theme/app_theme.dart';
import '../models/file_rank_game_state.dart';

class AnswerButtons extends StatelessWidget {
  final bool isFile;
  final AnswerFeedback? feedback;
  final ValueChanged<int> onTap;

  const AnswerButtons({
    super.key,
    required this.isFile,
    required this.feedback,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final labels =
        isFile ? ChessConstants.files : ChessConstants.ranks;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          for (int i = 0; i < labels.length; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(
              child: _AnswerButton(
                label: isFile ? labels[i].toUpperCase() : labels[i],
                color: _buttonColor(i),
                onTap: () => onTap(i),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _buttonColor(int index) {
    if (feedback == null) return AppColors.primary;

    if (feedback!.result == AnswerResult.correct &&
        index == feedback!.correctIndex) {
      return AppColors.correctGreen;
    }
    if (feedback!.result == AnswerResult.incorrect) {
      if (index == feedback!.tappedIndex) return AppColors.incorrectRed;
      if (index == feedback!.correctIndex) return AppColors.correctGreen;
    }
    return AppColors.primary;
  }
}

class _AnswerButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AnswerButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 2,
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
