import 'dart:math' as math;

import 'package:calvinchesstrainer/l10n/app_localizations.dart';
import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/opening_book_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/board_theme.dart';
import '../../../core/ui/board_frame.dart';
import '../../../core/ui/buttons.dart';
import '../../../core/ui/components.dart';
import '../../../core/widgets/trainer_layout.dart';
import '../../drills/warmup_actions.dart' show closeDrill;
import '../models/opening_game_state.dart';
import '../models/uci_move.dart';
import '../providers/opening_game_provider.dart';
import '../widgets/eval_bar.dart';
import '../widgets/eval_delta_overlay.dart';
import '../widgets/move_history_panel.dart';
import '../widgets/opening_picker.dart';
import '../widgets/thinking_indicator.dart';

/// Two lines of the opening name, reserved even when there is none, so the
/// board never resizes as names come and go.
const _kOpeningNameFontSize = 14.0;
const _kOpeningNameLineHeight = 1.3;
const _kOpeningNameHeight =
    _kOpeningNameFontSize * _kOpeningNameLineHeight * 2 + 2;

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
  /// progressively as the engine finishes each move. Key = standard UCI
  /// (`e1g1`, `e7e8q`), matching the engine's hint keys.
  Map<String, MoveEval> _extraMoveEvals = {};

  /// The selected piece's evaluation session has ended — finished,
  /// cancelled or failed — so nothing more will arrive: squares without a
  /// score stop showing "thinking".
  bool _pieceAnalysisDone = false;

  /// Identifies the current evaluation session, so a superseded session's
  /// late callbacks can't overwrite newer results.
  int _evalSession = 0;

  /// Stops the engine while the app is in the background, and picks the
  /// analysis back up when it returns.
  late final AppLifecycleListener _lifecycle;

  /// The opening picker is open (or opening): one at a time, and no
  /// analysis restarts behind it.
  bool _pickerOpen = false;

  /// The board position is about to change — drop the selected piece and
  /// its now-stale evaluations.
  void _clearAnalysisSelection() {
    setState(() {
      _selectedPieceSquare = null;
      _extraMoveEvals = {};
      _pieceAnalysisDone = false;
      _evalSession++;
    });
  }

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onHide: _onAppHidden,
      onShow: _onAppShown,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(openingGameProvider.notifier).startGame(
            widget.mode,
            widget.difficulty,
            widget.playerColor,
          );
    });
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _evalSession++;
    super.dispose();
  }

  void _onAppHidden() {
    if (!mounted) return;
    if (_selectedPieceSquare != null) _clearAnalysisSelection();
    ref.read(openingGameProvider.notifier).pauseAnalysis();
  }

  void _onAppShown() {
    if (!mounted || _pickerOpen) return;
    ref.read(openingGameProvider.notifier).resumeHints();
  }

  Future<void> _showOpeningPicker() async {
    if (_pickerOpen) return;
    _pickerOpen = true;
    try {
      await _runOpeningPicker();
    } finally {
      _pickerOpen = false;
    }
  }

  Future<void> _runOpeningPicker() async {
    final notifier = ref.read(openingGameProvider.notifier);
    final navigator = Navigator.of(context);
    final bookService = ref.read(openingBookServiceProvider);

    // Drop the piece analysis first: pausing ends its session, and squares
    // still waiting for a score would otherwise keep "thinking" forever.
    _clearAnalysisSelection();
    await notifier.pauseHints();
    if (!mounted) return;

    final selectedPgn = await navigator.push<String>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (ctx) => Scaffold(
          appBar: AppBar(
            title: Text(AppLocalizations.of(ctx)!.startFromOpening),
            leading: IconButton(
              icon: const Icon(Icons.close),
              tooltip: MaterialLocalizations.of(ctx).closeButtonTooltip,
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
      notifier.startFromOpening(selectedPgn);
    } else {
      notifier.resumeHints();
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(openingGameProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final landscape = TrainerLayout.isLandscape(constraints);
            return TrainerLayout(
              topBar: PlayTopBar(
                title: l10n.openingExplorer,
                onClose: () => closeDrill(context),
                closeTooltip: MaterialLocalizations.of(context).backButtonTooltip,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleIconButton(
                      icon: Icons.menu_book_rounded,
                      tooltip: l10n.startFromOpening,
                      onPressed: _showOpeningPicker,
                    ),
                    const SizedBox(width: 6),
                    CircleIconButton(
                      icon: Icons.swap_vert_rounded,
                      tooltip: l10n.flipBoard,
                      onPressed: () => setState(() {
                        _orientation = _orientation == Side.white
                            ? Side.black
                            : Side.white;
                      }),
                    ),
                    const SizedBox(width: 6),
                    CircleIconButton(
                      icon: _showScores ? Icons.tag : Icons.tag_outlined,
                      tooltip: _showScores ? l10n.hideScores : l10n.showScores,
                      onPressed: () =>
                          setState(() => _showScores = !_showScores),
                    ),
                  ],
                ),
              ),
              header: _buildHeader(gameState, l10n),
              board: (context, size) => BoardFrame(
                size: size,
                orientation: _orientation,
                builder: (context, boardSize) =>
                    _buildBoard(gameState, boardSize),
              ),
              footer: _buildFooter(gameState, landscape: landscape),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildHeader(OpeningGameState gameState, AppLocalizations l10n) {
    return [
      const SizedBox(height: 4),
      SizedBox(
        height: _kOpeningNameHeight,
        child: Center(
          child: Text(
            gameState.openingName ?? '',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: AppFonts.ui,
              fontSize: _kOpeningNameFontSize,
              height: _kOpeningNameLineHeight,
              fontWeight: FontWeight.w600,
              color: AppColors.ink2,
            ),
          ),
        ),
      ),
      const SizedBox(height: 4),
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
      if (gameState.engineUnavailable) _buildEngineBanner(l10n),
      const SizedBox(height: 8),
    ];
  }

  Widget _buildEngineBanner(AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.only(left: 12, right: 4),
      decoration: BoxDecoration(
        color: AppColors.amberSoft,
        border: Border.all(color: AppColors.amber),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: AppColors.amberInk, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.engineUnavailable,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(minimumSize: const Size(64, 44)),
            onPressed: () =>
                ref.read(openingGameProvider.notifier).retryEngine(),
            child: Text(l10n.retry),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFooter(
    OpeningGameState gameState, {
    required bool landscape,
  }) {
    final panel = MoveHistoryPanel(
      lines: gameState.lines,
      activeLineIndex: gameState.activeLineIndex,
      cursorPly: gameState.cursorPly,
      // Portrait: a fixed height (rows scroll), so the board never resizes
      // as variations appear. Landscape: the side panel has room for more.
      maxHeight: landscape
          ? MoveHistoryPanel.rowExtent * 6
          : MoveHistoryPanel.rowExtent * 2.5,
      enabled: gameState.mode == OpeningMode.practice &&
          !gameState.isEngineThinking,
      onTapMove: (lineIndex, ply) {
        _clearAnalysisSelection();
        ref.read(openingGameProvider.notifier).goTo(lineIndex, ply);
      },
      onBack: () {
        _clearAnalysisSelection();
        ref.read(openingGameProvider.notifier).scrubBack();
      },
      onForward: () {
        _clearAnalysisSelection();
        ref.read(openingGameProvider.notifier).scrubForward();
      },
    );
    return [
      const SizedBox(height: 8),
      if (landscape)
        panel
      else
        SizedBox(
          height: MoveHistoryPanel.rowExtent * 2.5,
          child: Align(alignment: Alignment.topCenter, child: panel),
        ),
      const SizedBox(height: 12),
    ];
  }

  Widget _buildBoard(OpeningGameState gameState, double boardSize) {
    final orientation = _orientation;
    final position = ref.read(openingGameProvider.notifier).currentPosition;
    final isPractice = gameState.mode == OpeningMode.practice;

    final isInteractive = !gameState.isGameOver &&
        !gameState.isEngineThinking &&
        (isPractice || gameState.isPlayerTurn);

    final validMoves = isInteractive
        ? makeLegalMoves(position)
        : const IMapConst<Square, ISet<Square>>({});

    // Practice plays both sides. Challenge: the side the player chose —
    // never the board's orientation, which the flip button changes.
    final playerSide = isPractice
        ? PlayerSide.both
        : (gameState.playerColor == Side.white
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

    final board = Chessboard(
      size: boardSize,
      orientation: orientation,
      fen: gameState.currentFen,
      lastMove: gameState.lastMove,
      settings: AppBoard.settings(
        animationDuration: const Duration(milliseconds: 250),
        showValidMoves: isInteractive && pieceAnalysis == null,
        autoQueenPromotion: true,
      ).copyWith(
        dragFeedbackScale: 1.2,
        dragFeedbackOffset: const Offset(0.0, -0.4),
      ),
      game: GameData(
        playerSide: playerSide,
        sideToMove: position.turn,
        validMoves: validMoves,
        isCheck: position.isCheck,
        promotionMove: null,
        onMove: (move, {bool? viaDragAndDrop}) {
          setState(() {
            _selectedPieceSquare = null;
            _extraMoveEvals = {};
            _pieceAnalysisDone = false;
            _evalSession++;
          });
          if (move is NormalMove) {
            ref.read(openingGameProvider.notifier).handlePlayerMove(move);
          }
        },
        onPromotionSelection: (_) {},
      ),
      shapes: shapes,
      squareHighlights: pieceAnalysis?.highlights ?? const IMapConst({}),
    );

    // The board is always child 0 of the same Stack (and always inside the
    // Listener), so overlays coming and going never rebuild its state.
    return SizedBox.square(
      dimension: boardSize,
      child: Stack(
        children: [
          Listener(
            behavior: HitTestBehavior.translucent,
            onPointerUp: isPractice && isInteractive
                ? (event) =>
                    _handleBoardTap(event.localPosition, boardSize, orientation)
                : null,
            child: board,
          ),
          if (isPractice && !gameState.isGameOver && pieceAnalysis != null)
            _PieceAnalysisOverlay(
              boardSize: boardSize,
              orientation: orientation,
              analysisEntries: pieceAnalysis.entries,
              showScores: _showScores,
            )
          else if (isPractice &&
              !gameState.isGameOver &&
              gameState.topMoves.isNotEmpty)
            EvalDeltaOverlay(
              boardSize: boardSize,
              orientation: orientation,
              topMoves: gameState.topMoves,
              showScores: _showScores,
            ),
          if (gameState.isGameOver && gameState.gameEnd != null)
            Positioned.fill(child: _GameEndBanner(end: gameState.gameEnd!)),
        ],
      ),
    );
  }

  void _handleBoardTap(Offset localPos, double boardSize, Side orientation) {
    // The position *now*: when this tap was the end of a move, the board has
    // already moved on (the board's own handler runs first).
    final position = ref.read(openingGameProvider.notifier).currentPosition;
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
        _pieceAnalysisDone = false;
        _evalSession++;
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
  }

  void _evaluateMissingMoves(Square fromSquare, Position position) {
    final dests = makeLegalMoves(position)[fromSquare];
    if (dests == null || dests.isEmpty) return;

    // Evaluate ALL moves for this piece — don't trust top 5 data which
    // may be from an early/inaccurate wave. Standard spelling (castling
    // once, as e1g1; promotions as e7e8q), so keys match the engine's.
    final movesToEval = <String, NormalMove>{};
    for (final dest in dests) {
      final move =
          standardMove(position, NormalMove(from: fromSquare, to: dest));
      movesToEval[move.uci] = move;
    }

    final session = ++_evalSession;

    ref
        .read(openingGameProvider.notifier)
        .evaluateSpecificMoves(
          movesToEval.values.toList(),
          onResult: (uci, eval) {
            if (mounted && session == _evalSession) {
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
        })
        .whenComplete(() {
          // Nothing more will arrive for this session — whether it ran to
          // the last pass, errored, or was cancelled. Clear every "still
          // thinking" signal so none can spin forever.
          if (!mounted || session != _evalSession) return;
          setState(() {
            _pieceAnalysisDone = true;
            _extraMoveEvals = {
              for (final entry in _extraMoveEvals.entries)
                entry.key: entry.value.asFinal(),
            };
          });
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
      final move =
          standardMove(position, NormalMove(from: fromSquare, to: dest));
      // Castling is legal onto g1 and onto the h1 rook: one badge, on the
      // king's destination.
      if (move.to != dest) continue;
      final uci = move.uci;
      final topMove = topMovesMap[uci];
      final isBook = openingBook.isBookMove(position, move);

      MoveClassification? classification;
      String? scoreText;
      String? depthText;
      var isRefining = false;

      // Prefer the dedicated per-move evaluation (same fixed depth as the
      // baseline, so scores match the arrow view); fall back to top-5 data.
      final extra = _extraMoveEvals[uci];
      if (extra != null) {
        // Delivering checkmate is the best move there is.
        classification = extra.mateIn == 0
            ? MoveClassification.best
            : classifyDelta(extra.deltaPawns);
        scoreText = formatEval(extra.centipawns, extra.mateIn);
        depthText = extra.depth > 0 ? 'd${extra.depth}' : null;
        isRefining = !extra.isFinal && !_pieceAnalysisDone;
      } else if (topMove != null && topMove.hasEval) {
        classification = topMove.classification;
        scoreText = formatEval(topMove.centipawns, topMove.mateIn);
        // Borrowed from the arrow search — this move's own evaluation is
        // still queued, so it will change (unless the session has ended).
        isRefining = !_pieceAnalysisDone;
      }

      // Book membership wins the color; the engine's #1 move gets `best`.
      if (isBook) {
        classification = MoveClassification.book;
      } else if (classification != null && uci == bestUci) {
        classification = MoveClassification.best;
      }

      // No data yet (evaluation still running) → animated thinking badge.
      // Once the session has ended, a square without a score just gets a
      // plain badge.
      final hasData = classification != null;
      final isPending = !hasData && !_pieceAnalysisDone;
      final effective = classification ?? MoveClassification.good;
      final color = hasData
          ? colorForClassification(effective)
          : Colors.blueGrey.shade200;
      final icon = uci == bestUci
          ? '👑'
          : hasData
              ? classificationStyle(effective).icon
              : '';

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
        depthText: depthText,
        isPending: isPending,
        isRefining: isRefining,
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

    for (final suggested in gameState.topMoves) {
      final move = parseUci(suggested.uci);
      if (move == null) continue;
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

    return ISet(shapes);
  }
}

/// "Checkmate!" / "Draw!" over the finished position.
class _GameEndBanner extends StatelessWidget {
  final GameEnd end;

  const _GameEndBanner({required this.end});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isMate = end == GameEnd.checkmate;

    return IgnorePointer(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.6, end: 1.0),
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutBack,
              builder: (context, scale, child) =>
                  Transform.scale(scale: scale, child: child),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                decoration: BoxDecoration(
                  color: (isMate ? AppColors.primary : Colors.blueGrey.shade700)
                      .withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isMate
                          ? Icons.emoji_events_rounded
                          : Icons.handshake_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      isMate ? l10n.checkmate : l10n.draw,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PieceAnalysisEntry {
  final Square square;
  final MoveClassification classification;
  final Color color;
  final String icon;
  final String? scoreText;

  /// Search depth behind [scoreText], e.g. "d12" (null = not yet known).
  final String? depthText;

  /// True while this move's evaluation hasn't arrived yet.
  final bool isPending;

  /// True while a deeper pass will still update this move's score.
  final bool isRefining;

  const _PieceAnalysisEntry({
    required this.square,
    required this.classification,
    required this.color,
    required this.icon,
    this.scoreText,
    this.depthText,
    this.isPending = false,
    this.isRefining = false,
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
    // Runs while any square is waiting for its first score (bouncing dots)
    // or is still being refined by a deeper pass (spinner on the depth chip).
    final isActive = widget.analysisEntries.any(
      (e) => e.isPending || (e.isRefining && widget.showScores),
    );
    if (isActive && !_pulse.isAnimating) {
      _pulse.repeat();
    } else if (!isActive && _pulse.isAnimating) {
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
    // The badge sits over the square's top-right corner; kept inside the
    // board so it isn't cut off on the top rank or the right-hand file.
    final maxOffset = math.max(0.0, widget.boardSize - size);
    final left = (offset.dx + _squareSize - size * 0.8).clamp(0.0, maxOffset);
    final top = (offset.dy - size * 0.2).clamp(0.0, maxOffset);

    return Positioned(
      left: left,
      top: top,
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
    final fontSize = (_squareSize * 0.22).clamp(8.0, 15.0);

    return Positioned(
      left: offset.dx,
      top: offset.dy,
      width: _squareSize,
      height: _squareSize,
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
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
              if (entry.depthText != null || entry.isRefining) ...[
                SizedBox(height: _squareSize * 0.03),
                _buildDepthChip(entry),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// "d12" with a spinner while a deeper pass is still coming — tells the
  /// user this square's score is provisional and will keep improving.
  Widget _buildDepthChip(_PieceAnalysisEntry entry) {
    final fontSize = (_squareSize * 0.16).clamp(7.0, 11.0);
    final spinnerSize = fontSize * 1.1;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: fontSize * 0.35, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (entry.isRefining) ...[
            AnimatedBuilder(
              animation: _pulse,
              builder: (context, _) => Transform.rotate(
                angle: _pulse.value * 2 * math.pi,
                child: CustomPaint(
                  size: Size.square(spinnerSize),
                  painter: _SpinnerArcPainter(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ),
            ),
            if (entry.depthText != null) SizedBox(width: fontSize * 0.3),
          ],
          if (entry.depthText != null)
            Text(
              entry.depthText!,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.95),
                fontSize: fontSize,
                fontWeight: FontWeight.w700,
                height: 1.1,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
        ],
      ),
    );
  }
}

/// A three-quarter ring — rotated by the caller to read as a spinner.
class _SpinnerArcPainter extends CustomPainter {
  final Color color;

  const _SpinnerArcPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.2;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromLTWH(
        stroke / 2,
        stroke / 2,
        size.width - stroke,
        size.height - stroke,
      ),
      0,
      math.pi * 1.45,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _SpinnerArcPainter oldDelegate) =>
      oldDelegate.color != color;
}
