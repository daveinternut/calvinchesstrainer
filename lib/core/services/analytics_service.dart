import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService(FirebaseAnalytics.instance);
});

class AnalyticsService {
  final FirebaseAnalytics _analytics;

  AnalyticsService(this._analytics);

  FirebaseAnalytics get instance => _analytics;

  // --- File/Rank Trainer ---

  void logFileRankDrillStarted({
    required String subject,
    required String mode,
    required bool hardMode,
  }) {
    _analytics.logEvent(
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
    _analytics.logEvent(
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
    _analytics.logEvent(
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
    _analytics.logEvent(
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

  // --- Chess Vision ---

  void logVisionDrillStarted({
    required String drill,
    required String mode,
    required String piece,
    String? target,
  }) {
    _analytics.logEvent(
      name: 'vision_drill_started',
      parameters: {
        'drill': drill,
        'mode': mode,
        'piece': piece,
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
    _analytics.logEvent(
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
    _analytics.logEvent(
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
    _analytics.logEvent(
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
    _analytics.logEvent(
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
    required String piece,
    String? target,
    required int configurationsCompleted,
    required int totalErrors,
    required int bestStreak,
    required bool isNewRecord,
    int? elapsedSeconds,
  }) {
    _analytics.logEvent(
      name: 'vision_drill_completed',
      parameters: {
        'drill': drill,
        'mode': mode,
        'piece': piece,
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
