import 'package:flutter/material.dart';
import 'package:calvinchesstrainer/l10n/app_localizations.dart';

import '../../../core/theme/app_theme.dart';

class FoundProgressIndicator extends StatelessWidget {
  final int totalCorrect;
  final int totalFound;
  final bool showNoneHint;
  final AppLocalizations l10n;

  const FoundProgressIndicator({
    super.key,
    required this.totalCorrect,
    required this.totalFound,
    required this.l10n,
    this.showNoneHint = false,
  });

  @override
  Widget build(BuildContext context) {
    if (totalCorrect == 0 && showNoneHint) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          l10n.tapNoneHint,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (totalCorrect == 0) {
      return const SizedBox(height: 36);
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '${l10n.found}  ',
          style: TextStyle(
            fontSize: 15,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        for (int i = 0; i < totalCorrect; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          _Dot(filled: i < totalFound),
        ],
        const SizedBox(width: 10),
        Text(
          l10n.foundOfTotal(totalFound, totalCorrect),
          style: TextStyle(
            fontSize: 15,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  final bool filled;

  const _Dot({required this.filled});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      width: filled ? 16 : 14,
      height: filled ? 16 : 14,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? AppColors.correctGreen : Colors.transparent,
        border: Border.all(
          color: filled ? AppColors.correctGreen : Colors.grey.shade400,
          width: 2,
        ),
      ),
    );
  }
}
