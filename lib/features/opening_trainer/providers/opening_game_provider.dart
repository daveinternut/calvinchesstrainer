import 'dart:developer' as dev;
import 'dart:math';

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

// Time budget (ms) for position evaluation (after a move).
const _kEvalTimeMs = 500;

// Progressive hint waves — fast first result, then deeper refinement.
const _kHintWavesMs = [500, 1500, 4000, 10000];


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
      dev.log('OpeningGame: Stockfish init failed: $e');
      state = state.copyWith(isEngineThinking: false);
      return;
    }

    await _openingBook.load();

    try {
      final eval = await _stockfish.evaluate(_kInitialFEN, movetime: 200);
      state = state.copyWith(currentEval: eval);
    } catch (e) {
      dev.log('OpeningGame: initial eval failed: $e');
    }

    _stopEngine();

    if (mode == OpeningMode.practice) {
      _hintsFuture = _requestHints();
    } else if (!state.isPlayerTurn) {
      _engineMove();
    }
  }

  /// Start practice from a specific opening position by replaying its moves.
  Future<void> startFromOpening(String pgn) async {
    _hintFen = null;
    _stockfish.stopSearch();

    _position = Chess.initial;
    final sanMoves = <String>[];
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
      sanMoves.add(foundSan);
    }

    final openingInfo = _openingBook.getOpening(sanMoves);

    state = state.copyWith(
      currentFen: _position.fen,
      moveHistory: history,
      sanMoves: sanMoves,
      userMoveCount: sanMoves.length,
      isPlayerTurn: true,
      isEngineThinking: false,
      isGameOver: false,
      topMoves: const [],
      openingName: () => openingInfo?.name,
      openingEco: () => openingInfo?.eco,
      currentEval: const EvalResult(centipawns: 0),
      thinkingWave: -1,
      thinkingTotalWaves: 0,
    );

    _hintsFuture = _requestHints();
    await _hintsFuture;
  }

  Future<void> handlePlayerMove(NormalMove move) async {
    if (state.isGameOver) return;
    if (state.mode == OpeningMode.challenge &&
        (!state.isPlayerTurn || state.isEngineThinking)) return;

    if (!_position.isLegal(move)) return;

    // Abort any running engine search and cancel in-progress hint waves.
    // Don't dispose the engine — just stop the search so the new hints
    // can reuse it immediately without re-initialization delay.
    _hintFen = null;
    _stockfish.stopSearch();

    final (newPosition, san) = _position.makeSan(move);
    _position = newPosition;
    final newFen = _position.fen;

    final newSanMoves = [...state.sanMoves, san];
    final hintsBeforeMove = List<SuggestedMove>.from(state.topMoves);

    final isPractice = state.mode == OpeningMode.practice;

    state = state.copyWith(
      currentFen: newFen,
      sanMoves: newSanMoves,
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
        uci: '${move.from.name}${move.to.name}',
        eval: state.currentEval.pawns,
        isUserMove: true,
        move: move,
        hintsBeforeMove: hintsBeforeMove,
      );

      final openingInfo = _openingBook.getOpening(newSanMoves);

      state = state.copyWith(
        moveHistory: [...state.moveHistory, record],
        isPlayerTurn: true,
        openingName: () => openingInfo?.name ?? state.openingName,
        openingEco: () => openingInfo?.eco ?? state.openingEco,
      );

      if (_position.isGameOver) {
        _endGame();
        return;
      }

      // Yield to let any aborted engine search finish unwinding
      await Future.delayed(Duration.zero);

      _hintsFuture = _requestHints();
      await _hintsFuture;

      // Update the move record's eval now that hints set the real eval
      if (state.moveHistory.isNotEmpty) {
        final updatedHistory = List<MoveRecord>.from(state.moveHistory);
        final last = updatedHistory.last;
        updatedHistory[updatedHistory.length - 1] = MoveRecord(
          fen: last.fen,
          san: last.san,
          uci: last.uci,
          eval: state.currentEval.pawns,
          isUserMove: last.isUserMove,
          move: last.move,
          hintsBeforeMove: last.hintsBeforeMove,
        );
        state = state.copyWith(moveHistory: updatedHistory);
      }
      return;
    }

    // Challenge mode: separate eval needed for mistake detection
    EvalResult eval;
    try {
      eval = await _stockfish.evaluate(newFen, movetime: _kEvalTimeMs);
    } catch (e) {
      dev.log('OpeningGame: eval after move failed: $e');
      eval = state.currentEval;
    }

    final record = MoveRecord(
      fen: newFen,
      san: san,
      uci: '${move.from.name}${move.to.name}',
      eval: eval.pawns,
      isUserMove: true,
      move: move,
      hintsBeforeMove: hintsBeforeMove,
    );

    final openingInfo = _openingBook.getOpening(newSanMoves);

    state = state.copyWith(
      currentEval: eval,
      moveHistory: [...state.moveHistory, record],
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
    final newSanMoves = [...state.sanMoves, san];

    EvalResult evalAfterEngine;
    try {
      evalAfterEngine =
          await _stockfish.evaluate(newFen, movetime: _kEvalTimeMs);
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

    final openingInfo = _openingBook.getOpening(newSanMoves);

    state = state.copyWith(
      currentFen: newFen,
      currentEval: evalAfterEngine,
      moveHistory: [...state.moveHistory, record],
      sanMoves: newSanMoves,
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

  /// The in-flight [_requestHints] future, so [pauseHints] can await it.
  Future<void>? _hintsFuture;

  /// Fully stop hint computation and wait for the in-flight [_requestHints]
  /// to finish before returning.  Call this (and await it) before navigating
  /// away (e.g. pushing the opening picker).
  Future<void> pauseHints() async {
    _hintFen = null;
    _stockfish.stopSearch();
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
      thinkingWave: -1,
      thinkingTotalWaves: 0,
    );
  }

  /// Resume hints for the current position.
  void resumeHints() {
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

    // Show book moves INSTANTLY before any engine work.
    // Get all legal moves as SAN, find book continuations.
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

    final bookMoves = _openingBook.getBookContinuations(
      state.sanMoves,
      legalSans.keys.toList(),
    );

    if (bookMoves.length >= hintCount) {
      final topBook = bookMoves.take(hintCount).toList();
      final bookSuggestions = topBook.map((b) {
        final move = legalSans[b.san]!;
        return SuggestedMove(
          uci: '${move.from.name}${move.to.name}',
          san: b.san,
          centipawns: baselineEvalCp,
          evalDelta: 0,
          isBook: true,
        );
      }).toList();

      state = state.copyWith(topMoves: bookSuggestions);
    }
    final waves = state.mode == OpeningMode.practice
        ? _kHintWavesMs
        : [_kHintWavesMs.first];

    for (int i = 0; i < waves.length; i++) {
      if (_hintFen != fen || state.isGameOver) break;

      state = state.copyWith(
        isEngineThinking: i == 0 && state.mode != OpeningMode.practice,
        thinkingWave: i,
        thinkingTotalWaves: waves.length,
      );

      List<ScoredMove> moves;
      try {
        moves = await _stockfish.getTopMoves(
          fen,
          count: hintCount,
          movetime: waves[i],
        );
      } catch (e) {
        dev.log('OpeningGame: getTopMoves wave $i failed: $e');
        break;
      }

      if (_hintFen != fen || state.isGameOver) break;

      // Use the best move's score as the position eval AND as the
      // baseline for deltas. This avoids stale baselines after bad moves.
      final bestCp =
          moves.isNotEmpty ? moves.first.centipawns : baselineEvalCp;
      final suggested = _buildSuggestions(moves, bestCp);

      if (suggested.isNotEmpty) {
        state = state.copyWith(
          topMoves: suggested,
          currentEval: EvalResult(centipawns: bestCp),
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

    if (_hintFen == fen) {
      state = state.copyWith(thinkingWave: -1, thinkingTotalWaves: 0);
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
        final isBook = _openingBook.isBookMove(state.sanMoves, san);
        suggested.add(SuggestedMove(
          uci: scored.uci,
          san: san,
          centipawns: scored.centipawns,
          mateIn: scored.mateIn,
          evalDelta: delta,
          isBook: isBook,
        ));
      }
    }
    return suggested;
  }

  /// Evaluate specific moves that aren't in the top 5.
  /// Returns a map of UCI string → eval delta in centipawns.
  /// Pauses thinking waves so these evaluations run immediately.
  Future<Map<String, int>> evaluateSpecificMoves(List<NormalMove> moves) async {
    // Pause the thinking waves and abort any running search
    // so these evals can use the engine immediately.
    _hintFen = null;
    _stockfish.stopSearch();

    // Brief yield to let the wave loop bail
    await Future.delayed(Duration.zero);

    final results = <String, int>{};
    final currentCp = state.currentEval.centipawns;
    final sideMultiplier = _position.turn == Side.white ? 1 : -1;

    for (final move in moves) {
      if (!_position.isLegal(move)) continue;
      try {
        final newPos = _position.playUnchecked(move);
        final eval = await _stockfish.evaluate(newPos.fen, movetime: 100);
        final delta = (eval.centipawns - currentCp) * sideMultiplier;
        results['${move.from.name}${move.to.name}'] = delta;
      } catch (e) {
        dev.log('evaluateSpecificMoves: failed for ${move.from.name}${move.to.name}: $e');
      }
    }
    return results;
  }

  Future<void> undoMove() async {
    if (state.moveHistory.isEmpty || state.isEngineThinking) return;

    _hintFen = null;
    _stockfish.stopSearch();

    final history = List<MoveRecord>.from(state.moveHistory);
    final sans = List<String>.from(state.sanMoves);

    final undone = history.removeLast();
    sans.removeLast();

    // Restore the cached hints from the undone move — these are the
    // exact arrows the user saw before making that move.
    final cachedHints = undone.hintsBeforeMove;

    if (history.isEmpty) {
      _position = Chess.initial;
      final openingInfo = _openingBook.getOpening(sans);
      state = state.copyWith(
        currentFen: _kInitialFEN,
        moveHistory: history,
        sanMoves: sans,
        userMoveCount: max(0, state.userMoveCount - 1),
        currentEval: const EvalResult(centipawns: 0),
        topMoves: cachedHints,
        isPlayerTurn: true,
        openingName: () => openingInfo?.name,
        openingEco: () => openingInfo?.eco,
        lastEngineMove: () => null,
      );
    } else {
      final prev = history.last;
      _position = Chess.fromSetup(Setup.parseFen(prev.fen));
      final openingInfo = _openingBook.getOpening(sans);
      state = state.copyWith(
        currentFen: prev.fen,
        moveHistory: history,
        sanMoves: sans,
        userMoveCount: max(0, state.userMoveCount - 1),
        currentEval: EvalResult(centipawns: (prev.eval * 100).round()),
        topMoves: cachedHints,
        isPlayerTurn: true,
        openingName: () => openingInfo?.name ?? state.openingName,
        openingEco: () => openingInfo?.eco ?? state.openingEco,
        lastEngineMove: () => null,
      );
    }

    // If no cached hints (e.g. initial position), recompute
    if (cachedHints.isEmpty && state.mode == OpeningMode.practice) {
      _hintsFuture = _requestHints();
      await _hintsFuture;
    }
  }

  /// Stop the engine so its native isolates don't block hot restart.
  /// Called when the engine is idle (user is thinking, game over).
  /// The next engine call re-initializes automatically via _ensureReady().
  void _stopEngine() {
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

  void startReview() {
    if (state.moveHistory.isEmpty) return;
    _position = Chess.initial;

    state = state.copyWith(
      isReviewing: true,
      reviewIndex: -1,
      currentFen: _kInitialFEN,
      currentEval: const EvalResult(centipawns: 0),
      lastEngineMove: () => null,
    );
  }

  void reviewForward() {
    if (!state.isReviewing) return;
    final nextIndex = state.reviewIndex + 1;
    if (nextIndex >= state.moveHistory.length) return;

    final record = state.moveHistory[nextIndex];

    _position = Chess.fromSetup(Setup.parseFen(record.fen));

    state = state.copyWith(
      reviewIndex: nextIndex,
      currentFen: record.fen,
      currentEval: EvalResult(centipawns: (record.eval * 100).round()),
      lastEngineMove: () =>
          !record.isUserMove ? record.move : state.lastEngineMove,
    );
  }

  void reviewBack() {
    if (!state.isReviewing) return;
    final prevIndex = state.reviewIndex - 1;

    if (prevIndex < 0) {
      _position = Chess.initial;
      state = state.copyWith(
        reviewIndex: -1,
        currentFen: _kInitialFEN,
        currentEval: const EvalResult(centipawns: 0),
        lastEngineMove: () => null,
      );
      return;
    }

    final record = state.moveHistory[prevIndex];
    _position = Chess.fromSetup(Setup.parseFen(record.fen));

    state = state.copyWith(
      reviewIndex: prevIndex,
      currentFen: record.fen,
      currentEval: EvalResult(centipawns: (record.eval * 100).round()),
      lastEngineMove: () =>
          !record.isUserMove ? record.move : null,
    );
  }

  void exitReview() {
    if (state.moveHistory.isNotEmpty) {
      final lastRecord = state.moveHistory.last;
      _position = Chess.fromSetup(Setup.parseFen(lastRecord.fen));
    }
    state = state.copyWith(
      isReviewing: false,
      reviewIndex: -1,
      currentFen: state.moveHistory.isNotEmpty
          ? state.moveHistory.last.fen
          : _kInitialFEN,
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
