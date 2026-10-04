import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import '../../../core/board_utils.dart';
import '../../../core/theme/app_theme.dart';

/// `moves`, `letters` and `pieceValue` are menu-only subjects: the notation
/// menu routes them to the move trainer, letter trainer and Which Side Wins
/// respectively — this provider never handles them.
enum TrainerSubject { files, ranks, squares, moves, letters, pieceValue }

enum TrainerMode { explore, practice, speed }

enum AnswerResult { correct, incorrect }

class AnswerFeedback {
  final AnswerResult result;
  final int tappedIndex;
  final int correctIndex;
  final bool isFile;
  final int? tappedRankIndex;
  final int? correctRankIndex;

  const AnswerFeedback({
    required this.result,
    required this.tappedIndex,
    required this.correctIndex,
    required this.isFile,
    this.tappedRankIndex,
    this.correctRankIndex,
  });
}

class FileRankGameState {
  final TrainerSubject subject;
  final TrainerMode mode;
  final bool isHardMode;
  final String? currentPrompt;
  final int? currentTargetIndex;
  final int? currentTargetRankIndex;
  final bool currentPromptIsFile;
  final int streak;
  final int bestStreak;
  final int totalCorrect;
  final int totalAttempts;
  final int? timeRemainingSeconds;
  final AnswerFeedback? lastFeedback;
  final bool isGameOver;
  final bool isWaitingForNext;

  /// Set at game over when the round beat the saved personal best.
  final bool isNewRecord;

  const FileRankGameState({
    required this.subject,
    required this.mode,
    this.isHardMode = false,
    this.currentPrompt,
    this.currentTargetIndex,
    this.currentTargetRankIndex,
    this.currentPromptIsFile = true,
    this.streak = 0,
    this.bestStreak = 0,
    this.totalCorrect = 0,
    this.totalAttempts = 0,
    this.timeRemainingSeconds,
    this.lastFeedback,
    this.isGameOver = false,
    this.isWaitingForNext = false,
    this.isNewRecord = false,
  });

  FileRankGameState copyWith({
    TrainerSubject? subject,
    TrainerMode? mode,
    bool? isHardMode,
    String? Function()? currentPrompt,
    int? Function()? currentTargetIndex,
    int? Function()? currentTargetRankIndex,
    bool? currentPromptIsFile,
    int? streak,
    int? bestStreak,
    int? totalCorrect,
    int? totalAttempts,
    int? Function()? timeRemainingSeconds,
    AnswerFeedback? Function()? lastFeedback,
    bool? isGameOver,
    bool? isWaitingForNext,
    bool? isNewRecord,
  }) {
    return FileRankGameState(
      subject: subject ?? this.subject,
      mode: mode ?? this.mode,
      isHardMode: isHardMode ?? this.isHardMode,
      currentPrompt:
          currentPrompt != null ? currentPrompt() : this.currentPrompt,
      currentTargetIndex: currentTargetIndex != null
          ? currentTargetIndex()
          : this.currentTargetIndex,
      currentTargetRankIndex: currentTargetRankIndex != null
          ? currentTargetRankIndex()
          : this.currentTargetRankIndex,
      currentPromptIsFile: currentPromptIsFile ?? this.currentPromptIsFile,
      streak: streak ?? this.streak,
      bestStreak: bestStreak ?? this.bestStreak,
      totalCorrect: totalCorrect ?? this.totalCorrect,
      totalAttempts: totalAttempts ?? this.totalAttempts,
      timeRemainingSeconds: timeRemainingSeconds != null
          ? timeRemainingSeconds()
          : this.timeRemainingSeconds,
      lastFeedback:
          lastFeedback != null ? lastFeedback() : this.lastFeedback,
      isGameOver: isGameOver ?? this.isGameOver,
      isWaitingForNext: isWaitingForNext ?? this.isWaitingForNext,
      isNewRecord: isNewRecord ?? this.isNewRecord,
    );
  }

  IMap<Square, SquareHighlight> get allHighlights {
    IMap<Square, SquareHighlight> highlights = const IMapConst<Square, SquareHighlight>({});
    final feedback = lastFeedback;

    if (subject == TrainerSubject.squares) {
      if (feedback != null) {
        if (feedback.result == AnswerResult.incorrect &&
            feedback.tappedRankIndex != null) {
          highlights = highlights.addAll(highlightSquare(
            feedback.tappedIndex,
            feedback.tappedRankIndex!,
            AppColors.incorrectRed.withValues(alpha: 0.6),
          ));
        }
        if (feedback.correctRankIndex != null) {
          highlights = highlights.addAll(highlightSquare(
            feedback.correctIndex,
            feedback.correctRankIndex!,
            AppColors.correctGreen.withValues(alpha: 0.6),
          ));
        }
      }
    } else {
      if (feedback != null && feedback.isFile) {
        if (feedback.result == AnswerResult.incorrect) {
          highlights = highlights.addAll(highlightFile(
            feedback.tappedIndex,
            AppColors.incorrectRed.withValues(alpha: 0.6),
          ));
        }
        highlights = highlights.addAll(highlightFile(
          feedback.correctIndex,
          AppColors.correctGreen.withValues(alpha: 0.6),
        ));
      } else if (feedback != null && !feedback.isFile) {
        if (feedback.result == AnswerResult.incorrect) {
          highlights = highlights.addAll(highlightRank(
            feedback.tappedIndex,
            AppColors.incorrectRed.withValues(alpha: 0.6),
          ));
        }
        highlights = highlights.addAll(highlightRank(
          feedback.correctIndex,
          AppColors.correctGreen.withValues(alpha: 0.6),
        ));
      }
    }

    return highlights;
  }
}
