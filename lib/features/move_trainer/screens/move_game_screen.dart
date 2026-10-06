import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:calvinchesstrainer/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/audio/audio_service.dart';
import '../../../core/audio/sound_switch.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/board_theme.dart';
import '../../../core/ui/board_frame.dart';
import '../../../core/ui/components.dart';
import '../../../core/widgets/square_name_overlay.dart';
import '../../../core/widgets/trainer_layout.dart';
import '../../drills/warmup_actions.dart';
import '../../file_rank_trainer/widgets/milestone_banner.dart';
import '../../file_rank_trainer/widgets/streak_counter.dart';
import '../../file_rank_trainer/widgets/timer_bar.dart';
import '../../file_rank_trainer/widgets/results_card.dart';
import '../models/move_game_state.dart';
import '../providers/move_game_provider.dart';
import '../widgets/move_prompt_display.dart';

class MoveGameScreen extends ConsumerStatefulWidget {
  final MoveTrainerMode mode;
  final bool isHardMode;

  /// A step of the daily warm-up (the results then move on to the next).
  final bool warmup;

  const MoveGameScreen({
    super.key,
    required this.mode,
    this.isHardMode = false,
    this.warmup = false,
  });

  @override
  ConsumerState<MoveGameScreen> createState() => _MoveGameScreenState();
}

class _MoveGameScreenState extends ConsumerState<MoveGameScreen> {
  late final AudioService _audioService;

  @override
  void initState() {
    super.initState();
    _audioService = ref.read(audioServiceProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) => _startGame());
  }

  void _startGame() {
    ref.read(moveGameProvider.notifier).startGame(
          widget.mode,
          isHardMode: widget.isHardMode,
        );
  }

  @override
  void dispose() {
    _audioService.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final gameState = ref.watch(moveGameProvider);
    final orientation = widget.isHardMode ? Side.black : Side.white;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            TrainerLayout(
              topBar: PlayTopBar(
                title: l10n.drillReadMoves,
                subtitle: warmupSubtitle(ref, l10n, widget.warmup) ??
                    _subtitle(l10n),
                onClose: () => closeDrill(context),
                closeTooltip: l10n.endDrill,
                trailing: Text(
                  '${gameState.totalCorrect}/${gameState.totalAttempts}',
                ),
                action: const SoundButton(),
              ),
              header: [
                const SizedBox(height: 4),
                MovePromptDisplay(gameState: gameState),
                const SizedBox(height: 8),
                StreakCounter(
                  streak: gameState.streak,
                  bestStreak: gameState.bestStreak,
                ),
                const SizedBox(height: 8),
              ],
              // Coordinates stay hidden: reading the square is the drill.
              board: (context, size) => BoardFrame(
                size: size,
                orientation: orientation,
                showCoordinates: false,
                builder: (context, boardSize) =>
                    _buildBoard(gameState, boardSize),
              ),
              footer: [
                if (gameState.mode == MoveTrainerMode.speed &&
                    gameState.timeRemainingSeconds != null) ...[
                  const SizedBox(height: 12),
                  TimerBar(remainingSeconds: gameState.timeRemainingSeconds!),
                ],
                const SizedBox(height: 16),
              ],
            ),
            MilestoneBanner(streak: gameState.streak),
            if (gameState.isGameOver)
              Positioned.fill(child: _results(gameState)),
          ],
        ),
      ),
    );
  }

  Widget _results(MoveGameState gameState) {
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
      missed: gameState.missed.toSet().take(8).toList(),
      primaryLabel: actions.primaryLabel,
      onPlayAgain: actions.onPrimary,
      secondaryLabel: actions.secondaryLabel,
      onBack: actions.onSecondary,
    );
  }

  String _subtitle(AppLocalizations l10n) {
    final mode = switch (widget.mode) {
      MoveTrainerMode.practice => l10n.practice,
      MoveTrainerMode.speed => l10n.speedRound,
    };
    return widget.isHardMode ? '$mode · ${l10n.playAsBlack}' : mode;
  }

  Widget _buildBoard(MoveGameState gameState, double boardSize) {
    final puzzle = gameState.currentPuzzle;
    final fen = gameState.displayFen;

    if (gameState.isLoading || puzzle == null || fen == null) {
      return SizedBox(
        width: boardSize,
        height: boardSize,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final orientation = widget.isHardMode ? Side.black : Side.white;

    final isInteractive =
        !gameState.isWaitingForNext && !gameState.isGameOver;

    final validMoves = isInteractive
        ? makeLegalMoves(puzzle.position)
        : const IMapConst<Square, ISet<Square>>({});

    final board = Chessboard(
      size: boardSize,
      orientation: orientation,
      fen: fen,
      lastMove: gameState.lastFeedback == null ? gameState.lastSetupMove : null,
      settings: AppBoard.settings(
        animationDuration: const Duration(milliseconds: 250),
        showValidMoves: isInteractive,
        autoQueenPromotion: true,
      ),
      game: GameData(
        playerSide: orientation == Side.white
            ? PlayerSide.white
            : PlayerSide.black,
        // Side to move and check come from the position on screen, which
        // differs from the puzzle position once a correct answer is played.
        sideToMove: gameState.sideToMove ?? Side.white,
        validMoves: validMoves,
        isCheck: gameState.isCheck,
        promotionMove: null,
        onMove: (move, {bool? viaDragAndDrop}) {
          if (move is NormalMove) {
            ref.read(moveGameProvider.notifier).handleMove(move);
          }
        },
        onPromotionSelection: (_) {},
      ),
      shapes: gameState.feedbackShapes,
      squareHighlights: gameState.squareHighlights,
    );

    final labels = _buildMoveLabels(gameState);
    if (labels.isEmpty) return board;
    return Stack(
      children: [
        board,
        SquareNameOverlay(
          boardSize: boardSize,
          orientation: orientation,
          labels: labels,
        ),
      ],
    );
  }

  List<SquareLabel> _buildMoveLabels(MoveGameState gameState) {
    final feedback = gameState.lastFeedback;
    if (feedback == null) return const [];

    final labels = <SquareLabel>[];
    final isCorrect = feedback.result == MoveFeedbackResult.correct;

    if (isCorrect) {
      labels.add(SquareLabel(
        file: feedback.correctMove.to.file,
        rank: feedback.correctMove.to.rank,
        name: feedback.correctMove.to.name,
        color: AppColors.correctGreen.withValues(alpha: 0.9),
      ));
    } else {
      if (feedback.attemptedMove != null &&
          feedback.attemptedMove!.to != feedback.correctMove.to) {
        labels.add(SquareLabel(
          file: feedback.attemptedMove!.to.file,
          rank: feedback.attemptedMove!.to.rank,
          name: feedback.attemptedMove!.to.name,
          color: AppColors.incorrectRed.withValues(alpha: 0.9),
        ));
      }
      labels.add(SquareLabel(
        file: feedback.correctMove.to.file,
        rank: feedback.correctMove.to.rank,
        name: feedback.correctMove.to.name,
        color: AppColors.correctGreen.withValues(alpha: 0.9),
      ));
    }

    return labels;
  }
}
