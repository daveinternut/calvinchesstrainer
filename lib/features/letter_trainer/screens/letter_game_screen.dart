import 'package:flutter/material.dart';
import 'package:calvinchesstrainer/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/audio/audio_service.dart';
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

  const LetterGameScreen({
    super.key,
    required this.mode,
    this.isHardMode = false,
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(letterGameProvider.notifier)
          .startGame(widget.mode, isHardMode: widget.isHardMode);
    });
  }

  @override
  void dispose() {
    _audioService.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(letterGameProvider);

    return Scaffold(
      appBar: AppBar(
        title: FittedBox(fit: BoxFit.scaleDown, child: Text(_title)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (gameState.mode != LetterTrainerMode.explore)
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
            LayoutBuilder(
              builder: (context, constraints) =>
                  _buildContent(gameState, constraints),
            ),
            if (gameState.mode != LetterTrainerMode.explore)
              MilestoneBanner(
                streak: gameState.streak,
                alignToTrainerLayout: false,
              ),
            if (gameState.isGameOver)
              Container(
                color: Colors.black54,
                child: ResultsCard(
                  totalCorrect: gameState.totalCorrect,
                  totalAttempts: gameState.totalAttempts,
                  bestStreak: gameState.bestStreak,
                  isNewRecord: gameState.isNewRecord,
                  onPlayAgain: () {
                    ref
                        .read(letterGameProvider.notifier)
                        .startGame(widget.mode, isHardMode: widget.isHardMode);
                  },
                  onBack: () => context.pop(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// One centred column, capped in width so a landscape iPad doesn't spread
  /// the tiles across the screen. When the window is too short for the fixed
  /// prompt, streak and timer plus the tiles, the whole page scrolls instead
  /// of overflowing.
  Widget _buildContent(LetterGameState gameState, BoxConstraints constraints) {
    final isExplore = gameState.mode == LetterTrainerMode.explore;
    final header = <Widget>[
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

  String get _title {
    final l10n = AppLocalizations.of(context)!;
    final mode = switch (widget.mode) {
      LetterTrainerMode.explore => l10n.explore,
      LetterTrainerMode.practice => l10n.practice,
      LetterTrainerMode.speed => l10n.speedRound,
    };
    return l10n.titleFileRankGame(l10n.letters, mode);
  }
}
