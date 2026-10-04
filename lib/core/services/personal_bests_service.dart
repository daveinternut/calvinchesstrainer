import 'dart:convert';
import 'dart:developer' as dev;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The device's key-value store, loaded by `main()` before `runApp` and
/// injected with an override.
///
/// Null when it failed to load (and in widget tests): personal bests then
/// last for the session only, which is how the app behaved before they were
/// persisted.
final sharedPreferencesProvider = Provider<SharedPreferences?>((ref) => null);

/// Personal bests for every trainer, saved on the device.
///
/// This provider stays alive for the whole app, so the game providers can be
/// `autoDispose` (a round never outlives its screen) without losing records.
/// Keys are namespaced by trainer, e.g. `fileRank.files_speed_false` or
/// `vision.forksAndSkewers_queen_rook_speed`; the value is a score (higher is
/// better) or a time in seconds (lower is better), per the caller's `submit`.
final personalBestsProvider =
    NotifierProvider<PersonalBestsNotifier, Map<String, int>>(
      PersonalBestsNotifier.new,
    );

class PersonalBestsNotifier extends Notifier<Map<String, int>> {
  static const _storageKey = 'personal_bests_v1';

  SharedPreferences? get _prefs => ref.read(sharedPreferencesProvider);

  @override
  Map<String, int> build() {
    final raw = _prefs?.getString(_storageKey);
    if (raw == null) return const {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return {
        for (final entry in decoded.entries)
          if (entry.value is int) entry.key: entry.value as int,
      };
    } catch (e) {
      dev.log('PersonalBests: ignoring unreadable saved bests: $e');
      return const {};
    }
  }

  /// The saved best for [key], or null if no round has been recorded yet.
  int? best(String key) => state[key];

  /// Saves [score] if it beats the best for [key], and returns whether it did.
  ///
  /// Higher is better unless [lowerIsBetter] (times). A higher-is-better
  /// score of 0 never counts as a record.
  bool submit(String key, int score, {bool lowerIsBetter = false}) {
    final current = state[key];
    final isRecord = lowerIsBetter
        ? (current == null || score < current)
        : (score > 0 && (current == null || score > current));
    if (!isRecord) return false;
    state = {...state, key: score};
    _save();
    return true;
  }

  void _save() {
    final prefs = _prefs;
    if (prefs == null) return;
    prefs.setString(_storageKey, jsonEncode(state)).catchError((Object e) {
      dev.log('PersonalBests: could not save: $e');
      return false;
    });
  }
}
