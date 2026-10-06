# CLAUDE.md

The always-loaded control panel for this repo. Read this in full; it's built to get an agent productive fast. For depth, follow the pointers to `resources/`.

## What this is

**Calvin Chess Trainer** — a Flutter app for drilling **board vision and notation**. Home shows a **daily warm-up** (five timed drills), **Continue** (the last drill), the **Opening Explorer** (play through openings with Stockfish hints and an eval bar), and every drill in two sections: **Vision** (find checks, find captures, hanging pieces, forks & skewers, knight sight, knight flight, pawn attack, mate in 1 — the scanning drills use curated real positions) and **Notation** (squares, files & ranks, read moves, piece letters, piece values). A drill opens a setup panel that remembers your last setup. Plus a Tactics placeholder that nothing links to.

Stack: Flutter/Dart · **Riverpod** (`Notifier`; game providers `autoDispose`) · **GoRouter** · **chessground + dartchess** (lichess, GPL-3.0) · **stockfish** (FFI native, WASM on web) · Firebase Analytics · shared_preferences (personal bests, drill setups, Continue) · just_audio + audio_session / flutter_tts · gen-l10n (10 locales, English fallback) · bundled fonts: Bricolage Grotesque (UI) + Geist Mono (notation).

## Documentation (where to go for depth)

| File | Use it for |
|---|---|
| **CLAUDE.md** (this) | Always loaded. Mental model, repo map, task router, conventions, gotchas, commands. |
| **[resources/000 Index.md](resources/000%20Index.md)** | The full code map: system map (data flow + provider→service graph), per-feature file tables with key logic, routes, **Quick reference** (providers/enums/timing), **Glossary**, **Known Gaps**. Read for any non-trivial task. |
| **[resources/000 Explanations.md](resources/000%20Explanations.md)** | Narrative deep dives per subsystem (audio, each trainer, the vision engines, iOS signing). |
| **[resources/000 lichess documentation.md](resources/000%20lichess%20documentation.md)** | chessground/dartchess API reference. |

**Rule: when you change code these docs describe, update the doc in the same change.**

## Mental model

Feature-first. **Each trainer = one immutable `*_state.dart` + one Riverpod `Notifier` (`*_provider.dart`) that owns all game logic + a thin `*_screen.dart`.** The board is a *pure function of provider state* (the state exposes highlight getters — `allHighlights`, `feedbackShapes`, `boardFen`). Game providers are **`autoDispose`**: a round — its timers, engine work and pending audio — ends when its screen closes. Anything that must outlive a screen lives in an app-lifetime provider instead (personal bests: `personalBestsProvider`). Board screens lay out through **`TrainerLayout`** (portrait column; board-left/panel-right in landscape, `PlayTopBar` on top) with the board in a **`BoardFrame`** (coordinates outside). Cross-cutting code (audio, analytics, engine, puzzles, opening book, bests, board helpers) lives in `lib/core/`; the **design system** is `core/theme/` (tokens, type, board look) + `core/ui/` (components). Drills are described once in the **drill catalog** (`features/drills/drill_catalog.dart`) — home, sections, Continue and the warm-up all read it. Follow this shape for new work. (Full data-flow: Index → System map.)

## Repo map

```
lib/
  main.dart              boot: (debug) stockfish cleanup → Firebase init in the background → load saved bests → runApp(ProviderScope) (no orientation lock in Dart — see Gotchas)
  app.dart               MaterialApp.router · GoRouter (13 routes, each named; unknown paths → home) · ScreenViewObserver (analytics)
  firebase_options.dart  generated — DO NOT edit
  core/
    audio/audio_service.dart       voice clips + SFX + cheers + haptics + TTS (owns ALL haptics; ambient
                                   session; a new announcement or stop() cancels the rest of the old one;
                                   `muted` follows the Sound switch)
    audio/sound_switch.dart        the in-app Sound switch: soundOnProvider (saved on device) + SoundButton,
                                   the speaker in home's header and every drill's PlayTopBar
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
    theme/app_theme.dart           AppColors (tokens), AppFonts, AppText (mono = notation, number = scores), AppTheme.light (no dark)
    theme/board_theme.dart         AppBoard.settings() — the one board look (sage, cburnett, coordinates off)
    ui/                            design-system components: buttons, SegmentedPicker, PlayTopBar, StatTile, NotationChip,
                                   BoardFrame (coordinates outside), DrillGlyph, LogoMark
    constants.dart  widgets/       ChessConstants, SquareNameOverlay, TrainerLayout
  features/<trainer>/    models/ · providers/ · screens/ · widgets/   (+ services/ for vision & pieces)
    drills/              the drill catalog, drill setups + Continue (drillPrefsProvider), the warm-up
                         (warmupProvider, roundActions), DrillSectionScreen (Vision/Notation), setup panel, tiles
    home/                warm-up card, Continue, Opening Explorer, Vision + Notation tiles
    chess_vision/        8 drills; 4 pure engines         → /chess-vision/game     (section: /chess-vision)
    file_rank_trainer/   squares, files & ranks           → /file-rank-trainer/game (section: /file-rank-trainer; hosts the shared widget kit)
    letter_trainer/      piece letters (K Q R B N)        → /letter-trainer/game
    move_trainer/        read moves (puzzles)             → /move-trainer/game
    pieces/              piece values ("which side wins?") → /the-pieces/which-side-wins
    opening_trainer/     Opening Explorer (Stockfish)     → /opening-trainer       (partly wired — see Gotchas)
    about/  tactics_trainer/(placeholder)
  l10n/                  10 locales via gen-l10n; edit app_*.arb (template app_en.arb) then `flutter gen-l10n`
```

## Task router — "to do X, start here"

| To… | Open |
|---|---|
| Add or change a drill (name, glyph, modes, options, route, best) | `features/drills/drill_catalog.dart` (+ `DrillId` in `drills/models/drill.dart`, strings in every `.arb`). Featured on home via `HomeScreen._visionTiles` / `_notationTiles` |
| Add a new trainer | copy a `features/<x>/` folder; follow the Notifier pattern (public static `bestKeyFor`); screen = `TrainerLayout` + `PlayTopBar` (with `action: const SoundButton()`) + `BoardFrame` + `roundActions`; register a route + `name` in `app.dart` (parse `warmup=1`); describe its drill in the catalog |
| Change the look (colours, type, components, board) | `core/theme/app_theme.dart`, `core/theme/board_theme.dart`, `core/ui/` |
| Home layout / the warm-up card | `features/home/screens/home_screen.dart` |
| Drill setup UI (options, modes, Start) | `features/drills/widgets/drill_setup_panel.dart`; list/sheet layout in `drills/screens/drill_section_screen.dart` |
| The daily warm-up (its steps, the hand-off) | `features/drills/providers/warmup_provider.dart`, `drills/warmup_actions.dart` |
| Change game logic / scoring / streaks / timers | that trainer's `providers/*_provider.dart` |
| Change board rendering / feedback colors | that trainer's `screens/*_screen.dart` + the highlight getters in its `models/*_state.dart` |
| Change a feedback delay or speed-round length | the trainer's `*_provider.dart` (hardcoded; values listed in Index → Quick reference) |
| Fix fork/skewer, knight, or pawn logic | `features/chess_vision/services/{fork_skewer,knight,pawn_attack}_engine.dart` |
| Fix check/capture/hanging/mate-in-1 detection | `features/chess_vision/services/scan_engine.dart` (must mirror `scripts/curate_scanning_positions.py`; shared fixtures in `test/scan_engine_test.dart`) |
| Regenerate scanning/mate-in-1 position sets | `scripts/curate_scanning_positions.py` → `assets/puzzles/{scan_*,mate_in_one_puzzles}.json`; loaded by `core/services/scan_position_service.dart` + `mateInOnePuzzleServiceProvider` |
| Touch the engine / eval bar / hint arrows | `core/services/stockfish_engine_io.dart` (native impl) + `features/opening_trainer/providers/opening_game_provider.dart`. Change the *contract* in `stockfish_engine_api.dart` and mirror it in both impls |
| Gate a feature that needs the engine | check `kEngineAvailable` (from `core/services/stockfish_service.dart`) — never `kIsWeb`. See the home card + the `/opening-trainer` redirect |
| Build / deploy the web app | `scripts/build_web.sh` → `build/web`, then `firebase deploy --only hosting`. Read the header comment first: the build is a workaround, not a plain `flutter build web` |
| Ship an iOS build (TestFlight / App Store) | `scripts/build_ipa.sh` (`--check` first). Key in `~/.appstoreconnect/private_keys/`, IDs in `scripts/build_ipa.env` (gitignored). It picks the next build number from App Store Connect and writes it back to `pubspec.yaml`. Android: `scripts/deploy_play.sh` (`--track alpha` = closed test); Play Console walkthrough + listing text in `resources/store/android/PUBLISHING.md` |
| Store screenshots, app icon, Play graphics / listing text | `tool/store_assets/store_assets_test.dart` (`flutter test` that file; then `dart run flutter_launcher_icons` if the icon changed) → `resources/store/`, `resources/icon/`, `assets/images/app_icon.png`. Copy: `resources/store/listing.md` |
| Puzzle loading / regenerate puzzle set | `core/services/puzzle_service.dart`, `assets/puzzles/`, `scripts/curate_puzzles.py` |
| Opening names / book moves | `core/services/opening_book_service.dart`, `assets/data/eco_openings.json` |
| Audio clips or haptics | `core/audio/audio_service.dart` (`playMilestone` is driven by `MilestoneBanner`) |
| Sound on/off (the speaker button) | `core/audio/sound_switch.dart`; `AudioService.muted` skips every sound, haptics stay |
| Personal bests / saved progress | `core/services/personal_bests_service.dart` — `submit(key, score, lowerIsBetter:)` at game over; keys namespaced per trainer (`vision.`, `fileRank.`, `letter.`, `move.`, `pieces.`) |
| Lay a screen out for tablet landscape | `core/widgets/trainer_layout.dart` (header/board/footer; check 820×1180 and 1180×820, plus a short window like 568×320) |
| Add or translate UI text | `lib/l10n/app_*.arb` → `flutter gen-l10n` |
| Add/change a route or navigation | `lib/app.dart` |
| Analytics events | `core/services/analytics_service.dart` (called from the providers) |
| Theme / colors / fonts | `core/theme/app_theme.dart` |

## Conventions (do these)

- **Notifier pattern** as above — keep screens thin; logic in the notifier.
- **Design system:** colours from `AppColors` tokens (brand = actions/found, amber = target, vermilion = miss), text from `AppText`. **`AppText.mono` (Geist Mono) is for chess notation only** (squares, moves, piece letters); scores, streaks and timers use `AppText.number`. Boards: `AppBoard.settings(...)` inside `BoardFrame` (`showCoordinates: false` when the drill tests coordinates). Compose `core/ui/` components rather than styling Material widgets ad hoc.
- **Game screens:** `PlayTopBar` (close → `closeDrill`, subtitle `warmupSubtitle(...) ??` the mode, `action: const SoundButton()`) and results through `roundActions(...)`, so every screen works as a warm-up step. Take a `warmup` bool from the route.
- **Lifecycle:** game providers are `NotifierProvider.autoDispose`; cancel timers in `ref.onDispose`; after **every** `await` in a notifier, `if (!ref.mounted) return;` before touching `state`/`ref` (Riverpod 3 throws on a disposed Ref). Read services a continuation needs into fields in `build()`.
- **Bests:** at game over call `personalBestsProvider.notifier.submit(...)` and store its result in state (`isNewRecord`); results cards read the state flag, never a getter computed after the best was saved.
- **`copyWith` nullable idiom:** nullable fields take a `T? Function()?` thunk — pass `() => null` to *clear*, omit to *keep*. (Used in every `*_state.dart`.)
- **Plugin-first:** never hand-roll chess logic or board rendering — use dartchess (`position.isLegal`, `makeLegalMoves`, SAN, FEN) and chessground (`Chessboard` / `Chessboard.fixed`).
- **Navigation:** forward = `context.push()`, back = `context.pop()`. Every route gets a `name` (feeds Analytics screen views).
- **Shared UI kit:** `StreakCounter` / `TimerBar` / `ResultsCard` / `MilestoneBanner` live under `file_rank_trainer/widgets/` and are reused by other trainers — edits there are cross-cutting.
- **Localize new strings:** add to all `lib/l10n/app_*.arb`, then `flutter gen-l10n`; read via `AppLocalizations.of(context)`.

## Gotchas (know before you trust the code)

- **Personal bests are saved on the device** (`personalBestsProvider`, shared_preferences; loaded in `main()` with a timeout — without them bests last the session). Recorded at game over: speed-round scores, plus concentric and timed-pawn *times* (lower is better). The only other saved state is each drill's setup + Continue (`drillPrefsProvider`) and the Sound switch (`soundOnProvider`); there is no cloud backend (Firebase Auth/Firestore were removed).
- **Opening trainer is partly wired:** `/opening-trainer` hard-codes practice/easy/white; `OpeningMenuScreen` + the `LivesDisplay`/`MedalProgress`/`PrincipleCard` widgets are **built but never mounted**; there is no `/opening-trainer/game` route. Challenge mode, lives, and medals are unreachable.
- **`feedback_service.dart` is HTTP feedback, not audio/haptics** — name collides with `audio_service.dart`. Haptics live in `AudioService`, which also **swallows playback errors** and builds asset paths from strings (renames fail silently).
- **The audio session is `ambient`**, configured by `AudioService` before the first sound: the app mixes with other apps' audio (a parent's music keeps playing) and obeys the silent switch. Unconfigured, just_audio would fall back to a non-mixing "music" session that stops other audio on the first beep.
- **Two things silence the app:** the phone's Silent mode (the ambient session above; Do Not Disturb/Focus does not) and the in-app **Sound switch** (`soundOnProvider`, saved as `sound_on_v1`). Sound off sets `AudioService.muted`: every clip, blip, cheer and TTS line returns before loading, and switching off stops what is playing. Haptics stay on (the system setting governs them). Nothing may be audio-only: every spoken prompt is also on screen, and Explore labels what you tap (Files & Ranks on the board's edge). The Opening Explorer's bar has no speaker (its tools fill it); home's covers it.
- **Tablets rotate; phones stay portrait.** iPad: all four orientations in Info.plist, no `UIRequiresFullScreen` (deprecated in iPadOS 26), so multitasking is on and iPadOS ignores any programmatic lock. iPhone: portrait only, from Info.plist. Android: `MainActivity.kt` asks for portrait when the smallest width is under 600 dp and leaves tablets free (it re-checks on configuration changes, so a foldable can switch). **Don't add `SystemChrome.setPreferredOrientations`** — on Android it would override `MainActivity` and lock tablets too. Every screen must work in landscape and in resizable windows (Stage Manager, split screen, the web app on a phone held sideways): board screens use `TrainerLayout`, which also goes side by side in windows shorter than 360 pt; menus are width-capped and scroll.
- **Web ships WebAssembly only — `flutter build web` cannot build this app.** It always also compiles a dart2js fallback, and dart2js has no 64-bit ints, so dartchess's bitboards (`SquareSet(0xffffffffffffffff)`) fail to compile. dart2wasm has real int64 and is exact. Use `scripts/build_web.sh`. Consequence: the app needs a **WasmGC browser** (Chrome/Edge 119+, Firefox 120+, **Safari 18.2+ / iOS 18.2+**) — older iPads get a "no compatible build" error, not a graceful fallback.
- **Two engines, one contract.** Native runs real Stockfish over `dart:ffi`; web runs **Stockfish 19 Lite WASM in a Web Worker** (`web/stockfish/`, loaded lazily on first `initialize()` so the home screen never fetches its 1.7 MB). Both implement `StockfishService`. The UCI protocol handling is **deliberately duplicated** between `stockfish_engine_io.dart` and `stockfish_engine_web.dart` rather than shared, to keep the shipping native engine untouchable — **fix protocol bugs in both** (same convention as `scan_engine.dart` ↔ `curate_scanning_positions.py`).
- **One engine per Opening Explorer visit.** It starts on demand and the screen hands it back with `disposeWhenIdle()` when it closes — never dispose between moves. Restarts are expensive *and leak*: the `stockfish` package's native glue opens two pipes per start and never closes them (4 file descriptors each; iOS starts apps at a soft limit of 256), which is why `AppDelegate.swift` raises the soft limit to 4096. `isBusy` covers a start in flight; `stopSearch()` drops queued ops (`SearchCancelledException`); a timed-out search is drained to its `bestmove` before the next op; a failed start is sticky until Retry.
- **`kEngineAvailable` is now true everywhere**, so the gates in `home_screen.dart` and the `/opening-trainer` redirect are currently no-ops. They are kept as the seam for any future engine-less target — don't delete them.
- **Never let Firebase gate startup.** `main()` starts `Firebase.initializeApp` **in the background** (8s timeout, errors caught) and calls `runApp()` without waiting; `markFirebaseReady()` flips `analyticsAvailable` when it lands. On web the Firebase SDK is a runtime `import()` from gstatic; an ad blocker, privacy extension or DNS filter makes that import reject as an *unhandled JS promise*, so `initializeApp()` never completes **and never throws** — awaiting it before `runApp()` once stranded visitors on the splash screen, and the 8s-timeout fix still cost every blocked visitor 8 seconds. `AnalyticsService` resolves `FirebaseAnalytics.instance` lazily and only after `analyticsAvailable`; events (and `ScreenViewObserver` screen views) are dropped until then, and `logEvent`'s async failures are caught. Reproduce with DevTools request blocking on `*googletagmanager.com*` + `*firebase-analytics*`.
- **Flutter's web output is NOT content-hashed**, so `build_web.sh` stamps the entrypoints itself: it rewrites `mainWasmPath` / `jsSupportRuntimePath` in `flutter_bootstrap.js` to `main.dart.wasm?v=<hash>`. Without that, a browser cannot tell one deploy from the next. **Cache headers alone cannot fix this** — changing `Cache-Control` does *not* evict what a browser already stored, so anyone served a long `max-age` stays pinned to that build until it expires (this happened: an early `immutable, max-age=31536000` left real visitors stuck on a pre-engine build, and a hard refresh did not clear it). `firebase.json` now serves everything `no-cache` except `web/stockfish/**`, whose version is in the filename. **Firebase applies the *last* matching `headers` rule**, so the catch-all `**` comes first and specific overrides after it.
- **The web engine is single-threaded on purpose.** The multi-threaded WASM build needs `SharedArrayBuffer`, which would force COOP/COEP on the host and pull CanvasKit off the gstatic CDN. Single-threaded still hits depth 15 in 500 ms — past the hardest setting (skill 18 / 500 ms).
- **No illustrations ship.** The v1 home-card art and its BradBunR font are archived in `resources/art/v1-home-cards/` (not bundled). Drill icons are `DrillGlyph`s, drawn from board states. `app_icon.png` (**1024×1024**, what iOS App Store icon generation needs) stays in `assets/images/` for `flutter_launcher_icons`; it and the Android adaptive layers are rendered from the LogoMark by `tool/store_assets/`.
- **`build_web.sh` prunes chessground assets** that Flutter can't tree-shake: 40 piece sets + 25 board textures → just the sets `lib/` actually references. That is ~1880 files and 29 MB. The keep-list is **derived from `PieceSet.*` in `lib/`**, so a new set is kept automatically; board textures are only dropped while `green` (solid-colour) is the sole scheme. Live first load is **~5.5 MB**.
- **The `calvin-web` launch config also writes `build/web`** — it is `flutter run -d web-server --wasm`, so it leaves a *debug* build (12 MB wasm + source map, no cache-busting stamp, unpruned assets) in the deploy directory. Always re-run `./scripts/build_web.sh` right before `firebase deploy`.
- **Fonts are bundled through pubspec `fonts:`** — `Bricolage` (Bricolage Grotesque static instances, weights 400–800) and `GeistMono` (400–600); their OFL texts in `assets/licenses/` are registered in `main()`. A weight outside those falls back to the nearest. google_fonts was removed; nothing is downloaded. Neither font has Cyrillic/CJK — those locales use the platform font.
- **Each drill remembers its own setup** (`drillPrefsProvider`, `drill_prefs_v1`); Start and Continue record it, warm-up steps don't. The section routes kept their old paths and names (`/chess-vision` = `chess_vision_menu`, `/file-rank-trainer` = `file_rank_menu`) so deep links and analytics screen names still work; `?drill=` picks the drill.
- **Warm-up steps replace each other** (`pushReplacement` in `roundActions`), so Back from any step goes home. A game screen opened with `warmup=1` but no active warm-up (e.g. after a restart) just plays normally.
- **Avoid `IntrinsicHeight` around Material buttons** — their intrinsic height is underestimated, which overflowed the iPad-landscape home. The home's landscape row is top-aligned instead.
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
