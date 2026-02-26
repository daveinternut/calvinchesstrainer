import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import '../../../core/constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/square_name_overlay.dart';
import '../models/file_rank_game_state.dart';
import '../providers/file_rank_game_provider.dart';
import '../widgets/prompt_display.dart';
import '../widgets/streak_counter.dart';
import '../widgets/timer_bar.dart';
import '../widgets/results_card.dart';

class FileRankGameScreen extends ConsumerStatefulWidget {
  final TrainerSubject subject;
  final TrainerMode mode;
  final bool isHardMode;

  const FileRankGameScreen({
    super.key,
    required this.subject,
    required this.mode,
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
          onPressed: () => context.pop(),
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
                          final orientation =
                              widget.isHardMode ? Side.black : Side.white;
                          final board = Chessboard.fixed(
                            size: boardSize,
                            orientation: orientation,
                            fen: kInitialBoardFEN,
                            settings: ChessboardSettings(
                              enableCoordinates: false,
                              colorScheme: ChessboardColorScheme.green,
                              pieceAssets: PieceSet.cburnett.assets,
                              animationDuration:
                                  const Duration(milliseconds: 200),
                            ),
                            squareHighlights: gameState.allHighlights,
                            onTouchedSquare: (square) {
                              ref
                                  .read(fileRankGameProvider.notifier)
                                  .handleBoardTap(
                                    square.file,
                                    square.rank,
                                  );
                            },
                          );
                          final labels = _buildSquareLabels(gameState);
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
                          isHardMode: widget.isHardMode,
                        );
                  },
                  onBack: () => context.pop(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<SquareLabel> _buildSquareLabels(FileRankGameState gameState) {
    if (gameState.subject != TrainerSubject.squares ||
        gameState.lastFeedback == null) {
      return const [];
    }

    final feedback = gameState.lastFeedback!;
    if (feedback.tappedRankIndex == null) return const [];

    final labels = <SquareLabel>[];
    final isCorrect = feedback.result == AnswerResult.correct;

    labels.add(SquareLabel(
      file: feedback.tappedIndex,
      rank: feedback.tappedRankIndex!,
      name: ChessConstants.squareName(
        feedback.tappedIndex,
        feedback.tappedRankIndex!,
      ),
      color: isCorrect
          ? AppColors.correctGreen.withValues(alpha: 0.85)
          : AppColors.incorrectRed.withValues(alpha: 0.85),
    ));

    if (!isCorrect && feedback.correctRankIndex != null) {
      labels.add(SquareLabel(
        file: feedback.correctIndex,
        rank: feedback.correctRankIndex!,
        name: ChessConstants.squareName(
          feedback.correctIndex,
          feedback.correctRankIndex!,
        ),
        color: AppColors.correctGreen.withValues(alpha: 0.85),
      ));
    }

    return labels;
  }

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
