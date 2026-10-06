import 'dart:developer' as dev;

import 'package:calvinchesstrainer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/personal_bests_service.dart' show sharedPreferencesProvider;
import '../ui/buttons.dart';

/// The in-app Sound switch: whether Calvin plays its voice, answer blips and
/// cheers. On by default and saved on the device.
///
/// App-lifetime, like personal bests. `audioServiceProvider` listens to it,
/// so turning sound off also cuts off whatever is playing. Haptics ignore it:
/// they aren't sound, and the system's haptics setting governs them.
final soundOnProvider = NotifierProvider<SoundOnNotifier, bool>(
  SoundOnNotifier.new,
);

class SoundOnNotifier extends Notifier<bool> {
  static const _storageKey = 'sound_on_v1';

  @override
  bool build() {
    final saved = ref.read(sharedPreferencesProvider)?.get(_storageKey);
    return saved is bool ? saved : true;
  }

  /// Flips the switch and saves it.
  void toggle() {
    state = !state;
    final prefs = ref.read(sharedPreferencesProvider);
    if (prefs == null) return;
    prefs.setBool(_storageKey, state).catchError((Object e) {
      dev.log('SoundOn: could not save: $e');
      return false;
    });
  }
}

/// The speaker button that flips [soundOnProvider]: in home's header and at
/// the end of every drill's `PlayTopBar` (as its `action`).
class SoundButton extends ConsumerWidget {
  const SoundButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final on = ref.watch(soundOnProvider);
    return CircleIconButton(
      icon: on ? Icons.volume_up_rounded : Icons.volume_off_rounded,
      tooltip: on ? l10n.turnSoundOff : l10n.turnSoundOn,
      onPressed: ref.read(soundOnProvider.notifier).toggle,
    );
  }
}
