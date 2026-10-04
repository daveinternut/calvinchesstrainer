import 'package:flutter/material.dart';
import 'package:calvinchesstrainer/l10n/app_localizations.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/ui/buttons.dart';
import '../../../core/ui/components.dart';

/// A finished round, over the dimmed page: the score big, a "New Record!"
/// badge, a few stats, what was missed, and what to do next.
///
/// Capped in width so it stays a card on an iPad, and scrollable so a short
/// landscape window can't overflow it.
class ResultsSheet extends StatelessWidget {
  const ResultsSheet({
    super.key,
    required this.heading,
    required this.score,
    required this.primaryLabel,
    required this.onPrimary,
    required this.secondaryLabel,
    required this.onSecondary,
    this.scoreCaption,
    this.isNewRecord = false,
    this.stats = const [],
    this.missed = const [],
  });

  final String heading;
  final String score;
  final String? scoreCaption;
  final bool isNewRecord;

  /// Label/value pairs shown as tiles under the score.
  final List<(String, String)> stats;

  /// Prompts the player got wrong ("b6", "Nf3"), as chips.
  final List<String> missed;

  final String primaryLabel;
  final VoidCallback onPrimary;
  final String secondaryLabel;
  final VoidCallback onSecondary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ColoredBox(
      color: const Color(0x730E1B16),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Material(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(28),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      heading,
                      textAlign: TextAlign.center,
                      style: AppText.label.copyWith(fontSize: 15),
                    ),
                    Text(
                      score,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: AppFonts.ui,
                        fontSize: 96,
                        height: 1.0,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -4,
                        color: AppColors.ink,
                      ),
                    ),
                    if (scoreCaption != null)
                      Text(
                        scoreCaption!,
                        textAlign: TextAlign.center,
                        style: AppText.body.copyWith(fontSize: 16),
                      ),
                    if (isNewRecord) ...[
                      const SizedBox(height: 12),
                      Center(child: _NewRecordBadge(label: l10n.newRecord)),
                    ],
                    if (stats.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          for (var i = 0; i < stats.length; i++) ...[
                            if (i > 0) const SizedBox(width: 10),
                            Expanded(
                              child: StatTile(
                                label: stats[i].$1,
                                value: stats[i].$2,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                    if (missed.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      FieldLabel(l10n.resultsMissed),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final m in missed)
                            NotationChip.missed(m, height: 40),
                        ],
                      ),
                    ],
                    const SizedBox(height: 22),
                    AppPrimaryButton(
                      label: primaryLabel,
                      onPressed: onPrimary,
                      expand: true,
                      height: 56,
                    ),
                    const SizedBox(height: 10),
                    AppSecondaryButton(
                      label: secondaryLabel,
                      onPressed: onSecondary,
                      expand: true,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NewRecordBadge extends StatelessWidget {
  const _NewRecordBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.amberSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 18, color: AppColors.amber),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontFamily: AppFonts.ui,
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: AppColors.amberInk,
            ),
          ),
        ],
      ),
    );
  }
}

/// The results of a countdown round (Speed Round, Blitz): correct answers,
/// accuracy and best streak. The action labels default to Play Again /
/// Done; the warm-up swaps in Next / End warm-up.
class ResultsCard extends StatelessWidget {
  final int totalCorrect;
  final int totalAttempts;
  final int bestStreak;
  final bool isNewRecord;
  final VoidCallback onPlayAgain;
  final VoidCallback onBack;
  final List<String> missed;
  final String? primaryLabel;
  final String? secondaryLabel;

  const ResultsCard({
    super.key,
    required this.totalCorrect,
    required this.totalAttempts,
    required this.bestStreak,
    required this.isNewRecord,
    required this.onPlayAgain,
    required this.onBack,
    this.missed = const [],
    this.primaryLabel,
    this.secondaryLabel,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ResultsSheet(
      heading: l10n.timesUp,
      score: '$totalCorrect',
      scoreCaption: l10n.correct,
      isNewRecord: isNewRecord,
      stats: [
        (
          l10n.accuracy,
          totalAttempts > 0
              ? '${(totalCorrect / totalAttempts * 100).round()}%'
              : '-',
        ),
        (l10n.bestStreak, '$bestStreak'),
      ],
      missed: missed,
      primaryLabel: primaryLabel ?? l10n.playAgain,
      onPrimary: onPlayAgain,
      secondaryLabel: secondaryLabel ?? l10n.done,
      onSecondary: onBack,
    );
  }
}
