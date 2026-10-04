/// Platform-neutral engine contract.
///
/// Kept free of `dart:ffi` / `dart:io` / `dart:js_interop` so it compiles
/// everywhere. Two implementations honour it: `stockfish_engine_io.dart`
/// (real Stockfish over `dart:ffi` on iOS/Android) and
/// `stockfish_engine_web.dart` (Stockfish WASM in a Web Worker). Pick one via
/// `stockfish_service.dart`, which is the only file consumers should import.
library;

class EvalResult {
  final int centipawns;

  /// Moves to mate, from the same perspective as [centipawns] (positive:
  /// white mates). `0` means the side to move is already checkmated — the
  /// winner is then given by the sign of [centipawns], since `-0 == 0`.
  final int? mateIn;

  /// Search depth this eval was reported at (0 = unknown, e.g. aborted).
  final int depth;

  const EvalResult({required this.centipawns, this.mateIn, this.depth = 0});

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

/// The engine could not be started (or died). Operations keep failing fast
/// with this until [StockfishService.initialize] is called again — the
/// "Retry" path — so a broken engine costs one start timeout, not one per
/// move.
class EngineUnavailableException implements Exception {
  final Object? cause;

  const EngineUnavailableException([this.cause]);

  @override
  String toString() => 'EngineUnavailableException: $cause';
}

/// The operation was dropped by [StockfishService.stopSearch] before it got
/// to search. Not an error: the caller asked for it to go away.
class SearchCancelledException implements Exception {
  const SearchCancelledException();

  @override
  String toString() => 'SearchCancelledException';
}

/// A UCI chess engine. Every search takes a `movetime` ceiling in
/// milliseconds so a slow implementation degrades into a shallower search
/// rather than a stalled UI.
///
/// Operations run strictly one at a time (UCI has no request ids, so a
/// listener would otherwise parse another search's output), and an operation
/// never returns before its own search's `bestmove` has been read.
abstract class StockfishService {
  bool get isReady;

  /// Whether an engine operation is running or queued, or the engine is
  /// starting. The engine is only ever released while this is false.
  bool get isBusy;

  /// Start the engine. A no-op when it is already running; joins a start
  /// that is already in progress. After a failed start, this is also the
  /// retry: operations fail fast with [EngineUnavailableException] until it
  /// is called again. Throws [EngineUnavailableException] on failure.
  Future<void> initialize();

  /// Abort the running search and drop every operation still queued behind
  /// it (they fail with [SearchCancelledException]). Operations requested
  /// after this call run normally.
  void stopSearch();

  /// Evaluate a position and return the score from white's perspective.
  Future<EvalResult> evaluate(String fen, {int? depth, int? movetime});

  /// Get the best move for a position at a given skill level. Null when the
  /// position has no legal move (`bestmove (none)`) or the search failed.
  Future<String?> getBestMove(
    String fen, {
    int? depth,
    int? movetime,
    int skillLevel = 20,
  });

  /// Get the top N moves for a position (for practice mode hint arrows).
  Future<List<ScoredMove>> getTopMoves(
    String fen, {
    int count = 3,
    int? depth,
    int? movetime,
    void Function(int depth)? onDepth,
  });

  /// Release the engine as soon as nothing is running, queued or starting
  /// (immediately when idle). Any later call to an engine method cancels a
  /// release that hasn't happened yet, so a screen that reopens quickly
  /// keeps the warm engine.
  void disposeWhenIdle();

  /// App teardown: [stopSearch], then [disposeWhenIdle].
  void dispose();
}
