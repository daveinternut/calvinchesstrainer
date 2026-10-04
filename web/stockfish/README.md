# Stockfish 19 Lite (WebAssembly)

The chess engine for the **web build only**. iOS and Android use the native
`stockfish` package over `dart:ffi` — nothing here affects them.

| File | |
|---|---|
| `stockfish-19-lite-single.js` | emscripten glue; loaded as a Web Worker |
| `stockfish-19-lite-single.wasm` | the engine (1.7 MB) |
| `LICENSE.txt` | GPL-3.0 (Stockfish / stockfish.js) |

Source: [`stockfish` npm 19.0.0](https://www.npmjs.com/package/stockfish)
([nmrugg/stockfish.js](https://github.com/nmrugg/stockfish.js)), GPL-3.0.

## Why this exact variant

`stockfish` npm ships four builds. We use **lite-single**:

| Build | Size | Notes |
|---|---|---|
| `stockfish-19.wasm` | 94.5 MB | full NNUE net — unusable over the wire |
| `stockfish-19-single.wasm` | 94.5 MB | same net, single-threaded |
| `stockfish-19-lite.wasm` | 1.6 MB | small net, **multi-threaded** |
| **`stockfish-19-lite-single.wasm`** | **1.7 MB** | small net, single-threaded ✅ |

The multi-threaded builds need `SharedArrayBuffer`, which requires
`Cross-Origin-Opener-Policy: same-origin` + `Cross-Origin-Embedder-Policy:
require-corp` on the host. lite-single contains **no `SharedArrayBuffer`
reference at all**, so it needs no headers and no cross-origin isolation —
which also means CanvasKit can keep loading from the gstatic CDN.

Measured in a browser Worker: **depth 15 in 500 ms at ~814k nps**. The app caps
difficulty at skill level 18 with a 500 ms movetime, so this is ample.

## Updating

Download the tarball and copy the two lite-single files here:

```bash
npm pack stockfish@<version>
```

Keep the filenames in sync with `_kEngineWorkerUrl` in
`lib/core/services/stockfish_engine_web.dart`. The `.wasm` is located by the
emscripten glue **relative to the worker script's URL**, so the two files must
stay in the same directory.
