import 'dart:developer' as dev;

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Set by `main()` once `Firebase.initializeApp` has actually completed.
bool _firebaseReady = false;

/// Whether it is safe to touch `FirebaseAnalytics.instance`.
///
/// False until Firebase finishes initializing in the background — and forever
/// on web behind an ad blocker, privacy extension or filtering DNS, because the
/// SDK is a runtime import from gstatic. Reading `.instance` in that state
/// throws `TypeError: Cannot read properties of undefined (reading
/// 'initializeAnalytics')`, so callers must **check this instead of catching**.
bool get analyticsAvailable => _firebaseReady;

/// Called by `main()` only, after a successful `Firebase.initializeApp`.
void markFirebaseReady() => _firebaseReady = true;

/// Analytics is strictly best-effort: the app must work without it.
///
/// `main()` starts Firebase in the background rather than awaiting it before
/// `runApp`, so the service resolves `FirebaseAnalytics.instance` lazily, on
/// the first event after Firebase came up. Until then — and forever on web
/// behind an ad blocker, privacy extension or filtering DNS, where the SDK
/// import from gstatic never resolves — every event is dropped.
final analyticsServiceProvider = Provider<AnalyticsService>(
  (ref) => AnalyticsService(),
);

class AnalyticsService {
  FirebaseAnalytics? _analytics;

  /// The Firebase instance once it is safe to touch, else null. Never reads
  /// `FirebaseAnalytics.instance` before `markFirebaseReady()`: on web that
  /// throws when Firebase never initialized.
  FirebaseAnalytics? get _instance {
    if (_analytics != null) return _analytics;
    if (!analyticsAvailable) return null;
    try {
      return _analytics = FirebaseAnalytics.instance;
    } catch (e) {
      dev.log('Analytics unavailable; events will be dropped: $e');
      return null;
    }
  }

  /// Whether events are actually reaching Firebase.
  bool get isEnabled => _instance != null;

  /// The single choke point for every typed event below. Swallows failures,
  /// including the asynchronous ones `logEvent` reports through its Future:
  /// a dropped analytics event must never interrupt a drill.
  void _logEvent({required String name, Map<String, Object>? parameters}) {
    final analytics = _instance;
    if (analytics == null) return;
    try {
      analytics
          .logEvent(name: name, parameters: parameters)
          .catchError((Object e) {
        dev.log('Analytics: event "$name" dropped: $e');
      });
    } catch (e) {
      dev.log('Analytics: event "$name" dropped: $e');
    }
  }

  /// One screen view per named route (see [ScreenViewObserver]).
  void logScreenView(String screenName) {
    final analytics = _instance;
    if (analytics == null) return;
    try {
      analytics.logScreenView(screenName: screenName).catchError((Object e) {
        dev.log('Analytics: screen view "$screenName" dropped: $e');
      });
    } catch (e) {
      dev.log('Analytics: screen view "$screenName" dropped: $e');
    }
  }

  // --- File/Rank Trainer ---

  void logFileRankDrillStarted({
    required String subject,
    required String mode,
    required bool hardMode,
  }) {
    _logEvent(
      name: 'file_rank_drill_started',
      parameters: {
        'subject': subject,
        'mode': mode,
        'hard_mode': hardMode.toString(),
      },
    );
  }

  void logFileRankDrillCompleted({
    required String subject,
    required String mode,
    required bool hardMode,
    required int totalCorrect,
    required int totalAttempts,
    required int bestStreak,
    required bool isNewRecord,
  }) {
    _logEvent(
      name: 'file_rank_drill_completed',
      parameters: {
        'subject': subject,
        'mode': mode,
        'hard_mode': hardMode.toString(),
        'total_correct': totalCorrect,
        'total_attempts': totalAttempts,
        'best_streak': bestStreak,
        'accuracy': totalAttempts > 0
            ? ((totalCorrect / totalAttempts) * 100).round()
            : 0,
        'is_new_record': isNewRecord.toString(),
      },
    );
  }

  // --- Move Trainer ---

  void logMoveDrillStarted({
    required String mode,
    required bool hardMode,
  }) {
    _logEvent(
      name: 'move_drill_started',
      parameters: {
        'mode': mode,
        'hard_mode': hardMode.toString(),
      },
    );
  }

  void logMoveDrillCompleted({
    required String mode,
    required bool hardMode,
    required int totalCorrect,
    required int totalAttempts,
    required int bestStreak,
    required bool isNewRecord,
  }) {
    _logEvent(
      name: 'move_drill_completed',
      parameters: {
        'mode': mode,
        'hard_mode': hardMode.toString(),
        'total_correct': totalCorrect,
        'total_attempts': totalAttempts,
        'best_streak': bestStreak,
        'accuracy': totalAttempts > 0
            ? ((totalCorrect / totalAttempts) * 100).round()
            : 0,
        'is_new_record': isNewRecord.toString(),
      },
    );
  }

  // --- Letter Trainer (piece letters) ---

  void logLetterDrillStarted({
    required String mode,
    required bool hardMode,
  }) {
    _logEvent(
      name: 'letter_drill_started',
      parameters: {
        'mode': mode,
        'hard_mode': hardMode.toString(),
      },
    );
  }

  void logLetterDrillCompleted({
    required String mode,
    required bool hardMode,
    required int totalCorrect,
    required int totalAttempts,
    required int bestStreak,
    required bool isNewRecord,
  }) {
    _logEvent(
      name: 'letter_drill_completed',
      parameters: {
        'mode': mode,
        'hard_mode': hardMode.toString(),
        'total_correct': totalCorrect,
        'total_attempts': totalAttempts,
        'best_streak': bestStreak,
        'accuracy': totalAttempts > 0
            ? ((totalCorrect / totalAttempts) * 100).round()
            : 0,
        'is_new_record': isNewRecord.toString(),
      },
    );
  }

  // --- Chess Vision ---

  // `piece`/`target` are null for the scanning drills (findChecks,
  // findCaptures, hangingPieces, mateInOne), which have no piece selection.
  void logVisionDrillStarted({
    required String drill,
    required String mode,
    String? piece,
    String? target,
  }) {
    _logEvent(
      name: 'vision_drill_started',
      parameters: {
        'drill': drill,
        'mode': mode,
        if (piece != null) 'piece': piece,
        if (target != null) 'target': target,
      },
    );
  }

  // --- Opening Trainer ---

  void logOpeningDrillStarted({
    required String mode,
    required String difficulty,
    required String playerColor,
  }) {
    _logEvent(
      name: 'opening_drill_started',
      parameters: {
        'mode': mode,
        'difficulty': difficulty,
        'player_color': playerColor,
      },
    );
  }

  void logOpeningDrillCompleted({
    required String mode,
    required String difficulty,
    required String playerColor,
    required int userMoves,
    required String medal,
    required int livesUsed,
  }) {
    _logEvent(
      name: 'opening_drill_completed',
      parameters: {
        'mode': mode,
        'difficulty': difficulty,
        'player_color': playerColor,
        'user_moves': userMoves,
        'medal': medal,
        'lives_used': livesUsed,
      },
    );
  }

  // --- Pieces (Which Side Wins) ---

  void logPiecesDrillStarted({
    required String mode,
  }) {
    _logEvent(
      name: 'pieces_drill_started',
      parameters: {
        'mode': mode,
      },
    );
  }

  void logPiecesDrillCompleted({
    required String mode,
    required int totalCorrect,
    required int totalAttempts,
    required int bestStreak,
    required bool isNewRecord,
  }) {
    _logEvent(
      name: 'pieces_drill_completed',
      parameters: {
        'mode': mode,
        'total_correct': totalCorrect,
        'total_attempts': totalAttempts,
        'best_streak': bestStreak,
        'accuracy': totalAttempts > 0
            ? ((totalCorrect / totalAttempts) * 100).round()
            : 0,
        'is_new_record': isNewRecord.toString(),
      },
    );
  }

  void logVisionDrillCompleted({
    required String drill,
    required String mode,
    String? piece,
    String? target,
    required int configurationsCompleted,
    required int totalErrors,
    required int bestStreak,
    required bool isNewRecord,
    int? elapsedSeconds,
  }) {
    _logEvent(
      name: 'vision_drill_completed',
      parameters: {
        'drill': drill,
        'mode': mode,
        if (piece != null) 'piece': piece,
        if (target != null) 'target': target,
        'configs_completed': configurationsCompleted,
        'total_errors': totalErrors,
        'best_streak': bestStreak,
        'is_new_record': isNewRecord.toString(),
        if (elapsedSeconds != null) 'elapsed_seconds': elapsedSeconds,
      },
    );
  }
}

/// Logs a screen view for every page route by its GoRouter route `name`,
/// like `FirebaseAnalyticsObserver` — but safe to construct before Firebase
/// is up, because [AnalyticsService] drops events until it is.
class ScreenViewObserver extends RouteObserver<ModalRoute<dynamic>> {
  ScreenViewObserver(this._analytics);

  final AnalyticsService _analytics;

  void _send(Route<dynamic> route) {
    if (route is! PageRoute) return;
    _analytics.logScreenView(route.settings.name ?? 'unknown');
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _send(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) _send(newRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute != null && route is PageRoute) _send(previousRoute);
  }
}
