import 'dart:math' as math;

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../file_rank_trainer/widgets/streak_counter.dart';
import '../../file_rank_trainer/widgets/timer_bar.dart';
import '../../file_rank_trainer/widgets/results_card.dart';
import '../models/move_game_state.dart';
import '../providers/move_game_provider.dart';
import '../widgets/move_prompt_display.dart';

class MoveGameScreen extends ConsumerStatefulWidget {
  final MoveTrainerMode mode;
  final bool isHardMode;

  const MoveGameScreen({
    super.key,
    required this.mode,
    this.isHardMode = false,
  });

  @override
  ConsumerState<MoveGameScreen> createState() => _MoveGameScreenState();
}

class _MoveGameScreenState extends ConsumerState<MoveGameScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(moveGameProvider.notifier).startGame(
            widget.mode,
            isHardMode: widget.isHardMode,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(moveGameProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(_menuRoute),
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
                  const SizedBox(height: 12),
                  MovePromptDisplay(gameState: gameState),
                  const SizedBox(height: 12),
                  StreakCounter(
                    streak: gameState.streak,
                    bestStreak: gameState.bestStreak,
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Center(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final boardSize = math.min(
                            constraints.maxWidth,
                            constraints.maxHeight,
                          );
                          return _buildBoard(gameState, boardSize);
                        },
                      ),
                    ),
                  ),
                  if (gameState.mode == MoveTrainerMode.speed &&
                      gameState.timeRemainingSeconds != null) ...[
                    const SizedBox(height: 12),
                    TimerBar(
                      remainingSeconds: gameState.timeRemainingSeconds!,
                    ),
                  ],
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
                      ref.read(moveGameProvider.notifier).isNewRecord,
                  onPlayAgain: () {
                    ref.read(moveGameProvider.notifier).startGame(
                          widget.mode,
                          isHardMode: widget.isHardMode,
                        );
                  },
                  onBack: () => context.go(_menuRoute),
                ),
              ),
          ],
        ),
      ),
    );
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

    final orientation =
        gameState.sideToMove == Side.white ? Side.white : Side.black;

    final isInteractive =
        !gameState.isWaitingForNext && !gameState.isGameOver;

    final validMoves = isInteractive
        ? makeLegalMoves(puzzle.position)
        : const IMapConst<Square, ISet<Square>>({});

    return Chessboard(
      size: boardSize,
      orientation: orientation,
      fen: fen,
      lastMove: gameState.lastFeedback == null ? gameState.lastSetupMove : null,
      settings: ChessboardSettings(
        enableCoordinates: !widget.isHardMode,
        colorScheme: ChessboardColorScheme.green,
        pieceAssets: PieceSet.cburnett.assets,
        animationDuration: const Duration(milliseconds: 250),
        showValidMoves: isInteractive,
        showLastMove: true,
        autoQueenPromotion: true,
      ),
      game: GameData(
        playerSide: orientation == Side.white
            ? PlayerSide.white
            : PlayerSide.black,
        sideToMove: gameState.sideToMove ?? Side.white,
        validMoves: validMoves,
        isCheck: puzzle.position.isCheck,
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
  }

  String get _menuRoute =>
      '/move-trainer'
      '?mode=${widget.mode.name}'
      '&hardMode=${widget.isHardMode}';

  String get _title {
    final mode = switch (widget.mode) {
      MoveTrainerMode.practice => 'Practice',
      MoveTrainerMode.speed => 'Speed Round',
    };
    return 'Moves - $mode';
  }
}
