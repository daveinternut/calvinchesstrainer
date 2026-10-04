#!/usr/bin/env bash
#
# Build the web (WebAssembly) bundle into build/web.
#
# WHY THIS SCRIPT EXISTS
# ----------------------
# `flutter build web --wasm` cannot build this app. It always compiles TWICE —
# dart2wasm plus a dart2js fallback for browsers without WasmGC — and hardcodes
# both (flutter_tools/lib/src/commands/build_web.dart, `compilerConfigs`). There
# is no flag to skip the fallback.
#
# The dart2js half can never succeed here: dartchess represents the board as
# 64-bit integer bitboards, and dart2js has no 64-bit ints (JS numbers are
# doubles, and its bitwise ops are 32-bit). It fails on literals like
# `SquareSet(0xffffffffffffffff)`. That is why dartchess declares no web
# platform. dart2wasm has real int64, so the same code is exact there —
# verified: identical results to native for legal-move generation and FEN.
#
# `flutter run -d web-server --wasm` uses a SINGLE compiler config
# (isolated/resident_web_runner.dart), so it compiles wasm only and writes a
# complete bundle to build/web. That is the supported command this script
# drives. Its one weakness: it does not strip/minify the wasm the way
# `flutter build` does (9.0 MB vs 2.8 MB), so we harvest the stripped artifacts
# from the failed `flutter build web --wasm` and drop them in afterwards.
#
# Revisit this script if Flutter ever adds a wasm-only build, or if dartchess
# gains dart2js support. Either one collapses it back to a single command.
#
set -euo pipefail

cd "$(dirname "$0")/.."
PORT="${WEB_BUILD_PORT:-8099}"
LOG="$(mktemp -t calvinweb)"
STASH="$(mktemp -d -t calvinwasm)"
trap 'rm -rf "$STASH" "$LOG"' EXIT

echo "==> 1/5  Harvesting stripped wasm (this build's dart2js half is expected to fail)"
rm -rf .dart_tool/flutter_build
flutter build web --wasm >"$LOG" 2>&1 || true

WASM_SRC="$(find .dart_tool/flutter_build -maxdepth 2 -name main.dart.wasm | head -1)"
if [[ -z "$WASM_SRC" ]]; then
  echo "ERROR: dart2wasm produced no output. Real compile error — full log:" >&2
  cat "$LOG" >&2
  exit 1
fi
cp "$(dirname "$WASM_SRC")"/main.dart.{wasm,mjs,support.js} "$STASH/"
echo "    stripped wasm: $(du -h "$STASH/main.dart.wasm" | cut -f1)"

echo "==> 2/5  Assembling build/web (wasm-only, via the web-server device)"
flutter run --release -d web-server --wasm \
  --web-port="$PORT" --web-hostname=localhost >"$LOG" 2>&1 &
RUN_PID=$!
DEADLINE=$(( SECONDS + 600 ))
until grep -q "is being served at" "$LOG" 2>/dev/null; do
  if ! kill -0 "$RUN_PID" 2>/dev/null; then
    echo "ERROR: build failed before serving. Full log:" >&2; cat "$LOG" >&2; exit 1
  fi
  if (( SECONDS > DEADLINE )); then
    echo "ERROR: timed out after 10 min waiting for the bundle." >&2
    kill "$RUN_PID" 2>/dev/null || true; exit 1
  fi
  sleep 2
done
kill "$RUN_PID" 2>/dev/null || true
wait "$RUN_PID" 2>/dev/null || true

echo "==> 3/5  Swapping in the stripped wasm, and cache-busting the entrypoint"
cp "$STASH"/main.dart.{wasm,mjs,support.js} build/web/
rm -f build/web/main.dart.wasm.map   # 3.5 MB source map, not wanted in production

# ---------------------------------------------------------------------------
# Flutter's web output is NOT content-hashed: main.dart.wasm keeps its name
# forever, so a browser that cached it has no way to tell a new deploy apart.
# Response headers cannot fix this on their own — changing Cache-Control does
# not evict entries a browser already stored, so anyone who loaded the site
# under a long max-age stays pinned to that build until it expires.
#
# Stamping the entrypoint URLs with a content hash sidesteps it entirely: a new
# build is a new URL, which no cache can satisfy. flutter_bootstrap.js itself is
# served no-cache, so it is always fresh and always points at the current hash.
# ---------------------------------------------------------------------------
BUILD_HASH="$(shasum -a 256 build/web/main.dart.wasm | cut -c1-12)"
python3 - "$BUILD_HASH" <<'PY'
import re, sys
h = sys.argv[1]
p = 'build/web/flutter_bootstrap.js'
s = open(p).read()
before = s
for key, fname in (('mainWasmPath', 'main.dart.wasm'),
                   ('jsSupportRuntimePath', 'main.dart.mjs')):
    s = re.sub(r'("%s"\s*:\s*")%s(")' % (key, re.escape(fname)),
               r'\g<1>%s?v=%s\g<2>' % (fname, h), s)
if s == before:
    sys.exit('ERROR: could not stamp entrypoint paths in flutter_bootstrap.js')
open(p, 'w').write(s)
print(f'    entrypoints stamped ?v={h}')
PY

# ---------------------------------------------------------------------------
# Prune chessground assets the app can never load.
#
# chessground bundles 40 piece sets (~27 MB, 1904 files) and 25 board textures.
# Flutter has no way to tree-shake a package's declared assets, so all of it
# lands in build/web. That is ~95% of the deployed file count, and it is what
# made the first Firebase deploy time out mid-upload.
#
# The keep-list is DERIVED FROM THE SOURCE rather than hardcoded, so adding
# `PieceSet.merida` to a screen automatically keeps merida. Leftover entries in
# AssetManifest.bin are harmless: Flutter only fetches an asset on demand.
#
# Debugging note: firebase.json rewrites `**` to /index.html, so a pruned asset
# comes back as 200 text/html rather than a clean 404. If pieces ever render as
# broken images, check the response CONTENT-TYPE, not the status code.
# ---------------------------------------------------------------------------
echo "==> 4/5  Pruning unused chessground assets"
CG="build/web/assets/packages/chessground/assets"
BEFORE_N=$(find build/web -type f | wc -l | tr -d ' ')

KEEP_SETS=$(grep -rhoE 'PieceSet\.[a-zA-Z0-9_]+' lib/ | sed 's/PieceSet\.//' | sort -u)
if [[ -z "$KEEP_SETS" ]]; then
  echo "    WARNING: found no PieceSet.* reference in lib/ — keeping all sets." >&2
elif [[ -d "$CG/piece_sets" ]]; then
  echo "    piece sets in use: $(echo "$KEEP_SETS" | tr '\n' ' ')"
  for dir in "$CG"/piece_sets/*/; do
    name=$(basename "$dir")
    grep -qx "$name" <<<"$KEEP_SETS" || rm -rf "$dir"
  done
fi

# Board textures are only fetched by image-backed colour schemes. Every scheme
# this app uses is solid-colour (ChessboardColorScheme.green ->
# SolidColorChessboardBackground), so the textures are dead weight. Bail out of
# this prune the moment a second scheme appears, rather than guess.
SCHEMES=$(grep -rhoE 'ChessboardColorScheme\.[a-zA-Z0-9_]+' lib/ | sed 's/ChessboardColorScheme\.//' | sort -u)
if [[ "$SCHEMES" == "green" && -d "$CG/boards" ]]; then
  rm -rf "$CG/boards"
else
  echo "    keeping board textures (colour schemes in use: ${SCHEMES:-none})"
fi

AFTER_N=$(find build/web -type f | wc -l | tr -d ' ')
echo "    removed $((BEFORE_N - AFTER_N)) files"

echo "==> 5/5  Done"
echo "    build/web/main.dart.wasm  $(du -h build/web/main.dart.wasm | cut -f1)"
echo "    build/web total on disk   $(du -sh build/web | cut -f1)"
echo "    files to deploy           $AFTER_N"
echo
echo "Preview:  npx serve build/web      (or any static server)"
echo "Deploy:   firebase deploy --only hosting"
