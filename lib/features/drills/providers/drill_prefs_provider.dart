import 'dart:convert';
import 'dart:developer' as dev;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/personal_bests_service.dart'
    show sharedPreferencesProvider;
import '../drill_catalog.dart';
import '../models/drill.dart';

/// The player's remembered setup for each drill, and the last drill they
/// started (home's Continue card).
class DrillPrefs {
  const DrillPrefs({this.configs = const {}, this.lastPlayed});

  final Map<DrillId, DrillConfig> configs;
  final DrillConfig? lastPlayed;

  /// The setup [drill] opens with: the last one used, else its default.
  DrillConfig configFor(DrillId drill) =>
      drill.normalize(configs[drill] ?? drill.defaultConfig);

  /// Whether [drill] has ever been started (tiles show "New" until then).
  bool hasPlayed(DrillId drill) => configs.containsKey(drill);
}

/// App-lifetime and saved on the device, like personal bests.
final drillPrefsProvider = NotifierProvider<DrillPrefsNotifier, DrillPrefs>(
  DrillPrefsNotifier.new,
);

class DrillPrefsNotifier extends Notifier<DrillPrefs> {
  static const _storageKey = 'drill_prefs_v1';

  @override
  DrillPrefs build() {
    final raw = ref.read(sharedPreferencesProvider)?.getString(_storageKey);
    if (raw == null) return const DrillPrefs();
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final configs = <DrillId, DrillConfig>{};
      for (final value in (json['configs'] as List? ?? const [])) {
        final config = DrillConfig.fromJson(value);
        if (config != null) configs[config.drill] = config;
      }
      return DrillPrefs(
        configs: configs,
        lastPlayed: DrillConfig.fromJson(json['lastPlayed']),
      );
    } catch (e) {
      dev.log('DrillPrefs: ignoring unreadable saved settings: $e');
      return const DrillPrefs();
    }
  }

  /// Remembers [config] as its drill's setup and as the drill to continue.
  void recordStart(DrillConfig config) {
    final c = config.drill.normalize(config);
    state = DrillPrefs(
      configs: {...state.configs, c.drill: c},
      lastPlayed: c,
    );
    _save();
  }

  void _save() {
    final prefs = ref.read(sharedPreferencesProvider);
    if (prefs == null) return;
    final json = jsonEncode({
      'configs': [for (final c in state.configs.values) c.toJson()],
      if (state.lastPlayed != null) 'lastPlayed': state.lastPlayed!.toJson(),
    });
    prefs.setString(_storageKey, json).catchError((Object e) {
      dev.log('DrillPrefs: could not save: $e');
      return false;
    });
  }
}
