import 'package:calvinchesstrainer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/ui/buttons.dart';
import '../../../core/ui/drill_glyph.dart';
import '../drill_catalog.dart';
import '../providers/warmup_provider.dart';

/// The end of the daily warm-up: each step with its score.
class WarmupDoneScreen extends ConsumerWidget {
  const WarmupDoneScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(warmupProvider);

    void done() {
      ref.read(warmupProvider.notifier).end();
      context.go('/');
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        color: AppColors.brandSoft,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 34,
                        color: AppColors.brand,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    l10n.warmupDoneTitle,
                    textAlign: TextAlign.center,
                    style: AppText.display,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.warmupDoneBody,
                    textAlign: TextAlign.center,
                    style: AppText.body.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  for (var i = 0; i < state.steps.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.line),
                        ),
                        child: Row(
                          children: [
                            DrillGlyph(
                              spec: state.steps[i].drill.glyph,
                              size: 44,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                state.steps[i].drill.title(l10n),
                                style: AppText.cardTitle,
                              ),
                            ),
                            Text(
                              i < state.scores.length
                                  ? '${state.scores[i]}'
                                  : '–',
                              style: AppText.number.copyWith(fontSize: 22),
                            ),
                            const SizedBox(width: 6),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  AppPrimaryButton(
                    label: l10n.done,
                    onPressed: done,
                    expand: true,
                    height: 56,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
