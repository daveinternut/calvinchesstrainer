import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/audio/audio_service.dart';
import '../../../core/constants.dart';
import '../models/file_rank_game_state.dart';

final fileRankGameProvider =
    NotifierProvider<FileRankGameNotifier, FileRankGameState>(
  FileRankGameNotifier.new,
);

class FileRankGameNotifier extends Notifier<FileRankGameState> {
  final _random = Random();
  Timer? _advanceTimer;
  Timer? _countdownTimer;
  final Map<String, int> _personalBests = {};

  AudioService get _audio => ref.read(audioServiceProvider);

  String get _bestKey =>
      '${state.subject.name}_${state.mode.name}_${state.isReverse}_${state.isHardMode}';

  int get personalBest => _personalBests[_bestKey] ?? 0;

  @override
  FileRankGameState build() {
    ref.onDispose(_dispose);
    return const FileRankGameState(
      subject: TrainerSubject.files,
      mode: TrainerMode.explore,
    );
  }

  void startGame(TrainerSubject subject, TrainerMode mode, bool isReverse, {bool isHardMode = false}) {
    _cancelTimers();
    state = FileRankGameState(
      subject: subject,
      mode: mode,
      isReverse: isReverse,
      isHardMode: isHardMode,
      timeRemainingSeconds: mode == TrainerMode.speed ? 30 : null,
    );

    if (mode != TrainerMode.explore) {
      _generateNextPrompt();
    }
    if (mode == TrainerMode.speed) {
      _startCountdown();
    }
  }

  void handleBoardTap(int file, int rank) {
    if (state.isGameOver || state.isWaitingForNext) return;

    if (state.mode == TrainerMode.explore) {
      _handleExploreTap(file, rank);
      return;
    }

    if (state.isReverse) return;

    if (state.subject == TrainerSubject.squares) {
      _evaluateSquareAnswer(file, rank);
    } else {
      final tappedIndex = state.currentPromptIsFile ? file : rank;
      _evaluateAnswer(tappedIndex);
    }
  }

  void handleAnswerButtonTap(int index) {
    if (state.isGameOver || state.isWaitingForNext) return;
    if (!state.isReverse) return;

    _evaluateAnswer(index);
  }

  void _handleExploreTap(int file, int rank) {
    if (state.subject == TrainerSubject.files) {
      state = state.copyWith(
        lastFeedback: () => AnswerFeedback(
          result: AnswerResult.correct,
          tappedIndex: file,
          correctIndex: file,
          isFile: true,
        ),
      );
      _audio.speakFile(ChessConstants.files[file]);
    } else if (state.subject == TrainerSubject.ranks) {
      state = state.copyWith(
        lastFeedback: () => AnswerFeedback(
          result: AnswerResult.correct,
          tappedIndex: rank,
          correctIndex: rank,
          isFile: false,
        ),
      );
      _audio.speakRank(ChessConstants.ranks[rank]);
    } else if (state.subject == TrainerSubject.squares) {
      state = state.copyWith(
        lastFeedback: () => AnswerFeedback(
          result: AnswerResult.correct,
          tappedIndex: file,
          correctIndex: file,
          isFile: true,
          tappedRankIndex: rank,
          correctRankIndex: rank,
        ),
      );
      _audio.speakSquare(ChessConstants.files[file], ChessConstants.ranks[rank]);
    }

    _scheduleAdvance(const Duration(milliseconds: 800));
  }

  void _evaluateAnswer(int tappedIndex) {
    final target = state.currentTargetIndex;
    if (target == null) return;

    final isCorrect = tappedIndex == target;
    final newStreak = isCorrect ? state.streak + 1 : 0;
    final newBestStreak = max(newStreak, state.bestStreak);
    final isMilestone = isCorrect && newStreak > 0 && newStreak % 5 == 0;

    state = state.copyWith(
      streak: newStreak,
      bestStreak: newBestStreak,
      totalCorrect: isCorrect ? state.totalCorrect + 1 : state.totalCorrect,
      totalAttempts: state.totalAttempts + 1,
      isWaitingForNext: true,
      lastFeedback: () => AnswerFeedback(
        result: isCorrect ? AnswerResult.correct : AnswerResult.incorrect,
        tappedIndex: tappedIndex,
        correctIndex: target,
        isFile: state.currentPromptIsFile,
      ),
    );

    if (isCorrect) {
      _audio.playCorrect();
      if (isMilestone) {
        _audio.playStreakMilestone(newStreak);
      }
    } else {
      _audio.playIncorrect();
    }

    final delay = state.mode == TrainerMode.speed
        ? (isCorrect
            ? const Duration(milliseconds: 200)
            : const Duration(milliseconds: 600))
        : (isCorrect
            ? const Duration(milliseconds: 400)
            : const Duration(milliseconds: 1200));

    _scheduleAdvance(delay);
  }

  void _evaluateSquareAnswer(int file, int rank) {
    final targetFile = state.currentTargetIndex;
    final targetRank = state.currentTargetRankIndex;
    if (targetFile == null || targetRank == null) return;

    final isCorrect = file == targetFile && rank == targetRank;
    final newStreak = isCorrect ? state.streak + 1 : 0;
    final newBestStreak = max(newStreak, state.bestStreak);
    final isMilestone = isCorrect && newStreak > 0 && newStreak % 5 == 0;

    state = state.copyWith(
      streak: newStreak,
      bestStreak: newBestStreak,
      totalCorrect: isCorrect ? state.totalCorrect + 1 : state.totalCorrect,
      totalAttempts: state.totalAttempts + 1,
      isWaitingForNext: true,
      lastFeedback: () => AnswerFeedback(
        result: isCorrect ? AnswerResult.correct : AnswerResult.incorrect,
        tappedIndex: file,
        correctIndex: targetFile,
        isFile: true,
        tappedRankIndex: rank,
        correctRankIndex: targetRank,
      ),
    );

    if (isCorrect) {
      _audio.playCorrect();
      if (isMilestone) {
        _audio.playStreakMilestone(newStreak);
      }
    } else {
      _audio.playIncorrect();
    }

    final delay = state.mode == TrainerMode.speed
        ? (isCorrect
            ? const Duration(milliseconds: 200)
            : const Duration(milliseconds: 600))
        : (isCorrect
            ? const Duration(milliseconds: 400)
            : const Duration(milliseconds: 1200));

    _scheduleAdvance(delay);
  }

  void _generateNextPrompt() {
    if (state.subject == TrainerSubject.squares) {
      _generateSquarePrompt();
      return;
    }

    final previousTarget = state.currentTargetIndex;
    final previousIsFile = state.currentPromptIsFile;

    final isFile = state.subject == TrainerSubject.files;

    int target;
    do {
      target = _random.nextInt(8);
    } while (target == previousTarget && isFile == previousIsFile);

    final prompt = isFile
        ? ChessConstants.files[target]
        : ChessConstants.ranks[target];

    state = state.copyWith(
      currentPrompt: () => prompt,
      currentTargetIndex: () => target,
      currentPromptIsFile: isFile,
      lastFeedback: () => null,
      isWaitingForNext: false,
    );

    if (!state.isReverse) {
      if (isFile) {
        _audio.speakFile(prompt);
      } else {
        _audio.speakRank(prompt);
      }
    }
  }

  void _generateSquarePrompt() {
    final prevFile = state.currentTargetIndex;
    final prevRank = state.currentTargetRankIndex;

    int fileIdx, rankIdx;
    do {
      fileIdx = _random.nextInt(8);
      rankIdx = _random.nextInt(8);
    } while (fileIdx == prevFile && rankIdx == prevRank);

    final prompt = ChessConstants.squareName(fileIdx, rankIdx);

    state = state.copyWith(
      currentPrompt: () => prompt,
      currentTargetIndex: () => fileIdx,
      currentTargetRankIndex: () => rankIdx,
      currentPromptIsFile: true,
      lastFeedback: () => null,
      isWaitingForNext: false,
    );

    if (!state.isReverse) {
      _audio.speakSquare(
        ChessConstants.files[fileIdx],
        ChessConstants.ranks[rankIdx],
      );
    }
  }

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
      if (state.mode == TrainerMode.explore) {
        state = state.copyWith(
          lastFeedback: () => null,
          isWaitingForNext: false,
        );
      } else {
        _generateNextPrompt();
      }
    });
  }

  bool get isNewRecord {
    if (state.mode != TrainerMode.speed) return false;
    final best = _personalBests[_bestKey] ?? 0;
    return state.totalCorrect > best && state.totalCorrect > 0;
  }

  void _checkAndUpdatePersonalBest() {
    if (state.mode != TrainerMode.speed) return;
    final current = _personalBests[_bestKey] ?? 0;
    if (state.totalCorrect > current) {
      _personalBests[_bestKey] = state.totalCorrect;
      _audio.playNewRecord();
    }
  }

  void _cancelTimers() {
    _advanceTimer?.cancel();
    _countdownTimer?.cancel();
  }

  void _dispose() {
    _cancelTimers();
  }
}
