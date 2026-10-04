/// The engine, as the rest of the app sees it.
///
/// This is the only engine file consumers should import. It re-exports the
/// platform-neutral contract and picks an implementation at compile time:
/// real Stockfish over `dart:ffi` on iOS/Android (`stockfish_engine_io.dart`),
/// Stockfish WASM in a Web Worker on web (`stockfish_engine_web.dart`) —
/// `dart:ffi` has no web implementation, so the native path cannot even
/// compile there.
///
/// Anything that depends on a working engine must check [kEngineAvailable]
/// first — see the Opening Explorer card in `home_screen.dart` and the
/// `/opening-trainer` redirect in `app.dart`. Both platforms have an engine
/// today, so those gates are the seam for a future engine-less target.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'stockfish_engine_api.dart';
import 'stockfish_engine_io.dart'
    if (dart.library.js_interop) 'stockfish_engine_web.dart' as impl;

export 'stockfish_engine_api.dart';

/// Whether this platform has a real chess engine behind
/// [stockfishServiceProvider]. True on iOS, Android and web.
const bool kEngineAvailable = impl.kEngineAvailable;

/// One service for the app's lifetime. The engine behind it starts on demand
/// and is handed back by its user (`disposeWhenIdle`) — the Opening trainer
/// keeps it for the whole screen session.
final stockfishServiceProvider = Provider<StockfishService>((ref) {
  final service = impl.createStockfishService();
  ref.onDispose(service.dispose);
  return service;
});

/// Unblock any lingering engine left over from a previous run, so hot restart
/// works. Call this at the top of main(). No-op where there is no engine.
void stockfishCleanupForRestart() => impl.cleanupForRestart();
