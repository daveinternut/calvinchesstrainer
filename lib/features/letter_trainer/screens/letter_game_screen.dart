import 'package:flutter/material.dart';
import 'package:calvinchesstrainer/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/audio/audio_service.dart';
import '../../../core/audio/sound_switch.dart';
import '../../../core/ui/components.dart';
import '../../drills/warmup_actions.dart';
import '../../file_rank_trainer/widgets/milestone_banner.dart';
import '../../file_rank_trainer/widgets/results_card.dart';
import '../../file_rank_trainer/widgets/streak_counter.dart';
import '../../file_rank_trainer/widgets/timer_bar.dart';
import '../models/letter_game_state.dart';
import '../providers/letter_game_provider.dart';
import '../widgets/letter_answer_grid.dart';
import '../widgets/letter_explore_grid.dart';
import '../widgets/letter_prompt_display.dart';

class LetterGameScreen extends ConsumerStatefulWidget {
  final LetterTrainerMode mode;
  final bool isHardMode;

  /// A step of the daily warm-up (the results then move on to the next).
  final bool warmup;

  const LetterGameScreen({
    super.key,
    required this.mode,
    this.isHardMode = false,
    this.warmup = false,
  });

  @override
  ConsumerState<LetterGameScreen> createState() => _LetterGameScreenState();
}

class _LetterGameScreenState extends ConsumerState<LetterGameScreen> {
  static const double _maxContentWidth = 640;

  /// Below this height the prompt, streak, timer and tiles can't all fit, so
  /// the page scrolls as one.
  static const double _minColumnHeight = 520;

  late final AudioService _audioService;

  @override
  void initState() {
    super.initState();
    _audioService = ref.read(audioServiceProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) => _startGame());
  }

  void _startGame() {
    ref
        .read(letterGameProvider.notifier)
        .startGame(widget.mode, isHardMode: widget.isHardMode);
  }

  @override
  void dispose() {
    _audioService.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final gameState = ref.watch(letterGameProvider);

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            LayoutBuilder(
              builder: (context, constraints) =>
                  _buildContent(gameState, constraints, l10n),
            ),
            if (gameState.mode != LetterTrainerMode.explore)
              MilestoneBanner(
                streak: gameState.streak,
                alignToTrainerLayout: false,
              ),
            if (gameState.isGameOver)
              Positioned.fill(child: _results(gameState)),
          ],
        ),
      ),
    );
  }

  Widget _results(LetterGameState gameState) {
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

  /// One centred column, capped in width so a landscape iPad doesn't spread
  /// the tiles across the screen. When the window is too short for the fixed
  /// prompt, streak and timer plus the tiles, the whole page scrolls instead
  /// of overflowing.
  Widget _buildContent(
    LetterGameState gameState,
    BoxConstraints constraints,
    AppLocalizations l10n,
  ) {
    final isExplore = gameState.mode == LetterTrainerMode.explore;
    final header = <Widget>[
      PlayTopBar(
        title: l10n.drillPieceLetters,
        subtitle: warmupSubtitle(ref, l10n, widget.warmup) ?? _subtitle(l10n),
        onClose: () => closeDrill(context),
        closeTooltip: l10n.endDrill,
        trailing: isExplore
            ? null
            : Text('${gameState.totalCorrect}/${gameState.totalAttempts}'),
        action: const SoundButton(),
      ),
      const SizedBox(height: 12),
      LetterPromptDisplay(gameState: gameState),
      const SizedBox(height: 12),
      if (!isExplore) ...[
        StreakCounter(
          streak: gameState.streak,
          bestStreak: gameState.bestStreak,
        ),
        const SizedBox(height: 12),
      ],
    ];
    final tiles = isExplore
        ? LetterExploreGrid(
            gameState: gameState,
            onTap: (piece) =>
                ref.read(letterGameProvider.notifier).handleAnswer(piece),
          )
        : LetterAnswerGrid(
            gameState: gameState,
            onTap: (piece) =>
                ref.read(letterGameProvider.notifier).handleAnswer(piece),
          );
    final footer = <Widget>[
      if (gameState.mode == LetterTrainerMode.speed &&
          gameState.timeRemainingSeconds != null) ...[
        const SizedBox(height: 12),
        TimerBar(remainingSeconds: gameState.timeRemainingSeconds!),
      ],
      const SizedBox(height: 16),
    ];

    final column = constraints.maxHeight < _minColumnHeight
        ? SingleChildScrollView(
            child: Column(children: [...header, tiles, ...footer]),
          )
        : Column(
            children: [
              ...header,
              Expanded(
                child: Center(child: SingleChildScrollView(child: tiles)),
              ),
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

  String _subtitle(AppLocalizations l10n) {
    final mode = switch (widget.mode) {
      LetterTrainerMode.explore => l10n.explore,
      LetterTrainerMode.practice => l10n.practice,
      LetterTrainerMode.speed => l10n.speedRound,
    };
    return widget.isHardMode ? '$mode · ${l10n.playAsBlack}' : mode;
  }
}
