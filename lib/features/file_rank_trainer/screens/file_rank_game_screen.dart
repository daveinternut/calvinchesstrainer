import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import '../models/file_rank_game_state.dart';
import '../providers/file_rank_game_provider.dart';
import '../widgets/prompt_display.dart';
import '../widgets/streak_counter.dart';
import '../widgets/timer_bar.dart';
import '../widgets/results_card.dart';
import '../widgets/answer_buttons.dart';

class FileRankGameScreen extends ConsumerStatefulWidget {
  final TrainerSubject subject;
  final TrainerMode mode;
  final bool isReverse;
  final bool isHardMode;

  const FileRankGameScreen({
    super.key,
    required this.subject,
    required this.mode,
    this.isReverse = false,
    this.isHardMode = false,
  });

  @override
  ConsumerState<FileRankGameScreen> createState() => _FileRankGameScreenState();
}

class _FileRankGameScreenState extends ConsumerState<FileRankGameScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(fileRankGameProvider.notifier).startGame(
            widget.subject,
            widget.mode,
            widget.isReverse,
            isHardMode: widget.isHardMode,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(fileRankGameProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(_menuRoute),
        ),
        actions: [
          if (gameState.mode != TrainerMode.explore)
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
                  PromptDisplay(gameState: gameState),
                  const SizedBox(height: 12),
                  if (gameState.mode != TrainerMode.explore)
                    StreakCounter(
                      streak: gameState.streak,
                      bestStreak: gameState.bestStreak,
                    ),
                  if (gameState.mode != TrainerMode.explore)
                    const SizedBox(height: 12),
                  Expanded(
                    child: Center(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final boardSize = math.min(
                            constraints.maxWidth,
                            constraints.maxHeight,
                          );
                          return Chessboard.fixed(
                            size: boardSize,
                            orientation: Side.white,
                            fen: kInitialBoardFEN,
                            settings: ChessboardSettings(
                              enableCoordinates: !widget.isHardMode,
                              colorScheme: ChessboardColorScheme.green,
                              pieceAssets: PieceSet.cburnett.assets,
                              animationDuration:
                                  const Duration(milliseconds: 200),
                            ),
                            squareHighlights: gameState.allHighlights,
                            onTouchedSquare: gameState.isReverse
                                ? null
                                : (square) {
                                    ref
                                        .read(fileRankGameProvider.notifier)
                                        .handleBoardTap(
                                          square.file,
                                          square.rank,
                                        );
                                  },
                          );
                        },
                      ),
                    ),
                  ),
                  if (gameState.mode == TrainerMode.speed &&
                      gameState.timeRemainingSeconds != null) ...[
                    const SizedBox(height: 12),
                    TimerBar(
                      remainingSeconds: gameState.timeRemainingSeconds!,
                    ),
                  ],
                  if (gameState.isReverse &&
                      gameState.mode != TrainerMode.explore) ...[
                    const SizedBox(height: 16),
                    AnswerButtons(
                      isFile: gameState.currentPromptIsFile,
                      feedback: gameState.lastFeedback,
                      onTap: (index) {
                        ref
                            .read(fileRankGameProvider.notifier)
                            .handleAnswerButtonTap(index);
                      },
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
                      ref.read(fileRankGameProvider.notifier).isNewRecord,
                  onPlayAgain: () {
                    ref.read(fileRankGameProvider.notifier).startGame(
                          widget.subject,
                          widget.mode,
                          widget.isReverse,
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

  String get _menuRoute =>
      '/file-rank-trainer'
      '?subject=${widget.subject.name}'
      '&mode=${widget.mode.name}'
      '&reverse=${widget.isReverse}'
      '&hardMode=${widget.isHardMode}';

  String get _title {
    final subject = switch (widget.subject) {
      TrainerSubject.files => 'Files',
      TrainerSubject.ranks => 'Ranks',
      TrainerSubject.squares => 'Squares',
      TrainerSubject.moves => 'Moves',
    };
    final mode = switch (widget.mode) {
      TrainerMode.explore => 'Explore',
      TrainerMode.practice => 'Practice',
      TrainerMode.speed => 'Speed Round',
    };
    return '$subject - $mode';
  }
}
