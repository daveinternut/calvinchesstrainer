import 'package:flutter/material.dart';
import 'package:calvinchesstrainer/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/audio/audio_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/ui/components.dart';
import '../../drills/warmup_actions.dart';
import '../../file_rank_trainer/widgets/streak_counter.dart';
import '../../file_rank_trainer/widgets/timer_bar.dart';
import '../../file_rank_trainer/widgets/results_card.dart';
import '../models/which_side_wins_state.dart';
import '../providers/which_side_wins_provider.dart';
import '../widgets/piece_group_panel.dart';
import '../widgets/vs_divider.dart';

class WhichSideWinsScreen extends ConsumerStatefulWidget {
  final WhichSideWinsMode mode;

  /// A step of the daily warm-up (the results then move on to the next).
  final bool warmup;

  const WhichSideWinsScreen({
    super.key,
    required this.mode,
    this.warmup = false,
  });

  @override
  ConsumerState<WhichSideWinsScreen> createState() =>
      _WhichSideWinsScreenState();
}

class _WhichSideWinsScreenState extends ConsumerState<WhichSideWinsScreen> {
  static const double _maxContentWidth = 900;

  /// Below this height the panels can't share the page with the prompt,
  /// streak and timer, so the page scrolls with fixed-height panels instead.
  static const double _minColumnHeight = 460;
  static const double _scrollingPanelHeight = 260;

  late final AudioService _audioService;

  @override
  void initState() {
    super.initState();
    _audioService = ref.read(audioServiceProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) => _startGame());
  }

  void _startGame() =>
      ref.read(whichSideWinsProvider.notifier).startGame(widget.mode);

  @override
  void dispose() {
    _audioService.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final gameState = ref.watch(whichSideWinsProvider);

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            LayoutBuilder(
              builder: (context, constraints) =>
                  _buildContent(gameState, constraints, l10n),
            ),
            if (gameState.isGameOver)
              Positioned.fill(child: _results(gameState)),
          ],
        ),
      ),
    );
  }

  Widget _results(WhichSideWinsState gameState) {
    final actions = roundActions(
      context,
      ref,
      warmup: widget.warmup,
      score: gameState.totalCorrect,
      onPlayAgain: _startGame,
    );
    return ResultsCard(
      totalCorrect: gameState.totalCorrect,
      totalAttempts: gameState.totalAttempts,
      bestStreak: gameState.bestStreak,
      isNewRecord: gameState.isNewRecord,
      primaryLabel: actions.primaryLabel,
      onPlayAgain: actions.onPrimary,
      secondaryLabel: actions.secondaryLabel,
      onBack: actions.onSecondary,
    );
  }

  /// One centred column, capped in width so a landscape iPad keeps the two
  /// sides close enough to compare at a glance.
  Widget _buildContent(
    WhichSideWinsState gameState,
    BoxConstraints constraints,
    AppLocalizations l10n,
  ) {
    final header = <Widget>[
      PlayTopBar(
        title: l10n.drillPieceValues,
        subtitle: warmupSubtitle(ref, l10n, widget.warmup) ??
            (widget.mode == WhichSideWinsMode.speed
                ? l10n.speedRound
                : l10n.practice),
        onClose: () => closeDrill(context),
        closeTooltip: l10n.endDrill,
        trailing: Text('${gameState.totalCorrect}/${gameState.totalAttempts}'),
      ),
      const SizedBox(height: 12),
      Text(
        l10n.tapTheSideWorthMore,
        style: AppText.display.copyWith(fontSize: 28),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 8),
      StreakCounter(
        streak: gameState.streak,
        bestStreak: gameState.bestStreak,
      ),
      const SizedBox(height: 8),
    ];
    final footer = <Widget>[
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
    ];

    final column = constraints.maxHeight < _minColumnHeight
        ? SingleChildScrollView(
            child: Column(
              children: [
                ...header,
                SizedBox(
                  height: _scrollingPanelHeight,
                  child: _buildPuzzleArea(gameState),
                ),
                ...footer,
              ],
            ),
          )
        : Column(
            children: [
              ...header,
              Expanded(child: _buildPuzzleArea(gameState)),
              ...footer,
            ],
          );

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxContentWidth),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: column,
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
    // After an answer, show what each side is worth.
    final showTotals = gameState.lastResult != null;

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
          total: showTotals ? puzzle.leftValue : null,
        ),
        const VsDivider(),
        PieceGroupPanel(
          pieces: puzzle.rightGroup,
          onTap: () => ref
              .read(whichSideWinsProvider.notifier)
              .handleAnswer(AnswerSide.right),
          backgroundColor: rightColor,
          enabled: !gameState.isWaitingForNext,
          total: showTotals ? puzzle.rightValue : null,
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
      if (side == gameState.lastAnswerSide) {
        return AppColors.correctGreen.withValues(alpha: 0.2);
      }
      return null;
    }

    if (side == gameState.lastAnswerSide) {
      return AppColors.incorrectRed.withValues(alpha: 0.2);
    }
    if (side == correctSide) {
      return AppColors.correctGreen.withValues(alpha: 0.2);
    }
    return null;
  }

  Widget _buildDifficultyIndicator(WhichSideWinsState gameState) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final active = index < gameState.currentDifficulty;
        return Container(
          width: 10,
          height: 10,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? AppColors.brand : AppColors.line2,
          ),
        );
      }),
    );
  }
}
