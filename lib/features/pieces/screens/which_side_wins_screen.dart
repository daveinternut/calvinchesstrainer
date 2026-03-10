import 'package:flutter/material.dart';
import 'package:calvinchesstrainer/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../file_rank_trainer/widgets/streak_counter.dart';
import '../../file_rank_trainer/widgets/timer_bar.dart';
import '../../file_rank_trainer/widgets/results_card.dart';
import '../models/which_side_wins_state.dart';
import '../providers/which_side_wins_provider.dart';
import '../widgets/piece_group_panel.dart';
import '../widgets/vs_divider.dart';

class WhichSideWinsScreen extends ConsumerStatefulWidget {
  final WhichSideWinsMode mode;
  final PiecesDifficulty difficulty;

  const WhichSideWinsScreen({
    super.key,
    required this.mode,
    this.difficulty = PiecesDifficulty.easy,
  });

  @override
  ConsumerState<WhichSideWinsScreen> createState() =>
      _WhichSideWinsScreenState();
}

class _WhichSideWinsScreenState extends ConsumerState<WhichSideWinsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(whichSideWinsProvider.notifier).startGame(
            widget.mode,
            difficulty: widget.difficulty,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final gameState = ref.watch(whichSideWinsProvider);

    return Scaffold(
      appBar: AppBar(
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(_title(l10n)),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${gameState.totalCorrect}/${gameState.totalAttempts}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Text(
                    l10n.tapTheSideWorthMore,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  StreakCounter(
                    streak: gameState.streak,
                    bestStreak: gameState.bestStreak,
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _buildPuzzleArea(gameState),
                  ),
                  if (gameState.mode == WhichSideWinsMode.speed &&
                      gameState.timeRemainingSeconds != null) ...[
                    const SizedBox(height: 12),
                    TimerBar(
                      remainingSeconds: gameState.timeRemainingSeconds!,
                    ),
                  ],
                  if (gameState.mode == WhichSideWinsMode.practice)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: _buildDifficultyIndicator(gameState),
                    ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            if (gameState.isGameOver)
              Container(
                color: Colors.black54,
                child: ResultsCard(
                  totalCorrect: gameState.totalCorrect,
                  totalAttempts: gameState.totalAttempts,
                  bestStreak: gameState.bestStreak,
                  isNewRecord:
                      ref.read(whichSideWinsProvider.notifier).isNewRecord,
                  onPlayAgain: () {
                    ref
                        .read(whichSideWinsProvider.notifier)
                        .startGame(widget.mode, difficulty: widget.difficulty);
                  },
                  onBack: () => context.pop(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPuzzleArea(WhichSideWinsState gameState) {
    final puzzle = gameState.currentPuzzle;
    if (puzzle == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final leftColor = _panelColor(
      gameState, AnswerSide.left, puzzle.correctSide,
    );
    final rightColor = _panelColor(
      gameState, AnswerSide.right, puzzle.correctSide,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        PieceGroupPanel(
          pieces: puzzle.leftGroup,
          onTap: () => ref
              .read(whichSideWinsProvider.notifier)
              .handleAnswer(AnswerSide.left),
          backgroundColor: leftColor,
          enabled: !gameState.isWaitingForNext,
        ),
        const VsDivider(),
        PieceGroupPanel(
          pieces: puzzle.rightGroup,
          onTap: () => ref
              .read(whichSideWinsProvider.notifier)
              .handleAnswer(AnswerSide.right),
          backgroundColor: rightColor,
          enabled: !gameState.isWaitingForNext,
        ),
      ],
    );
  }

  Color? _panelColor(
    WhichSideWinsState gameState,
    AnswerSide side,
    AnswerSide correctSide,
  ) {
    if (gameState.lastResult == null) return null;

    if (gameState.lastResult == AnswerResult.correct) {
      // Correct answer: highlight the tapped (correct) side green
      if (side == gameState.lastAnswerSide) {
        return AppColors.correctGreen.withValues(alpha: 0.2);
      }
      return null;
    }

    // Incorrect answer: red on tapped side, green on correct side
    if (side == gameState.lastAnswerSide) {
      return AppColors.incorrectRed.withValues(alpha: 0.2);
    }
    if (side == correctSide) {
      return AppColors.correctGreen.withValues(alpha: 0.2);
    }
    return null;
  }

  Widget _buildDifficultyIndicator(WhichSideWinsState gameState) {
    final bounds = gameState.difficulty;
    final levelCount = bounds.maxLevel - bounds.minLevel + 1;
    final filledCount = gameState.currentLevel - bounds.minLevel + 1;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(levelCount, (index) {
        final active = index < filledCount;
        return Container(
          width: 10,
          height: 10,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active
                ? const Color(0xFF0277BD)
                : Colors.grey.shade300,
          ),
        );
      }),
    );
  }

  String _title(AppLocalizations l10n) {
    final mode = switch (widget.mode) {
      WhichSideWinsMode.practice => l10n.practice,
      WhichSideWinsMode.speed => l10n.speedRound,
    };
    return '${l10n.whichSideWins} — $mode';
  }
}
