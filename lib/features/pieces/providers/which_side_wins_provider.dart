import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/audio/audio_service.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/services/personal_bests_service.dart';
import '../models/which_side_wins_state.dart';
import '../services/piece_value_engine.dart';

/// Auto-disposed: a round never outlives its screen, so leaving mid-round
/// cancels both timers (no late buzzes or "new record" cheers).
final whichSideWinsProvider =
    NotifierProvider.autoDispose<WhichSideWinsNotifier, WhichSideWinsState>(
  WhichSideWinsNotifier.new,
);

class WhichSideWinsNotifier extends Notifier<WhichSideWinsState> {
  final _engine = PieceValueEngine();
  final _random = Random();
  Timer? _advanceTimer;
  Timer? _countdownTimer;

  AudioService get _audio => ref.read(audioServiceProvider);
  AnalyticsService get _analytics => ref.read(analyticsServiceProvider);

  /// Personal-best key, e.g. `pieces.speed`.
  static String bestKeyFor(WhichSideWinsMode mode) => 'pieces.${mode.name}';

  String get _bestKey => bestKeyFor(state.mode);

  @override
  WhichSideWinsState build() {
    ref.onDispose(_cancelTimers);
    return const WhichSideWinsState(mode: WhichSideWinsMode.practice);
  }

  void startGame(WhichSideWinsMode mode) {
    _cancelTimers();
    state = WhichSideWinsState(
      mode: mode,
      timeRemainingSeconds: mode == WhichSideWinsMode.speed ? 30 : null,
    );

    _analytics.logPiecesDrillStarted(mode: mode.name);

    _generateNextPuzzle();
    if (mode == WhichSideWinsMode.speed) {
      _startCountdown();
    }
  }

  void handleAnswer(AnswerSide side) {
    if (state.isGameOver || state.isWaitingForNext) return;
    final puzzle = state.currentPuzzle;
    if (puzzle == null) return;

    final isCorrect = side == puzzle.correctSide;
    final newStreak = isCorrect ? state.streak + 1 : 0;
    final newBestStreak = max(newStreak, state.bestStreak);

    var newDifficulty = state.currentDifficulty;
    if (isCorrect &&
        state.mode == WhichSideWinsMode.practice &&
        newStreak > 0 &&
        newStreak % 3 == 0 &&
        newDifficulty < 5) {
      newDifficulty++;
    }
    if (!isCorrect &&
        state.mode == WhichSideWinsMode.practice &&
        newDifficulty > 1) {
      newDifficulty--;
    }

    state = state.copyWith(
      streak: newStreak,
      bestStreak: newBestStreak,
      totalCorrect: isCorrect ? state.totalCorrect + 1 : state.totalCorrect,
      totalAttempts: state.totalAttempts + 1,
      currentDifficulty: newDifficulty,
      lastResult: () => isCorrect ? AnswerResult.correct : AnswerResult.incorrect,
      lastAnswerSide: () => side,
      isWaitingForNext: true,
    );

    if (isCorrect) {
      _audio.playCorrect();
    } else {
      _audio.playIncorrect();
    }

    final delay = state.mode == WhichSideWinsMode.speed
        ? (isCorrect
            ? const Duration(milliseconds: 300)
            : const Duration(milliseconds: 800))
        : (isCorrect
            ? const Duration(milliseconds: 600)
            : const Duration(milliseconds: 1400));

    _scheduleAdvance(delay);
  }

  void _generateNextPuzzle() {
    final difficulty = state.mode == WhichSideWinsMode.speed
        ? _random.nextInt(5) + 1
        : state.currentDifficulty;

    final puzzle = _engine.generate(difficulty);

    state = state.copyWith(
      currentPuzzle: () => puzzle,
      lastResult: () => null,
      lastAnswerSide: () => null,
      isWaitingForNext: false,
    );
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final remaining = (state.timeRemainingSeconds ?? 0) - 1;
      if (remaining <= 0) {
        _endRound();
      } else {
        state = state.copyWith(timeRemainingSeconds: () => remaining);
      }
    });
  }

  void _endRound() {
    _cancelTimers();
    final isNewRecord = state.mode == WhichSideWinsMode.speed &&
        ref.read(personalBestsProvider.notifier).submit(
              _bestKey,
              state.totalCorrect,
            );
    state = state.copyWith(
      timeRemainingSeconds: () => 0,
      isGameOver: true,
      isWaitingForNext: true,
      isNewRecord: isNewRecord,
    );
    if (isNewRecord) _audio.playNewRecord();
    _analytics.logPiecesDrillCompleted(
      mode: state.mode.name,
      totalCorrect: state.totalCorrect,
      totalAttempts: state.totalAttempts,
      bestStreak: state.bestStreak,
      isNewRecord: isNewRecord,
    );
    _audio.playGameOver();
  }

  void _scheduleAdvance(Duration delay) {
    _advanceTimer?.cancel();
    _advanceTimer = Timer(delay, () {
      if (state.isGameOver) return;
      _generateNextPuzzle();
    });
  }

  void _cancelTimers() {
    _advanceTimer?.cancel();
    _countdownTimer?.cancel();
  }
}
