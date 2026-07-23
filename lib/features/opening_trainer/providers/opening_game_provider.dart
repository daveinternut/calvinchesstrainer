import 'dart:developer' as dev;

import 'package:dartchess/dartchess.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/audio/audio_service.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/services/opening_book_service.dart';
import '../../../core/services/stockfish_service.dart';
import '../models/opening_game_state.dart';

const _kInitialFEN = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';

final openingGameProvider =
    NotifierProvider<OpeningGameNotifier, OpeningGameState>(
        OpeningGameNotifier.new);

// Fixed search depth for position evaluation (after a move). Depth-based
// searches (unlike movetime) return near-identical results for the same
// position, so displayed scores don't drift between views.
const _kEvalDepth = 12;

// Per-move evaluation passes (selected-piece analysis): a quick shallow
// pass paints every badge fast, then deeper passes refine the numbers in
// place. Each pass re-evaluates the root at its own depth so the deltas
// driving the colors always compare same-depth numbers.
const _kMoveEvalPassDepths = [8, 12, 18];
const _kMoveEvalPassCapMs = [1500, 3000, 6000];

// Progressive hint waves — fast shallow result first, then deeper refinement.
// Each wave also carries a movetime ceiling so a fixed-depth search can't
// run away on a slow device (the cap rarely bites on real hardware).
const _kHintWaveDepths = [8, 12, 16, 18];
const _kHintWaveCapMs = [2500, 5000, 10000, 15000];

// Movetime ceiling for single-position evaluations.
const _kEvalCapMs = 4000;

// How many extra book moves (outside the engine's top list) to show.
const _kMaxBookExtras = 2;


class OpeningGameNotifier extends Notifier<OpeningGameState> {
  Position _position = Chess.initial;

  StockfishService get _stockfish => ref.read(stockfishServiceProvider);
  OpeningBookService get _openingBook => ref.read(openingBookServiceProvider);
  AudioService get _audio => ref.read(audioServiceProvider);
  AnalyticsService get _analytics => ref.read(analyticsServiceProvider);

  @override
  OpeningGameState build() {
    ref.onDispose(_dispose);
    return const OpeningGameState(
      mode: OpeningMode.practice,
      difficulty: OpeningDifficulty.easy,
      playerColor: Side.white,
      currentFen: _kInitialFEN,
    );
  }

  Future<void> startGame(
    OpeningMode mode,
    OpeningDifficulty difficulty,
    Side playerColor,
  ) async {
    _position = Chess.initial;

    state = OpeningGameState(
      mode: mode,
      difficulty: difficulty,
      playerColor: playerColor,
      currentFen: _kInitialFEN,
      lines: [GameLine(moves: const [])],
      livesRemaining: mode == OpeningMode.challenge ? difficulty.lives : 99,
      maxLives: mode == OpeningMode.challenge ? difficulty.lives : 99,
      isPlayerTurn: mode == OpeningMode.practice ? true : playerColor == Side.white,
      isEngineThinking: false,
    );

    _analytics.logOpeningDrillStarted(
      mode: mode.name,
      difficulty: difficulty.name,
      playerColor: playerColor.name,
    );

    try {
      await _stockfish.initialize();
    } catch (e) {
      // Don't give up the session — every engine op re-initializes on
      // demand via _ensureReady, so a transient failure here self-heals.
      dev.log('OpeningGame: Stockfish init failed (will retry on use): $e');
    }

    await _openingBook.load();

    try {
      final eval = await _evalCached(_kInitialFEN, depth: 10);
      state = state.copyWith(currentEval: eval);
    } catch (e) {
      dev.log('OpeningGame: initial eval failed: $e');
    }

    if (mode == OpeningMode.practice) {
      _hintsFuture = _requestHints();
    } else if (!state.isPlayerTurn) {
      _engineMove();
    } else {
      _stopEngine();
    }
  }

  /// Start practice from a specific opening position by replaying its moves.
  Future<void> startFromOpening(String pgn) async {
    _hintFen = null;
    cancelPieceEvals();

    _position = Chess.initial;
    final history = <MoveRecord>[];

    final moveTokens = pgn
        .replaceAll(RegExp(r'\d+\.\s*'), '')
        .trim()
        .split(RegExp(r'\s+'));

    for (final token in moveTokens) {
      if (token.isEmpty) continue;

      // Find the legal move matching this SAN
      NormalMove? foundMove;
      String? foundSan;
      for (final entry in _position.legalMoves.entries) {
        for (final dest in entry.value.squares) {
          final candidate = NormalMove(from: entry.key, to: dest);
          try {
            final (_, san) = _position.makeSan(candidate);
            if (san == token) {
              foundMove = candidate;
              foundSan = san;
              break;
            }
          } catch (_) {}
        }
        if (foundMove != null) break;
      }

      if (foundMove == null || foundSan == null) {
        dev.log('startFromOpening: could not find move "$token"');
        break;
      }

      final (newPos, _) = _position.makeSan(foundMove);
      _position = newPos;

      history.add(MoveRecord(
        fen: _position.fen,
        san: foundSan,
        uci: '${foundMove.from.name}${foundMove.to.name}',
        eval: 0,
        isUserMove: true,
        move: foundMove,
      ));
    }

    final openingInfo = _openingBook.getOpeningForPosition(_position);

    state = state.copyWith(
      currentFen: _position.fen,
      lines: [GameLine(moves: history)],
      activeLineIndex: 0,
      cursorPly: history.length - 1,
      userMoveCount: history.length,
      isPlayerTurn: true,
      isEngineThinking: false,
      isGameOver: false,
      topMoves: const [],
      openingName: () => openingInfo?.name,
      openingEco: () => openingInfo?.eco,
      currentEval: const EvalResult(centipawns: 0),
      engineDepth: -1,
      engineTargetDepth: 0,
    );

    _hintsFuture = _requestHints();
    await _hintsFuture;
  }

  Future<void> handlePlayerMove(NormalMove move) async {
    if (state.isGameOver) return;
    if (state.mode == OpeningMode.challenge &&
        (!state.isPlayerTurn || state.isEngineThinking)) return;

    if (!_position.isLegal(move)) return;

    final isPractice = state.mode == OpeningMode.practice;
    final uciStr = '${move.from.name}${move.to.name}';

    // If this move already exists as a continuation of the current position
    // in some line (the next move of the active line, or the branch move of
    // an existing variation), don't record anything — just navigate there.
    if (isPractice) {
      final existing = _findContinuation(uciStr);
      if (existing != null) {
        await _goTo(existing.$1, existing.$2);
        return;
      }
    }

    // Abort any running engine search, in-progress hint waves and per-move
    // eval session. Don't dispose the engine — just stop the search so the
    // new hints can reuse it immediately without re-initialization delay.
    _hintFen = null;
    cancelPieceEvals();

    final cursorBefore = state.cursorPly;
    final wasAtTip = state.cursorAtTip;

    final (newPosition, san) = _position.makeSan(move);
    _position = newPosition;
    final newFen = _position.fen;

    final hintsBeforeMove = List<SuggestedMove>.from(state.topMoves);

    state = state.copyWith(
      currentFen: newFen,
      userMoveCount: state.userMoveCount + 1,
      isPlayerTurn: isPractice,
      isEngineThinking: !isPractice,
      topMoves: const [],
      lastMoveWasMistake: false,
      previousEval: () => state.currentEval,
    );

    if (isPractice) {
      // Practice: skip separate eval — _requestHints will set the eval
      // from the best move's score, keeping everything consistent.
      final record = MoveRecord(
        fen: newFen,
        san: san,
        uci: uciStr,
        eval: state.currentEval.pawns,
        isUserMove: true,
        move: move,
        hintsBeforeMove: hintsBeforeMove,
      );

      // At the tip: extend the active line. Mid-line with a move the line
      // doesn't contain: branch a new variation off the active line.
      final List<GameLine> lines;
      final int lineIndex;
      final active = state.activeLine ?? const GameLine(moves: []);
      if (wasAtTip) {
        lineIndex = state.lines.isEmpty ? 0 : state.activeLineIndex;
        final extendedLine = active.extended(record);
        lines = state.lines.isEmpty
            ? [extendedLine]
            : ([...state.lines]..[lineIndex] = extendedLine);
      } else {
        final variation = GameLine(
          moves: [...active.moves.sublist(0, cursorBefore + 1), record],
          branchPly: cursorBefore + 1,
          parentIndex: state.activeLineIndex,
        );
        lines = [...state.lines, variation];
        lineIndex = lines.length - 1;
      }
      final ply = lines[lineIndex].moves.length - 1;

      final openingInfo = _openingBook.getOpeningForPosition(_position);

      state = state.copyWith(
        lines: lines,
        activeLineIndex: lineIndex,
        cursorPly: ply,
        isPlayerTurn: true,
        openingName: () => openingInfo?.name ?? state.openingName,
        openingEco: () => openingInfo?.eco ?? state.openingEco,
        lastEngineMove: () => null,
      );

      if (_position.isGameOver) {
        _endGame();
        return;
      }

      // Yield to let any aborted engine search finish unwinding
      await Future.delayed(Duration.zero);

      // The record's eval starts as the pre-move eval; the hint analysis
      // corrects it (keyed by FEN, so navigation can't misdirect the patch
      // — see _linesWithEvalForFen).
      _hintsFuture = _requestHints();
      await _hintsFuture;
      return;
    }

    // Challenge mode: separate eval needed for mistake detection
    EvalResult eval;
    try {
      eval = await _evalCached(newFen, depth: _kEvalDepth);
    } catch (e) {
      dev.log('OpeningGame: eval after move failed: $e');
      eval = state.currentEval;
    }

    final record = MoveRecord(
      fen: newFen,
      san: san,
      uci: uciStr,
      eval: eval.pawns,
      isUserMove: true,
      move: move,
      hintsBeforeMove: hintsBeforeMove,
    );

    final openingInfo = _openingBook.getOpeningForPosition(_position);

    state = state.copyWith(
      currentEval: eval,
      lines: _linesWithTipAppended(record),
      cursorPly: state.cursorPly + 1,
      openingName: () => openingInfo?.name ?? state.openingName,
      openingEco: () => openingInfo?.eco ?? state.openingEco,
    );

    if (_position.isGameOver) {
      _endGame();
      return;
    }

    // Challenge mode: check for mistakes, then CPU responds
    final prevCp = state.previousEval?.centipawns ?? 0;
    final currCp = eval.centipawns;

    final drop = state.playerColor == Side.white
        ? prevCp - currCp
        : currCp - prevCp;

    if (drop > state.difficulty.mistakeThresholdCp) {
      final newLives = state.livesRemaining - 1;
      _audio.playIncorrect();

      if (newLives <= 0) {
        state = state.copyWith(
          livesRemaining: 0,
          lastMoveWasMistake: true,
          isEngineThinking: false,
        );
        _endGame();
        return;
      }

      state = state.copyWith(
        livesRemaining: newLives,
        lastMoveWasMistake: true,
      );
    }

    await _engineMove();
  }

  Future<void> _engineMove() async {
    if (state.isGameOver) return;

    state = state.copyWith(isEngineThinking: true);

    String? bestMoveUci;
    try {
      bestMoveUci = await _stockfish.getBestMove(
        _position.fen,
        movetime: state.difficulty.moveTimeMs,
        skillLevel: state.difficulty.skillLevel,
      );
    } catch (e) {
      dev.log('OpeningGame: getBestMove failed: $e');
    }

    if (bestMoveUci == null || state.isGameOver) {
      state = state.copyWith(
        isPlayerTurn: true,
        isEngineThinking: false,
      );
      return;
    }

    final engineMove = _parseUciMove(bestMoveUci);
    if (engineMove == null || !_position.isLegal(engineMove)) {
      state = state.copyWith(
        isPlayerTurn: true,
        isEngineThinking: false,
      );
      return;
    }

    final (newPosition, san) = _position.makeSan(engineMove);
    _position = newPosition;
    final newFen = _position.fen;

    EvalResult evalAfterEngine;
    try {
      evalAfterEngine = await _evalCached(newFen, depth: _kEvalDepth);
    } catch (e) {
      dev.log('OpeningGame: eval after engine move failed: $e');
      evalAfterEngine = state.currentEval;
    }

    final record = MoveRecord(
      fen: newFen,
      san: san,
      uci: bestMoveUci,
      eval: evalAfterEngine.pawns,
      isUserMove: false,
      move: engineMove,
    );

    final openingInfo = _openingBook.getOpeningForPosition(_position);

    state = state.copyWith(
      currentFen: newFen,
      currentEval: evalAfterEngine,
      lines: _linesWithTipAppended(record),
      cursorPly: state.cursorPly + 1,
      isPlayerTurn: true,
      isEngineThinking: false,
      lastEngineMove: () => engineMove,
      lastMoveWasMistake: false,
      openingName: () => openingInfo?.name ?? state.openingName,
      openingEco: () => openingInfo?.eco ?? state.openingEco,
    );

    if (_position.isGameOver) {
      _endGame();
      return;
    }

    if (state.mode == OpeningMode.practice) {
      _hintsFuture = _requestHints();
      await _hintsFuture;
    } else {
      _stopEngine();
    }
  }

  /// Track which FEN the current hint computation is for.
  /// If the position changes (user moves) mid-wave, later waves bail out.
  String? _hintFen;

  /// Latest computed hint arrows per position, so scrubbing back to an
  /// already-analyzed position restores its arrows (and eval) instantly.
  final Map<String, List<SuggestedMove>> _hintsByFen = {};

  /// The in-flight [_requestHints] future, so [pauseHints] can await it.
  Future<void>? _hintsFuture;

  /// Fully stop hint computation and wait for the in-flight [_requestHints]
  /// to finish before returning.  Call this (and await it) before navigating
  /// away (e.g. pushing the opening picker).
  Future<void> pauseHints() async {
    _hintFen = null;
    cancelPieceEvals();
    _stopEngine();

    final pending = _hintsFuture;
    _hintsFuture = null;
    if (pending != null) {
      try {
        await pending.timeout(const Duration(milliseconds: 500));
      } catch (_) {
        // Timeout or error — the loop has bailed via _hintFen check.
      }
    }

    state = state.copyWith(
      engineDepth: -1,
      engineTargetDepth: 0,
    );
  }

  /// Resume hints for the current position (no-op if an analysis for this
  /// position is already running).
  void resumeHints() {
    if (_hintFen == _position.fen) return;
    if (!state.isGameOver && state.mode == OpeningMode.practice) {
      _hintsFuture = _requestHints();
    }
  }

  Future<void> _requestHints() async {
    if (state.isGameOver) return;

    final fen = _position.fen;
    _hintFen = fen;

    final baselineEvalCp = state.currentEval.centipawns;
    final hintCount = state.mode == OpeningMode.practice ? 5 : 3;

    // Get all legal moves as SAN, find book continuations (sorted by
    // popularity — main lines first, exotic sidelines last).
    final legalMoves = _position.legalMoves;
    final legalSans = <String, NormalMove>{};
    for (final entry in legalMoves.entries) {
      for (final dest in entry.value.squares) {
        final move = NormalMove(from: entry.key, to: dest);
        if (_position.isLegal(move)) {
          final (_, san) = _position.makeSan(move);
          legalSans[san] = move;
        }
      }
    }

    final bookMoves = _openingBook.getBookContinuations(_position, legalSans);

    // Show book moves INSTANTLY before any engine work — but never downgrade
    // already-displayed engine results (e.g. hints resumed after a deselect).
    if (state.topMoves.isEmpty && bookMoves.isNotEmpty) {
      final bookSuggestions = bookMoves.take(hintCount).map((b) {
        final move = legalSans[b.san]!;
        return SuggestedMove(
          uci: '${move.from.name}${move.to.name}',
          san: b.san,
          centipawns: 0,
          isBook: true,
          hasEval: false,
        );
      }).toList();

      state = state.copyWith(topMoves: bookSuggestions);
    }

    final waveDepths = state.mode == OpeningMode.practice
        ? _kHintWaveDepths
        : [_kHintWaveDepths.first];

    for (int i = 0; i < waveDepths.length; i++) {
      if (_hintFen != fen || state.isGameOver) break;

      state = state.copyWith(
        isEngineThinking: i == 0 && state.mode != OpeningMode.practice,
        engineDepth: i == 0 ? 0 : state.engineDepth,
        engineTargetDepth: waveDepths.last,
      );

      List<ScoredMove> moves;
      try {
        moves = await _stockfish.getTopMoves(
          fen,
          count: hintCount,
          depth: waveDepths[i],
          movetime: _kHintWaveCapMs[i],
          onDepth: (d) {
            if (_hintFen == fen && !state.isGameOver && d > state.engineDepth) {
              state = state.copyWith(engineDepth: d);
            }
          },
        );
      } catch (e) {
        dev.log('OpeningGame: getTopMoves wave $i failed: $e');
        break;
      }

      if (_hintFen != fen || state.isGameOver) break;

      // Use the best move's score as the position eval AND as the baseline
      // for the color-classification deltas.
      final bestCp =
          moves.isNotEmpty ? moves.first.centipawns : baselineEvalCp;
      final suggested = _buildSuggestions(moves, bestCp);

      if (suggested.isNotEmpty) {
        // Keep the most popular book moves visible even when they fall
        // outside the engine's top list (main-line transpositions matter
        // more to a learner than the engine's 5th-best try).
        final engineUcis = suggested.map((s) => s.uci).toSet();
        var extras = 0;
        for (final b in bookMoves) {
          if (extras >= _kMaxBookExtras) break;
          final move = legalSans[b.san]!;
          final uci = '${move.from.name}${move.to.name}';
          if (engineUcis.contains(uci)) continue;
          suggested.add(SuggestedMove(
            uci: uci,
            san: b.san,
            centipawns: 0,
            isBook: true,
            hasEval: false,
          ));
          extras++;
        }

        if (_hintsByFen.length > 200) _hintsByFen.clear();
        _hintsByFen[fen] = suggested;

        state = state.copyWith(
          topMoves: suggested,
          currentEval: EvalResult(centipawns: bestCp),
          lines: _linesWithEvalForFen(fen, bestCp / 100.0),
          isEngineThinking: false,
        );
      } else {
        state = state.copyWith(isEngineThinking: false);
      }

      // Don't stop engine between waves — keep it alive so stopSearch()
      // can abort it instantly when the user moves. Only stop after the
      // final wave completes.
    }

    // All waves done (or bailed) — stop the engine for hot-restart safety
    _stopEngine();

    // Clear the depth readout unless a newer analysis for a different
    // position already owns it (_hintFen == null means we were cancelled
    // with nothing else running — e.g. a piece was selected — and the
    // readout would otherwise stay stuck).
    if (_hintFen == fen || _hintFen == null) {
      state = state.copyWith(engineDepth: -1, engineTargetDepth: 0);
    }
  }

  List<SuggestedMove> _buildSuggestions(
    List<ScoredMove> moves,
    int baselineEvalCp,
  ) {
    if (moves.isEmpty) return [];

    final sideMultiplier = _position.turn == Side.white ? 1 : -1;

    final suggested = <SuggestedMove>[];
    for (final scored in moves) {
      final move = _parseUciMove(scored.uci);
      if (move != null && _position.isLegal(move)) {
        final (_, san) = _position.makeSan(move);
        final delta = (scored.centipawns - baselineEvalCp) * sideMultiplier;
        final isBook = _openingBook.isBookMove(_position, move);
        suggested.add(SuggestedMove(
          uci: scored.uci,
          san: san,
          centipawns: scored.centipawns,
          mateIn: scored.mateIn,
          evalDelta: delta,
          isBook: isBook,
          isBest: scored.multipvIndex == 1,
        ));
      }
    }
    return suggested;
  }

  /// Cache of position evals keyed by "fen#depth". Fixed-depth searches are
  /// stable, so cached values keep repeat views identical (and instant).
  final Map<String, EvalResult> _evalCache = {};

  Future<EvalResult> _evalCached(
    String fen, {
    required int depth,
    int capMs = _kEvalCapMs,
  }) async {
    final key = '$fen#$depth';
    final cached = _evalCache[key];
    if (cached != null) return cached;

    var eval = await _stockfish.evaluate(fen, depth: depth, movetime: capMs);
    if (eval.depth == 0) {
      // A bestmove left over from a just-aborted search can complete an
      // eval before any info line arrives. Retry once. (Partial-depth
      // results are NOT retried: they mean the movetime cap bit or we were
      // cancelled — retrying would double the cost for nothing.)
      eval = await _stockfish.evaluate(fen, depth: depth, movetime: capMs);
    }
    // Only cache full-depth results — shallow/aborted ones must not stick.
    if (eval.depth >= depth) {
      if (_evalCache.length > 1000) _evalCache.clear();
      _evalCache[key] = eval;
    }
    return eval;
  }

  /// Engine claim refcount: >0 while [evaluateSpecificMoves] sessions run,
  /// so no code path tears the engine down mid-analysis (see [_stopEngine]).
  int _pieceEvalSessions = 0;

  /// Bumped to cancel running eval loops (superseded selection, deselect).
  int _pieceEvalGeneration = 0;

  /// Cancel any running per-move evaluation loop (e.g. the user deselected
  /// the piece) so a resumed hint search doesn't queue behind stale evals.
  void cancelPieceEvals() {
    _pieceEvalGeneration++;
    _stockfish.stopSearch();
  }

  /// Evaluate specific moves (selected-piece analysis) at a fixed depth.
  /// Returns a map of UCI string → [MoveEval] (absolute post-move eval from
  /// white's perspective + delta vs. this position's eval at the same depth).
  /// [onResult] fires as each move finishes so the UI can fill in
  /// progressively. Pauses thinking waves so these evals run immediately.
  Future<Map<String, MoveEval>> evaluateSpecificMoves(
    List<NormalMove> moves, {
    void Function(String uci, MoveEval eval)? onResult,
  }) async {
    // Claim the engine BEFORE any await: the cancelled hint pass below ends
    // by calling _stopEngine, which must see the claim and leave the native
    // engine alive for our evals. Bumping the generation also cancels any
    // previous still-running session (selecting piece B while A evaluates).
    _pieceEvalSessions++;
    final generation = ++_pieceEvalGeneration;

    try {
      // Pause the thinking waves and abort any running search
      // so these evals can use the engine immediately.
      _hintFen = null;
      _stockfish.stopSearch();
      state = state.copyWith(engineDepth: -1, engineTargetDepth: 0);

      final results = <String, MoveEval>{};
      final rootFen = _position.fen;
      final sideMultiplier = _position.turn == Side.white ? 1 : -1;

      bool cancelled() =>
          generation != _pieceEvalGeneration ||
          _position.fen != rootFen ||
          state.isGameOver;

      // Progressive passes: shallow first so every badge gets a number
      // quickly, then deeper passes overwrite each badge via [onResult].
      // Cached evals make later passes (and re-selections) skip finished
      // work instantly.
      for (int pass = 0; pass < _kMoveEvalPassDepths.length; pass++) {
        if (cancelled()) break;
        final depth = _kMoveEvalPassDepths[pass];
        final capMs = _kMoveEvalPassCapMs[pass];
        final isLastPass = pass == _kMoveEvalPassDepths.length - 1;

        // Baseline at the SAME depth as this pass's per-move evals —
        // comparing a deep root eval against shallow child evals is what
        // made scores disagree between views.
        int rootCp;
        try {
          rootCp =
              (await _evalCached(rootFen, depth: depth, capMs: capMs))
                  .centipawns;
        } catch (e) {
          dev.log('evaluateSpecificMoves: root eval failed: $e');
          rootCp = state.currentEval.centipawns;
        }

        for (final move in moves) {
          // Bail if the game moved on or this session was superseded.
          if (cancelled()) break;
          if (!_position.isLegal(move)) continue;
          try {
            final newPos = _position.playUnchecked(move);
            final eval =
                await _evalCached(newPos.fen, depth: depth, capMs: capMs);
            final delta = (eval.centipawns - rootCp) * sideMultiplier;
            final uci = '${move.from.name}${move.to.name}';
            final moveEval = MoveEval(
              centipawns: eval.centipawns,
              mateIn: eval.mateIn,
              deltaCp: delta,
              // Report the depth actually reached — a movetime cap can cut
              // a pass short, and showing the real depth is more honest
              // than the one we asked for.
              depth: eval.depth > 0 ? eval.depth : depth,
              isFinal: isLastPass,
            );
            results[uci] = moveEval;
            onResult?.call(uci, moveEval);
          } catch (e) {
            dev.log('evaluateSpecificMoves: failed for ${move.from.name}${move.to.name}: $e');
          }
        }
      }
      return results;
    } finally {
      _pieceEvalSessions--;
      // Engine is idle now unless hints have resumed — safe to tear down.
      _stopEngine();
    }
  }

  /// All lines with every record for position [fen] stamped with [evalPawns].
  /// Keyed by FEN so an analysis result can only ever land on the position
  /// it belongs to — this is what keeps the per-line eval tags honest
  /// (records created by the opening picker start at 0.0, and a post-move
  /// patch could otherwise race with navigation).
  List<GameLine> _linesWithEvalForFen(String fen, double evalPawns) {
    List<GameLine>? patched;
    for (int li = 0; li < state.lines.length; li++) {
      var line = state.lines[li];
      for (int ply = 0; ply < line.moves.length; ply++) {
        final record = line.moves[ply];
        if (record.fen == fen && record.eval != evalPawns) {
          line = line.withMoveReplaced(ply, record.withEval(evalPawns));
          patched ??= [...state.lines];
          patched[li] = line;
        }
      }
    }
    return patched ?? state.lines;
  }

  /// The active line with [record] appended at its tip (challenge/engine
  /// path — the cursor is always at the tip there).
  List<GameLine> _linesWithTipAppended(MoveRecord record) {
    if (state.lines.isEmpty) {
      return [
        GameLine(moves: [record])
      ];
    }
    final index = state.activeLineIndex;
    return [...state.lines]..[index] = state.lines[index].extended(record);
  }

  /// If playing [uci] from the current cursor position re-enters a move
  /// that's already recorded — the next move of the active line, or the
  /// branch move of an existing variation — return (lineIndex, ply) to
  /// navigate to instead of recording a duplicate.
  (int, int)? _findContinuation(String uci) {
    final active = state.activeLine;
    if (active == null) return null;
    final cursor = state.cursorPly;
    final cursorFen =
        cursor >= 0 ? active.moves[cursor].fen : _kInitialFEN;

    for (int li = 0; li < state.lines.length; li++) {
      final line = state.lines[li];
      if (line.moves.length <= cursor + 1) continue;
      final prevFen = cursor >= 0
          ? (cursor < line.moves.length ? line.moves[cursor].fen : null)
          : _kInitialFEN;
      if (prevFen != cursorFen) continue;
      if (line.moves[cursor + 1].uci == uci) return (li, cursor + 1);
    }
    return null;
  }

  /// Step one ply back along the active line (non-destructive).
  Future<void> scrubBack() async {
    if (state.cursorPly < 0) return;
    await _goTo(state.activeLineIndex, state.cursorPly - 1);
  }

  /// Step one ply forward along the active line.
  Future<void> scrubForward() async {
    final line = state.activeLine;
    if (line == null || state.cursorPly >= line.moves.length - 1) return;
    await _goTo(state.activeLineIndex, state.cursorPly + 1);
  }

  /// Activate line [lineIndex] and show the position after its move at
  /// [ply] (-1 = starting position). Never discards moves.
  Future<void> goTo(int lineIndex, int ply) => _goTo(lineIndex, ply);

  Future<void> _goTo(int lineIndex, int ply) async {
    if (state.mode != OpeningMode.practice) return;
    if (lineIndex < 0 || lineIndex >= state.lines.length) return;
    final line = state.lines[lineIndex];
    if (ply < -1 || ply >= line.moves.length) return;

    _hintFen = null;
    cancelPieceEvals();

    final record = ply >= 0 ? line.moves[ply] : null;
    final fen = record?.fen ?? _kInitialFEN;
    _position =
        record != null ? Chess.fromSetup(Setup.parseFen(fen)) : Chess.initial;
    final openingInfo = _openingBook.getOpeningForPosition(_position);

    // Best available arrows for this position: results of a previous live
    // analysis, else the arrows recorded when the next move was played here.
    var cachedHints = _hintsByFen[fen] ?? const <SuggestedMove>[];
    if (cachedHints.isEmpty && ply + 1 < line.moves.length) {
      cachedHints = line.moves[ply + 1].hintsBeforeMove;
    }

    // Prefer the eval carried by the cached analysis (deepest known);
    // fall back to the eval stored on the move record.
    final cachedBest =
        cachedHints.where((m) => m.isBest && m.hasEval).toList();
    final evalCp = cachedBest.isNotEmpty
        ? cachedBest.first.centipawns
        : ((record?.eval ?? 0) * 100).round();

    state = state.copyWith(
      currentFen: fen,
      activeLineIndex: lineIndex,
      cursorPly: ply,
      currentEval: EvalResult(centipawns: evalCp),
      topMoves: cachedHints,
      isPlayerTurn: true,
      isEngineThinking: false,
      // Navigating away from a finished line puts play back in progress.
      isGameOver: false,
      openingName: () => openingInfo?.name ?? state.openingName,
      openingEco: () => openingInfo?.eco ?? state.openingEco,
      lastEngineMove: () => null,
    );

    if (cachedHints.isEmpty && state.mode == OpeningMode.practice) {
      _hintsFuture = _requestHints();
      await _hintsFuture;
    }
  }

  /// Stop the engine so its native isolates don't block hot restart.
  /// Called when the engine is idle (user is thinking, game over).
  /// The next engine call re-initializes automatically via _ensureReady().
  ///
  /// If anything is still using the engine — per-move evals, a hint pass
  /// draining — do nothing: quitting a live engine strands its pending
  /// operation and the next initialize stalls in 'Multiple instances'
  /// retries until the old native process exits. Whoever holds the claim
  /// calls _stopEngine again when it finishes.
  void _stopEngine() {
    if (_pieceEvalSessions > 0 || _stockfish.isBusy) return;
    _stockfish.dispose();
  }

  void _endGame() {
    state = state.copyWith(
      isGameOver: true,
      isPlayerTurn: false,
      isEngineThinking: false,
    );

    _audio.playGameOver();
    _stopEngine();

    _analytics.logOpeningDrillCompleted(
      mode: state.mode.name,
      difficulty: state.difficulty.name,
      playerColor: state.playerColor.name,
      userMoves: state.userMoveCount,
      medal: state.currentMedal.name,
      livesUsed: state.maxLives - state.livesRemaining,
    );
  }

  Position get currentPosition => _position;

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

  void _dispose() {
    // Engine is shared via service provider, not disposed here
  }
}
