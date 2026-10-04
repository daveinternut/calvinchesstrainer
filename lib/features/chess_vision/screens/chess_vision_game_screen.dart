import 'package:flutter/material.dart';
import 'package:calvinchesstrainer/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart'
    show Board, NormalMove, Piece, Side, Square, makeLegalMoves;
import 'package:fast_immutable_collections/fast_immutable_collections.dart';

import '../../../core/audio/audio_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/board_theme.dart';
import '../../../core/ui/board_frame.dart';
import '../../../core/ui/buttons.dart';
import '../../../core/ui/components.dart';
import '../../../core/widgets/square_name_overlay.dart';
import '../../../core/widgets/trainer_layout.dart';
import '../../drills/drill_catalog.dart';
import '../../drills/models/drill.dart';
import '../../drills/warmup_actions.dart';
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

  /// A step of the daily warm-up (the results then move on to the next).
  final bool warmup;

  const ChessVisionGameScreen({
    super.key,
    required this.drill,
    required this.piece,
    this.target = TargetPiece.rook,
    required this.mode,
    this.warmup = false,
  });

  @override
  ConsumerState<ChessVisionGameScreen> createState() =>
      _ChessVisionGameScreenState();
}

class _ChessVisionGameScreenState
    extends ConsumerState<ChessVisionGameScreen> {
  late final AudioService _audioService;

  /// Levels in a timed Pawn Attack run (3 pawns up to 8).
  static const _pawnAttackLevels = ChessVisionNotifier.pawnAttackLastLevel -
      ChessVisionNotifier.pawnAttackFirstLevel +
      1;

  /// Set once this screen has started its game. Until then the provider holds
  /// its neutral state (or, after a very quick back-and-start, the previous
  /// game's), so the screen draws only a neutral skeleton.
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _audioService = ref.read(audioServiceProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _started = true);
      _restartGame();
    });
  }

  @override
  void dispose() {
    _audioService.stop();
    super.dispose();
  }

  /// The mode the game really runs in. The provider owns it once the game
  /// has started (it can coerce further, e.g. an empty concentric spiral);
  /// before that, the shared coercion rule.
  VisionMode _modeOf(ChessVisionState gameState) =>
      _started ? gameState.mode : widget.drill.effectiveMode(widget.mode);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final gameState = ref.watch(chessVisionProvider);
    final mode = _modeOf(gameState);
    final pending = !_started || gameState.isLoading;
    final streak = pending ? 0 : gameState.streak;
    final orientation = pending ? Side.white : gameState.boardOrientation;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            TrainerLayout(
              topBar: PlayTopBar(
                title: DrillCatalog.forVision(widget.drill).title(l10n),
                subtitle: warmupSubtitle(ref, l10n, widget.warmup) ??
                    _subtitle(l10n, mode),
                onClose: () => closeDrill(context),
                closeTooltip: l10n.endDrill,
                trailing: Text(pending ? '' : _scoreText(gameState, l10n, mode)),
              ),
              header: [
                const SizedBox(height: 8),
                _buildPromptBlock(gameState, l10n, pending),
                const SizedBox(height: 12),
                _buildProgressArea(gameState, l10n, mode, pending),
                const SizedBox(height: 8),
                StreakCounter(
                  streak: streak,
                  bestStreak: pending ? 0 : gameState.bestStreak,
                ),
                const SizedBox(height: 8),
              ],
              board: (context, size) => BoardFrame(
                size: size,
                orientation: orientation,
                builder: (context, boardSize) =>
                    _buildBoard(gameState, boardSize, l10n, pending),
              ),
              footer: [
                ..._buildFooter(gameState, l10n, mode, pending),
                const SizedBox(height: 16),
              ],
            ),
            // Lines itself up with the TrainerLayout: in landscape it rises
            // in the side panel, clear of the board.
            MilestoneBanner(streak: streak),
            if (!pending && gameState.isGameOver)
              Positioned.fill(
                child: _buildResultsOverlay(gameState, l10n, mode),
              ),
          ],
        ),
      ),
    );
  }

  /// The top bar's second line: the piece and mode the game runs with.
  String _subtitle(AppLocalizations l10n, VisionMode mode) {
    final drill = DrillCatalog.forVision(widget.drill);
    final drillMode = switch (mode) {
      VisionMode.practice => DrillMode.practice,
      VisionMode.speed => DrillMode.speed,
      VisionMode.concentric => DrillMode.concentric,
    };
    return [
      if (drill.usesPiece) widget.piece.localizedLabel(l10n),
      if (drill.usesTarget) widget.target.localizedLabel(l10n),
      drill.modeLabel(drillMode, l10n),
    ].join(' · ');
  }

  /// The question being asked: a big headline, the full instruction under
  /// it, and (on real positions) whose move it is.
  Widget _buildPromptBlock(
      ChessVisionState gameState, AppLocalizations l10n, bool pending) {
    final title = switch (widget.drill) {
      VisionDrillType.forksAndSkewers => l10n.promptTitleForks,
      VisionDrillType.knightSight => l10n.promptTitleKnightSight,
      VisionDrillType.knightFlight => l10n.promptTitleKnightFlight,
      VisionDrillType.pawnAttack => l10n.promptTitlePawnAttack,
      VisionDrillType.findChecks => l10n.promptTitleChecks,
      VisionDrillType.findCaptures => l10n.promptTitleCaptures,
      VisionDrillType.hangingPieces => l10n.promptTitleHanging,
      VisionDrillType.mateInOne => l10n.promptTitleMate,
    };
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.drill.isScanDrill) ...[
          _buildSideToPlayBadge(gameState, l10n, pending),
          const SizedBox(height: 10),
        ],
        Text(
          title,
          textAlign: TextAlign.center,
          style: AppText.display.copyWith(fontSize: 30),
        ),
        const SizedBox(height: 4),
        _buildDrillPrompt(l10n),
      ],
    );
  }

  // --- Footer (buttons, clocks) ---

  List<Widget> _buildFooter(ChessVisionState gameState, AppLocalizations l10n,
      VisionMode mode, bool pending) {
    final drill = widget.drill;
    return [
      // Clocks first, then the actions, which sit lowest (thumb reach).
      if (mode == VisionMode.speed &&
          drill != VisionDrillType.pawnAttack &&
          !gameState.loadFailed) ...[
        const SizedBox(height: 12),
        TimerBar(
          remainingSeconds: pending
              ? ChessVisionNotifier.speedRoundSeconds
              : gameState.timeRemainingSeconds ??
                  ChessVisionNotifier.speedRoundSeconds,
          totalSeconds: ChessVisionNotifier.speedRoundSeconds,
        ),
      ],
      if (mode == VisionMode.concentric) ...[
        const SizedBox(height: 12),
        _buildConcentricProgress(gameState, l10n, pending),
      ],
      if (drill == VisionDrillType.pawnAttack && mode == VisionMode.speed) ...[
        const SizedBox(height: 12),
        _buildPawnAttackStopwatch(gameState, l10n, pending),
      ],
      if (drill == VisionDrillType.forksAndSkewers &&
          mode != VisionMode.concentric) ...[
        const SizedBox(height: 12),
        _buildNoneButton(gameState, l10n, pending),
      ],
      if (drill.isTapScanDrill && !gameState.loadFailed) ...[
        const SizedBox(height: 12),
        _buildScanSkipButton(gameState, l10n, pending),
      ],
      if (drill == VisionDrillType.pawnAttack) ...[
        const SizedBox(height: 12),
        _buildStartOverButton(gameState, l10n, pending),
      ],
      if (_showFlightRetryButtons(gameState, pending)) ...[
        const SizedBox(height: 12),
        _buildFlightRetryButtons(l10n),
      ],
    ];
  }

  bool _showFlightRetryButtons(ChessVisionState gameState, bool pending) {
    if (widget.drill != VisionDrillType.knightFlight || pending) return false;
    if (!gameState.flightComplete || gameState.isRoundComplete) return false;
    final isOptimal = gameState.flightPath.length == gameState.minimumMoves;
    return !isOptimal;
  }

  Widget _buildFlightRetryButtons(AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: AppSecondaryButton(
            onPressed: () =>
                ref.read(chessVisionProvider.notifier).retryFlight(),
            icon: Icons.replay_rounded,
            label: l10n.retry,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AppPrimaryButton(
            onPressed: () =>
                ref.read(chessVisionProvider.notifier).skipFlight(),
            icon: Icons.skip_next_rounded,
            label: l10n.skip,
          ),
        ),
      ],
    );
  }

  /// The full-width outlined action button shared by None, Skip and Start
  /// over.
  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
  }) {
    return AppSecondaryButton(
      label: label,
      icon: icon,
      onPressed: onPressed,
      expand: true,
    );
  }

  Widget _buildNoneButton(
      ChessVisionState gameState, AppLocalizations l10n, bool pending) {
    final enabled = !pending &&
        !gameState.isGameOver &&
        !gameState.isRoundComplete &&
        !gameState.showingRevealedAnswer;
    return _actionButton(
      icon: Icons.block_rounded,
      label: l10n.none,
      onPressed: enabled
          ? () => ref.read(chessVisionProvider.notifier).handleNoneTap()
          : null,
    );
  }

  Widget _buildScanSkipButton(
      ChessVisionState gameState, AppLocalizations l10n, bool pending) {
    final enabled = !pending &&
        !gameState.isGameOver &&
        !gameState.isRoundComplete &&
        !gameState.showingRevealedAnswer;
    return _actionButton(
      icon: Icons.skip_next_rounded,
      label: l10n.skip,
      onPressed: enabled
          ? () => ref.read(chessVisionProvider.notifier).skipScanPosition()
          : null,
    );
  }

  /// Pawn Attack's way out of a self-made dead end: the board goes back to
  /// how it was dealt. Enabled once the piece has moved; when the pawns left
  /// can no longer all be captured it lights up, so the way out is obvious.
  Widget _buildStartOverButton(
      ChessVisionState gameState, AppLocalizations l10n, bool pending) {
    final enabled = !pending &&
        !gameState.isGameOver &&
        !gameState.isRoundComplete &&
        gameState.pawnAttackMoves > 0;
    void onPressed() =>
        ref.read(chessVisionProvider.notifier).startOverPawnBoard();

    if (!enabled || !gameState.pawnAttackDeadEnd) {
      return _actionButton(
        icon: Icons.restart_alt_rounded,
        label: l10n.startOver,
        onPressed: enabled ? onPressed : null,
      );
    }
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.restart_alt_rounded, size: 20),
        label: Text(l10n.startOver),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.amber,
          foregroundColor: AppColors.ink,
        ),
      ),
    );
  }

  // --- Progress area (header) ---

  Widget _buildProgressArea(ChessVisionState gameState, AppLocalizations l10n,
      VisionMode mode, bool pending) {
    List<String> labels() => pending
        ? const []
        : [for (final sq in gameState.foundSquares) gameState.foundLabel(sq)];
    switch (widget.drill) {
      case VisionDrillType.forksAndSkewers:
      case VisionDrillType.knightSight:
        return FoundProgressIndicator(
          totalCorrect: pending ? 0 : gameState.totalCorrect,
          totalFound: pending ? 0 : gameState.totalFound,
          foundLabels: labels(),
          showNoneHint: widget.drill == VisionDrillType.forksAndSkewers &&
              mode != VisionMode.concentric &&
              !pending &&
              !gameState.isRoundComplete &&
              !gameState.showingRevealedAnswer,
          l10n: l10n,
        );
      case VisionDrillType.knightFlight:
        return _buildFlightProgress(gameState, l10n, pending);
      case VisionDrillType.pawnAttack:
        return _buildPawnAttackProgress(gameState, l10n, mode, pending);
      case VisionDrillType.findChecks:
      case VisionDrillType.findCaptures:
      case VisionDrillType.hangingPieces:
        // The three tap drills render visually identical real positions —
        // only the prompt tells the player which question is being asked.
        if (!pending && gameState.isRoundComplete) {
          return SizedBox(
            height: 44,
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: AppColors.brand),
                const SizedBox(width: 8),
                Text(
                  l10n.allClear,
                  style: AppText.cardTitle.copyWith(color: AppColors.brand),
                ),
              ],
            ),
          );
        }
        return FoundProgressIndicator(
          totalCorrect: pending ? 0 : gameState.totalCorrect,
          totalFound: pending ? 0 : gameState.totalFound,
          foundLabels: labels(),
          l10n: l10n,
        );
      case VisionDrillType.mateInOne:
        return const SizedBox.shrink();
    }
  }

  /// The full instruction, under the headline.
  Widget _buildDrillPrompt(AppLocalizations l10n) {
    final prompt = switch (widget.drill) {
      VisionDrillType.forksAndSkewers => l10n.visionPromptForks,
      VisionDrillType.knightSight => l10n.visionPromptKnightSight,
      VisionDrillType.knightFlight => l10n.visionPromptKnightFlight,
      VisionDrillType.pawnAttack => l10n.visionPromptPawnAttack,
      VisionDrillType.findChecks => l10n.scanPromptChecks,
      VisionDrillType.findCaptures => l10n.scanPromptCaptures,
      VisionDrillType.hangingPieces => l10n.scanPromptHanging,
      VisionDrillType.mateInOne => l10n.scanPromptMate,
    };
    return Text(
      prompt,
      textAlign: TextAlign.center,
      style: AppText.body.copyWith(fontSize: 14.5),
    );
  }

  /// "White to play" / "Black to play" — real positions come with either
  /// side to move (and the board flips to match), so the mover must be
  /// unmistakable the moment the position loads.
  Widget _buildSideToPlayBadge(
      ChessVisionState gameState, AppLocalizations l10n, bool pending) {
    // Fixed height so the layout doesn't jump when the position arrives.
    if (pending || gameState.scanDisplayFen == null) {
      return const SizedBox(height: 26);
    }
    final isWhite = gameState.scanSideToMove == Side.white;
    return SideToMovePill(
      side: gameState.scanSideToMove,
      label: isWhite ? l10n.whiteToPlay : l10n.blackToPlay,
    );
  }

  /// A row of small stat tiles (Knight Flight and Pawn Attack progress).
  Widget _statRow(List<(String, bool)> stats) {
    return Row(
      children: [
        for (var i = 0; i < stats.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.line),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  stats[i].$1,
                  style: AppText.body.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: stats[i].$2 ? AppColors.verm : AppColors.ink,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFlightProgress(
      ChessVisionState gameState, AppLocalizations l10n, bool pending) {
    final min = pending ? 0 : gameState.minimumMoves ?? 0;
    final current = pending ? 0 : gameState.flightPath.length;
    return _statRow([
      (l10n.minimumMoves(min), false),
      (l10n.yourMoves(current), current > min),
    ]);
  }

  Widget _buildPawnAttackProgress(ChessVisionState gameState,
      AppLocalizations l10n, VisionMode mode, bool pending) {
    final remaining = pending ? 0 : gameState.remainingPawns.length;
    return _statRow([
      (l10n.pawnsRemaining(remaining), false),
      if (mode == VisionMode.speed)
        (l10n.levelOfEight(gameState.pawnAttackDifficulty), false),
      (l10n.movesCount(pending ? 0 : gameState.pawnAttackMoves), false),
    ]);
  }

  // --- Board ---

  Widget _buildBoard(ChessVisionState gameState, double boardSize,
      AppLocalizations l10n, bool pending) {
    final drill = widget.drill;
    final pieceAssets = PieceSet.cburnett.assets;

    if (pending) {
      // Neutral until this screen's game exists: a spinner while a scanning
      // set loads, otherwise an empty board (never another drill's position).
      if (drill.isScanDrill) return _buildBoardSpinner(boardSize);
      return Chessboard.fixed(
        size: boardSize,
        orientation: Side.white,
        fen: Board.empty.fen,
        settings: AppBoard.settings(),
      );
    }

    if (drill.isScanDrill && gameState.loadFailed) {
      return _buildLoadFailed(boardSize, l10n);
    }

    void onTap(Square square) =>
        ref.read(chessVisionProvider.notifier).handleBoardTap(square);

    // Mate in 1 plays a real move on an interactive board (move-trainer
    // machinery); the three tap scanning drills fall through to the fixed
    // board below.
    if (drill == VisionDrillType.mateInOne) {
      return _buildMateBoard(gameState, boardSize, pieceAssets);
    }
    if (drill.isTapScanDrill && gameState.scanDisplayFen == null) {
      return _buildBoardSpinner(boardSize);
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
        settings: AppBoard.settings(showValidMoves: showDots),
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
      settings: AppBoard.settings(),
      squareHighlights: gameState.allHighlights,
      shapes: _buildShapes(gameState, pieceAssets),
      onTouchedSquare: onTap,
    );
  }

  Widget _buildBoardSpinner(double boardSize) => SizedBox(
        width: boardSize,
        height: boardSize,
        child: const Center(child: CircularProgressIndicator()),
      );

  /// Shown in the board's place when a scanning drill's curated set can't be
  /// loaded: a message and a Retry, instead of an endless spinner.
  Widget _buildLoadFailed(double boardSize, AppLocalizations l10n) {
    return SizedBox(
      width: boardSize,
      height: boardSize,
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: SizedBox(
            width: 280,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: AppColors.ink3,
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.loadFailed,
                  textAlign: TextAlign.center,
                  style: AppText.cardTitle,
                ),
                const SizedBox(height: 16),
                AppPrimaryButton(
                  onPressed: _restartGame,
                  icon: Icons.refresh_rounded,
                  label: l10n.retry,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMateBoard(
      ChessVisionState gameState, double boardSize, PieceAssets pieceAssets) {
    final puzzle = gameState.currentMatePuzzle;
    final fen = gameState.scanDisplayFen;

    if (gameState.isLoading || puzzle == null || fen == null) {
      return _buildBoardSpinner(boardSize);
    }

    final orientation = gameState.boardOrientation;
    final isInteractive =
        !gameState.isRoundComplete && !gameState.isGameOver;
    // After a correct mate the board shows the mated position: its side to
    // move is the mated side, so chessground highlights the mated king.
    final shown = gameState.matedPosition ?? puzzle.position;

    final validMoves = isInteractive
        ? makeLegalMoves(puzzle.position)
        : const IMapConst<Square, ISet<Square>>({});

    final board = Chessboard(
      size: boardSize,
      orientation: orientation,
      fen: fen,
      lastMove: gameState.mateFeedback == null ? puzzle.setupMove : null,
      settings: AppBoard.settings(
        animationDuration: const Duration(milliseconds: 250),
        showValidMoves: isInteractive,
        autoQueenPromotion: true,
      ),
      game: GameData(
        playerSide: orientation == Side.white
            ? PlayerSide.white
            : PlayerSide.black,
        sideToMove: shown.turn,
        validMoves: validMoves,
        isCheck: shown.isCheck,
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

  // --- Stopwatch modes (timed Pawn Attack, concentric) ---

  static String _clock(int seconds) =>
      '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';

  /// A stopwatch card: elapsed time big, a caption, and a progress bar.
  Widget _stopwatchCard({
    required String caption,
    required int elapsed,
    required double progress,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                _clock(elapsed),
                style: AppText.number.copyWith(fontSize: 36, height: 1.1),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  caption,
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.caption,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.well,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.brand),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPawnAttackStopwatch(
      ChessVisionState gameState, AppLocalizations l10n, bool pending) {
    // Levels cleared, so the bar fills completely when the last one falls.
    return _stopwatchCard(
      caption: l10n.levelOfEight(gameState.pawnAttackDifficulty),
      elapsed: pending ? 0 : gameState.elapsedSeconds,
      progress: pending
          ? 0.0
          : (gameState.configurationsCompleted / _pawnAttackLevels)
              .clamp(0.0, 1.0),
    );
  }

  Widget _buildConcentricProgress(
      ChessVisionState gameState, AppLocalizations l10n, bool pending) {
    final total = pending ? 0 : gameState.concentricTotal;
    final index = pending ? 0 : gameState.concentricIndex;
    return _stopwatchCard(
      caption: l10n.positionOfTotal(index, total),
      elapsed: pending ? 0 : gameState.elapsedSeconds,
      progress: total > 0 ? index / total : 0.0,
    );
  }

  // --- Results ---

  Widget _buildResultsOverlay(
      ChessVisionState gameState, AppLocalizations l10n, VisionMode mode) {
    final actions = roundActions(
      context,
      ref,
      warmup: widget.warmup,
      score: gameState.configurationsCompleted,
      onPlayAgain: _restartGame,
    );

    // Stopwatch modes rank by time: the time is the score.
    final stopwatchStat = mode == VisionMode.concentric
        ? (l10n.bestStreak, '${gameState.bestStreak}')
        : (widget.drill == VisionDrillType.pawnAttack &&
                mode == VisionMode.speed)
            ? (l10n.rounds, '${gameState.configurationsCompleted}')
            : null;
    if (stopwatchStat != null) {
      return ResultsSheet(
        heading: mode == VisionMode.concentric
            ? l10n.drillComplete
            : l10n.allClear,
        score: _clock(gameState.elapsedSeconds),
        scoreCaption: l10n.time,
        isNewRecord: gameState.isNewRecord,
        stats: [(l10n.errors, '${gameState.totalErrors}'), stopwatchStat],
        primaryLabel: actions.primaryLabel,
        onPrimary: actions.onPrimary,
        secondaryLabel: actions.secondaryLabel,
        onSecondary: actions.onSecondary,
      );
    }

    return ResultsCard(
      totalCorrect: gameState.configurationsCompleted,
      totalAttempts: gameState.configurationsCompleted + gameState.totalErrors,
      bestStreak: gameState.bestStreak,
      isNewRecord: gameState.isNewRecord,
      primaryLabel: actions.primaryLabel,
      onPlayAgain: actions.onPrimary,
      secondaryLabel: actions.secondaryLabel,
      onBack: actions.onSecondary,
    );
  }

  /// Starts (or restarts) this screen's game: first frame, Play Again, and
  /// the Retry after a failed load.
  void _restartGame() {
    ref.read(chessVisionProvider.notifier).startGame(
          widget.drill,
          widget.mode,
          widget.piece,
          targetPiece: widget.target,
        );
  }

  // --- Score ---

  String _scoreText(
      ChessVisionState gameState, AppLocalizations l10n, VisionMode mode) {
    if (mode == VisionMode.concentric) {
      return '${gameState.configurationsCompleted}/${gameState.concentricTotal}';
    }
    if (widget.drill == VisionDrillType.pawnAttack &&
        mode == VisionMode.speed) {
      return '${gameState.configurationsCompleted}/$_pawnAttackLevels';
    }
    return l10n.solvedCount(gameState.configurationsCompleted);
  }
}
