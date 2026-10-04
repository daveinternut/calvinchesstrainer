import 'package:flutter/material.dart';
import 'package:calvinchesstrainer/l10n/app_localizations.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/ui/components.dart';

/// "Found 2 / 3" with one chip per answer: the ones found so far in
/// notation ([foundLabels]: "Rf6+", "d5"), then dashed slots still to find.
class FoundProgressIndicator extends StatelessWidget {
  final int totalCorrect;
  final int totalFound;
  final bool showNoneHint;
  final List<String> foundLabels;
  final AppLocalizations l10n;

  const FoundProgressIndicator({
    super.key,
    required this.totalCorrect,
    required this.totalFound,
    required this.l10n,
    this.showNoneHint = false,
    this.foundLabels = const [],
  });

  @override
  Widget build(BuildContext context) {
    if (totalCorrect == 0 && showNoneHint) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.well,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          l10n.tapNoneHint,
          style: AppText.body.copyWith(fontSize: 14),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (totalCorrect == 0) {
      return const SizedBox(height: 36);
    }

    final found = totalFound.clamp(0, totalCorrect);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.found, style: AppText.body.copyWith(fontSize: 14)),
            const SizedBox(width: 8),
            Text(
              '$found / $totalCorrect',
              style: AppText.number.copyWith(fontSize: 16),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < totalCorrect; i++)
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 64),
                child: i < found
                    ? NotationChip.found(
                        i < foundLabels.length ? foundLabels[i] : '✓',
                        height: 44,
                      )
                    : const NotationChip.empty(height: 44),
              ),
          ],
        ),
      ],
    );
  }
}
