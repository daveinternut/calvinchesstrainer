# CLAUDE.md

The always-loaded control panel for this repo. Read this in full; it's built to get an agent productive fast. For depth, follow the pointers to `resources/`.

## What this is

**Calvin Chess Trainer** — a Flutter chess-training app for kids. Three trainers on the home screen: **Chess Vision** (forks/skewers, knight sight/flight, pawn attack, plus four scanning drills on curated real positions: find checks, find captures, hanging pieces, mate-in-1 — the hero card), **Chess Notation** (file/rank/square, letters, move-from-notation, piece value), and **Opening Explorer** (play through openings with Stockfish hints and an eval bar). Plus a Tactics placeholder that nothing links to.

Stack: Flutter/Dart · **Riverpod** (`Notifier`; game providers `autoDispose`) · **GoRouter** · **chessground + dartchess** (lichess, GPL-3.0) · **stockfish** (FFI native, WASM on web) · Firebase Analytics · shared_preferences (saved personal bests) · just_audio + audio_session / flutter_tts · gen-l10n (10 locales, English fallback).

## Documentation (where to go for depth)

| File | Use it for |
|---|---|
| **CLAUDE.md** (this) | Always loaded. Mental model, repo map, task router, conventions, gotchas, commands. |
| **[resources/000 Index.md](resources/000%20Index.md)** | The full code map: system map (data flow + provider→service graph), per-feature file tables with key logic, routes, **Quick reference** (providers/enums/timing), **Glossary**, **Known Gaps**. Read for any non-trivial task. |
| **[resources/000 Explanations.md](resources/000%20Explanations.md)** | Narrative deep dives per subsystem (audio, each trainer, the vision engines, iOS signing). |
| **[resources/000 lichess documentation.md](resources/000%20lichess%20documentation.md)** | chessground/dartchess API reference. |

**Rule: when you change code these docs describe, update the doc in the same change.**

## Mental model

Feature-first. **Each trainer = one immutable `*_state.dart` + one Riverpod `Notifier` (`*_provider.dart`) that owns all game logic + a thin `*_screen.dart`.** The board is a *pure function of provider state* (the state exposes highlight getters — `allHighlights`, `feedbackShapes`, `boardFen`). Game providers are **`autoDispose`**: a round — its timers, engine work and pending audio — ends when its screen closes. Anything that must outlive a screen lives in an app-lifetime provider instead (personal bests: `personalBestsProvider`). Board screens lay out through **`TrainerLayout`** (portrait column; board-left/panel-right in landscape). Cross-cutting code (audio, analytics, engine, puzzles, opening book, bests, board helpers) lives in `lib/core/`. Follow this shape for new work. (Full data-flow: Index → System map.)

## Repo map

```
lib/
  main.dart              boot: (debug) stockfish cleanup → Firebase init in the background → load saved bests → portrait lock (holds on iPhone only) → runApp(ProviderScope)
  app.dart               MaterialApp.router · GoRouter (12 routes, each named; unknown paths → home) · ScreenViewObserver (analytics)
  firebase_options.dart  generated — DO NOT edit
  core/
    audio/audio_service.dart       voice clips + SFX + cheers + haptics + TTS (owns ALL haptics; ambient
                                   session; a new announcement or stop() cancels the rest of the old one)
    services/
      puzzle_service.dart          move-trainer puzzles (ParsedPuzzle)
      stockfish_service.dart       ENGINE ENTRY — import only this. Re-exports the API,
                                   picks an impl at compile time, exposes kEngineAvailable
      stockfish_engine_api.dart    platform-neutral contract (EvalResult, ScoredMove,
                                   abstract StockfishService) — no dart:ffi/dart:io
      stockfish_engine_io.dart     native impl: FFI/UCI, one process-wide instance
      stockfish_engine_web.dart    web impl: Stockfish 19 Lite WASM in a Web Worker
                                   (binary in web/stockfish/; dart:js_interop, no pub dep)
      opening_book_service.dart    ECO opening names + book moves
      personal_bests_service.dart  personalBestsProvider — bests for every trainer, saved on device
      analytics_service.dart       12 typed Firebase drill events + ScreenViewObserver (no-op until Firebase is up)
      feedback_service.dart        HTTP user-feedback form (NOT audio, despite the name)
    board_utils.dart               file/rank/square index → chessground highlight map
    theme/  constants/  widgets/   AppTheme.light (no dark), constants, SquareNameOverlay, TrainerLayout
  features/<trainer>/    models/ · providers/ · screens/ · widgets/   (+ services/ for vision & pieces)
    chess_vision/        8 drills; 4 pure engines         → /chess-vision          (home-screen hero)
    file_rank_trainer/   files/ranks/squares + the chips  → /file-rank-trainer     (hosts the shared widget kit)
    letter_trainer/      piece letters (K Q R B N)        → /letter-trainer/game   (entered via the Letters chip)
    move_trainer/        move from notation (puzzles)     → /move-trainer/game     (entered via the Moves chip)
    pieces/              "which side wins?"               → /the-pieces/which-side-wins (via the Piece Value chip)
    opening_trainer/     Opening Explorer (Stockfish)     → /opening-trainer       (partly wired — see Gotchas)
    home/  about/  tactics_trainer/(placeholder)
  l10n/                  10 locales via gen-l10n; edit app_*.arb (template app_en.arb) then `flutter gen-l10n`
```

## Task router — "to do X, start here"

| To… | Open |
|---|---|
| Add a new trainer | copy a `features/<x>/` folder; follow the Notifier pattern; register a route + `name` in `app.dart`; add a card in `home/screens/home_screen.dart` |
| Change game logic / scoring / streaks / timers | that trainer's `providers/*_provider.dart` |
| Change board rendering / feedback colors | that trainer's `screens/*_screen.dart` + the highlight getters in its `models/*_state.dart` |
| Change a feedback delay or speed-round length | the trainer's `*_provider.dart` (hardcoded; values listed in Index → Quick reference) |
| Fix fork/skewer, knight, or pawn logic | `features/chess_vision/services/{fork_skewer,knight,pawn_attack}_engine.dart` |
| Fix check/capture/hanging/mate-in-1 detection | `features/chess_vision/services/scan_engine.dart` (must mirror `scripts/curate_scanning_positions.py`; shared fixtures in `test/scan_engine_test.dart`) |
| Regenerate scanning/mate-in-1 position sets | `scripts/curate_scanning_positions.py` → `assets/puzzles/{scan_*,mate_in_one_puzzles}.json`; loaded by `core/services/scan_position_service.dart` + `mateInOnePuzzleServiceProvider` |
| Touch the engine / eval bar / hint arrows | `core/services/stockfish_engine_io.dart` (native impl) + `features/opening_trainer/providers/opening_game_provider.dart`. Change the *contract* in `stockfish_engine_api.dart` and mirror it in both impls |
| Gate a feature that needs the engine | check `kEngineAvailable` (from `core/services/stockfish_service.dart`) — never `kIsWeb`. See the home card + the `/opening-trainer` redirect |
| Build / deploy the web app | `scripts/build_web.sh` → `build/web`, then `firebase deploy --only hosting`. Read the header comment first: the build is a workaround, not a plain `flutter build web` |
| Ship an iOS build (TestFlight / App Store) | `scripts/build_ipa.sh` (`--check` first). Key in `~/.appstoreconnect/private_keys/`, IDs in `scripts/build_ipa.env` (gitignored). It picks the next build number from App Store Connect and writes it back to `pubspec.yaml`. Android: `scripts/deploy_play.sh` |
| Puzzle loading / regenerate puzzle set | `core/services/puzzle_service.dart`, `assets/puzzles/`, `scripts/curate_puzzles.py` |
| Opening names / book moves | `core/services/opening_book_service.dart`, `assets/data/eco_openings.json` |
| Audio clips or haptics | `core/audio/audio_service.dart` (`playMilestone` is driven by `MilestoneBanner`) |
| Personal bests / saved progress | `core/services/personal_bests_service.dart` — `submit(key, score, lowerIsBetter:)` at game over; keys namespaced per trainer (`vision.`, `fileRank.`, `letter.`, `move.`, `pieces.`) |
| Lay a screen out for iPad landscape | `core/widgets/trainer_layout.dart` (header/board/footer; check 820×1180 and 1180×820) |
| Add or translate UI text | `lib/l10n/app_*.arb` → `flutter gen-l10n` |
| Add/change a route or navigation | `lib/app.dart` |
| Analytics events | `core/services/analytics_service.dart` (called from the providers) |
| Theme / colors / fonts | `core/theme/app_theme.dart` |

## Conventions (do these)

- **Notifier pattern** as above — keep screens thin; logic in the notifier.
- **Lifecycle:** game providers are `NotifierProvider.autoDispose`; cancel timers in `ref.onDispose`; after **every** `await` in a notifier, `if (!ref.mounted) return;` before touching `state`/`ref` (Riverpod 3 throws on a disposed Ref). Read services a continuation needs into fields in `build()`.
- **Bests:** at game over call `personalBestsProvider.notifier.submit(...)` and store its result in state (`isNewRecord`); results cards read the state flag, never a getter computed after the best was saved.
- **`copyWith` nullable idiom:** nullable fields take a `T? Function()?` thunk — pass `() => null` to *clear*, omit to *keep*. (Used in every `*_state.dart`.)
- **Plugin-first:** never hand-roll chess logic or board rendering — use dartchess (`position.isLegal`, `makeLegalMoves`, SAN, FEN) and chessground (`Chessboard` / `Chessboard.fixed`).
- **Navigation:** forward = `context.push()`, back = `context.pop()`. Every route gets a `name` (feeds Analytics screen views).
- **Shared UI kit:** `StreakCounter` / `TimerBar` / `ResultsCard` / `MilestoneBanner` live under `file_rank_trainer/widgets/` and are reused by other trainers — edits there are cross-cutting.
- **Localize new strings:** add to all `lib/l10n/app_*.arb`, then `flutter gen-l10n`; read via `AppLocalizations.of(context)`.

## Gotchas (know before you trust the code)

- **Personal bests are saved on the device** (`personalBestsProvider`, shared_preferences; loaded in `main()` with a timeout — without them bests last the session). Recorded at game over: speed-round scores, plus concentric and timed-pawn *times* (lower is better). Nothing else persists, and there is no cloud backend (Firebase Auth/Firestore were removed).
- **Opening trainer is partly wired:** `/opening-trainer` hard-codes practice/easy/white; `OpeningMenuScreen` + the `LivesDisplay`/`MedalProgress`/`PrincipleCard` widgets are **built but never mounted**; there is no `/opening-trainer/game` route. Challenge mode, lives, and medals are unreachable.
- **`feedback_service.dart` is HTTP feedback, not audio/haptics** — name collides with `audio_service.dart`. Haptics live in `AudioService`, which also **swallows playback errors** and builds asset paths from strings (renames fail silently).
- **The audio session is `ambient`**, configured by `AudioService` before the first sound: the app mixes with other apps' audio (a parent's music keeps playing) and obeys the silent switch. Unconfigured, just_audio would fall back to a non-mixing "music" session that stops other audio on the first beep.
- **iPad ignores the portrait lock.** Multitasking is on (all four iPad orientations, no `UIRequiresFullScreen` — which iPadOS 26 deprecates, and iPadOS 26 also refuses programmatic orientation changes). Every screen must work in landscape and in resizable windows: board screens use `TrainerLayout`, menus are width-capped and scroll. iPhone stays portrait (Info.plist + `setPreferredOrientations`).
- **Web ships WebAssembly only — `flutter build web` cannot build this app.** It always also compiles a dart2js fallback, and dart2js has no 64-bit ints, so dartchess's bitboards (`SquareSet(0xffffffffffffffff)`) fail to compile. dart2wasm has real int64 and is exact. Use `scripts/build_web.sh`. Consequence: the app needs a **WasmGC browser** (Chrome/Edge 119+, Firefox 120+, **Safari 18.2+ / iOS 18.2+**) — older iPads get a "no compatible build" error, not a graceful fallback.
- **Two engines, one contract.** Native runs real Stockfish over `dart:ffi`; web runs **Stockfish 19 Lite WASM in a Web Worker** (`web/stockfish/`, loaded lazily on first `initialize()` so the home screen never fetches its 1.7 MB). Both implement `StockfishService`. The UCI protocol handling is **deliberately duplicated** between `stockfish_engine_io.dart` and `stockfish_engine_web.dart` rather than shared, to keep the shipping native engine untouchable — **fix protocol bugs in both** (same convention as `scan_engine.dart` ↔ `curate_scanning_positions.py`).
- **One engine per Opening Explorer visit.** It starts on demand and the screen hands it back with `disposeWhenIdle()` when it closes — never dispose between moves. Restarts are expensive *and leak*: the `stockfish` package's native glue opens two pipes per start and never closes them (4 file descriptors each; iOS starts apps at a soft limit of 256), which is why `AppDelegate.swift` raises the soft limit to 4096. `isBusy` covers a start in flight; `stopSearch()` drops queued ops (`SearchCancelledException`); a timed-out search is drained to its `bestmove` before the next op; a failed start is sticky until Retry.
- **`kEngineAvailable` is now true everywhere**, so the gates in `home_screen.dart` and the `/opening-trainer` redirect are currently no-ops. They are kept as the seam for any future engine-less target — don't delete them.
- **Never let Firebase gate startup.** `main()` starts `Firebase.initializeApp` **in the background** (8s timeout, errors caught) and calls `runApp()` without waiting; `markFirebaseReady()` flips `analyticsAvailable` when it lands. On web the Firebase SDK is a runtime `import()` from gstatic; an ad blocker, privacy extension or DNS filter makes that import reject as an *unhandled JS promise*, so `initializeApp()` never completes **and never throws** — awaiting it before `runApp()` once stranded visitors on the splash screen, and the 8s-timeout fix still cost every blocked visitor 8 seconds. `AnalyticsService` resolves `FirebaseAnalytics.instance` lazily and only after `analyticsAvailable`; events (and `ScreenViewObserver` screen views) are dropped until then, and `logEvent`'s async failures are caught. Reproduce with DevTools request blocking on `*googletagmanager.com*` + `*firebase-analytics*`.
- **Flutter's web output is NOT content-hashed**, so `build_web.sh` stamps the entrypoints itself: it rewrites `mainWasmPath` / `jsSupportRuntimePath` in `flutter_bootstrap.js` to `main.dart.wasm?v=<hash>`. Without that, a browser cannot tell one deploy from the next. **Cache headers alone cannot fix this** — changing `Cache-Control` does *not* evict what a browser already stored, so anyone served a long `max-age` stays pinned to that build until it expires (this happened: an early `immutable, max-age=31536000` left real visitors stuck on a pre-engine build, and a hard refresh did not clear it). `firebase.json` now serves everything `no-cache` except `web/stockfish/**`, whose version is in the filename. **Firebase applies the *last* matching `headers` rule**, so the catch-all `**` comes first and specific overrides after it.
- **The web engine is single-threaded on purpose.** The multi-threaded WASM build needs `SharedArrayBuffer`, which would force COOP/COEP on the host and pull CanvasKit off the gstatic CDN. Single-threaded still hits depth 15 in 500 ms — past the hardest setting (skill 18 / 500 ms).
- **Card art is sized for display, not for print — keep it that way.** The three card PNGs were 2500–2700 px wide (4 MB each) and are now **1200 px** (`app_icon.png` is **1024×1024**, the size iOS App Store icon generation needs, so `flutter_launcher_icons` still works). They render at ~330 pt. Dropping a fresh export straight from Illustrator re-bloats every platform. Full-res masters: `resources/art/` (outside `assets/`, so it ships nowhere) and git history.
- **`build_web.sh` prunes chessground assets** that Flutter can't tree-shake: 40 piece sets + 25 board textures → just the sets `lib/` actually references. That is ~1880 files and 29 MB. The keep-list is **derived from `PieceSet.*` in `lib/`**, so a new set is kept automatically; board textures are only dropped while `green` (solid-colour) is the sole scheme. Live first load is **~5.5 MB**.
- **The `calvin-web` launch config also writes `build/web`** — it is `flutter run -d web-server --wasm`, so it leaves a *debug* build (12 MB wasm + source map, no cache-busting stamp, unpruned assets) in the deploy directory. Always re-run `./scripts/build_web.sh` right before `firebase deploy`.
- **Inter is bundled, not downloaded** (`assets/google_fonts/` — Regular/Medium/SemiBold, plus `OFL.txt` registered with `LicenseRegistry`), and `main()` sets `GoogleFonts.config.allowRuntimeFetching = false`. google_fonts finds the files by name (`Inter-SemiBold.ttf`), so a newly used Inter weight needs its TTF added there or it throws.
- **English is the fallback locale** (`preferred-supported-locales: [en]` in `l10n.yaml`). Flutter falls back to the *first* supported locale for an unsupported device language, and gen-l10n otherwise sorts German first.
- **No dark theme;** OS font-scaling is disabled (`TextScaler.noScaling`).
- **iOS/Android bundle IDs currently mismatch** (Index → Project info; Explanations → iOS Signing).

## Commands & verifying a change

```bash
flutter pub get
flutter run                  # device / emulator — the main way to verify
flutter analyze              # lint/type check before declaring done
flutter test                 # unit/widget tests under test/
flutter gen-l10n             # after editing lib/l10n/*.arb (also runs on build)
flutter build ios --release  # iOS 15.0 min target
./scripts/build_ipa.sh --check   # App Store Connect: key, app record, last build (read-only)
./scripts/build_ipa.sh           # analyze + test → .ipa → upload to TestFlight
```

**Web** (WebAssembly only — see Gotchas):

```bash
./scripts/build_web.sh                     # → build/web  (NOT `flutter build web`, which cannot work here)
flutter run -d web-server --wasm --web-port=8087   # iterate; serves at localhost:8087
firebase deploy --only hosting             # deploy build/web
```

To verify a gameplay change, `flutter run` and exercise the affected screen (see the Task router for which feature). Prefer this over assuming — the board's behavior is state-driven and easy to eyeball. Check iPad portrait **and landscape**. `flutter test` runs on the VM: engine-service logic is covered through a fake engine (`NativeStockfishService.forTesting`), but the real Stockfish binary only runs on a simulator/device, and the web engine (`dart:js_interop`) only in a browser.

## Do NOT hand-edit (generated)

- `lib/firebase_options.dart` → regenerate via `flutterfire configure`
- `lib/l10n/app_localizations*.dart` → regenerate via `flutter gen-l10n`
