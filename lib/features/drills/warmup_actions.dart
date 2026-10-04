import 'package:calvinchesstrainer/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'drill_catalog.dart';
import 'providers/warmup_provider.dart';

/// What a finished round's two buttons do.
typedef RoundActions = ({
  String primaryLabel,
  VoidCallback onPrimary,
  String secondaryLabel,
  VoidCallback onSecondary,
});

/// The results buttons for a game screen: Play Again / Done, or — when the
/// round is a step of the daily warm-up — Next (or Finish) / End warm-up.
///
/// Warm-up steps replace each other on the navigation stack, so Back from
/// any step returns to wherever the warm-up was started.
RoundActions roundActions(
  BuildContext context,
  WidgetRef ref, {
  required bool warmup,
  required int score,
  required VoidCallback onPlayAgain,
}) {
  final l10n = AppLocalizations.of(context)!;
  final state = ref.read(warmupProvider);
  if (warmup && state.isActive) {
    final next = state.next;
    return (
      primaryLabel: next == null
          ? l10n.warmupFinish
          : l10n.warmupNext(next.drill.title(l10n)),
      onPrimary: () {
        final step = ref.read(warmupProvider.notifier).completeStep(score);
        context.pushReplacement(
          step == null
              ? '/warm-up/done'
              : step.drill.location(step, warmup: true),
        );
      },
      secondaryLabel: l10n.warmupEnd,
      onSecondary: () {
        ref.read(warmupProvider.notifier).end();
        closeDrill(context);
      },
    );
  }
  return (
    primaryLabel: l10n.playAgain,
    onPrimary: onPlayAgain,
    secondaryLabel: l10n.done,
    onSecondary: () => closeDrill(context),
  );
}

/// "Warm-up · 2 of 5" for a game screen's top bar, or null outside one.
String? warmupSubtitle(WidgetRef ref, AppLocalizations l10n, bool warmup) {
  if (!warmup) return null;
  final state = ref.watch(warmupProvider);
  if (!state.isActive) return null;
  return l10n.warmupStep(state.index + 1, state.steps.length);
}

/// Leaves a game screen (its close button), even when it was opened as the
/// first page (a deep link on web).
void closeDrill(BuildContext context) =>
    context.canPop() ? context.pop() : context.go('/');
