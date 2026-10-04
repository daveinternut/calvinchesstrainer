/// Web engine: Stockfish 19 Lite compiled to WebAssembly, in a Web Worker.
///
/// Selected by the conditional import in `stockfish_service.dart` on web. The
/// native path (`stockfish_engine_io.dart`, real Stockfish over `dart:ffi`) is
/// untouched by anything in this file — iOS and Android never compile it, and
/// it adds no pub dependency, only `dart:js_interop` from the SDK.
///
/// The engine binary lives in `web/stockfish/` (see the README there for which
/// build variant and why). It is **single-threaded** on purpose: the
/// multi-threaded builds need `SharedArrayBuffer`, which would force
/// `Cross-Origin-Opener-Policy` / `Cross-Origin-Embedder-Policy` on the host
/// and drag CanvasKit off the gstatic CDN. Single-threaded still reaches
/// depth 15 in 500 ms, well past the app's hardest setting (skill 18 / 500 ms).
///
/// Loading is lazy: the Worker — and therefore the 1.7 MB `.wasm` — is only
/// created on the first [WebStockfishService.initialize], which happens when
/// the Opening Trainer screen opens, and it then lives for that screen's
/// session (released through `disposeWhenIdle` when the screen closes). The
/// home screen never pays for it.
///
/// > **Mirror warning.** The UCI handling and the engine lifecycle below
/// > (operation queue, start / release, the timeout drain, score parsing,
/// > white-perspective normalisation, the MultiPV depth snapshot) are
/// > deliberately duplicated from `stockfish_engine_io.dart` rather than
/// > refactored into a shared base, so that web support cannot destabilise
/// > the shipping native engine. **Fix a protocol or lifecycle bug in both
/// > files.** This mirrors the existing `scan_engine.dart` ↔
/// > `curate_scanning_positions.py` convention in this repo.
library;

import 'dart:async';
import 'dart:developer' as dev;
import 'dart:js_interop';

import 'stockfish_engine_api.dart';

/// Web has a real engine.
const bool kEngineAvailable = true;

StockfishService createStockfishService() => WebStockfishService();

/// No-op: there is no lingering native thread to quit on web.
void cleanupForRestart() {}

/// Path to the emscripten glue, relative to the document base.
///
/// The glue locates its `.wasm` sibling relative to **its own** URL, so both
/// files must stay in the same directory. Keep in sync with `web/stockfish/`.
const String _kEngineWorkerUrl = 'stockfish/stockfish-19-lite-single.js';

/// The first `isready` only returns once the worker has downloaded and
/// instantiated its wasm, so this covers the 1.7 MB fetch as well as
/// startup — hence far longer than the native start timeout. A worker that
/// fails to load reports an error event and fails at once instead.
const Duration _kStartTimeout = Duration(seconds: 45);

/// Ceiling for one search. Searches carry their own `movetime` caps, so this
/// only fires when the page was frozen mid-search (a background tab).
const Duration _kSearchTimeout = Duration(seconds: 30);

/// How long a timed-out search may take to answer `stop` with its `bestmove`
/// before the worker is replaced.
const Duration _kDrainTimeout = Duration(seconds: 5);

// --- Minimal JS interop ------------------------------------------------------
// Declared inline rather than pulling in `package:web`, so the web build adds
// no dependency that native resolution has to care about.

@JS('Worker')
extension type _Worker._(JSObject _) implements JSObject {
  external factory _Worker(String scriptUrl);
  external void postMessage(JSAny? message);
  external void terminate();
  external set onmessage(JSFunction? value);
  external set onerror(JSFunction? value);
}

extension type _MessageEvent._(JSObject _) implements JSObject {
  external JSAny? get data;
}

extension type _ErrorEvent._(JSObject _) implements JSObject {
  external String? get message;
}

// -----------------------------------------------------------------------------

class WebStockfishService implements StockfishService {
  _Worker? _worker;
  bool _isReady = false;

  /// The start in progress, if any. It counts as busy, so the worker is
  /// never released half-started.
  Future<void>? _initFuture;

  /// Why the last start failed. Operations fail fast with it until
  /// [initialize] is called again (the screen's Retry button) — otherwise
  /// every move would sit out another 45 s start timeout.
  EngineUnavailableException? _startFailure;

  /// Every line the engine has emitted. Broadcast because each operation
  /// attaches its own short-lived listener, exactly like the native stdout.
  final StreamController<String> _lines = StreamController<String>.broadcast();

  /// Worker error events: the script failed to load, or the wasm crashed.
  final StreamController<String> _errors =
      StreamController<String>.broadcast();

  /// Serialization gate — engine operations run strictly one at a time.
  /// The UCI protocol has no request ids: an op's listener would otherwise
  /// parse info/bestmove lines belonging to another op's search.
  Future<void> _opTail = Future.value();
  int _activeOps = 0;

  /// Bumped by [stopSearch]: an operation queued under an older epoch is
  /// dropped when its turn comes instead of starting a search nobody wants.
  int _epoch = 0;

  /// Set by [disposeWhenIdle]; cleared by any new request for the engine.
  bool _releaseRequested = false;

  @override
  bool get isReady => _isReady && _worker != null;

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

  static void _post(_Worker worker, String command) {
    worker.postMessage(command.toJS);
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
    // A start that failed earlier may have left a worker behind.
    final stale = _worker;
    if (stale != null) _dropWorker(stale);

    final worker = _createWorker();
    _worker = worker;

    final readyok = Completer<void>();
    final lineSub = _lines.stream.listen((line) {
      if (line == 'readyok' && !readyok.isCompleted) readyok.complete();
    });
    final errorSub = _errors.stream.listen((message) {
      if (!readyok.isCompleted) {
        readyok.completeError(StateError('worker error: $message'));
      }
    });
    try {
      _post(worker, 'uci');
      _post(worker, 'isready');
      await readyok.future.timeout(_kStartTimeout);
    } catch (e) {
      dev.log('StockfishService(web): engine failed to start: $e');
      _dropWorker(worker);
      rethrow;
    } finally {
      await lineSub.cancel();
      await errorSub.cancel();
    }

    // Only a live, still-current worker is ever marked ready.
    if (!identical(_worker, worker)) {
      throw const EngineUnavailableException('Stockfish stopped while starting');
    }
    _isReady = true;
  }

  _Worker _createWorker() {
    final worker = _Worker(_kEngineWorkerUrl);
    worker.onmessage = ((_MessageEvent event) {
      final data = event.data;
      // The engine posts UCI text lines; ignore anything else it emits.
      if (data != null && data.isA<JSString>()) {
        final line = (data as JSString).toDart;
        if (!_lines.isClosed) _lines.add(line);
      }
    }).toJS;
    worker.onerror = ((_ErrorEvent event) {
      final message = event.message ?? 'unknown error';
      dev.log('StockfishService(web): worker error: $message');
      if (!_errors.isClosed) _errors.add(message);
    }).toJS;
    return worker;
  }

  /// Forget [worker] if it is still the current one, and terminate it.
  void _dropWorker(_Worker worker) {
    if (identical(_worker, worker)) {
      _worker = null;
      _isReady = false;
    }
    try {
      worker.onmessage = null;
      worker.onerror = null;
      worker.terminate();
    } catch (e) {
      dev.log('StockfishService(web): terminate error (ignored): $e');
    }
  }

  Future<_Worker> _ensureReady() async {
    final failure = _startFailure;
    if (failure != null) throw failure;
    await _start();
    final worker = _worker;
    if (worker == null || !_isReady) {
      throw const EngineUnavailableException('Stockfish unavailable');
    }
    return worker;
  }

  void _releaseIfIdle() {
    if (!_releaseRequested || isBusy) return;
    _releaseRequested = false;
    final worker = _worker;
    if (worker != null) _dropWorker(worker);
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
    final worker = _worker;
    if (worker != null && _isReady) _post(worker, 'stop');
  }

  /// Run one search: send [commands] (ending with `go`) and feed every
  /// output line to [onLine]. Returns only once that search's own
  /// `bestmove` has been read. On timeout it sends `stop` and keeps waiting:
  /// returning early would leave the late `bestmove` to be read as the
  /// *next* operation's result, shifting every result after it by one. A
  /// worker that won't answer `stop` is replaced.
  Future<void> _search(
    int epoch,
    List<String> commands,
    void Function(String line) onLine,
  ) async {
    final worker = await _ensureReady();
    if (epoch != _epoch) throw const SearchCancelledException();

    final finished = Completer<void>();
    finished.future.ignore(); // Errors are read below, never left unhandled.
    final lineSub = _lines.stream.listen((line) {
      onLine(line);
      if (line.startsWith('bestmove') && !finished.isCompleted) {
        finished.complete();
      }
    });
    final errorSub = _errors.stream.listen((message) {
      if (!finished.isCompleted) {
        finished.completeError(
            EngineUnavailableException('worker error: $message'));
      }
    });

    try {
      for (final command in commands) {
        _post(worker, command);
      }
      try {
        await finished.future.timeout(_kSearchTimeout);
      } on TimeoutException {
        _post(worker, 'stop');
        try {
          await finished.future.timeout(_kDrainTimeout);
        } on TimeoutException {
          dev.log('StockfishService(web): no bestmove after stop; restarting');
          _dropWorker(worker);
        }
      }
    } on EngineUnavailableException {
      _dropWorker(worker);
      rethrow;
    } finally {
      await lineSub.cancel();
      await errorSub.cancel();
    }
  }

  String _goCommand({int? depth, int? movetime}) {
    // Depth + movetime combine: the engine stops at whichever comes first.
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

  /// Stockfish scores from the side-to-move's perspective. Negate when black
  /// is to move so all our values are from white's perspective.
  static EvalResult _toWhitePerspective(EvalResult raw, String fen) {
    if (!_isBlackToMove(fen)) return raw;
    return EvalResult(
      centipawns: -raw.centipawns,
      mateIn: raw.mateIn != null ? -raw.mateIn! : null,
      depth: raw.depth,
    );
  }

  @override
  Future<EvalResult> evaluate(String fen, {int? depth, int? movetime}) {
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
      // reported now; when the engine moves on to a deeper one, the previous
      // is kept as `lastComplete`. At the end prefer the current iteration
      // only if it reported at least as many moves (a `stop` can cut one
      // short).
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
