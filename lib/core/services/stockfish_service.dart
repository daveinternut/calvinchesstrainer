import 'dart:async';
import 'dart:developer' as dev;
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stockfish/stockfish.dart';

final stockfishServiceProvider = Provider<StockfishService>((ref) {
  final service = StockfishService();
  ref.onDispose(service.dispose);
  return service;
});

/// Send "quit" directly to any lingering native Stockfish thread via FFI.
/// Call this at the top of main() so hot restart can unblock the old engine's
/// stdout isolate (which is stuck in a blocking nativeStdoutRead FFI call).
void stockfishCleanupForRestart() {
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

class EvalResult {
  final int centipawns;
  final int? mateIn;

  const EvalResult({required this.centipawns, this.mateIn});

  double get pawns => centipawns / 100.0;

  bool get isMate => mateIn != null;

  @override
  String toString() =>
      isMate ? 'M${mateIn! > 0 ? "+$mateIn" : mateIn}' : pawns.toStringAsFixed(1);
}

class ScoredMove {
  final String uci;
  final int centipawns;
  final int? mateIn;
  final int multipvIndex;

  const ScoredMove({
    required this.uci,
    required this.centipawns,
    this.mateIn,
    required this.multipvIndex,
  });

  double get pawns => centipawns / 100.0;
}

class StockfishService {
  static Stockfish? _stockfish;
  static bool _isReady = false;
  static Future<void>? _initFuture;

  StreamSubscription<String>? _subscription;

  // Track pending operations so dispose() can cancel them
  final List<Completer<dynamic>> _pendingCompleters = [];

  bool get isReady => _isReady;

  Future<void> initialize() async {
    if (_isReady && _stockfish != null) return;
    if (_initFuture != null) {
      await _initFuture;
      return;
    }
    _initFuture = _doInitialize();
    try {
      await _initFuture;
    } finally {
      _initFuture = null;
    }
  }

  Future<void> _doInitialize() async {
    // Clean up stale instance from a previous failed init
    if (_stockfish != null && !_isReady) {
      _disposeEngine();
    }

    if (_stockfish == null) {
      _stockfish = await _createWithRetry();
    }

    // Wait for native engine to finish starting
    if (_stockfish!.state.value != StockfishState.ready) {
      final stateCompleter = Completer<void>();
      void listener() {
        final v = _stockfish?.state.value;
        if (!stateCompleter.isCompleted) {
          if (v == StockfishState.ready) {
            stateCompleter.complete();
          } else if (v == StockfishState.error ||
              v == StockfishState.disposed) {
            stateCompleter
                .completeError(StateError('Stockfish entered state $v'));
          }
        }
      }

      _stockfish!.state.addListener(listener);
      if (_stockfish!.state.value == StockfishState.ready) {
        if (!stateCompleter.isCompleted) stateCompleter.complete();
      }
      try {
        await stateCompleter.future.timeout(const Duration(seconds: 10));
      } catch (e) {
        _stockfish!.state.removeListener(listener);
        dev.log('StockfishService: engine failed to reach ready state: $e');
        _disposeEngine();
        rethrow;
      }
      _stockfish!.state.removeListener(listener);
    }

    // Engine is ready — send UCI handshake
    final uciCompleter = Completer<void>();
    _subscription = _stockfish!.stdout.listen((line) {
      if (line == 'readyok' && !uciCompleter.isCompleted) {
        uciCompleter.complete();
      }
    });

    _stockfish!.stdin = 'uci';
    _stockfish!.stdin = 'isready';

    try {
      await uciCompleter.future.timeout(const Duration(seconds: 10));
    } on TimeoutException {
      dev.log('StockfishService: UCI handshake timed out');
      _disposeEngine();
      rethrow;
    } finally {
      await _subscription?.cancel();
      _subscription = null;
    }

    _isReady = true;
  }

  /// Try to create a [Stockfish] instance, retrying if the previous native
  /// thread hasn't finished exiting yet ("Multiple instances" error).
  /// This happens after hot restart when the old C++ thread is still alive.
  static Future<Stockfish> _createWithRetry() async {
    for (int attempt = 0; attempt < 6; attempt++) {
      try {
        return Stockfish();
      } on StateError catch (e) {
        dev.log('StockfishService: create attempt ${attempt + 1}/6 failed: $e');
        if (attempt < 5) {
          await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
        } else {
          rethrow;
        }
      }
    }
    throw StateError('Failed to create Stockfish after retries');
  }

  /// Dispose the engine via the package's dispose().  This closes the
  /// internal ReceivePort (which otherwise keeps the Dart isolate alive
  /// and blocks hot restart).
  static void _disposeEngine() {
    final sf = _stockfish;
    _stockfish = null;
    _isReady = false;
    if (sf == null) return;
    try {
      sf.dispose();
    } catch (e) {
      dev.log('StockfishService: dispose error (ignored): $e');
    }
  }

  Future<void> _ensureReady() async {
    if (!_isReady || _stockfish == null) {
      await initialize();
    }
  }

  void _cancelAllPending() {
    for (final c in _pendingCompleters) {
      if (!c.isCompleted) {
        c.completeError(StateError('StockfishService disposed'));
      }
    }
    _pendingCompleters.clear();
  }

  /// Abort any running search. Sends UCI "stop" which makes the engine
  /// immediately output "bestmove", unblocking any pending getTopMoves/
  /// evaluate/getBestMove call.
  void stopSearch() {
    if (_stockfish != null && _isReady) {
      try {
        _stockfish!.stdin = 'stop';
      } catch (_) {}
    }
  }

  String _goCommand({int? depth, int? movetime}) {
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
    );
  }

  /// Evaluate a position and return the score from white's perspective.
  Future<EvalResult> evaluate(
    String fen, {
    int? depth,
    int? movetime,
  }) async {
    await _ensureReady();

    final completer = Completer<EvalResult>();
    _pendingCompleters.add(completer);
    EvalResult? lastResult;

    final sub = _stockfish!.stdout.listen((line) {
      if (line.startsWith('info ') && line.contains('score ')) {
        final result = _parseEval(line);
        if (result != null) lastResult = result;
      } else if (line.startsWith('bestmove ')) {
        if (!completer.isCompleted) {
          completer.complete(lastResult ?? const EvalResult(centipawns: 0));
        }
      }
    });

    _stockfish!.stdin = 'setoption name Skill Level value 20';
    _stockfish!.stdin = 'setoption name MultiPV value 1';
    _stockfish!.stdin = 'position fen $fen';
    _stockfish!.stdin = _goCommand(depth: depth, movetime: movetime);

    try {
      final result = await completer.future.timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          try { _stockfish?.stdin = 'stop'; } catch (_) {}
          return lastResult ?? const EvalResult(centipawns: 0);
        },
      );
      return _toWhitePerspective(result, fen);
    } finally {
      _pendingCompleters.remove(completer);
      await sub.cancel();
    }
  }

  /// Get the best move for a position at a given skill level.
  Future<String?> getBestMove(
    String fen, {
    int? depth,
    int? movetime,
    int skillLevel = 20,
  }) async {
    await _ensureReady();

    final completer = Completer<String?>();
    _pendingCompleters.add(completer);

    final sub = _stockfish!.stdout.listen((line) {
      if (line.startsWith('bestmove ')) {
        final match = RegExp(r'bestmove (\S+)').firstMatch(line);
        if (!completer.isCompleted) {
          completer.complete(match?.group(1));
        }
      }
    });

    _stockfish!.stdin = 'setoption name Skill Level value $skillLevel';
    _stockfish!.stdin = 'setoption name MultiPV value 1';
    _stockfish!.stdin = 'position fen $fen';
    _stockfish!.stdin = _goCommand(depth: depth, movetime: movetime);

    try {
      return await completer.future.timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          try { _stockfish?.stdin = 'stop'; } catch (_) {}
          return null;
        },
      );
    } finally {
      _pendingCompleters.remove(completer);
      await sub.cancel();
    }
  }

  /// Get the top N moves for a position (for practice mode hint arrows).
  Future<List<ScoredMove>> getTopMoves(
    String fen, {
    int count = 3,
    int? depth,
    int? movetime,
  }) async {
    await _ensureReady();

    final completer = Completer<List<ScoredMove>>();
    _pendingCompleters.add(completer);
    // Keep the latest result for each multipv index regardless of depth.
    // With movetime searches, the engine may output an incomplete set at
    // the highest depth before bestmove arrives. By not clearing on depth
    // change, earlier complete results are preserved and only overwritten
    // when a deeper result for the same multipv index arrives.
    final moves = <int, ScoredMove>{};

    final sub = _stockfish!.stdout.listen((line) {
      if (line.startsWith('info ') && line.contains('multipv ')) {
        final mpvMatch = RegExp(r'multipv (\d+)').firstMatch(line);
        final pvMatch = RegExp(r' pv (\S+)').firstMatch(line);
        final eval = _parseEval(line);

        if (mpvMatch != null && pvMatch != null && eval != null) {
          final mpv = int.parse(mpvMatch.group(1)!);
          final uci = pvMatch.group(1)!;
          final normalized = _toWhitePerspective(eval, fen);

          moves[mpv] = ScoredMove(
            uci: uci,
            centipawns: normalized.centipawns,
            mateIn: normalized.mateIn,
            multipvIndex: mpv,
          );
        }
      } else if (line.startsWith('bestmove ')) {
        if (!completer.isCompleted) {
          final sorted = moves.values.toList()
            ..sort((a, b) => a.multipvIndex.compareTo(b.multipvIndex));
          completer.complete(sorted);
        }
      }
    });

    _stockfish!.stdin = 'setoption name Skill Level value 20';
    _stockfish!.stdin = 'setoption name MultiPV value $count';
    _stockfish!.stdin = 'position fen $fen';
    _stockfish!.stdin = _goCommand(depth: depth, movetime: movetime);

    try {
      return await completer.future.timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          try { _stockfish?.stdin = 'stop'; } catch (_) {}
          final sorted = moves.values.toList()
            ..sort((a, b) => a.multipvIndex.compareTo(b.multipvIndex));
          return sorted;
        },
      );
    } finally {
      _pendingCompleters.remove(completer);
      await sub.cancel();
    }
  }

  EvalResult? _parseEval(String line) {
    final mateMatch = RegExp(r'score mate (-?\d+)').firstMatch(line);
    if (mateMatch != null) {
      final mateIn = int.parse(mateMatch.group(1)!);
      final cp = mateIn > 0 ? 10000 : -10000;
      return EvalResult(centipawns: cp, mateIn: mateIn);
    }

    final cpMatch = RegExp(r'score cp (-?\d+)').firstMatch(line);
    if (cpMatch != null) {
      return EvalResult(centipawns: int.parse(cpMatch.group(1)!));
    }

    return null;
  }

  void dispose() {
    _cancelAllPending();
    _subscription?.cancel();
    _subscription = null;
    _disposeEngine();
  }
}
