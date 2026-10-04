/// Native (iOS/Android) engine implementation: real Stockfish over `dart:ffi`.
///
/// Selected by the conditional import in `stockfish_service.dart` wherever
/// `dart:js_interop` is unavailable. Its web counterpart is
/// `stockfish_engine_web.dart` (Stockfish WASM in a Web Worker).
///
/// > **Mirror warning.** The UCI handling and the engine lifecycle below
/// > (operation queue, start / release, the timeout drain, score parsing,
/// > white-perspective normalisation, the MultiPV depth snapshot) are
/// > deliberately duplicated in `stockfish_engine_web.dart` rather than
/// > shared. **Fix a protocol or lifecycle bug in both files.**
library;

import 'dart:async';
import 'dart:developer' as dev;
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:stockfish/stockfish.dart';

import 'stockfish_engine_api.dart';

/// Stockfish ships as a native binary, so it is always available here.
const bool kEngineAvailable = true;

StockfishService createStockfishService() => NativeStockfishService();

/// Send "quit" directly to any lingering native Stockfish thread via FFI.
/// Call this at the top of main() so hot restart can unblock the old engine's
/// stdout isolate (which is stuck in a blocking nativeStdoutRead FFI call).
void cleanupForRestart() {
  try {
    final nativeLib = Platform.isAndroid
        ? DynamicLibrary.open('libstockfish.so')
        : DynamicLibrary.process();
    final stdinWrite = nativeLib
        .lookup<NativeFunction<IntPtr Function(Pointer<Utf8>)>>(
            'stockfish_stdin_write')
        .asFunction<int Function(Pointer<Utf8>)>();
    final ptr = 'quit\n'.toNativeUtf8();
    stdinWrite(ptr);
    calloc.free(ptr);
  } catch (_) {}
}

/// The one native Stockfish, owned by the app's single [StockfishService]
/// (`stockfishServiceProvider`). The `stockfish` package allows one native
/// engine per process: `Stockfish()` throws until the previous engine has
/// fully exited.
///
/// The engine starts on demand and then stays up for the whole Opening
/// trainer session; the screen hands it back through [disposeWhenIdle] when
/// it closes. Restarting is expensive: it reloads the network, and the
/// package's native glue opens two new pipes per start without closing the
/// old ones (4 file descriptors leaked per start — on iOS's default limit of
/// 256 that eventually breaks every file open in the app). Hence one start
/// per screen visit, and `AppDelegate.swift` raising the soft limit to 4096.
class NativeStockfishService implements StockfishService {
  NativeStockfishService()
      : this._(
          Stockfish.new,
          const Duration(seconds: 10),
          const Duration(seconds: 30),
          const Duration(seconds: 5),
          const Duration(milliseconds: 500),
        );

  /// Drives a fake engine with short timeouts — the native library is only
  /// built for iOS and Android, so tests cannot start the real one.
  @visibleForTesting
  NativeStockfishService.forTesting({
    required Stockfish Function() createEngine,
    Duration startTimeout = const Duration(seconds: 10),
    Duration searchTimeout = const Duration(seconds: 30),
    Duration drainTimeout = const Duration(seconds: 5),
    Duration retryDelay = const Duration(milliseconds: 500),
  }) : this._(
          createEngine,
          startTimeout,
          searchTimeout,
          drainTimeout,
          retryDelay,
        );

  NativeStockfishService._(
    this._createEngine,
    this._startTimeout,
    this._searchTimeout,
    this._drainTimeout,
    this._retryDelay,
  );

  final Stockfish Function() _createEngine;

  /// Ceiling for each start phase (native threads up; UCI handshake).
  final Duration _startTimeout;

  /// Ceiling for one search. Searches carry their own `movetime` caps, so
  /// this only fires when the app was frozen mid-search (iPad asleep or in
  /// the background).
  final Duration _searchTimeout;

  /// How long a timed-out search may take to answer `stop` with its
  /// `bestmove` before the engine is restarted.
  final Duration _drainTimeout;

  /// Base backoff while the previous native engine finishes exiting.
  final Duration _retryDelay;

  Stockfish? _stockfish;
  bool _isReady = false;

  /// The start in progress, if any. It counts as busy, so the engine is
  /// never released half-started (quitting a starting engine fails, and the
  /// package's one-engine slot then stays taken for good).
  Future<void>? _initFuture;

  /// Why the last start failed. Operations fail fast with it until
  /// [initialize] is called again (the screen's Retry button).
  EngineUnavailableException? _startFailure;

  /// Serialization gate — engine operations run strictly one at a time.
  /// The UCI protocol has no request ids: an op's stdout listener would
  /// otherwise parse info/bestmove lines belonging to another op's search.
  Future<void> _opTail = Future.value();
  int _activeOps = 0;

  /// Bumped by [stopSearch]: an operation queued under an older epoch is
  /// dropped when its turn comes instead of starting a search nobody wants.
  int _epoch = 0;

  /// Set by [disposeWhenIdle]; cleared by any new request for the engine.
  bool _releaseRequested = false;

  @override
  bool get isReady => _isReady && _stockfish != null;

  @override
  bool get isBusy => _activeOps > 0 || _initFuture != null;

  Future<T> _serialized<T>(Future<T> Function(int epoch) op) async {
    final epoch = _epoch;
    _releaseRequested = false;
    _activeOps++;
    final prev = _opTail;
    final gate = Completer<void>();
    _opTail = gate.future;
    try {
      await prev;
      if (epoch != _epoch) throw const SearchCancelledException();
      return await op(epoch);
    } finally {
      gate.complete();
      _activeOps--;
      _releaseIfIdle();
    }
  }

  @override
  Future<void> initialize() {
    _releaseRequested = false;
    _startFailure = null;
    return _start();
  }

  /// Joins the start in progress, or begins one. [_initFuture] is assigned
  /// before any of the start runs, so a start that settles early can never
  /// leave it set (which would read as busy forever).
  Future<void> _start() {
    if (isReady) return Future.value();
    final inFlight = _initFuture;
    if (inFlight != null) return inFlight;

    final done = Completer<void>();
    _initFuture = done.future;
    _doInitialize().then(
      (_) {
        _initFuture = null;
        done.complete();
      },
      onError: (Object e, StackTrace stack) {
        _initFuture = null;
        final failure =
            e is EngineUnavailableException ? e : EngineUnavailableException(e);
        _startFailure = failure;
        done.completeError(failure, stack);
      },
    ).whenComplete(_releaseIfIdle);
    return done.future;
  }

  Future<void> _doInitialize() async {
    // A start that failed earlier may have left an engine behind.
    final stale = _stockfish;
    if (stale != null) _dropEngine(stale);

    final sf = await _createWithRetry();
    _stockfish = sf;
    try {
      await _waitUntilRunning(sf);
      await _handshake(sf);
    } catch (e) {
      dev.log('StockfishService: engine failed to start: $e');
      _dropEngine(sf);
      rethrow;
    }

    // Only a live, still-current engine is ever marked ready.
    if (!identical(_stockfish, sf) ||
        sf.state.value != StockfishState.ready) {
      _dropEngine(sf);
      throw const EngineUnavailableException('Stockfish stopped while starting');
    }
    _isReady = true;
  }

  /// Create a [Stockfish], retrying while the previous native engine is
  /// still exiting ("Multiple instances" — after a release or a hot restart).
  Future<Stockfish> _createWithRetry() async {
    for (var attempt = 1;; attempt++) {
      try {
        return _createEngine();
      } on StateError catch (e) {
        dev.log('StockfishService: create attempt $attempt/6 failed: $e');
        if (attempt >= 6) rethrow;
        await Future<void>.delayed(_retryDelay * attempt);
      }
    }
  }

  /// Wait for the package to report its native threads running.
  Future<void> _waitUntilRunning(Stockfish sf) async {
    if (sf.state.value == StockfishState.ready) return;
    final running = Completer<void>();
    void listener() {
      if (running.isCompleted) return;
      final v = sf.state.value;
      if (v == StockfishState.ready) {
        running.complete();
      } else if (v == StockfishState.error || v == StockfishState.disposed) {
        running.completeError(StateError('Stockfish entered state $v'));
      }
    }

    sf.state.addListener(listener);
    listener(); // It may have changed before we subscribed.
    try {
      await running.future.timeout(_startTimeout);
    } finally {
      sf.state.removeListener(listener);
    }
  }

  Future<void> _handshake(Stockfish sf) async {
    final readyok = Completer<void>();
    final sub = sf.stdout.listen((line) {
      if (line == 'readyok' && !readyok.isCompleted) readyok.complete();
    });
    try {
      sf.stdin = 'uci';
      sf.stdin = 'isready';
      await readyok.future.timeout(_startTimeout);
    } finally {
      await sub.cancel();
    }
  }

  /// Forget [sf] if it is still the current engine, and make it exit.
  void _dropEngine(Stockfish sf) {
    if (identical(_stockfish, sf)) {
      _stockfish = null;
      _isReady = false;
    }
    _quit(sf);
  }

  /// Ask [sf] to exit. The package only accepts 'quit' from a running
  /// engine, and keeps its one-engine slot taken until the native side has
  /// exited — so an engine that is still starting is quit the moment it
  /// comes up, instead of being orphaned where nothing can ever replace it.
  static void _quit(Stockfish sf) {
    void sendQuit() {
      try {
        sf.dispose();
      } catch (e) {
        dev.log('StockfishService: quit failed (ignored): $e');
      }
    }

    switch (sf.state.value) {
      case StockfishState.ready:
        sendQuit();
      case StockfishState.starting:
        void listener() {
          final v = sf.state.value;
          if (v == StockfishState.starting) return;
          sf.state.removeListener(listener);
          if (v == StockfishState.ready) sendQuit();
        }
        sf.state.addListener(listener);
      case StockfishState.error:
      case StockfishState.disposed:
        // Already gone; the package has released its slot.
        break;
    }
  }

  Future<Stockfish> _ensureReady() async {
    final current = _stockfish;
    if (_isReady &&
        current != null &&
        current.state.value != StockfishState.ready) {
      dev.log('StockfishService: engine stopped unexpectedly; restarting');
      _dropEngine(current);
    }
    final failure = _startFailure;
    if (failure != null) throw failure;
    await _start();
    final sf = _stockfish;
    if (sf == null || !_isReady) {
      throw const EngineUnavailableException('Stockfish unavailable');
    }
    return sf;
  }

  void _releaseIfIdle() {
    if (!_releaseRequested || isBusy) return;
    _releaseRequested = false;
    final sf = _stockfish;
    if (sf != null) _dropEngine(sf);
  }

  @override
  void disposeWhenIdle() {
    _releaseRequested = true;
    _releaseIfIdle();
  }

  @override
  void dispose() {
    stopSearch();
    disposeWhenIdle();
  }

  /// Abort the running search ("stop" makes the engine answer with its
  /// bestmove at once) and drop everything queued behind it.
  @override
  void stopSearch() {
    _epoch++;
    final sf = _stockfish;
    if (sf != null && _isReady) _send(sf, 'stop');
  }

  static void _send(Stockfish sf, String command) {
    try {
      sf.stdin = command;
    } catch (_) {}
  }

  /// Run one search: send [commands] (ending with `go`) and feed every
  /// output line to [onLine]. Returns only once that search's own
  /// `bestmove` has been read. On timeout it sends `stop` and keeps waiting:
  /// returning early would leave the late `bestmove` to be read as the
  /// *next* operation's result, shifting every result after it by one. An
  /// engine that won't answer `stop` is restarted.
  Future<void> _search(
    int epoch,
    List<String> commands,
    void Function(String line) onLine,
  ) async {
    final sf = await _ensureReady();
    if (epoch != _epoch) throw const SearchCancelledException();

    final finished = Completer<void>();
    finished.future.ignore(); // Errors are read below, never left unhandled.
    final sub = sf.stdout.listen(
      (line) {
        onLine(line);
        if (line.startsWith('bestmove') && !finished.isCompleted) {
          finished.complete();
        }
      },
      onDone: () {
        if (!finished.isCompleted) {
          finished.completeError(
              const EngineUnavailableException('Stockfish exited'));
        }
      },
    );

    try {
      try {
        for (final command in commands) {
          sf.stdin = command;
        }
      } catch (e) {
        throw EngineUnavailableException(e);
      }
      try {
        await finished.future.timeout(_searchTimeout);
      } on TimeoutException {
        _send(sf, 'stop');
        try {
          await finished.future.timeout(_drainTimeout);
        } on TimeoutException {
          dev.log('StockfishService: no bestmove after stop; restarting');
          _dropEngine(sf);
        }
      }
    } on EngineUnavailableException {
      _dropEngine(sf);
      rethrow;
    } finally {
      await sub.cancel();
    }
  }

  String _goCommand({int? depth, int? movetime}) {
    // Depth + movetime combine: the engine stops at whichever comes first.
    // Callers pass movetime as a ceiling so a fixed-depth search can't run
    // away on a slow device.
    if (depth != null && movetime != null) {
      return 'go depth $depth movetime $movetime';
    }
    if (movetime != null) return 'go movetime $movetime';
    return 'go depth ${depth ?? 10}';
  }

  static bool _isBlackToMove(String fen) {
    final parts = fen.split(' ');
    return parts.length > 1 && parts[1] == 'b';
  }

  /// Stockfish returns scores from the side-to-move's perspective.
  /// Negate when black is to move so all our values are from white's perspective.
  static EvalResult _toWhitePerspective(EvalResult raw, String fen) {
    if (!_isBlackToMove(fen)) return raw;
    return EvalResult(
      centipawns: -raw.centipawns,
      mateIn: raw.mateIn != null ? -raw.mateIn! : null,
      depth: raw.depth,
    );
  }

  @override
  Future<EvalResult> evaluate(
    String fen, {
    int? depth,
    int? movetime,
  }) {
    return _serialized((epoch) async {
      EvalResult? last;
      await _search(epoch, [
        'setoption name Skill Level value 20',
        'setoption name MultiPV value 1',
        'position fen $fen',
        _goCommand(depth: depth, movetime: movetime),
      ], (line) {
        if (line.startsWith('info ') && line.contains('score ')) {
          final result = _parseEval(line);
          if (result != null) last = result;
        }
      });
      return _toWhitePerspective(last ?? const EvalResult(centipawns: 0), fen);
    });
  }

  @override
  Future<String?> getBestMove(
    String fen, {
    int? depth,
    int? movetime,
    int skillLevel = 20,
  }) {
    return _serialized((epoch) async {
      String? best;
      await _search(epoch, [
        'setoption name Skill Level value $skillLevel',
        'setoption name MultiPV value 1',
        'position fen $fen',
        _goCommand(depth: depth, movetime: movetime),
      ], (line) {
        if (line.startsWith('bestmove ')) {
          best = RegExp(r'bestmove (\S+)').firstMatch(line)?.group(1);
        }
      });
      // `bestmove (none)`: the position has no legal move.
      return best == '(none)' ? null : best;
    });
  }

  /// Get the top N moves for a position (for practice mode hint arrows).
  ///
  /// All returned scores come from the same search depth (the deepest fully
  /// reported iteration) so the moves are directly comparable — mixing depths
  /// skews relative scores. [onDepth] streams the current search depth as
  /// iterations complete, for a live progress readout.
  @override
  Future<List<ScoredMove>> getTopMoves(
    String fen, {
    int count = 3,
    int? depth,
    int? movetime,
    void Function(int depth)? onDepth,
  }) {
    return _serialized((epoch) async {
      // Snapshot per depth iteration: `current` collects the iteration being
      // reported now; when the engine moves on to a deeper iteration, the
      // previous one is kept as `lastComplete`. At the end we prefer the
      // current iteration only if it reported at least as many moves as the
      // previous one (a `stop` can cut an iteration short mid-report).
      var currentDepth = 0;
      var current = <int, ScoredMove>{};
      var lastComplete = <int, ScoredMove>{};

      await _search(epoch, [
        'setoption name Skill Level value 20',
        'setoption name MultiPV value $count',
        'position fen $fen',
        _goCommand(depth: depth, movetime: movetime),
      ], (line) {
        if (!line.startsWith('info ') || !line.contains('multipv ')) return;
        final mpvMatch = RegExp(r'multipv (\d+)').firstMatch(line);
        final pvMatch = RegExp(r' pv (\S+)').firstMatch(line);
        final eval = _parseEval(line);
        if (mpvMatch == null || pvMatch == null || eval == null) return;

        if (eval.depth > currentDepth) {
          if (current.length >= lastComplete.length) {
            lastComplete = current;
          }
          current = <int, ScoredMove>{};
          currentDepth = eval.depth;
          onDepth?.call(currentDepth);
        }
        final mpv = int.parse(mpvMatch.group(1)!);
        final normalized = _toWhitePerspective(eval, fen);
        current[mpv] = ScoredMove(
          uci: pvMatch.group(1)!,
          centipawns: normalized.centipawns,
          mateIn: normalized.mateIn,
          multipvIndex: mpv,
        );
      });

      final chosen =
          current.length >= lastComplete.length ? current : lastComplete;
      return chosen.values.toList()
        ..sort((a, b) => a.multipvIndex.compareTo(b.multipvIndex));
    });
  }

  static EvalResult? _parseEval(String line) {
    final depthMatch = RegExp(r'\bdepth (\d+)').firstMatch(line);
    final depth = depthMatch != null ? int.parse(depthMatch.group(1)!) : 0;

    final mateMatch = RegExp(r'score mate (-?\d+)').firstMatch(line);
    if (mateMatch != null) {
      final mateIn = int.parse(mateMatch.group(1)!);
      // `mate 0`: the side to move is checkmated.
      final cp = mateIn > 0 ? 10000 : -10000;
      return EvalResult(centipawns: cp, mateIn: mateIn, depth: depth);
    }

    final cpMatch = RegExp(r'score cp (-?\d+)').firstMatch(line);
    if (cpMatch != null) {
      return EvalResult(centipawns: int.parse(cpMatch.group(1)!), depth: depth);
    }

    return null;
  }
}
