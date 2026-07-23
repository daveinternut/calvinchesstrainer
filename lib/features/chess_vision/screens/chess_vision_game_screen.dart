import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:calvinchesstrainer/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart'
    show NormalMove, Piece, Side, Square, makeLegalMoves;
import 'package:fast_immutable_collections/fast_immutable_collections.dart';

import '../../../core/audio/audio_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/square_name_overlay.dart';
import '../../file_rank_trainer/widgets/milestone_banner.dart';
import '../../file_rank_trainer/widgets/streak_counter.dart';
import '../../file_rank_trainer/widgets/timer_bar.dart';
import '../../file_rank_trainer/widgets/results_card.dart';
import '../models/chess_vision_state.dart';
import '../providers/chess_vision_provider.dart';
import '../services/knight_engine.dart';
import '../services/pawn_attack_engine.dart';
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
    final l10n = AppLocalizations.of(context)!;
    final gameState = ref.watch(chessVisionProvider);

    return Scaffold(
      appBar: AppBar(
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(_title),
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
                _scoreText(gameState, l10n),
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
                  _buildProgressArea(gameState, l10n),
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
                          return _buildBoard(
                              gameState, boardSize, pieceAssets);
                        },
                      ),
                    ),
                  ),
                  if (_showNoneButton) ...[
                    const SizedBox(height: 12),
                    _buildNoneButton(gameState, l10n),
                  ],
                  if (widget.drill.isTapScanDrill) ...[
                    const SizedBox(height: 12),
                    _buildScanSkipButton(gameState, l10n),
                  ],
                  if (_showFlightRetryButtons(gameState)) ...[
                    const SizedBox(height: 12),
                    _buildFlightRetryButtons(l10n),
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
                    _buildConcentricProgress(gameState, l10n),
                  ],
                  if (widget.drill == VisionDrillType.pawnAttack &&
                      widget.mode == VisionMode.speed) ...[
                    const SizedBox(height: 12),
                    _buildPawnAttackStopwatch(gameState, l10n),
                  ],
                  const SizedBox(height: 16),
                ],
              ),
            ),
            MilestoneBanner(streak: gameState.streak),
            if (gameState.isGameOver)
              Container(
                color: Colors.black54,
                child: _buildResultsOverlay(gameState, l10n),
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

  Widget _buildFlightRetryButtons(AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () =>
                ref.read(chessVisionProvider.notifier).retryFlight(),
            icon: const Icon(Icons.replay_rounded, size: 20),
            label: Text(l10n.retry),
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
            label: Text(l10n.skip),
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

  Widget _buildProgressArea(
      ChessVisionState gameState, AppLocalizations l10n) {
    switch (widget.drill) {
      case VisionDrillType.forksAndSkewers:
      case VisionDrillType.knightSight:
        return FoundProgressIndicator(
          totalCorrect: gameState.totalCorrect,
          totalFound: gameState.totalFound,
          showNoneHint: widget.drill == VisionDrillType.forksAndSkewers &&
              !gameState.isRoundComplete &&
              !gameState.showingRevealedAnswer,
          l10n: l10n,
        );
      case VisionDrillType.knightFlight:
        return _buildFlightProgress(gameState, l10n);
      case VisionDrillType.pawnAttack:
        return _buildPawnAttackProgress(gameState, l10n);
      case VisionDrillType.findChecks:
      case VisionDrillType.findCaptures:
      case VisionDrillType.hangingPieces:
        // The three tap drills render visually identical real positions —
        // only this prompt tells the kid which question is being asked.
        return Column(
          children: [
            _buildSideToPlayBadge(gameState, l10n),
            const SizedBox(height: 4),
            _buildScanPrompt(l10n),
            const SizedBox(height: 4),
            if (gameState.isRoundComplete)
              SizedBox(
                height: 36,
                child: Center(
                  child: Text(
                    l10n.allClear,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.correctGreen,
                    ),
                  ),
                ),
              )
            else
              FoundProgressIndicator(
                totalCorrect: gameState.totalCorrect,
                totalFound: gameState.totalFound,
                l10n: l10n,
              ),
          ],
        );
      case VisionDrillType.mateInOne:
        return Column(
          children: [
            _buildSideToPlayBadge(gameState, l10n),
            const SizedBox(height: 4),
            _buildScanPrompt(l10n),
          ],
        );
    }
  }

  /// "White to play" / "Black to play" pill — real positions come with
  /// either side to move (and the board flips to match), so the mover must
  /// be unmistakable the moment the position loads.
  Widget _buildSideToPlayBadge(
      ChessVisionState gameState, AppLocalizations l10n) {
    // Fixed height so the layout doesn't jump when the position arrives.
    if (gameState.isLoading || gameState.scanDisplayFen == null) {
      return const SizedBox(height: 26);
    }
    final isWhite = gameState.scanSideToMove == Side.white;
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isWhite ? Colors.white : Colors.grey.shade900,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: isWhite ? Colors.white : Colors.black,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade600),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isWhite ? l10n.whiteToPlay : l10n.blackToPlay,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isWhite ? AppColors.textPrimary : Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanPrompt(AppLocalizations l10n) {
    final prompt = switch (widget.drill) {
      VisionDrillType.findChecks => l10n.scanPromptChecks,
      VisionDrillType.findCaptures => l10n.scanPromptCaptures,
      VisionDrillType.hangingPieces => l10n.scanPromptHanging,
      VisionDrillType.mateInOne => l10n.scanPromptMate,
      _ => '',
    };
    return Text(
      prompt,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _buildScanSkipButton(
      ChessVisionState gameState, AppLocalizations l10n) {
    final enabled = !gameState.isGameOver &&
        !gameState.isRoundComplete &&
        !gameState.showingRevealedAnswer &&
        !gameState.isLoading;

    return SizedBox(
      height: 48,
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: enabled
            ? () => ref.read(chessVisionProvider.notifier).skipScanPosition()
            : null,
        icon: const Icon(Icons.skip_next_rounded, size: 20),
        label: Text(l10n.skip),
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

  Widget _buildFlightProgress(
      ChessVisionState gameState, AppLocalizations l10n) {
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
            l10n.minimumMoves(min),
            style: TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 24),
          Text(
            l10n.yourMoves(current),
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

  Widget _buildPawnAttackProgress(
      ChessVisionState gameState, AppLocalizations l10n) {
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
            l10n.pawnsRemaining(remaining),
            style: TextStyle(
              fontSize: 15,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (isTimed) ...[
            const SizedBox(width: 24),
            Text(
              l10n.levelOfEight(difficulty),
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(width: 24),
          Text(
            l10n.movesCount(gameState.pawnAttackMoves),
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

  Widget _buildBoard(
      ChessVisionState gameState, double boardSize, PieceAssets pieceAssets) {
    final drill = widget.drill;

    void onTap(Square square) =>
        ref.read(chessVisionProvider.notifier).handleBoardTap(square);

    // Mate in 1 plays a real move on an interactive board (move-trainer
    // machinery); the three tap scanning drills fall through to the fixed
    // board below with a loading guard.
    if (drill == VisionDrillType.mateInOne) {
      return _buildMateBoard(gameState, boardSize, pieceAssets);
    }
    if (drill.isTapScanDrill &&
        (gameState.isLoading || gameState.scanDisplayFen == null)) {
      return SizedBox(
        width: boardSize,
        height: boardSize,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    // Knight Flight and Pawn Attack move a single piece, so they use the
    // INTERACTIVE board wired for THREE input styles at once:
    //   • 1-tap — tap a destination square directly (onTouchedSquare), even on
    //     the first move, matching the original drill feel;
    //   • tap-to-select then tap a destination, and
    //   • drag-and-drop  (both via GameData + validMoves).
    // The move handlers no-op on a tap of the piece's own square, so the extra
    // callback a select/drag fires alongside onTouchedSquare can't double-count.
    // Forks & Skewers and Knight Sight mark arbitrary squares (no piece to
    // move), so they stay on the tap-anywhere fixed board.
    final movesAPiece = drill == VisionDrillType.knightFlight ||
        drill == VisionDrillType.pawnAttack;

    if (movesAPiece) {
      final current = drill == VisionDrillType.knightFlight
          ? (gameState.flightPath.isNotEmpty
              ? gameState.flightPath.last
              : gameState.knightSquare)
          : gameState.pieceSquare;
      final stillPlaying = drill == VisionDrillType.knightFlight
          ? !gameState.flightComplete
          : (!gameState.isRoundComplete && !gameState.isGameOver);
      final canMove = current != null && stillPlaying;

      ISet<Square> destsFrom(Square from) =>
          drill == VisionDrillType.knightFlight
              ? ISet(KnightEngine.knightMoves(from))
              : ISet(PawnAttackEngine.validMoves(
                  role: gameState.whitePiece.role,
                  from: from,
                  remainingPawns: gameState.remainingPawns,
                ));

      final validMoves = (current != null && canMove)
          ? IMap<Square, ISet<Square>>({current: destsFrom(current)})
          : const IMapConst<Square, ISet<Square>>({});

      // Knight Flight shows its legal hops as dots (a helpful nudge about how a
      // knight moves). Pawn Attack hides them so the player still has to judge
      // which squares are safe — the pawn threats are already flagged in red.
      final showDots = drill == VisionDrillType.knightFlight;

      return Chessboard(
        size: boardSize,
        orientation: Side.white,
        fen: gameState.boardFen,
        settings: ChessboardSettings(
          enableCoordinates: true,
          colorScheme: ChessboardColorScheme.green,
          pieceAssets: pieceAssets,
          animationDuration: const Duration(milliseconds: 200),
          showValidMoves: showDots,
        ),
        squareHighlights: gameState.allHighlights,
        shapes: _buildShapes(gameState, pieceAssets),
        game: GameData(
          playerSide: canMove ? PlayerSide.white : PlayerSide.none,
          sideToMove: Side.white,
          validMoves: validMoves,
          isCheck: false,
          promotionMove: null,
          onMove: (move, {bool? viaDragAndDrop}) {
            if (move is NormalMove) onTap(move.to);
          },
          onPromotionSelection: (_) {},
        ),
        onTouchedSquare: onTap,
      );
    }

    return Chessboard.fixed(
      size: boardSize,
      orientation: gameState.boardOrientation,
      fen: gameState.boardFen,
      settings: ChessboardSettings(
        enableCoordinates: true,
        colorScheme: ChessboardColorScheme.green,
        pieceAssets: pieceAssets,
        animationDuration: const Duration(milliseconds: 200),
      ),
      squareHighlights: gameState.allHighlights,
      shapes: _buildShapes(gameState, pieceAssets),
      onTouchedSquare: onTap,
    );
  }

  Widget _buildMateBoard(
      ChessVisionState gameState, double boardSize, PieceAssets pieceAssets) {
    final puzzle = gameState.currentMatePuzzle;
    final fen = gameState.scanDisplayFen;

    if (gameState.isLoading || puzzle == null || fen == null) {
      return SizedBox(
        width: boardSize,
        height: boardSize,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final orientation = gameState.boardOrientation;
    final isInteractive =
        !gameState.isRoundComplete && !gameState.isGameOver;

    final validMoves = isInteractive
        ? makeLegalMoves(puzzle.position)
        : const IMapConst<Square, ISet<Square>>({});

    final board = Chessboard(
      size: boardSize,
      orientation: orientation,
      fen: fen,
      lastMove: gameState.mateFeedback == null ? puzzle.setupMove : null,
      settings: ChessboardSettings(
        enableCoordinates: true,
        colorScheme: ChessboardColorScheme.green,
        pieceAssets: pieceAssets,
        animationDuration: const Duration(milliseconds: 250),
        showValidMoves: isInteractive,
        showLastMove: true,
        autoQueenPromotion: true,
      ),
      game: GameData(
        playerSide: orientation == Side.white
            ? PlayerSide.white
            : PlayerSide.black,
        sideToMove: gameState.scanSideToMove,
        validMoves: validMoves,
        isCheck: puzzle.position.isCheck,
        promotionMove: null,
        onMove: (move, {bool? viaDragAndDrop}) {
          if (move is NormalMove) {
            ref.read(chessVisionProvider.notifier).handleMateMove(move);
          }
        },
        onPromotionSelection: (_) {},
      ),
      shapes: gameState.mateFeedbackShapes,
      squareHighlights: gameState.allHighlights,
    );

    final labels = _buildMateLabels(gameState);
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

  List<SquareLabel> _buildMateLabels(ChessVisionState gameState) {
    final feedback = gameState.mateFeedback;
    if (feedback == null) return const [];

    final labels = <SquareLabel>[];
    final attempted = feedback.attemptedMove;

    if (feedback.isCorrect) {
      if (attempted != null) {
        labels.add(SquareLabel(
          file: attempted.to.file,
          rank: attempted.to.rank,
          name: attempted.to.name,
          color: AppColors.correctGreen.withValues(alpha: 0.85),
        ));
      }
    } else {
      if (attempted != null && attempted.to != feedback.solutionMove.to) {
        labels.add(SquareLabel(
          file: attempted.to.file,
          rank: attempted.to.rank,
          name: attempted.to.name,
          color: AppColors.incorrectRed.withValues(alpha: 0.85),
        ));
      }
      labels.add(SquareLabel(
        file: feedback.solutionMove.to.file,
        rank: feedback.solutionMove.to.rank,
        name: feedback.solutionMove.to.name,
        color: AppColors.correctGreen.withValues(alpha: 0.85),
      ));
    }

    return labels;
  }

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
      case VisionDrillType.findChecks:
        return _buildCheckGhostShapes(gameState, pieceAssets);
      case VisionDrillType.findCaptures:
      case VisionDrillType.hangingPieces:
        // The found piece itself is the target — the green highlight carries
        // the feedback; a ghost on top of a real piece would just be noise.
        return const ISetConst({});
      case VisionDrillType.mateInOne:
        // Unreachable (the mate board renders its own shapes), but the switch
        // stays exhaustive.
        return gameState.mateFeedbackShapes;
    }
  }

  /// Find Checks: a faded ghost of the checking piece on each found square —
  /// the same delight moment as the forks drill.
  ISet<Shape> _buildCheckGhostShapes(
      ChessVisionState gameState, PieceAssets pieceAssets) {
    final shapes = <Shape>{};
    for (final sq in gameState.foundSquares) {
      final piece = gameState.checkGhosts[sq];
      if (piece == null) continue;
      shapes.add(PieceShape(
        piece: piece,
        orig: sq,
        pieceAssets: pieceAssets,
        opacity: 0.45,
        scale: 0.9,
      ));
    }
    if (gameState.showingRevealedAnswer) {
      for (final sq in gameState.correctSquares) {
        if (gameState.foundSquares.contains(sq)) continue;
        final piece = gameState.checkGhosts[sq];
        if (piece == null) continue;
        shapes.add(PieceShape(
          piece: piece,
          orig: sq,
          pieceAssets: pieceAssets,
          opacity: 0.35,
          scale: 0.9,
        ));
      }
    }
    return ISet(shapes);
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
      // Goal marker: a bright ring (NOT a knight) marks the destination, so the
      // only knight on the board is the solid one the player actually moves.
      // chessground asserts 0 < scale <= 1.0; 1.0 is the thickest ring (stroke
      // = 1/16 of the square). The amber landing-pad tint (see allHighlights)
      // does the heavier visual lifting.
      shapes.add(Circle(
        color: AppColors.goalAmber,
        orig: target,
        scale: 1.0,
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

  Widget _buildNoneButton(ChessVisionState gameState, AppLocalizations l10n) {
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
        label: Text(l10n.none),
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

  Widget _buildPawnAttackStopwatch(
      ChessVisionState gameState, AppLocalizations l10n) {
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
              l10n.levelOfEight(difficulty),
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

  Widget _buildConcentricProgress(
      ChessVisionState gameState, AppLocalizations l10n) {
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
              l10n.positionOfTotal(gameState.concentricIndex, total),
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

  Widget _buildResultsOverlay(
      ChessVisionState gameState, AppLocalizations l10n) {
    if (widget.mode == VisionMode.concentric) {
      return _buildConcentricResults(gameState, l10n);
    }

    if (widget.drill == VisionDrillType.pawnAttack &&
        widget.mode == VisionMode.speed) {
      return _buildPawnAttackTimedResults(gameState, l10n);
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

  Widget _buildConcentricResults(
      ChessVisionState gameState, AppLocalizations l10n) {
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
                  child: Text(
                    l10n.newRecord,
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
                l10n.drillComplete,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 24),
              _StatRow(label: l10n.time, value: timeStr),
              const SizedBox(height: 10),
              _StatRow(label: l10n.errors, value: '${gameState.totalErrors}'),
              const SizedBox(height: 10),
              _StatRow(
                  label: l10n.bestStreak, value: '${gameState.bestStreak}'),
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
                      child: Text(l10n.menu),
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
                      child: Text(l10n.playAgain),
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

  Widget _buildPawnAttackTimedResults(
      ChessVisionState gameState, AppLocalizations l10n) {
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
                  child: Text(
                    l10n.newRecord,
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
                l10n.allClear,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 24),
              _StatRow(label: l10n.time, value: timeStr),
              const SizedBox(height: 10),
              _StatRow(label: l10n.errors, value: '${gameState.totalErrors}'),
              const SizedBox(height: 10),
              _StatRow(
                  label: l10n.rounds,
                  value: '${gameState.configurationsCompleted}'),
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
                      child: Text(l10n.menu),
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
                      child: Text(l10n.playAgain),
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
    final l10n = AppLocalizations.of(context)!;
    switch (widget.drill) {
      case VisionDrillType.forksAndSkewers:
        final pieceName = widget.piece.localizedLabel(l10n);
        final modeName = switch (widget.mode) {
          VisionMode.practice => l10n.practice,
          VisionMode.speed => l10n.speedRound,
          VisionMode.concentric => l10n.concentric,
        };
        return l10n.titleForksAndSkewers(pieceName, modeName);
      case VisionDrillType.knightSight:
        return l10n.knightSight;
      case VisionDrillType.knightFlight:
        return l10n.knightFlight;
      case VisionDrillType.pawnAttack:
        final pieceName = widget.piece.localizedLabel(l10n);
        final modeName =
            widget.mode == VisionMode.speed ? l10n.timed : l10n.practice;
        return l10n.titlePawnAttack(pieceName, modeName);
      case VisionDrillType.findChecks:
        return l10n.scanDrillChecks;
      case VisionDrillType.findCaptures:
        return l10n.scanDrillCaptures;
      case VisionDrillType.hangingPieces:
        return l10n.scanDrillHanging;
      case VisionDrillType.mateInOne:
        return l10n.scanDrillMate;
    }
  }

  String _scoreText(ChessVisionState gameState, AppLocalizations l10n) {
    if (widget.mode == VisionMode.concentric) {
      final total = ref.read(chessVisionProvider.notifier).concentricTotal;
      return '${gameState.configurationsCompleted}/$total';
    }
    if (widget.drill == VisionDrillType.pawnAttack &&
        widget.mode == VisionMode.speed) {
      return '${gameState.configurationsCompleted}/6';
    }
    return l10n.solvedCount(gameState.configurationsCompleted);
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
