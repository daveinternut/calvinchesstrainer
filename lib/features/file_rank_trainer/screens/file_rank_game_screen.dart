import 'package:flutter/material.dart';
import 'package:calvinchesstrainer/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import '../../../core/audio/audio_service.dart';
import '../../../core/audio/sound_switch.dart';
import '../../../core/constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/board_theme.dart';
import '../../../core/ui/board_frame.dart';
import '../../../core/ui/components.dart';
import '../../../core/widgets/square_name_overlay.dart';
import '../../../core/widgets/trainer_layout.dart';
import '../../drills/warmup_actions.dart';
import '../models/file_rank_game_state.dart';
import '../providers/file_rank_game_provider.dart';
import '../widgets/prompt_display.dart';
import '../widgets/milestone_banner.dart';
import '../widgets/streak_counter.dart';
import '../widgets/timer_bar.dart';
import '../widgets/results_card.dart';

class FileRankGameScreen extends ConsumerStatefulWidget {
  final TrainerSubject subject;
  final TrainerMode mode;
  final bool isHardMode;

  /// A step of the daily warm-up (the results then move on to the next).
  final bool warmup;

  const FileRankGameScreen({
    super.key,
    required this.subject,
    required this.mode,
    this.isHardMode = false,
    this.warmup = false,
  });

  @override
  ConsumerState<FileRankGameScreen> createState() => _FileRankGameScreenState();
}

class _FileRankGameScreenState extends ConsumerState<FileRankGameScreen> {
  late final AudioService _audioService;

  @override
  void initState() {
    super.initState();
    _audioService = ref.read(audioServiceProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) => _startGame());
  }

  void _startGame() {
    ref.read(fileRankGameProvider.notifier).startGame(
          widget.subject,
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
    final gameState = ref.watch(fileRankGameProvider);
    final isExplore = gameState.mode == TrainerMode.explore;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            TrainerLayout(
              topBar: PlayTopBar(
                title: _title(l10n),
                subtitle: warmupSubtitle(ref, l10n, widget.warmup) ??
                    _subtitle(l10n),
                onClose: () => closeDrill(context),
                closeTooltip: l10n.endDrill,
                trailing: isExplore
                    ? null
                    : Text('${gameState.totalCorrect}/${gameState.totalAttempts}'),
                action: const SoundButton(),
              ),
              header: [
                const SizedBox(height: 4),
                PromptDisplay(gameState: gameState),
                const SizedBox(height: 8),
                if (!isExplore) ...[
                  StreakCounter(
                    streak: gameState.streak,
                    bestStreak: gameState.bestStreak,
                  ),
                  const SizedBox(height: 8),
                ],
              ],
              // Coordinates stay hidden: naming the squares is the drill.
              board: (context, size) => BoardFrame(
                size: size,
                orientation: widget.isHardMode ? Side.black : Side.white,
                showCoordinates: false,
                builder: (context, boardSize) =>
                    _buildBoard(gameState, boardSize),
              ),
              footer: [
                if (gameState.mode == TrainerMode.speed &&
                    gameState.timeRemainingSeconds != null) ...[
                  const SizedBox(height: 12),
                  TimerBar(remainingSeconds: gameState.timeRemainingSeconds!),
                ],
                const SizedBox(height: 16),
              ],
            ),
            if (!isExplore) MilestoneBanner(streak: gameState.streak),
            if (gameState.isGameOver) Positioned.fill(child: _results(gameState)),
          ],
        ),
      ),
    );
  }

  Widget _results(FileRankGameState gameState) {
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

  Widget _buildBoard(FileRankGameState gameState, double boardSize) {
    final orientation = widget.isHardMode ? Side.black : Side.white;
    final board = Chessboard.fixed(
      size: boardSize,
      orientation: orientation,
      fen: kInitialBoardFEN,
      settings: AppBoard.settings(),
      squareHighlights: gameState.allHighlights,
      onTouchedSquare: (square) {
        ref.read(fileRankGameProvider.notifier).handleBoardTap(
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
  }

  List<SquareLabel> _buildSquareLabels(FileRankGameState gameState) {
    final feedback = gameState.lastFeedback;
    if (feedback == null) return const [];
    if (gameState.subject != TrainerSubject.squares) {
      return gameState.mode == TrainerMode.explore
          ? [_exploreLineLabel(feedback)]
          : const [];
    }
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
          ? AppColors.correctGreen.withValues(alpha: 0.9)
          : AppColors.incorrectRed.withValues(alpha: 0.9),
    ));

    if (!isCorrect && feedback.correctRankIndex != null) {
      labels.add(SquareLabel(
        file: feedback.correctIndex,
        rank: feedback.correctRankIndex!,
        name: ChessConstants.squareName(
          feedback.correctIndex,
          feedback.correctRankIndex!,
        ),
        color: AppColors.correctGreen.withValues(alpha: 0.9),
      ));
    }

    return labels;
  }

  /// Explore files or ranks: the tapped line's name on its edge square, where
  /// the coordinates would be (bottom for a file, left for a rank), so it
  /// reads with the sound off too.
  SquareLabel _exploreLineLabel(AnswerFeedback feedback) {
    final edge = widget.isHardMode ? 7 : 0; // the player's bottom rank / left file
    final line = feedback.tappedIndex;
    final color = AppColors.correctGreen.withValues(alpha: 0.9);
    return feedback.isFile
        ? SquareLabel(
            file: line,
            rank: edge,
            name: ChessConstants.files[line],
            color: color,
          )
        : SquareLabel(
            file: edge,
            rank: line,
            name: ChessConstants.ranks[line],
            color: color,
          );
  }

  String _title(AppLocalizations l10n) => switch (widget.subject) {
        TrainerSubject.files => l10n.files,
        TrainerSubject.ranks => l10n.ranks,
        TrainerSubject.squares => l10n.squares,
        TrainerSubject.moves => l10n.moves,
        TrainerSubject.letters => l10n.letters,
        TrainerSubject.pieceValue => l10n.pieceValue,
      };

  String _subtitle(AppLocalizations l10n) {
    final mode = switch (widget.mode) {
      TrainerMode.explore => l10n.explore,
      TrainerMode.practice => l10n.practice,
      TrainerMode.speed => l10n.speedRound,
    };
    return widget.isHardMode ? '$mode · ${l10n.playAsBlack}' : mode;
  }
}
