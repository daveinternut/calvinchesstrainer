import 'dart:async';
import 'dart:developer' as dev;

import 'package:dartchess/dartchess.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/audio/audio_service.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/services/opening_book_service.dart';
import '../../../core/services/stockfish_service.dart';
import '../models/opening_game_state.dart';
import '../models/uci_move.dart';

const _kInitialFEN = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';

/// One game session per visit to the screen. Auto-disposed with it, so no
/// analysis outlives the screen: disposal stops the search and hands the
/// engine back once its queue drains (see [OpeningGameNotifier._onDispose]).
final openingGameProvider =
    NotifierProvider.autoDispose<OpeningGameNotifier, OpeningGameState>(
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

/// Hint analysis of one position: its arrows, and how far the waves got —
/// so revisiting a position resumes the deeper waves instead of keeping a
/// shallow (depth-8) result for good.
class _PositionHints {
  final List<SuggestedMove> moves;

  /// Index into the wave list of the last wave that completed.
  final int wave;

  const _PositionHints(this.moves, this.wave);

  bool get isComplete => wave >= _kHintWaveDepths.length - 1;
}

class OpeningGameNotifier extends Notifier<OpeningGameState> {
  Position _position = Chess.initial;

  // Read once in build(): continuations that resume after the provider was
  // disposed must never need `ref` to reach the engine. (Read, not watched:
  // these services are fixed for the app's lifetime, and a rebuild would
  // reset the game.)
  late StockfishService _engine;
  late OpeningBookService _book;
  late AnalyticsService _analytics;

  /// Only touched synchronously, right after a `ref.mounted` check.
  AudioService get _audio => ref.read(audioServiceProvider);

  /// Bumped by every [startGame] / [startFromOpening] (and by disposal): a
  /// superseded start's continuation must not touch the game that replaced
  /// it.
  int _gameGeneration = 0;

  @override
  OpeningGameState build() {
    _engine = ref.read(stockfishServiceProvider);
    _book = ref.read(openingBookServiceProvider);
    _analytics = ref.read(analyticsServiceProvider);
    ref.onDispose(_onDispose);
    return const OpeningGameState(
      mode: OpeningMode.practice,
      difficulty: OpeningDifficulty.easy,
      playerColor: Side.white,
      currentFen: _kInitialFEN,
    );
  }

  /// The screen is gone: invalidate every in-flight continuation, abort the
  /// search (queued operations are dropped with it) and hand the engine back
  /// once its queue has drained. The engine is kept for the whole session
  /// until here — restarting it costs a network reload and leaks native file
  /// descriptors (see `stockfish_engine_io.dart`).
  void _onDispose() {
    _gameGeneration++;
    _pieceEvalGeneration++;
    _hintFen = null;
    _hintsFuture = null;
    _engine.stopSearch();
    _engine.disposeWhenIdle();
  }

  Future<void> startGame(
    OpeningMode mode,
    OpeningDifficulty difficulty,
    Side playerColor,
  ) async {
    final generation = ++_gameGeneration;
    _hintFen = null;
    cancelPieceEvals();
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

    // The engine and the opening book load in parallel, so book arrows and
    // the opening name never wait for the engine (on web, a 1.7 MB download).
    final engineStarted = _startEngine();
    await _ensureBookLoaded();
    if (!ref.mounted || generation != _gameGeneration) return;

    if (mode == OpeningMode.practice) {
      // The first wave waits for the engine start inside the service.
      _hintsFuture = _requestHints();
      return;
    }

    // Challenge (not reachable from the UI yet): a baseline eval for mistake
    // detection, then the engine opens if it plays white.
    if (!await engineStarted) return;
    if (!ref.mounted || generation != _gameGeneration) return;
    try {
      final eval = await _evalCached(_position, depth: 10);
      if (!ref.mounted || generation != _gameGeneration) return;
      state = state.copyWith(currentEval: eval);
    } catch (e) {
      dev.log('OpeningGame: initial eval failed: $e');
      if (!ref.mounted || generation != _gameGeneration) return;
    }
    if (!state.isPlayerTurn) await _engineMove();
  }

  /// Waits for the opening book (shared, loaded once; no wait once it is).
  /// A book that fails to load only costs the names and book arrows.
  Future<void> _ensureBookLoaded() async {
    if (_book.isLoaded) return;
    try {
      await _book.load();
    } catch (e) {
      dev.log('OpeningGame: opening book failed to load: $e');
    }
  }

  /// Start the engine, raising the "engine unavailable" banner on failure.
  /// Never throws.
  Future<bool> _startEngine() async {
    try {
      await _engine.initialize();
    } catch (e) {
      _markEngineUnavailable(e);
      return false;
    }
    if (ref.mounted && state.engineUnavailable) {
      state = state.copyWith(engineUnavailable: false);
    }
    return true;
  }

  void _markEngineUnavailable(Object error) {
    dev.log('OpeningGame: engine unavailable: $error');
    if (ref.mounted) state = state.copyWith(engineUnavailable: true);
  }

  /// The banner's Retry button: start the engine again, then pick the
  /// analysis of the current position back up.
  Future<void> retryEngine() async {
    state = state.copyWith(engineUnavailable: false);
    if (!await _startEngine() || !ref.mounted) return;
    _hintFen = null;
    resumeHints();
  }

  /// Start practice from a specific opening position by replaying its moves.
  Future<void> startFromOpening(String pgn) async {
    final generation = ++_gameGeneration;
    _hintFen = null;
    cancelPieceEvals();

    // The book names the position; on a fresh screen it may still be loading.
    await _ensureBookLoaded();
    if (!ref.mounted || generation != _gameGeneration) return;

    Position position = Chess.initial;
    final history = <MoveRecord>[];
    final tokens = pgn
        .replaceAll(RegExp(r'\d+\.\s*'), '')
        .trim()
        .split(RegExp(r'\s+'));
    for (final token in tokens) {
      if (token.isEmpty) continue;
      final parsed = position.parseSan(token);
      if (parsed is! NormalMove) {
        dev.log('startFromOpening: could not find move "$token"');
        break;
      }
      final move = standardMove(position, parsed);
      final (next, san) = position.makeSan(move);
      position = next;
      history.add(MoveRecord(
        fen: position.fen,
        san: san,
        uci: move.uci,
        eval: 0,
        isUserMove: true,
        move: move,
      ));
    }

    // A move made while the book loaded is superseded as well.
    _hintFen = null;
    cancelPieceEvals();
    _position = position;
    final openingInfo = _book.getOpeningForPosition(position);

    state = state.copyWith(
      currentFen: position.fen,
      lines: [GameLine(moves: history)],
      activeLineIndex: 0,
      cursorPly: history.length - 1,
      userMoveCount: history.length,
      isPlayerTurn: true,
      isEngineThinking: false,
      isGameOver: false,
      gameEnd: () => null,
      topMoves: const [],
      openingName: () => openingInfo?.name,
      openingEco: () => openingInfo?.eco,
      currentEval: const EvalResult(centipawns: 0),
      lastMove: () => history.isEmpty ? null : history.last.move,
      engineDepth: -1,
      engineTargetDepth: 0,
    );

    _hintsFuture = _requestHints();
    await _hintsFuture;
  }

  Future<void> handlePlayerMove(NormalMove playedMove) async {
    if (state.isGameOver) return;
    if (state.mode == OpeningMode.challenge &&
        (!state.isPlayerTurn || state.isEngineThinking)) {
      return;
    }

    // One spelling for every move: castling e1g1 (however it was dragged),
    // promotion explicit.
    final move = standardMove(_position, playedMove);
    if (!_position.isLegal(move)) return;

    final isPractice = state.mode == OpeningMode.practice;
    final uciStr = move.uci;

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
    // eval session. The engine itself stays up for the next analysis.
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
      lastMove: () => move,
    );

    if (isPractice) {
      // Practice: skip separate eval — _requestHints will set the eval
      // from the best move's score, keeping everything consistent. The
      // record's eval starts as the pre-move eval; the hint analysis
      // corrects it (keyed by FEN, so navigation can't misdirect the patch
      // — see _linesWithEvalForFen).
      final record = MoveRecord(
        fen: newFen,
        san: san,
        uci: uciStr,
        eval: state.currentEval.pawns,
        mateIn: state.currentEval.mateIn,
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

      final openingInfo = _book.getOpeningForPosition(_position);

      state = state.copyWith(
        lines: lines,
        activeLineIndex: lineIndex,
        cursorPly: ply,
        isPlayerTurn: true,
        openingName: () => openingInfo?.name ?? state.openingName,
        openingEco: () => openingInfo?.eco ?? state.openingEco,
      );

      if (_position.isGameOver) {
        _endGame();
        return;
      }

      _hintsFuture = _requestHints();
      await _hintsFuture;
      return;
    }

    // Challenge mode: separate eval needed for mistake detection
    final generation = _gameGeneration;
    EvalResult? eval;
    try {
      eval = await _evalCached(_position, depth: _kEvalDepth);
    } on EngineUnavailableException catch (e) {
      _markEngineUnavailable(e);
    } catch (e) {
      dev.log('OpeningGame: eval after move failed: $e');
    }
    if (!ref.mounted || generation != _gameGeneration) return;
    final result = eval ?? state.currentEval;

    final record = MoveRecord(
      fen: newFen,
      san: san,
      uci: uciStr,
      eval: result.pawns,
      mateIn: result.mateIn,
      isUserMove: true,
      move: move,
      hintsBeforeMove: hintsBeforeMove,
    );

    final openingInfo = _book.getOpeningForPosition(_position);

    state = state.copyWith(
      currentEval: result,
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
    final currCp = result.centipawns;

    final drop = state.playerColor == Side.white
        ? prevCp - currCp
        : currCp - prevCp;

    if (drop > state.difficulty.mistakeThresholdCp) {
      final newLives = state.livesRemaining - 1;
      unawaited(_audio.playIncorrect());

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

  /// The CPU opponent's reply (challenge mode only).
  Future<void> _engineMove() async {
    if (state.isGameOver || _position.isGameOver) return;
    final generation = _gameGeneration;
    final fenBefore = _position.fen;

    state = state.copyWith(isEngineThinking: true);

    String? bestMoveUci;
    try {
      bestMoveUci = await _engine.getBestMove(
        fenBefore,
        movetime: state.difficulty.moveTimeMs,
        skillLevel: state.difficulty.skillLevel,
      );
    } on EngineUnavailableException catch (e) {
      _markEngineUnavailable(e);
    } catch (e) {
      dev.log('OpeningGame: getBestMove failed: $e');
    }
    if (!ref.mounted || generation != _gameGeneration) return;

    // Only ever applied to the position it was computed for.
    final engineMove = bestMoveUci == null ? null : parseUci(bestMoveUci);
    if (engineMove == null ||
        state.isGameOver ||
        _position.fen != fenBefore ||
        !_position.isLegal(engineMove)) {
      state = state.copyWith(
        isPlayerTurn: true,
        isEngineThinking: false,
      );
      return;
    }

    final move = standardMove(_position, engineMove);
    final (newPosition, san) = _position.makeSan(move);
    _position = newPosition;
    final newFen = _position.fen;

    EvalResult? evalAfterEngine;
    try {
      evalAfterEngine = await _evalCached(newPosition, depth: _kEvalDepth);
    } catch (e) {
      dev.log('OpeningGame: eval after engine move failed: $e');
    }
    if (!ref.mounted || generation != _gameGeneration) return;
    final result = evalAfterEngine ?? state.currentEval;

    final record = MoveRecord(
      fen: newFen,
      san: san,
      uci: move.uci,
      eval: result.pawns,
      mateIn: result.mateIn,
      isUserMove: false,
      move: move,
    );

    final openingInfo = _book.getOpeningForPosition(_position);

    state = state.copyWith(
      currentFen: newFen,
      currentEval: result,
      lines: _linesWithTipAppended(record),
      cursorPly: state.cursorPly + 1,
      isPlayerTurn: true,
      isEngineThinking: false,
      lastMove: () => move,
      lastMoveWasMistake: false,
      openingName: () => openingInfo?.name ?? state.openingName,
      openingEco: () => openingInfo?.eco ?? state.openingEco,
    );

    if (_position.isGameOver) _endGame();
  }

  /// Track which FEN the current hint computation is for.
  /// If the position changes (user moves) mid-wave, later waves bail out.
  String? _hintFen;

  /// Latest hint analysis per position, so scrubbing back to an analyzed
  /// position restores its arrows (and eval) instantly — and resumes the
  /// remaining waves if it was cut short.
  final Map<String, _PositionHints> _hintsByFen = {};

  /// The in-flight [_requestHints] future, so [pauseHints] can await it.
  Future<void>? _hintsFuture;

  /// Fully stop hint computation and wait for the in-flight [_requestHints]
  /// to finish before returning. Call this (and await it) before navigating
  /// away (e.g. pushing the opening picker).
  Future<void> pauseHints() async {
    _hintFen = null;
    cancelPieceEvals();

    final pending = _hintsFuture;
    _hintsFuture = null;
    if (pending != null) {
      try {
        await pending.timeout(const Duration(milliseconds: 500));
      } catch (_) {
        // Timeout or error — the loop has bailed via the _hintFen check.
      }
    }
    if (!ref.mounted) return;

    state = state.copyWith(
      engineDepth: -1,
      engineTargetDepth: 0,
    );
  }

  /// The app went to the background: stop thinking (iOS would freeze the
  /// search mid-way anyway). [resumeHints] picks the position up again.
  void pauseAnalysis() {
    _hintFen = null;
    _hintsFuture = null;
    cancelPieceEvals();
    state = state.copyWith(engineDepth: -1, engineTargetDepth: 0);
  }

  /// Resume hints for the current position: a no-op if this position is
  /// already being analysed, an instant restore if it was fully analysed
  /// before, otherwise the waves continue from where they stopped.
  void resumeHints() {
    if (state.isGameOver || state.mode != OpeningMode.practice) return;
    final fen = _position.fen;
    if (_hintFen == fen) return;

    final cached = _hintsByFen[fen];
    if (cached != null && cached.isComplete) {
      state = state.copyWith(
        topMoves: cached.moves,
        currentEval: _evalOf(cached.moves) ?? state.currentEval,
      );
      return;
    }
    _hintsFuture = _requestHints(fromWave: cached == null ? 0 : cached.wave + 1);
  }

  Future<void> _requestHints({int fromWave = 0}) async {
    // A finished position is never analysed.
    if (state.isGameOver || _position.isGameOver) return;

    final position = _position;
    final fen = position.fen;
    _hintFen = fen;

    final isPractice = state.mode == OpeningMode.practice;
    final hintCount = isPractice ? 5 : 3;
    final waveDepths =
        isPractice ? _kHintWaveDepths : [_kHintWaveDepths.first];

    // Every legal move by SAN, in standard UCI (castling e1g1 rather than
    // dartchess's e1h1), so book moves and engine moves share one key.
    final legalSans = <String, NormalMove>{};
    for (final entry in position.legalMoves.entries) {
      for (final dest in entry.value.squares) {
        final move =
            standardMove(position, NormalMove(from: entry.key, to: dest));
        final (_, san) = position.makeSan(move);
        legalSans[san] = move;
      }
    }

    // Book continuations, sorted by popularity — main lines first, exotic
    // sidelines last.
    final bookMoves = _book.getBookContinuations(position, legalSans);

    // Show book moves INSTANTLY before any engine work — but never downgrade
    // already-displayed engine results (e.g. hints resumed after a deselect).
    if (state.topMoves.isEmpty && bookMoves.isNotEmpty) {
      state = state.copyWith(topMoves: [
        for (final b in bookMoves.take(hintCount))
          SuggestedMove(
            uci: legalSans[b.san]!.uci,
            san: b.san,
            centipawns: 0,
            isBook: true,
            hasEval: false,
          ),
      ]);
    }

    for (var i = fromWave; i < waveDepths.length; i++) {
      if (_hintFen != fen || state.isGameOver) break;

      state = state.copyWith(
        isEngineThinking: i == 0 && !isPractice,
        engineDepth: i == fromWave ? 0 : state.engineDepth,
        engineTargetDepth: waveDepths.last,
      );

      final List<ScoredMove> moves;
      try {
        moves = await _engine.getTopMoves(
          fen,
          count: hintCount,
          depth: waveDepths[i],
          movetime: _kHintWaveCapMs[i],
          onDepth: (d) {
            if (ref.mounted &&
                _hintFen == fen &&
                !state.isGameOver &&
                d > state.engineDepth) {
              state = state.copyWith(engineDepth: d);
            }
          },
        );
      } on SearchCancelledException {
        break;
      } on EngineUnavailableException catch (e) {
        _markEngineUnavailable(e);
        break;
      } catch (e) {
        dev.log('OpeningGame: getTopMoves wave $i failed: $e');
        break;
      }

      if (!ref.mounted) return;
      if (_hintFen != fen || state.isGameOver) break;

      final suggested = _buildSuggestions(position, moves);
      if (suggested.isEmpty) {
        state = state.copyWith(isEngineThinking: false);
        continue;
      }

      // Keep the most popular book moves visible even when they fall
      // outside the engine's top list (main-line transpositions matter
      // more to a learner than the engine's 5th-best try).
      final engineUcis = {for (final s in suggested) s.uci};
      var extras = 0;
      for (final b in bookMoves) {
        if (extras >= _kMaxBookExtras) break;
        final uci = legalSans[b.san]!.uci;
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
      _hintsByFen[fen] = _PositionHints(suggested, i);

      // The best move's score is the position eval AND the baseline for the
      // color-classification deltas.
      final best = moves.first;
      final eval = EvalResult(centipawns: best.centipawns, mateIn: best.mateIn);
      state = state.copyWith(
        topMoves: suggested,
        currentEval: eval,
        lines: _linesWithEvalForFen(fen, eval),
        isEngineThinking: false,
        engineUnavailable: false,
      );
    }

    if (!ref.mounted) return;
    // Clear the depth readout unless a newer analysis for a different
    // position already owns it (_hintFen == null means we were cancelled
    // with nothing else running — e.g. a piece was selected — and the
    // readout would otherwise stay stuck).
    if (_hintFen == fen || _hintFen == null) {
      state = state.copyWith(engineDepth: -1, engineTargetDepth: 0);
    }
  }

  List<SuggestedMove> _buildSuggestions(
    Position position,
    List<ScoredMove> moves,
  ) {
    if (moves.isEmpty) return [];

    final baselineCp = moves.first.centipawns;
    final sideMultiplier = position.turn == Side.white ? 1 : -1;

    final suggested = <SuggestedMove>[];
    final seen = <String>{};
    for (final scored in moves) {
      final parsed = parseUci(scored.uci);
      if (parsed == null) continue;
      final move = standardMove(position, parsed);
      if (!position.isLegal(move) || !seen.add(move.uci)) continue;
      final (_, san) = position.makeSan(move);
      suggested.add(SuggestedMove(
        uci: move.uci,
        san: san,
        centipawns: scored.centipawns,
        mateIn: scored.mateIn,
        evalDelta: (scored.centipawns - baselineCp) * sideMultiplier,
        isBook: _book.isBookMove(position, move),
        isBest: scored.multipvIndex == 1,
      ));
    }
    return suggested;
  }

  /// The position eval carried by an analysis result (its best move's).
  static EvalResult? _evalOf(List<SuggestedMove> hints) {
    for (final m in hints) {
      if (m.isBest && m.hasEval) {
        return EvalResult(centipawns: m.centipawns, mateIn: m.mateIn);
      }
    }
    return null;
  }

  /// The verdict on a finished position, which the engine is never asked
  /// about: checkmate is mate 0, signed for the winner; anything else (the
  /// positions dartchess calls game over: stalemate, insufficient material)
  /// is a draw.
  static EvalResult? _terminalEval(Position position) {
    if (!position.isGameOver) return null;
    if (position.isCheckmate) {
      return EvalResult(
        centipawns: position.turn == Side.white ? -10000 : 10000,
        mateIn: 0,
      );
    }
    return const EvalResult(centipawns: 0);
  }

  /// Cache of position evals keyed by "fen#depth". Fixed-depth searches are
  /// stable, so cached values keep repeat views identical (and instant).
  final Map<String, EvalResult> _evalCache = {};

  Future<EvalResult> _evalCached(
    Position position, {
    required int depth,
    int capMs = _kEvalCapMs,
  }) async {
    final terminal = _terminalEval(position);
    if (terminal != null) return terminal;

    final fen = position.fen;
    final key = '$fen#$depth';
    final cached = _evalCache[key];
    if (cached != null) return cached;

    final eval = await _engine.evaluate(fen, depth: depth, movetime: capMs);
    // Only cache full-depth results — shallow/aborted ones must not stick.
    if (eval.depth >= depth) {
      if (_evalCache.length > 1000) _evalCache.clear();
      _evalCache[key] = eval;
    }
    return eval;
  }

  /// Bumped to cancel running eval loops (superseded selection, deselect).
  int _pieceEvalGeneration = 0;

  /// Cancel any running per-move evaluation loop (e.g. the user deselected
  /// the piece) so a resumed hint search doesn't queue behind stale evals.
  void cancelPieceEvals() {
    _pieceEvalGeneration++;
    _engine.stopSearch();
  }

  /// Evaluate specific moves (selected-piece analysis) at a fixed depth.
  /// Returns a map of standard UCI (`e1g1`, `e7e8q` — see `uci_move.dart`)
  /// → [MoveEval] (absolute post-move eval from white's perspective + delta
  /// vs. this position's eval at the same depth). [onResult] fires as each
  /// move finishes so the UI can fill in progressively. Pauses thinking
  /// waves so these evals run immediately.
  Future<Map<String, MoveEval>> evaluateSpecificMoves(
    List<NormalMove> moves, {
    void Function(String uci, MoveEval eval)? onResult,
  }) async {
    // Bumping the generation also cancels any previous still-running
    // session (selecting piece B while A evaluates).
    final generation = ++_pieceEvalGeneration;
    final results = <String, MoveEval>{};
    if (state.isGameOver || _position.isGameOver) return results;

    // Pause the thinking waves and abort any running search
    // so these evals can use the engine immediately.
    _hintFen = null;
    _engine.stopSearch();
    state = state.copyWith(engineDepth: -1, engineTargetDepth: 0);

    final root = _position;
    final rootFen = root.fen;
    final sideMultiplier = root.turn == Side.white ? 1 : -1;

    // Standard spelling — badge keys must match the engine's (`e7e8q`) — and
    // de-duplicated: both king destinations (g1 and the h1 rook) castle.
    final targets = <String, NormalMove>{};
    for (final m in moves) {
      final move = standardMove(root, m);
      if (root.isLegal(move)) targets[move.uci] = move;
    }

    bool cancelled() =>
        !ref.mounted ||
        generation != _pieceEvalGeneration ||
        _position.fen != rootFen ||
        state.isGameOver;

    // Progressive passes: shallow first so every badge gets a number
    // quickly, then deeper passes overwrite each badge via [onResult].
    // Cached evals make later passes (and re-selections) skip finished
    // work instantly.
    for (var pass = 0; pass < _kMoveEvalPassDepths.length; pass++) {
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
            (await _evalCached(root, depth: depth, capMs: capMs)).centipawns;
      } on SearchCancelledException {
        break;
      } on EngineUnavailableException catch (e) {
        _markEngineUnavailable(e);
        break;
      } catch (e) {
        dev.log('evaluateSpecificMoves: root eval failed: $e');
        if (cancelled()) break;
        rootCp = state.currentEval.centipawns;
      }

      for (final entry in targets.entries) {
        if (cancelled()) break;
        final child = root.playUnchecked(entry.value);
        final terminal = child.isGameOver;
        // A finished position is reported final on the first pass.
        if (terminal && pass > 0) continue;
        try {
          final eval = await _evalCached(child, depth: depth, capMs: capMs);
          if (cancelled()) break;
          final moveEval = MoveEval(
            centipawns: eval.centipawns,
            mateIn: eval.mateIn,
            deltaCp: (eval.centipawns - rootCp) * sideMultiplier,
            // Report the depth actually reached — a movetime cap can cut
            // a pass short, and showing the real depth is more honest
            // than the one we asked for.
            depth: terminal ? 0 : (eval.depth > 0 ? eval.depth : depth),
            isFinal: terminal || isLastPass,
          );
          results[entry.key] = moveEval;
          onResult?.call(entry.key, moveEval);
        } on SearchCancelledException {
          break;
        } on EngineUnavailableException catch (e) {
          _markEngineUnavailable(e);
          return results;
        } catch (e) {
          dev.log('evaluateSpecificMoves: failed for ${entry.key}: $e');
        }
      }
    }
    return results;
  }

  /// All lines with every record for position [fen] stamped with [eval].
  /// Keyed by FEN so an analysis result can only ever land on the position
  /// it belongs to — this is what keeps the per-line eval tags honest
  /// (records created by the opening picker start at 0.0, and a post-move
  /// patch could otherwise race with navigation).
  List<GameLine> _linesWithEvalForFen(String fen, EvalResult eval) {
    List<GameLine>? patched;
    for (var li = 0; li < state.lines.length; li++) {
      var line = state.lines[li];
      for (var ply = 0; ply < line.moves.length; ply++) {
        final record = line.moves[ply];
        if (record.fen == fen &&
            (record.eval != eval.pawns || record.mateIn != eval.mateIn)) {
          line = line.withMoveReplaced(ply, record.withEval(eval));
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

  /// If playing [uci] (standard UCI) from the current cursor position
  /// re-enters a move that's already recorded — the next move of the active
  /// line, or the branch move of an existing variation — return
  /// (lineIndex, ply) to navigate to instead of recording a duplicate.
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
    final openingInfo = _book.getOpeningForPosition(_position);

    // Best available arrows for this position: a previous live analysis,
    // else the arrows recorded when the next move was played here.
    final cached = _hintsByFen[fen];
    var hints = cached?.moves ?? const <SuggestedMove>[];
    if (hints.isEmpty && ply + 1 < line.moves.length) {
      hints = line.moves[ply + 1].hintsBeforeMove;
    }

    // A finished position gets its verdict and the banner; otherwise prefer
    // the eval carried by the cached analysis (deepest known), falling back
    // to the one stored on the move record.
    final terminal = _terminalEval(_position);
    final eval = terminal ??
        _evalOf(hints) ??
        EvalResult(
          centipawns: ((record?.eval ?? 0) * 100).round(),
          mateIn: record?.mateIn,
        );
    final gameEnd = terminal == null
        ? null
        : (_position.isCheckmate ? GameEnd.checkmate : GameEnd.draw);

    state = state.copyWith(
      currentFen: fen,
      activeLineIndex: lineIndex,
      cursorPly: ply,
      currentEval: eval,
      topMoves: terminal != null ? const [] : hints,
      isPlayerTurn: true,
      isEngineThinking: false,
      // Navigating away from a finished line puts play back in progress.
      isGameOver: terminal != null,
      gameEnd: () => gameEnd,
      openingName: () => openingInfo?.name ?? state.openingName,
      openingEco: () => openingInfo?.eco ?? state.openingEco,
      lastMove: () => record?.move,
      engineDepth: -1,
      engineTargetDepth: 0,
    );

    // Analyse unless finished, or already analysed to the last wave.
    if (terminal != null || (cached?.isComplete ?? false)) return;
    _hintsFuture =
        _requestHints(fromWave: cached == null ? 0 : cached.wave + 1);
    await _hintsFuture;
  }

  /// The game is over: banner, verdict, sound. Nothing about a finished
  /// position is ever asked of the engine.
  void _endGame() {
    final mated = _position.isCheckmate;
    final verdict =
        _terminalEval(_position) ?? const EvalResult(centipawns: 0);
    _hintFen = null;

    state = state.copyWith(
      isGameOver: true,
      gameEnd: () => mated ? GameEnd.checkmate : GameEnd.draw,
      isPlayerTurn: false,
      isEngineThinking: false,
      topMoves: const [],
      currentEval: verdict,
      lines: _linesWithEvalForFen(_position.fen, verdict),
      engineDepth: -1,
      engineTargetDepth: 0,
    );

    unawaited(mated ? _audio.playCheckmateCall() : _audio.playGameOver());

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
}
