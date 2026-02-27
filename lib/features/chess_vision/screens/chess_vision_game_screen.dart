import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart' show Piece, Side;
import 'package:fast_immutable_collections/fast_immutable_collections.dart';

import '../../../core/audio/audio_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../file_rank_trainer/widgets/streak_counter.dart';
import '../../file_rank_trainer/widgets/timer_bar.dart';
import '../../file_rank_trainer/widgets/results_card.dart';
import '../models/chess_vision_state.dart';
import '../providers/chess_vision_provider.dart';
import '../widgets/found_progress_indicator.dart';

class ChessVisionGameScreen extends ConsumerStatefulWidget {
  final VisionDrillType drill;
  final WhitePiece piece;
  final TargetPiece target;
  final VisionMode mode;

  const ChessVisionGameScreen({
    super.key,
    required this.drill,
    required this.piece,
    this.target = TargetPiece.rook,
    required this.mode,
  });

  @override
  ConsumerState<ChessVisionGameScreen> createState() =>
      _ChessVisionGameScreenState();
}

class _ChessVisionGameScreenState
    extends ConsumerState<ChessVisionGameScreen> {
  late final AudioService _audioService;

  @override
  void initState() {
    super.initState();
    _audioService = ref.read(audioServiceProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chessVisionProvider.notifier).startGame(
            widget.drill,
            widget.mode,
            widget.piece,
            targetPiece: widget.target,
          );
    });
  }

  @override
  void dispose() {
    _audioService.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(chessVisionProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                _scoreText(gameState),
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
                  _buildProgressArea(gameState),
                  const SizedBox(height: 8),
                  StreakCounter(
                    streak: gameState.streak,
                    bestStreak: gameState.bestStreak,
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Center(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final boardSize = math.min(
                            constraints.maxWidth,
                            constraints.maxHeight,
                          );
                          final pieceAssets = PieceSet.cburnett.assets;
                          return Chessboard.fixed(
                            size: boardSize,
                            orientation: Side.white,
                            fen: gameState.boardFen,
                            settings: ChessboardSettings(
                              enableCoordinates: true,
                              colorScheme: ChessboardColorScheme.green,
                              pieceAssets: pieceAssets,
                              animationDuration:
                                  const Duration(milliseconds: 200),
                            ),
                            squareHighlights: gameState.allHighlights,
                            shapes: _buildShapes(gameState, pieceAssets),
                            onTouchedSquare: (square) {
                              ref
                                  .read(chessVisionProvider.notifier)
                                  .handleBoardTap(square);
                            },
                          );
                        },
                      ),
                    ),
                  ),
                  if (_showNoneButton) ...[
                    const SizedBox(height: 12),
                    _buildNoneButton(gameState),
                  ],
                  if (_showFlightRetryButtons(gameState)) ...[
                    const SizedBox(height: 12),
                    _buildFlightRetryButtons(),
                  ],
                  if (widget.drill != VisionDrillType.pawnAttack &&
                      widget.mode == VisionMode.speed &&
                      gameState.timeRemainingSeconds != null) ...[
                    const SizedBox(height: 12),
                    TimerBar(
                      remainingSeconds: gameState.timeRemainingSeconds!,
                      totalSeconds: 60,
                    ),
                  ],
                  if (widget.mode == VisionMode.concentric) ...[
                    const SizedBox(height: 12),
                    _buildConcentricProgress(gameState),
                  ],
                  if (widget.drill == VisionDrillType.pawnAttack &&
                      widget.mode == VisionMode.speed) ...[
                    const SizedBox(height: 12),
                    _buildPawnAttackStopwatch(gameState),
                  ],
                  const SizedBox(height: 16),
                ],
              ),
            ),
            if (gameState.isGameOver)
              Container(
                color: Colors.black54,
                child: _buildResultsOverlay(gameState),
              ),
          ],
        ),
      ),
    );
  }

  bool get _showNoneButton =>
      widget.drill == VisionDrillType.forksAndSkewers &&
      widget.mode != VisionMode.concentric;

  bool _showFlightRetryButtons(ChessVisionState gameState) {
    if (widget.drill != VisionDrillType.knightFlight) return false;
    if (!gameState.flightComplete) return false;
    final isOptimal = gameState.flightPath.length == gameState.minimumMoves;
    return !isOptimal;
  }

  Widget _buildFlightRetryButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () =>
                ref.read(chessVisionProvider.notifier).retryFlight(),
            icon: const Icon(Icons.replay_rounded, size: 20),
            label: const Text('Retry'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            onPressed: () =>
                ref.read(chessVisionProvider.notifier).skipFlight(),
            icon: const Icon(Icons.skip_next_rounded, size: 20),
            label: const Text('Skip'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- Progress area ---

  Widget _buildProgressArea(ChessVisionState gameState) {
    switch (widget.drill) {
      case VisionDrillType.forksAndSkewers:
      case VisionDrillType.knightSight:
        return FoundProgressIndicator(
          totalCorrect: gameState.totalCorrect,
          totalFound: gameState.totalFound,
          showNoneHint: widget.drill == VisionDrillType.forksAndSkewers &&
              !gameState.isRoundComplete &&
              !gameState.showingRevealedAnswer,
        );
      case VisionDrillType.knightFlight:
        return _buildFlightProgress(gameState);
      case VisionDrillType.pawnAttack:
        return _buildPawnAttackProgress(gameState);
    }
  }

  Widget _buildFlightProgress(ChessVisionState gameState) {
    final min = gameState.minimumMoves ?? 0;
    final current = gameState.flightPath.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Minimum: $min',
            style: TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 24),
          Text(
            'Your moves: $current',
            style: TextStyle(
              fontSize: 15,
              color: current > min
                  ? AppColors.incorrectRed
                  : AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPawnAttackProgress(ChessVisionState gameState) {
    final remaining = gameState.remainingPawns.length;
    final difficulty = gameState.pawnAttackDifficulty;
    final isTimed = widget.mode == VisionMode.speed;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Pawns: $remaining',
            style: TextStyle(
              fontSize: 15,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (isTimed) ...[
            const SizedBox(width: 24),
            Text(
              'Level $difficulty of 8',
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(width: 24),
          Text(
            'Moves: ${gameState.pawnAttackMoves}',
            style: TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // --- Shapes ---

  ISet<Shape> _buildShapes(ChessVisionState gameState, PieceAssets pieceAssets) {
    switch (widget.drill) {
      case VisionDrillType.forksAndSkewers:
        return _buildForkShapes(gameState, pieceAssets);
      case VisionDrillType.knightSight:
        return _buildKnightSightShapes(gameState, pieceAssets);
      case VisionDrillType.knightFlight:
        return _buildKnightFlightShapes(gameState, pieceAssets);
      case VisionDrillType.pawnAttack:
        return const ISetConst({});
    }
  }

  ISet<Shape> _buildForkShapes(
      ChessVisionState gameState, PieceAssets pieceAssets) {
    final shapes = <Shape>{};
    final whitePiece = Piece(color: Side.white, role: widget.piece.role);
    for (final sq in gameState.foundSquares) {
      shapes.add(PieceShape(
        piece: whitePiece,
        orig: sq,
        pieceAssets: pieceAssets,
        opacity: 0.45,
        scale: 0.9,
      ));
    }
    if (gameState.showingRevealedAnswer) {
      for (final sq in gameState.correctSquares) {
        if (!gameState.foundSquares.contains(sq)) {
          shapes.add(PieceShape(
            piece: whitePiece,
            orig: sq,
            pieceAssets: pieceAssets,
            opacity: 0.35,
            scale: 0.9,
          ));
        }
      }
    }
    return ISet(shapes);
  }

  ISet<Shape> _buildKnightSightShapes(
      ChessVisionState gameState, PieceAssets pieceAssets) {
    final shapes = <Shape>{};
    for (final sq in gameState.foundSquares) {
      shapes.add(PieceShape(
        piece: Piece.whiteKnight,
        orig: sq,
        pieceAssets: pieceAssets,
        opacity: 0.4,
        scale: 0.85,
      ));
    }
    return ISet(shapes);
  }

  ISet<Shape> _buildKnightFlightShapes(
      ChessVisionState gameState, PieceAssets pieceAssets) {
    final shapes = <Shape>{};

    final target = gameState.flightTargetSquare;
    if (target != null) {
      shapes.add(PieceShape(
        piece: Piece.whiteKnight,
        orig: target,
        pieceAssets: pieceAssets,
        opacity: 0.3,
        scale: 0.85,
      ));
    }

    final path = gameState.flightPath;
    final start = gameState.knightSquare;
    if (start == null) return ISet(shapes);

    const arrowColor = Color(0xCC4CAF50);

    if (path.isNotEmpty) {
      shapes.add(Arrow(
        color: arrowColor,
        orig: start,
        dest: path.first,
        scale: 0.5,
      ));
    }

    for (int i = 0; i < path.length - 1; i++) {
      shapes.add(Arrow(
        color: arrowColor,
        orig: path[i],
        dest: path[i + 1],
        scale: 0.5,
      ));
    }

    for (int i = 0; i < path.length - (gameState.flightComplete ? 0 : 1); i++) {
      if (path[i] != target) {
        shapes.add(PieceShape(
          piece: Piece.whiteKnight,
          orig: path[i],
          pieceAssets: pieceAssets,
          opacity: 0.25,
          scale: 0.7,
        ));
      }
    }

    return ISet(shapes);
  }

  // --- None button ---

  Widget _buildNoneButton(ChessVisionState gameState) {
    final enabled = !gameState.isGameOver &&
        !gameState.isRoundComplete &&
        !gameState.showingRevealedAnswer;

    return SizedBox(
      height: 48,
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: enabled
            ? () => ref.read(chessVisionProvider.notifier).handleNoneTap()
            : null,
        icon: const Icon(Icons.block_rounded, size: 20),
        label: const Text('None'),
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          side: BorderSide(
            color: enabled ? AppColors.textSecondary : Colors.grey.shade300,
          ),
          foregroundColor: AppColors.textPrimary,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // --- Pawn Attack stopwatch ---

  Widget _buildPawnAttackStopwatch(ChessVisionState gameState) {
    final minutes = gameState.elapsedSeconds ~/ 60;
    final seconds = gameState.elapsedSeconds % 60;
    final timeStr = '$minutes:${seconds.toString().padLeft(2, '0')}';
    final difficulty = gameState.pawnAttackDifficulty;
    final progress = (difficulty - 3) / 6;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Level $difficulty of 8',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              timeStr,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: Colors.grey.shade200,
            valueColor:
                const AlwaysStoppedAnimation<Color>(Color(0xFFE65100)),
          ),
        ),
      ],
    );
  }

  // --- Concentric progress ---

  Widget _buildConcentricProgress(ChessVisionState gameState) {
    final total = ref.read(chessVisionProvider.notifier).concentricTotal;
    final progress = total > 0 ? gameState.concentricIndex / total : 0.0;
    final minutes = gameState.elapsedSeconds ~/ 60;
    final seconds = gameState.elapsedSeconds % 60;
    final timeStr = '$minutes:${seconds.toString().padLeft(2, '0')}';

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Position ${gameState.concentricIndex} of $total',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              timeStr,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: Colors.grey.shade200,
            valueColor:
                const AlwaysStoppedAnimation<Color>(Color(0xFF6A1B9A)),
          ),
        ),
      ],
    );
  }

  // --- Results ---

  Widget _buildResultsOverlay(ChessVisionState gameState) {
    if (widget.mode == VisionMode.concentric) {
      return _buildConcentricResults(gameState);
    }

    if (widget.drill == VisionDrillType.pawnAttack &&
        widget.mode == VisionMode.speed) {
      return _buildPawnAttackTimedResults(gameState);
    }

    return ResultsCard(
      totalCorrect: gameState.configurationsCompleted,
      totalAttempts: gameState.configurationsCompleted + gameState.totalErrors,
      bestStreak: gameState.bestStreak,
      isNewRecord: ref.read(chessVisionProvider.notifier).isNewRecord,
      onPlayAgain: _restartGame,
      onBack: () => context.pop(),
    );
  }

  Widget _buildConcentricResults(ChessVisionState gameState) {
    final minutes = gameState.elapsedSeconds ~/ 60;
    final seconds = gameState.elapsedSeconds % 60;
    final timeStr = '$minutes:${seconds.toString().padLeft(2, '0')}';
    final isNew = ref.read(chessVisionProvider.notifier).isNewRecord;

    return Center(
      child: Card(
        margin: const EdgeInsets.all(32),
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isNew) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.correctGreen,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'New Record!',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Text(
                'Drill Complete!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 24),
              _StatRow(label: 'Time', value: timeStr),
              const SizedBox(height: 10),
              _StatRow(label: 'Errors', value: '${gameState.totalErrors}'),
              const SizedBox(height: 10),
              _StatRow(
                  label: 'Best Streak', value: '${gameState.bestStreak}'),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => context.pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Menu'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: _restartGame,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Play Again'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPawnAttackTimedResults(ChessVisionState gameState) {
    final minutes = gameState.elapsedSeconds ~/ 60;
    final seconds = gameState.elapsedSeconds % 60;
    final timeStr = '$minutes:${seconds.toString().padLeft(2, '0')}';
    final isNew = ref.read(chessVisionProvider.notifier).isNewRecord;

    return Center(
      child: Card(
        margin: const EdgeInsets.all(32),
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isNew) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.correctGreen,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'New Record!',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Text(
                'All Clear!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 24),
              _StatRow(label: 'Time', value: timeStr),
              const SizedBox(height: 10),
              _StatRow(label: 'Errors', value: '${gameState.totalErrors}'),
              const SizedBox(height: 10),
              _StatRow(
                  label: 'Rounds', value: '${gameState.configurationsCompleted}'),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => context.pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Menu'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: _restartGame,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Play Again'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _restartGame() {
    ref.read(chessVisionProvider.notifier).startGame(
          widget.drill,
          widget.mode,
          widget.piece,
          targetPiece: widget.target,
        );
  }

  // --- Title & score ---

  String get _title {
    switch (widget.drill) {
      case VisionDrillType.forksAndSkewers:
        final pieceName = widget.piece.label;
        final modeName = switch (widget.mode) {
          VisionMode.practice => 'Practice',
          VisionMode.speed => 'Speed Round',
          VisionMode.concentric => 'Concentric',
        };
        return '$pieceName \u2014 $modeName';
      case VisionDrillType.knightSight:
        return 'Knight Sight';
      case VisionDrillType.knightFlight:
        return 'Knight Flight';
      case VisionDrillType.pawnAttack:
        final pieceName = widget.piece.label;
        final modeName =
            widget.mode == VisionMode.speed ? 'Timed' : 'Practice';
        return 'Pawn Attack \u2014 $pieceName $modeName';
    }
  }

  String _scoreText(ChessVisionState gameState) {
    if (widget.mode == VisionMode.concentric) {
      final total = ref.read(chessVisionProvider.notifier).concentricTotal;
      return '${gameState.configurationsCompleted}/$total';
    }
    if (widget.drill == VisionDrillType.pawnAttack &&
        widget.mode == VisionMode.speed) {
      return '${gameState.configurationsCompleted}/6';
    }
    return '${gameState.configurationsCompleted} solved';
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
