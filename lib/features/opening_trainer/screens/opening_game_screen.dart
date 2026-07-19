import 'dart:math' as math;

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/opening_book_service.dart';
import '../../../core/theme/app_theme.dart';
import '../widgets/opening_picker.dart';
import '../models/opening_game_state.dart';
import '../providers/opening_game_provider.dart';
import '../widgets/eval_bar.dart';
import '../widgets/eval_delta_overlay.dart';
import '../widgets/move_history_panel.dart';
import '../widgets/thinking_indicator.dart';

class OpeningGameScreen extends ConsumerStatefulWidget {
  final OpeningMode mode;
  final OpeningDifficulty difficulty;
  final Side playerColor;

  const OpeningGameScreen({
    super.key,
    required this.mode,
    required this.difficulty,
    required this.playerColor,
  });

  @override
  ConsumerState<OpeningGameScreen> createState() => _OpeningGameScreenState();
}

class _OpeningGameScreenState extends ConsumerState<OpeningGameScreen> {
  bool _showScores = false;
  late Side _orientation = widget.playerColor;

  /// The square the user tapped to select a piece for per-move analysis.
  Square? _selectedPieceSquare;

  /// Dedicated per-move evaluations for the selected piece, filled in
  /// progressively as the engine finishes each move. Key = UCI string.
  Map<String, MoveEval> _extraMoveEvals = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(openingGameProvider.notifier).startGame(
            widget.mode,
            widget.difficulty,
            widget.playerColor,
          );
    });
  }

  Future<void> _showOpeningPicker(BuildContext context) async {
    final notifier = ref.read(openingGameProvider.notifier);
    await notifier.pauseHints();
    if (!mounted) return;

    final bookService = ref.read(openingBookServiceProvider);
    final selectedPgn = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (ctx) => Scaffold(
          appBar: AppBar(
            title: const Text('Start from Opening'),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ),
          body: OpeningPicker(
            bookService: bookService,
            onSelected: (pgn, name) {
              Navigator.of(ctx).pop(pgn);
            },
          ),
        ),
      ),
    );

    if (!mounted) return;
    if (selectedPgn != null) {
      setState(() {
        _selectedPieceSquare = null;
        _extraMoveEvals = {};
      });
      notifier.startFromOpening(selectedPgn);
    } else {
      notifier.resumeHints();
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(openingGameProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Opening Explorer'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_book_rounded, size: 20),
            tooltip: 'Start from opening',
            onPressed: () => _showOpeningPicker(context),
          ),
          IconButton(
            icon: const Icon(Icons.swap_vert_rounded, size: 20),
            tooltip: 'Flip board',
            onPressed: () => setState(() {
              _orientation = _orientation == Side.white
                  ? Side.black
                  : Side.white;
            }),
          ),
          IconButton(
            icon: Icon(
              _showScores ? Icons.tag : Icons.tag_outlined,
              size: 20,
            ),
            tooltip: _showScores ? 'Hide scores' : 'Show scores',
            onPressed: () => setState(() => _showScores = !_showScores),
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
                  if (gameState.openingName != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      gameState.openingName!,
                      style:
                          Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: EvalBar(eval: gameState.currentEval),
                      ),
                      if (gameState.engineTargetDepth > 0) ...[
                        const SizedBox(width: 8),
                        ThinkingIndicator(
                          depth: gameState.engineDepth,
                          targetDepth: gameState.engineTargetDepth,
                        ),
                      ],
                    ],
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
                          return _buildBoard(gameState, boardSize);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (gameState.moveHistory.isNotEmpty &&
                          !gameState.isEngineThinking)
                        IconButton(
                          onPressed: () {
                            ref
                                .read(openingGameProvider.notifier)
                                .undoMove();
                          },
                          icon: const Icon(Icons.undo_rounded),
                          tooltip: 'Undo',
                          iconSize: 20,
                          visualDensity: VisualDensity.compact,
                        ),
                      Expanded(
                        child: MoveHistoryPanel(
                          moveHistory: gameState.moveHistory,
                          isReviewing: gameState.isReviewing,
                          reviewIndex: gameState.reviewIndex,
                        ),
                      ),
                    ],
                  ),
                  if (gameState.isReviewing) ...[
                    const SizedBox(height: 8),
                    _buildReviewControls(),
                  ],
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBoard(OpeningGameState gameState, double boardSize) {
    final orientation = _orientation;
    final provider = ref.read(openingGameProvider.notifier);
    final position = provider.currentPosition;
    final isPractice = gameState.mode == OpeningMode.practice;

    final isInteractive = !gameState.isGameOver &&
        !gameState.isEngineThinking &&
        !gameState.isReviewing &&
        (isPractice || gameState.isPlayerTurn);

    final validMoves = isInteractive
        ? makeLegalMoves(position)
        : const IMapConst<Square, ISet<Square>>({});

    final sideToMove =
        position.turn == Side.white ? Side.white : Side.black;

    final playerSide = isPractice
        ? PlayerSide.both
        : (orientation == Side.white
            ? PlayerSide.white
            : PlayerSide.black);

    // Per-piece analysis: when a piece is selected, classify its moves
    final pieceAnalysis = _selectedPieceSquare != null && isPractice
        ? _analyzePieceMoves(
            position, _selectedPieceSquare!, gameState, validMoves)
        : null;

    // Hide global arrows when a piece is selected; show per-move annotations
    final shapes = pieceAnalysis != null
        ? const ISetConst<Shape>({})
        : _buildHintArrows(gameState);

    final moveHighlights = pieceAnalysis?.highlights;

    final board = Chessboard(
      size: boardSize,
      orientation: orientation,
      fen: gameState.currentFen,
      lastMove: gameState.lastEngineMove,
      settings: ChessboardSettings(
        enableCoordinates: true,
        colorScheme: ChessboardColorScheme.green,
        pieceAssets: PieceSet.cburnett.assets,
        animationDuration: const Duration(milliseconds: 250),
        showValidMoves: isInteractive && pieceAnalysis == null,
        showLastMove: true,
        autoQueenPromotion: true,
        dragFeedbackScale: 1.2,
        dragFeedbackOffset: const Offset(0.0, -0.4),
      ),
      game: GameData(
        playerSide: playerSide,
        sideToMove: sideToMove,
        validMoves: validMoves,
        isCheck: position.isCheck,
        promotionMove: null,
        onMove: (move, {bool? viaDragAndDrop}) {
          setState(() {
            _selectedPieceSquare = null;
            _extraMoveEvals = {};
          });
          if (move is NormalMove) {
            ref.read(openingGameProvider.notifier).handlePlayerMove(move);
          }
        },
        onPromotionSelection: (_) {},
      ),
      shapes: shapes,
      squareHighlights: moveHighlights ?? const IMapConst({}),
    );

    // Wrap in Listener to detect piece selection taps
    final boardWithListener = isPractice && isInteractive
        ? Listener(
            behavior: HitTestBehavior.translucent,
            onPointerUp: (event) {
              _handleBoardTap(
                  event.localPosition, boardSize, orientation, position);
            },
            child: board,
          )
        : board;

    if (isPractice && !gameState.isGameOver) {
      if (pieceAnalysis != null) {
        return Stack(
          children: [
            boardWithListener,
            _PieceAnalysisOverlay(
              boardSize: boardSize,
              orientation: orientation,
              analysisEntries: pieceAnalysis.entries,
              showScores: _showScores,
            ),
          ],
        );
      }
      if (gameState.topMoves.isNotEmpty) {
        return Stack(
          children: [
            boardWithListener,
            EvalDeltaOverlay(
              boardSize: boardSize,
              orientation: orientation,
              topMoves: gameState.topMoves,
              showScores: _showScores,
            ),
          ],
        );
      }
    }

    return boardWithListener;
  }

  void _handleBoardTap(
      Offset localPos, double boardSize, Side orientation, Position position) {
    final squareSize = boardSize / 8;
    final col = (localPos.dx / squareSize).floor().clamp(0, 7);
    final row = (localPos.dy / squareSize).floor().clamp(0, 7);
    final file = orientation == Side.white ? col : 7 - col;
    final rank = orientation == Side.white ? 7 - row : row;

    final square = Square.fromCoords(File(file), Rank(rank));
    final piece = position.board.pieceAt(square);

    // Tapping a piece of the current side: select/deselect it for analysis
    if (piece != null && piece.color == position.turn) {
      final newSelection = _selectedPieceSquare == square ? null : square;
      setState(() {
        _selectedPieceSquare = newSelection;
        _extraMoveEvals = {};
      });
      if (newSelection != null) {
        _evaluateMissingMoves(newSelection, position);
      } else {
        // Deselected — cancel the running per-move evals and restart the
        // hint analysis (otherwise arrows, eval bar and depth readout stay
        // stale, and resumed hints would queue behind stale evals).
        final notifier = ref.read(openingGameProvider.notifier);
        notifier.cancelPieceEvals();
        notifier.resumeHints();
      }
      return;
    }

    // If a piece is selected and user taps a destination square,
    // DON'T clear selection here — let the board handle the move.
    // The selection is cleared in onMove callback after the move completes.
    if (_selectedPieceSquare != null) return;

    // No piece selected, tapped empty/opponent square — nothing to do
  }

  void _evaluateMissingMoves(Square fromSquare, Position position) {
    final allLegal = makeLegalMoves(position);
    final dests = allLegal[fromSquare];
    if (dests == null || dests.isEmpty) return;

    // Evaluate ALL moves for this piece — don't trust top 5 data which
    // may be from an early/inaccurate wave.
    final movesToEval = <NormalMove>[];
    for (final dest in dests) {
      movesToEval.add(NormalMove(from: fromSquare, to: dest));
    }

    ref
        .read(openingGameProvider.notifier)
        .evaluateSpecificMoves(
          movesToEval,
          onResult: (uci, eval) {
            if (mounted && _selectedPieceSquare == fromSquare) {
              setState(() {
                _extraMoveEvals = {..._extraMoveEvals, uci: eval};
              });
            }
          },
        )
        // This future is fire-and-forget (results stream via onResult) — an
        // error here must never surface as an unhandled async exception.
        .catchError((Object e) {
      debugPrint('evaluateSpecificMoves failed: $e');
      return <String, MoveEval>{};
    });
  }

  _PieceAnalysisResult? _analyzePieceMoves(
    Position position,
    Square fromSquare,
    OpeningGameState gameState,
    IMap<Square, ISet<Square>> allValidMoves,
  ) {
    final dests = allValidMoves[fromSquare];
    if (dests == null || dests.isEmpty) return null;

    final topMovesMap = <String, SuggestedMove>{};
    String? bestUci;
    for (final sm in gameState.topMoves) {
      topMovesMap[sm.uci] = sm;
      if (sm.isBest) bestUci = sm.uci;
    }

    final openingBook = ref.read(openingBookServiceProvider);

    final highlights = <Square, SquareHighlight>{};
    final entries = <_PieceAnalysisEntry>[];

    for (final dest in dests) {
      final uci = '${fromSquare.name}${dest.name}';
      final move = NormalMove(from: fromSquare, to: dest);
      final topMove = topMovesMap[uci];
      final isBook = openingBook.isBookMove(position, move);

      MoveClassification? classification;
      String? scoreText;

      // Prefer the dedicated per-move evaluation (same fixed depth as the
      // baseline, so scores match the arrow view); fall back to top-5 data.
      final extra = _extraMoveEvals[uci];
      if (extra != null) {
        classification = classifyDelta(extra.deltaPawns);
        scoreText = formatEval(extra.centipawns, extra.mateIn);
      } else if (topMove != null && topMove.hasEval) {
        classification = topMove.classification;
        scoreText = formatEval(topMove.centipawns, topMove.mateIn);
      }

      // Book membership wins the color; the engine's #1 move gets `best`.
      if (isBook) {
        classification = MoveClassification.book;
      } else if (classification != null && uci == bestUci) {
        classification = MoveClassification.best;
      }

      // No data yet (evaluation still running) → animated thinking badge.
      final isPending = classification == null;
      final effective = classification ?? MoveClassification.good;
      final color = isPending
          ? Colors.blueGrey.shade200
          : colorForClassification(effective);
      final icon = uci == bestUci
          ? '👑'
          : isPending
              ? ''
              : classificationStyle(effective).icon;

      highlights[dest] = SquareHighlight(
        details: HighlightDetails(
          solidColor: color.withValues(alpha: 0.35),
        ),
      );

      entries.add(_PieceAnalysisEntry(
        square: dest,
        classification: effective,
        color: color,
        icon: icon,
        scoreText: scoreText,
        isPending: isPending,
      ));
    }

    return _PieceAnalysisResult(
      highlights: IMap(highlights),
      entries: entries,
    );
  }

  ISet<Shape> _buildHintArrows(OpeningGameState gameState) {
    if (gameState.topMoves.isEmpty || gameState.isGameOver) {
      return const ISetConst({});
    }

    final shapes = <Shape>{};

    for (int i = 0; i < gameState.topMoves.length; i++) {
      final suggested = gameState.topMoves[i];
      final move = _parseUciMove(suggested.uci);
      if (move != null) {
        // Shade carries "how far behind the best move" even when score
        // badges are hidden; the thick arrow is the engine's #1 move.
        final base = colorForClassification(suggested.classification);
        final color = suggested.hasEval
            ? shadeForDelta(base, suggested.deltaPawns)
            : base;
        shapes.add(Arrow(
          color: color.withValues(alpha: 0.8),
          orig: move.from,
          dest: move.to,
          scale: suggested.isBest ? 0.55 : 0.35,
        ));
      }
    }

    return ISet(shapes);
  }

  Widget _buildReviewControls() {
    final notifier = ref.read(openingGameProvider.notifier);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: () => notifier.reviewBack(),
          icon: const Icon(Icons.skip_previous_rounded),
          tooltip: 'Previous move',
        ),
        IconButton(
          onPressed: () => notifier.reviewForward(),
          icon: const Icon(Icons.skip_next_rounded),
          tooltip: 'Next move',
        ),
        const SizedBox(width: 16),
        TextButton(
          onPressed: () => notifier.exitReview(),
          child: const Text('Done'),
        ),
      ],
    );
  }

  NormalMove? _parseUciMove(String uci) {
    if (uci.length < 4) return null;
    try {
      final from = Square.fromName(uci.substring(0, 2));
      final to = Square.fromName(uci.substring(2, 4));
      Role? promotion;
      if (uci.length > 4) {
        promotion = switch (uci[4]) {
          'q' => Role.queen,
          'r' => Role.rook,
          'b' => Role.bishop,
          'n' => Role.knight,
          _ => null,
        };
      }
      return NormalMove(from: from, to: to, promotion: promotion);
    } catch (_) {
      return null;
    }
  }
}

class _PieceAnalysisEntry {
  final Square square;
  final MoveClassification classification;
  final Color color;
  final String icon;
  final String? scoreText;

  /// True while this move's evaluation hasn't arrived yet.
  final bool isPending;

  const _PieceAnalysisEntry({
    required this.square,
    required this.classification,
    required this.color,
    required this.icon,
    this.scoreText,
    this.isPending = false,
  });
}

class _PieceAnalysisResult {
  final IMap<Square, SquareHighlight> highlights;
  final List<_PieceAnalysisEntry> entries;

  const _PieceAnalysisResult({
    required this.highlights,
    required this.entries,
  });
}

class _PieceAnalysisOverlay extends StatefulWidget {
  final double boardSize;
  final Side orientation;
  final List<_PieceAnalysisEntry> analysisEntries;
  final bool showScores;

  const _PieceAnalysisOverlay({
    required this.boardSize,
    required this.orientation,
    required this.analysisEntries,
    this.showScores = false,
  });

  @override
  State<_PieceAnalysisOverlay> createState() => _PieceAnalysisOverlayState();
}

class _PieceAnalysisOverlayState extends State<_PieceAnalysisOverlay>
    with SingleTickerProviderStateMixin {
  /// One shared ticker drives every pending badge's bouncing dots.
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    _syncAnimation();
  }

  @override
  void didUpdateWidget(_PieceAnalysisOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncAnimation();
  }

  void _syncAnimation() {
    final hasPending = widget.analysisEntries.any((e) => e.isPending);
    if (hasPending && !_pulse.isAnimating) {
      _pulse.repeat();
    } else if (!hasPending && _pulse.isAnimating) {
      _pulse.stop();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  double get _squareSize => widget.boardSize / 8;

  Offset _squareOffset(Square square) {
    final file = square.file.value;
    final rank = square.rank.value;
    final x = widget.orientation == Side.white ? file : 7 - file;
    final y = widget.orientation == Side.white ? 7 - rank : rank;
    return Offset(x * _squareSize, y * _squareSize);
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox.square(
        dimension: widget.boardSize,
        child: Stack(
          children: [
            for (final entry in widget.analysisEntries) ...[
              _buildIconBadge(entry),
              if (widget.showScores && entry.scoreText != null)
                _buildScoreLabel(entry),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIconBadge(_PieceAnalysisEntry entry) {
    final offset = _squareOffset(entry.square);
    final size = _squareSize * 0.4;

    return Positioned(
      left: offset.dx + _squareSize - size * 0.8,
      top: offset.dy - size * 0.2,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: entry.color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 2,
              offset: const Offset(0.5, 0.5),
            ),
          ],
        ),
        child: entry.isPending
            ? _buildThinkingDots(size)
            : FittedBox(
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Text(
                    entry.icon,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  /// Three white dots bouncing in sequence (chat "typing" style) — reads
  /// instantly as "the engine is thinking about this square".
  Widget _buildThinkingDots(double badgeSize) {
    final dotSize = badgeSize * 0.16;
    final amplitude = badgeSize * 0.12;

    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (int i = 0; i < 3; i++) ...[
              if (i > 0) SizedBox(width: dotSize * 0.5),
              Transform.translate(
                offset: Offset(0, -_bounce(_pulse.value, i) * amplitude),
                child: Container(
                  width: dotSize,
                  height: dotSize,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  /// Bounce curve for dot [i]: each dot rises and falls over 55% of the
  /// cycle, staggered so they follow each other.
  double _bounce(double t, int i) {
    final phase = (t - i * 0.15) % 1.0;
    if (phase < 0 || phase > 0.55) return 0;
    return math.sin(phase / 0.55 * math.pi);
  }

  Widget _buildScoreLabel(_PieceAnalysisEntry entry) {
    final offset = _squareOffset(entry.square);
    final fontSize = (_squareSize * 0.22).clamp(8.0, 13.0);

    return Positioned(
      left: offset.dx,
      top: offset.dy,
      width: _squareSize,
      height: _squareSize,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: entry.color.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            entry.scoreText!,
            style: TextStyle(
              color: Colors.white,
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              height: 1.1,
            ),
          ),
        ),
      ),
    );
  }
}
