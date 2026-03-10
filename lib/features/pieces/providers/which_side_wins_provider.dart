import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/audio/audio_service.dart';
import '../../../core/services/analytics_service.dart';
import '../models/which_side_wins_state.dart';
import '../services/piece_value_engine.dart';

final whichSideWinsProvider =
    NotifierProvider<WhichSideWinsNotifier, WhichSideWinsState>(
  WhichSideWinsNotifier.new,
);

class WhichSideWinsNotifier extends Notifier<WhichSideWinsState> {
  final _engine = PieceValueEngine();
  Timer? _advanceTimer;
  Timer? _countdownTimer;
  final Map<String, int> _personalBests = {};

  AudioService get _audio => ref.read(audioServiceProvider);
  AnalyticsService get _analytics => ref.read(analyticsServiceProvider);

  String get _bestKey => '${state.mode.name}_${state.difficulty.name}';

  int get personalBest => _personalBests[_bestKey] ?? 0;

  @override
  WhichSideWinsState build() {
    ref.onDispose(_dispose);
    return const WhichSideWinsState(mode: WhichSideWinsMode.practice);
  }

  void startGame(WhichSideWinsMode mode, {PiecesDifficulty difficulty = PiecesDifficulty.easy}) {
    _cancelTimers();
    state = WhichSideWinsState(
      mode: mode,
      difficulty: difficulty,
      currentLevel: difficulty.startLevel,
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

    final bounds = state.difficulty;
    var newLevel = state.currentLevel;
    if (isCorrect &&
        state.mode == WhichSideWinsMode.practice &&
        newStreak > 0 &&
        newStreak % 3 == 0 &&
        newLevel < bounds.maxLevel) {
      newLevel++;
    }
    if (!isCorrect &&
        state.mode == WhichSideWinsMode.practice &&
        newLevel > bounds.minLevel) {
      newLevel--;
    }

    state = state.copyWith(
      streak: newStreak,
      bestStreak: newBestStreak,
      totalCorrect: isCorrect ? state.totalCorrect + 1 : state.totalCorrect,
      totalAttempts: state.totalAttempts + 1,
      currentLevel: newLevel,
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
    final bounds = state.difficulty;
    final difficulty = state.mode == WhichSideWinsMode.speed
        ? bounds.minLevel + _random.nextInt(bounds.maxLevel - bounds.minLevel + 1)
        : state.currentLevel;

    final puzzle = _engine.generate(difficulty);

    state = state.copyWith(
      currentPuzzle: () => puzzle,
      lastResult: () => null,
      lastAnswerSide: () => null,
      isWaitingForNext: false,
    );
  }

  final _random = Random();

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final remaining = (state.timeRemainingSeconds ?? 0) - 1;
      if (remaining <= 0) {
        _cancelTimers();
        state = state.copyWith(
          timeRemainingSeconds: () => 0,
          isGameOver: true,
          isWaitingForNext: true,
        );
        _checkAndUpdatePersonalBest();
        _audio.playGameOver();
      } else {
        state = state.copyWith(timeRemainingSeconds: () => remaining);
      }
    });
  }

  void _scheduleAdvance(Duration delay) {
    _advanceTimer?.cancel();
    _advanceTimer = Timer(delay, () {
      if (state.isGameOver) return;
      _generateNextPuzzle();
    });
  }

  bool get isNewRecord {
    if (state.mode != WhichSideWinsMode.speed) return false;
    final best = _personalBests[_bestKey] ?? 0;
    return state.totalCorrect > best && state.totalCorrect > 0;
  }

  void _checkAndUpdatePersonalBest() {
    if (state.mode != WhichSideWinsMode.speed) return;
    final newRecord = state.totalCorrect > (_personalBests[_bestKey] ?? 0) &&
        state.totalCorrect > 0;
    if (newRecord) {
      _personalBests[_bestKey] = state.totalCorrect;
      _audio.playNewRecord();
    }
    _analytics.logPiecesDrillCompleted(
      mode: state.mode.name,
      totalCorrect: state.totalCorrect,
      totalAttempts: state.totalAttempts,
      bestStreak: state.bestStreak,
      isNewRecord: newRecord,
    );
  }

  void _cancelTimers() {
    _advanceTimer?.cancel();
    _countdownTimer?.cancel();
  }

  void _dispose() {
    _cancelTimers();
  }
}
