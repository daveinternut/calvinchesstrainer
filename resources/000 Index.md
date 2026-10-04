# Calvin Chess Trainer — Code Map

> **The index.** This file is the single entry point for understanding the codebase. It is written to be read top-to-bottom by a human or an AI agent: orientation → architecture → entry flow → feature maps → core layer → routes → known gaps. For deeper narrative on individual subsystems see [000 Explanations.md](000%20Explanations.md); for the chessground/dartchess API reference see [000 lichess documentation.md](000%20lichess%20documentation.md).
>
> **Verified against code on 2026-10-03**, after the review-and-fix pass that made game providers `autoDispose`, persisted personal bests, added the iPad landscape layout and reworked the engine lifecycle. Where docs and code disagreed, code won. Known divergences (built-but-unwired UI) are called out in [Known Gaps & Cleanup](#known-gaps--cleanup) — read that section before assuming a feature is fully shipped.
>
> **Jump to:** [System map](#system-map) · [Features](#features) · [Core layer](#core-layer--libcore) · [Routes](#routes--libappdart) · [Quick reference](#quick-reference) · [Glossary](#glossary) · [Known gaps](#known-gaps--cleanup). For "which file do I edit to do X?", the **task router** lives in [CLAUDE.md](../CLAUDE.md) (auto-loaded each session).

## What this is

A Flutter chess-training app for kids. It teaches board fundamentals and chess vision through short, audio-rich, gamified drills — not by playing full games (except the opening explorer). **Three trainers are on the home screen**, ranked: Chess Vision is the hero card, Chess Notation and Opening Explorer share the row beneath it. The Pieces is no longer a home-screen destination — it is reached as the Piece Value subject inside Chess Notation. The owner's kids use it **mostly on iPad**, in both orientations.

| Trainer | What it teaches | Route hub |
|---|---|---|
| **Chess Vision** | Forks/skewers, knight sight, knight flight, pawn-attack navigation, plus four scanning drills on curated real positions (find checks, find captures, hanging pieces, mate in 1) | `/chess-vision` — **the home-screen hero card** |
| **Chess Notation** | Files, ranks, squares, piece letters, executing moves from notation, and **piece value** | `/file-rank-trainer` (the "Letters" subject hands off to `/letter-trainer/game`, "Moves" to `/move-trainer/game`, "Piece Value" to `/the-pieces/which-side-wins`) |
| **Opening Explorer** | Playing through openings with book moves, Stockfish hint arrows and an eval bar | `/opening-trainer` |
| _The Pieces_ | Relative piece values ("which side wins?") — **no longer a top-level trainer;** it is the Piece Value subject inside Chess Notation | `/the-pieces/which-side-wins` |
| _Tactics_ | _placeholder only — routed but unreachable_ | `/tactics-trainer` |

## Tech stack

| Layer | Choice | Notes |
|---|---|---|
| Framework | Flutter / Dart | `sdk: ^3.9.2`; app version `1.4.0+6` |
| State | **Riverpod** `flutter_riverpod ^3.2.1` | `Notifier`/`NotifierProvider`; **game providers are `.autoDispose`** |
| Routing | **GoRouter** `^17.1.0` | 12 flat routes, `context.push()`/`context.pop()`, unknown paths → `/` |
| Board UI | **chessground** `^8.0.1` (lichess) | board widget, piece sets, themes, drag-and-drop, animation — GPL-3.0 |
| Chess logic | **dartchess** `^0.12.1` (lichess) | legal moves, FEN/PGN, SAN, game state — GPL-3.0 |
| Engine | **stockfish** `^1.8.1` (+ Stockfish 19 Lite WASM on web) | powers the opening explorer only |
| Audio | **just_audio** `^0.10.5` + **audio_session** + **flutter_tts** `^4.2.5` | pre-recorded clips; ambient session; TTS is a fallback for dynamic phrases |
| Storage | **shared_preferences** | personal bests, on device only |
| Fonts | **google_fonts** `^8.0.2` (Inter, **bundled** in `assets/google_fonts/`) + bundled **BradBunR** | runtime font fetching is disabled; BradBunR is the playful display font |
| Backend | **Firebase Analytics** only | project `calvin-chess-trainer`; initialized in the background. Auth/Firestore were removed |
| Localization | `flutter_localizations` + `intl`, gen-l10n | **10 locales**, English fallback — see [Localization](#localization) |
| Misc | `fast_immutable_collections`, `http`, `package_info_plus`, `ffi` | FIC is required by chessground; `http` powers the feedback form; `package_info_plus` the About version |

**GPL-3.0 note:** chessground and dartchess are GPL-3.0, so the distributed app must be GPL-3.0.

## How to run

```bash
flutter pub get
flutter run                       # device/emulator
flutter gen-l10n                  # regenerate localizations after editing lib/l10n/*.arb (also runs on build)
flutter build ios --release       # iOS 15.0 min target
./scripts/build_web.sh            # web (WebAssembly only — see CLAUDE.md)
```

Firebase is configured for **web, android, iOS** (macOS/Windows/Linux throw `UnsupportedError`). Regenerate platform config with `flutterfire configure`.

---

## Architecture & conventions

**Feature-first folders.** Each trainer is a self-contained folder under `lib/features/<feature>/` with `models/`, `providers/`, `screens/`, `widgets/` (and `services/` for the algorithm-heavy ones). Cross-cutting code lives in `lib/core/`.

**The Notifier pattern (read this — every trainer follows it).** Each trainer is one immutable state class + one `Notifier` that owns *all* game logic. Screens are thin: they `watch` the state and forward taps/moves to the notifier. The recurring shape:

- **State class** (`*_state.dart`) — immutable, `copyWith`, plus computed getters that produce board coloring (`allHighlights`, `feedbackShapes`, `squareHighlights`, `boardFen`). **Gotcha:** `copyWith` uses the `T? Function()?` thunk idiom for nullable fields — pass `() => null` to *clear* a field; omitting the arg *keeps* it. Game states carry `isNewRecord`, set once at game over.
- **Notifier** (`*_provider.dart`) — declared **`NotifierProvider.autoDispose`**, so the round dies with its screen: `ref.onDispose` cancels every `Timer` (feedback-delay + countdown/stopwatch) and bumps generation tokens. `startGame()`, a tap/move handler, streak tracking, analytics calls. **After every `await`, `if (!ref.mounted) return;`** — Riverpod 3 throws on a disposed Ref. Input is gated by `isWaitingForNext` / `isGameOver` during feedback delays.
- **Screen** (`*_screen.dart`) — `Chessboard`/`Chessboard.fixed` inside **`TrainerLayout`** + the shared UI widgets; starts the game in a post-frame callback; stops audio on dispose.

**Plugin-first.** Never hand-roll chess logic or board rendering — chessground + dartchess cover board UI, piece art, move validation, FEN/PGN, SAN, and game-state detection. We build only game flow, scoring, audio, navigation, and a thin highlight bridge ([board_utils.dart](#core-layer--libcore)). See [000 Explanations.md](000%20Explanations.md#plugin-first-architecture).

**Personal bests are persisted.** Every trainer records its best through the app-lifetime `personalBestsProvider` (`core/services/personal_bests_service.dart`), saved with shared_preferences. Keys are namespaced per trainer (`vision.…`, `fileRank.…`, `letter.…`, `move.…`, `pieces.…`); `submit(key, score, lowerIsBetter:)` returns whether it was a record, and the notifier stores that in state for the results card. Bests are recorded in **speed mode** (plus concentric and timed-pawn *times*); practice has no end condition.

**Shared UI kit lives under `file_rank_trainer/widgets/`.** Four widgets there — `StreakCounter`, `TimerBar`, `ResultsCard`, `MilestoneBanner` — are imported by the file-rank, letter, move, pieces and chess-vision screens. Treat that directory as app-wide shared UI: a change there is cross-cutting. `MilestoneBanner` also plays the milestone cheer (`AudioService.playMilestone`) and sits at the bottom of the page (the bottom of the side panel in landscape).

### Entry-point flow

`main.dart` → `app.dart` → router → screens.

1. **`lib/main.dart`** — inside `runZonedGuarded`: `WidgetsFlutterBinding.ensureInitialized()` → `FlutterNativeSplash.preserve(...)` → (debug only) `stockfishCleanupForRestart()` → **start** `Firebase.initializeApp(...)` in the background (8s timeout; `markFirebaseReady()` on success) → load `SharedPreferences` (3s timeout) → portrait lock (`SystemChrome.setPreferredOrientations` — holds on iPhone, ignored on iPad) → `GoogleFonts.config.allowRuntimeFetching = false` + register the Inter license → `FlutterNativeSplash.remove()` → `runApp(ProviderScope(overrides: [sharedPreferencesProvider…], child: CalvinChessTrainerApp()))`.
2. **`lib/app.dart`** — `CalvinChessTrainerApp` builds `MaterialApp.router`: `theme: AppTheme.light` (light only — no dark theme), the GoRouter config, l10n delegates, and a `builder` that locks `textScaler: TextScaler.noScaling` (OS font-scaling is disabled app-wide). The top-level `_router` registers a `ScreenViewObserver` (screen view per route `name`; events are dropped until Firebase is ready) and sends any unknown path to `/` (`onException`).
3. **`lib/firebase_options.dart`** — FlutterFire-generated; do not hand-edit.

---

## System map

### Boot sequence

```
main.dart
 ├─ (debug) stockfishCleanupForRestart()   free a lingering native engine thread (hot-restart safety)
 ├─ Firebase.initializeApp()               NOT awaited — background; analytics no-ops until ready
 ├─ SharedPreferences.getInstance()         awaited (3s cap) → personalBestsProvider
 ├─ portrait lock (iPhone) + bundled fonts + native splash remove
 └─ runApp( ProviderScope( CalvinChessTrainerApp ) )
      └─ app.dart → MaterialApp.router
           ├─ AppTheme.light            (light theme only; textScaler locked to noScaling)
           ├─ AppLocalizations          (10 locales, English fallback)
           └─ GoRouter _router          12 routes + ScreenViewObserver; unknown paths → /
                 └─ <Feature>Screen     watches its autoDispose provider, renders via TrainerLayout
```

### Per-screen runtime loop

The board is a **pure function of provider state** — nothing game-related is stored on the widget.

```
user taps a square / drags a piece
 └─ Screen forwards to the feature Notifier   (handleBoardTap / handleMove / handleAnswer)
      ├─ Notifier mutates immutable state via copyWith
      ├─ calls core services: AudioService (speak/SFX/haptics), AnalyticsService (drill events),
      │  personalBestsProvider (at game over), engine
      └─ schedules Timers: feedback-delay (auto-advance) + speed countdown
 └─ Riverpod emits new state → Screen rebuilds → board reads state.allHighlights / feedbackShapes / boardFen
screen pops
 └─ autoDispose: ref.onDispose cancels timers / engine work; dispose() stops audio
```

Input is gated while `isWaitingForNext` or `isGameOver` is true (the handler early-returns).

### Feature notifier → core service dependencies

| Notifier (provider) | Audio | Analytics | Bests | Other services / engines |
|---|:---:|:---:|:---:|---|
| `fileRankGameProvider` | ✅ | ✅ | ✅ | — |
| `letterGameProvider` | ✅ | ✅ | ✅ | — |
| `moveGameProvider` | ✅ | ✅ | ✅ | `puzzleServiceProvider` |
| `chessVisionProvider` | ✅ | ✅ | ✅ | `ForkSkewerEngine` · `KnightEngine` · `PawnAttackEngine` · `ScanEngine` (static, pure) · `scanPositionServiceProvider` · `mateInOnePuzzleServiceProvider` |
| `openingGameProvider` | ✅ | ✅ | — | `stockfishServiceProvider` · `openingBookServiceProvider` |
| `whichSideWinsProvider` | ✅ | ✅ | ✅ | `PieceValueEngine` (instance) |

All six are `autoDispose`. `feedbackServiceProvider` is standalone (About screen only). **Only the opening explorer uses Stockfish.**

### Shared-widget graph

```
file_rank_trainer/widgets/ ──┬─ StreakCounter ─┐
                             ├─ TimerBar       ├─ imported by → file_rank, letter, move, pieces, chess_vision
                             ├─ ResultsCard    │
                             └─ MilestoneBanner┘   (plays AudioService.playMilestone)
core/widgets/TrainerLayout     ── used by → file_rank, move, chess_vision, opening screens
core/widgets/SquareNameOverlay ── imported by → file_rank_trainer, move_trainer, chess_vision (mate in 1)
```

Treat `file_rank_trainer/widgets/` as the app-wide UI kit: a change there ripples across trainers.

---

## Features

For each: where it's reached, its key files, the load-bearing logic, and gotchas. (Home-screen order is Chess Vision → Chess Notation → Opening Explorer; the sections below keep their original order.)

### The Pieces — `lib/features/pieces/`

"Which Side Wins?" — compare two groups of pieces by total value and tap the stronger side.

**Reached only through Chess Notation.** It has no home-screen card and no menu of its own: the notation menu's **Piece Value** subject chip pushes `/the-pieces/which-side-wins?mode=` directly.

| File | ~LoC | Purpose & key logic |
|---|---|---|
| `models/which_side_wins_state.dart` | 100 | `PieceType` enum (pawn 1 / knight 3 / bishop 3 / rook 5 / queen 9 — **no king**); `WhichSideWinsMode {practice, speed}`; `AnswerSide`; `PieceGroupPuzzle` (two `List<PieceType>` + `correctSide`, with `leftValue`/`rightValue` getters); immutable `WhichSideWinsState` (+ `isNewRecord`). |
| `services/piece_value_engine.dart` | 151 | **Key file.** `generate(difficulty)` builds puzzles at 5 levels: L1 = 1v1, value gap ≥4; L2 = 1v1, gap 1–3; L3 = 2–3 pieces, gap ≥3; L4 = 2–3 pieces, gap 1–2; L5 = 3–4 pieces, gap 1–3. Retries ≤100× to hit the gap window; sides never equal; random left/right assignment (verified over 20,000 puzzles per level in `piece_value_engine_test.dart`). |
| `providers/which_side_wins_provider.dart` | 170 | `whichSideWinsProvider` (autoDispose). **Progressive difficulty (practice only):** +1 level every 3 correct (cap 5), −1 on any wrong (floor 1). **Speed:** random level 1–5 per puzzle, 30s countdown. Delays: speed 300/800ms, practice 600/1400ms. Best key `pieces.{mode}`. |
| `screens/which_side_wins_screen.dart` | 230 | Two `PieceGroupPanel`s + `VsDivider`; tap to answer; **each side's point total appears during feedback**; practice shows a 5-dot difficulty indicator; content centred and capped at 900 wide. **Reuses** `StreakCounter`/`TimerBar`/`ResultsCard`. Stops audio on dispose. |
| `widgets/piece_group_panel.dart` | 100 | Renders a group of piece images (`PieceSet.cburnett.assets`), **sized from the panel** (LayoutBuilder picks the column count that gives the largest pieces, capped at 150) so they don't look tiny on iPad; optional `total` slot; animated feedback tint. |
| `widgets/vs_divider.dart` | 36 | Circular "VS" badge (BradBunR). |

### Chess Notation — `lib/features/file_rank_trainer/` + `letter_trainer/` + `move_trainer/`

The home "Chess Notation" card opens the **file-rank menu**, which has six subject chips: **Files, Ranks, Squares, Letters, Moves, Piece Value**. Files/Ranks/Squares run in the file-rank trainer; the other three hand off to sibling features — **Letters → `/letter-trainer/game`**, **Moves → `/move-trainer/game`**, **Piece Value → `/the-pieces/which-side-wins`**. So `FileRankMenuScreen` is the shared entry point for four features; none of the other three has a menu reachable from home.

**Per-subject menu rules:** Moves and Piece Value have no Explore mode (`_subjectHasExplore`); Piece Value also hides the Hard Mode toggle and swaps in its own Practice blurb plus a "Which Side Wins?" banner. Piece Value maps `TrainerMode` → `WhichSideWinsMode` (speed → speed, everything else → practice). Menus are width-capped at 640 and their mode cards are exposed to screen readers as buttons.

#### file_rank_trainer (static board, tap-to-answer)

| File | ~LoC | Purpose & key logic |
|---|---|---|
| `models/file_rank_game_state.dart` | 175 | `TrainerSubject {files, ranks, squares, moves, letters, pieceValue}` (**the last three are menu-only** — this provider never handles them), `TrainerMode {explore, practice, speed}`, `AnswerResult`, `AnswerFeedback`, immutable `FileRankGameState` (+ `isNewRecord`). **`allHighlights` getter** branches squares-vs-files/ranks and merges green-correct / red-incorrect square coloring (all alpha 0.6) via `board_utils`. No reverse mode, no yellow target. |
| `providers/file_rank_game_provider.dart` | 315 | `fileRankGameProvider` (autoDispose). Prompt generation avoids immediate repeats; speaks the answer via `AudioService`; schedules auto-advance. **Delays:** explore 800ms; files/ranks practice 400/1200ms, speed 200/600ms; **squares** practice **700**/1200ms, speed 200/600ms. Speed countdown 30s. Best key `fileRank.{subject}_{mode}_{isHardMode}`. |
| `screens/file_rank_game_screen.dart` | 245 | **The routed screen.** `TrainerLayout` + `Chessboard.fixed` (`enableCoordinates: false` always), `onTouchedSquare` → `handleBoardTap`. Hard mode flips orientation to `Side.black`. Squares mode overlays `SquareNameOverlay`. Composes `PromptDisplay`, `StreakCounter`, `TimerBar`, `MilestoneBanner`, `ResultsCard`. |
| `screens/file_rank_menu_screen.dart` | 400 | Subject chips + mode cards + Hard Mode toggle. **Routes by subject** (see above). |
| `widgets/streak_counter.dart` | 160 | **Shared.** Animated streak number; pulse 1→1.2→1 on each increment, a 1→1.5→1 green-glow celebration at every multiple of 5 (label captured when it starts; a reset cancels it). |
| `widgets/timer_bar.dart` | 105 | **Shared.** Countdown bar (default 30s), green→yellow→red; beats once per second under 5s + "Hurry". |
| `widgets/results_card.dart` | 140 | **Shared.** End-of-round overlay (capped at 440 wide, scrolls in short windows): NEW RECORD badge (`isNewRecord` from state), Correct / Accuracy% / Best streak, Menu / Play Again. |
| `widgets/milestone_banner.dart` | 200 | **Shared.** Celebration banner at every 5-streak, sliding up at the bottom of the page (bottom of `TrainerLayout`'s side panel in landscape — `alignToTrainerLayout`), plus `AudioService.playMilestone` (haptic + the `streak_5/10/15/20` cheers). |
| `widgets/prompt_display.dart` | 68 | Prompt text above the board. **Not shared** (move trainer has its own). |

#### letter_trainer (answer grid, no board)

| File | ~LoC | Purpose & key logic |
|---|---|---|
| `models/letter_game_state.dart` | 134 | `LetterTrainerMode {explore, practice, speed}`, `LetterQuestionDirection {letterToPiece, pieceToLetter}`, immutable `LetterGameState` (+ `isNewRecord`). Hard mode shows black pieces. |
| `providers/letter_game_provider.dart` | 200 | `letterGameProvider` (autoDispose). Delays: practice 700/1200ms, speed 200/600ms; 30s speed round. Best key `letter.letters_{mode}_{hard}`. |
| `screens/letter_game_screen.dart` | 190 | Prompt + `LetterAnswerGrid` / `LetterExploreGrid`; centred, capped at 640 wide, scrolls below 520 px of height (no board, so no `TrainerLayout`). |
| `widgets/letter_strings.dart` | 33 | `pieceNameFor(l10n, role)` — localized piece names, also used by the move trainer's subtitle. |

#### move_trainer (interactive board, puzzle-based)

| File | ~LoC | Purpose & key logic |
|---|---|---|
| `models/move_game_state.dart` | 145 | `MoveTrainerMode {practice, speed}`, `MoveFeedback`/`MoveFeedbackResult`, immutable `MoveGameState` (+ `isNewRecord`, `isCheck` for the *displayed* position). `feedbackShapes` → green `Arrow` only on **incorrect**; `squareHighlights` → green from/to only on **correct**. |
| `providers/move_game_provider.dart` | 220 | `moveGameProvider` (autoDispose). `startGame` has a generation token and `ref.mounted` check around the puzzle load. Hard mode filters puzzles to `Side.black`. Correctness = `puzzle.matches(move)` (dartchess `normalizeMove`, so a king-onto-rook drop counts as castling). **Correct** → `displayFen` updated (piece stays); **incorrect** → FEN unchanged (piece snaps back) + green arrow. **Delays:** practice **700**/1200ms, speed 200/600ms. Best key `move.{mode}_{hard}`. |
| `screens/move_game_screen.dart` | 260 | **The routed screen.** `TrainerLayout` + interactive `Chessboard` + `GameData` (`isCheck` from state). `SquareNameOverlay` on destination squares during feedback. |
| `screens/move_menu_screen.dart` | 250 | Practice/Speed + Hard Mode → `/move-trainer/game`. (Reachable via `/move-trainer`, but the live UI path is the file-rank menu's Moves chip.) |
| `widgets/move_prompt_display.dart` | 90 | SAN prominently (e.g. "Qb6") + `friendlyDescription(puzzle, l10n)` — square from `expectedMove.to`, localized piece name, castling detected (`Qfc8+` → "Queen to c8"). |

#### Puzzle pipeline

Puzzles come from the Lichess puzzle DB (CC0). `scripts/curate_puzzles.py` filters the 5.7M-row CSV (rating 600–1500, NbPlays > 500, no promotions, piece-balanced) into `assets/puzzles/moves_puzzles.json` (500 puzzles: 246 white-to-move, 254 black). `PuzzleService` parses each at runtime into a `ParsedPuzzle` (plays the setup move, derives SAN/role/side, capture/check flags). **Loading is memoized** (concurrent callers share one load; a failed load can be retried) and **`getRandomPuzzle` deals from a shuffled deck per side filter** — nothing repeats until the set is exhausted, `exclude` is never returned, and an empty side pool throws rather than returning a wrong-side puzzle. Its asset path is a constructor param, so `mateInOnePuzzleServiceProvider` reuses it for `mate_in_one_puzzles.json`. A second, **seeded/deterministic** script — `scripts/curate_scanning_positions.py` (python-chess; `--self-test` runs the cross-language fixtures) — produces the four Chess Vision scanning assets in one pass. See [000 Explanations.md](000%20Explanations.md#move-trainer).

### Chess Vision — `lib/features/chess_vision/`

**The most algorithm-heavy feature.** Eight drills run through **one** unified state + provider + screen, each branching on `VisionDrillType {forksAndSkewers, knightSight, knightFlight, pawnAttack, findChecks, findCaptures, hangingPieces, mateInOne}` (the enum carries `isScanDrill`/`isTapScanDrill`/`isKnightDrill` helpers, and `effectiveMode()` — the **one** mode-coercion rule shared by menu, provider and screen). The four engines under `services/` are the high-risk, high-value files.

The four **scanning drills** play on **curated real positions** (Lichess puzzle DB → `scripts/curate_scanning_positions.py` → `assets/puzzles/scan_{checks,captures,hanging}.json` + `mate_in_one_puzzles.json`). Ground truth is recomputed at runtime by `ScanEngine` from the FEN; curation only *selects* positions with byte-equivalent python-chess predicates (shared fixtures: `test/scan_engine_test.dart` ↔ the script's `--self-test`). Tap drills reuse the forks find-all machinery + a **Skip** reveal (1500 ms, streak reset, uncounted); the board **orients to the side to move**. Mate-in-1 reuses the move-trainer interactive board and is judged **by result** (`ScanEngine.isMatingMove`); a correct mate keeps the mated position on screen with the king highlighted.

| File | ~LoC | Purpose & key logic |
|---|---|---|
| `services/fork_skewer_engine.dart` | 190 | **Crown jewel.** `computeValidSquares(...)` brute-forces all 64 candidate squares; for each it builds a 4-piece position in dartchess (white piece, a white king on a **neutral** square, black king at **d5**, target) and verifies the white piece wins the target uncapturable on every black reply. The white king goes in a corner if one is safe — checked with **real attacks** (`board.attacksTo`, blockers included) — otherwise on any square ≥3 from the black king, ≥2 from the piece/target/block squares and off the piece–target line. (Corner-only placement with a blocker-blind attack check used to silently drop valid squares when the target sat in a corner.) Knight vs knight has no solutions anywhere. |
| `services/knight_engine.dart` | 51 | `knightMoves`, `isKnightMove`, `shortestPath` (BFS; returns hop count, −1 if unreachable). |
| `services/pawn_attack_engine.dart` | 200 | `pawnThreats`; `validMoves` (knight + ray-cast sliders; pawns block rays / can be captured; threatened empty squares are unsafe landings but don't stop a ray); **`isSolvable()`** (BFS, ≤64×256 states); `generatePawns(count, rng, {required Role role, …})` deals **only boards solvable for that piece** (bishop: dark squares by default). `startSquare` = a1. |
| `services/scan_engine.dart` | ~160 | Scanning ground truth from a `Position`: `checkTargets`/`checkTargetDetails` (castling skipped on both sides of the python contract, promotions expanded; for a promotion check the ghost is the *promoted* piece), `captureTargets`, `hangingTargets` (undefended N/B/R/Q — capturability deliberately not required), `matingMoves`/`isMatingMove`. Must stay byte-equivalent to `scripts/curate_scanning_positions.py`. |
| `models/chess_vision_state.dart` | 470 | Single state for all 8 drills (most fields null per drill). `VisionMode {practice, speed, concentric}`, `WhitePiece`, `TargetPiece` (different order). `boardFen`/`allHighlights` branch per drill. Notable fields: `concentricTotal`, `isNewRecord`, `pawnAttackStartPawns`, `pawnAttackDeadEnd`, `matedPosition`, `loadFailed`, `scanPosition`/`scanDisplayFen`, `checkGhosts`, `currentMatePuzzle`, `mateFeedback`, `isLoading`. |
| `providers/chess_vision_provider.dart` | 900 | `chessVisionProvider` (**autoDispose**; services cached in `build()`; `onDispose` cancels all 4 timers and bumps `_gameGeneration`; the asset-load await is followed by `ref.mounted` + generation checks; fresh state is neutral). **Scoring:** a round is credited the moment it is solved; only loading the next position waits for the feedback beat (so a last-second solve counts). A wrong **None** and a **Skip** share one reveal path and are **not** counted. **Forks:** solutions precomputed for all 63 targets at game start; **None rounds come at a fixed 15%** (`noneRoundChance`), otherwise the target is drawn from squares with solutions; an empty concentric spiral (knight vs knight) falls back to practice. **Pawn Attack:** solvable boards only, levels 3→8, `startOverPawnBoard()` (no penalty; the timed clock keeps running), `pawnAttackDeadEnd` recomputed after every move. Load failures set `loadFailed` (Retry). Bests: `vision.forksAndSkewers_{piece}_{target}_{mode}`, `vision.pawnAttack_{piece}_{mode}`, `vision.{drill}_{mode}`; concentric and timed pawn are `lowerIsBetter`. Constants: `noneRoundChance`, `speedRoundSeconds` (60), `pawnAttackFirstLevel`/`LastLevel`. |
| `screens/chess_vision_game_screen.dart` | 1250 | Single screen inside `TrainerLayout`, branching every region per drill. **An instruction line for all 8 drills** (the scan drills' style). Mode read from `gameState.mode`. Start over button for Pawn Attack (filled amber on a dead end). Load-error state (`loadFailed` + `retry`). Knight Flight & Pawn Attack use the interactive `Chessboard` + `GameData` *plus* `onTouchedSquare` (1-tap, tap-select and drag — the duplicate callback lands on the piece's own square, which the handlers ignore). Forks & Knight Sight stay on `Chessboard.fixed`. Mate in 1 takes `isCheck`/`sideToMove` from the displayed position. |
| `screens/chess_vision_menu_screen.dart` | 520 | Drill chips (4 rows / 8 drills; `Flexible` + `FittedBox` labels); forks shows piece + target + 3 mode cards — **the knight target is disabled when the piece is a knight**; the mode follows the drill and `_startGame` uses `effectiveMode`; options capped at 720 pt on wide windows. |
| `widgets/found_progress_indicator.dart` | 96 | "Found N of M" dots; shared by forks, knight sight and the three tap scan drills. |

### Opening Explorer — `lib/features/opening_trainer/`

Play through openings with a live eval bar, book moves and progressive hint arrows. **The only engine-backed feature.** In practice mode (the only reachable mode) the engine never replies — you play both sides.

> ⚠️ **Routing & UI reality.** The live route `/opening-trainer` hard-codes `OpeningGameScreen(mode: practice, difficulty: easy, playerColor: white)` — it takes **no query params**. `OpeningMenuScreen`, and the `LivesDisplay` / `MedalProgress` / `PrincipleCard` widgets, are **built but not wired**. Challenge mode, color/difficulty selection, lives, and medals are unreachable. See [Known Gaps](#known-gaps--cleanup).

| File | ~LoC | Purpose & key logic |
|---|---|---|
| `providers/opening_game_provider.dart` | ~1000 | **Key file.** `openingGameProvider` (**autoDispose**; engine + book services read once in `build()`; `ref.mounted` after every await, including the `onDepth` callback; `_gameGeneration` guards `startGame`/`startFromOpening`; book and engine load in parallel). **Engine lifecycle:** one engine for the whole screen session — no idle disposal between moves, hint passes, piece sessions or the picker; `onDispose` bumps every token, calls `stopSearch()` and `disposeWhenIdle()`. **Progressive hints:** `_requestHints` runs `getTopMoves` waves at depths **`[8,12,16,18]`** (practice; challenge runs one wave), book moves shown instantly and up to 2 popular book moves merged in; the hint cache records the last completed wave so a revisited position resumes deeper waves. **Move keys** go through `uci_move.dart` (`toUci`), so castling and promotions match the engine (`e1g1`, `e7e8q`) — no duplicate O-O or e1→h1 arrow. Mate scores carried through the eval bar, line tags and `_goTo`. Game end → `gameEnd` (checkmate/draw verdict); the engine is never asked about a finished position. `retryEngine()` after a failed start; `pauseAnalysis()`/`resumeHints()` for app backgrounding. **Lines & variations:** `GameLine`s + `activeLineIndex`/`cursorPly`, non-destructive `scrubBack`/`scrubForward`/`goTo`, branching, `_findContinuation`. |
| `models/opening_game_state.dart` | ~320 | `OpeningDifficulty(skillLevel, moveTimeMs, mistakeThresholdCp, lives)` — easy(3,200,150,3), medium(10,350,100,2), hard(18,500,50,1). `OpeningMode {practice, challenge}`; `MedalLevel`; `MoveClassification` (`best` = engine's #1, `book` = theory, the rest via forgiving `classifyDelta`); `SuggestedMove`, `MoveEval`, `formatEval` ("+0.3", "M3", `#` for mate on the board); `GameLine`; `MoveRecord.mateIn`; `GameEnd`; state fields `lastMove`, `gameEnd`, `engineUnavailable`, `engineDepth`/`engineTargetDepth`. |
| `models/uci_move.dart` | ~50 | `standardMove` (castling → king-to-g/c-file whatever square it was dropped on; a pawn reaching the last rank always queens), `toUci`, `parseUci` (`(none)` → null). |
| `models/opening_principles.dart` | 14 | 12 beginner tips. **Unused** (no `PrincipleCard` is shown). |
| `screens/opening_game_screen.dart` | ~950 | `TrainerLayout` (board left, eval bar/history/controls right in landscape; fixed-height opening name (2 lines) and history in portrait so the board never resizes). Localized strings. `AppLifecycleListener` stops the search when the app is hidden and resumes on show. Banners: "Checkmate!"/"Draw!" over the board; "engine unavailable" + Retry. Last-move highlight. AppBar: opening picker (selection cleared first; one at a time), flip board, toggle scores. Tap-a-piece **per-move analysis overlay** (badges clamped inside the board; castling gets one badge; "thinking" stops when a session ends). |
| `screens/opening_menu_screen.dart` | 332 | Color + difficulty + Practice/Challenge cards → would push `/opening-trainer/game?...`. **Not wired into the router.** |
| `widgets/eval_bar.dart` | 90 | White/dark bar, sigmoid `1/(1+e^(-cp/400))`, mate label, `#` for checkmate. |
| `widgets/eval_delta_overlay.dart` | ~180 | Move badges on each arrow's shaft (collision-nudged), absolute post-move eval, 👑 for the engine's #1; uses `parseUci`. |
| `widgets/opening_picker.dart` | 215 | Localized searchable opening browser (popular list + ECO A–E); waits for the shared book load; returns a PGN. |
| `widgets/thinking_indicator.dart` | ~110 | Animated brain + live "d12/18" depth readout. |
| `widgets/move_history_panel.dart` | ~380 | Lines panel (depth-first tree order, full sequence per row, active row owns the nav buttons); **44 pt nav buttons and move chips**; configurable `maxHeight`; mate-aware eval tags. |
| `widgets/lives_display.dart` / `medal_progress.dart` / `principle_card.dart` | — | **Built, not wired.** |

### Standalone screens

| File | ~LoC | Status |
|---|---|---|
| `features/home/screens/home_screen.dart` | 450 | **Nav hub, and it ranks rather than lists.** App icon + scaled BradBunR wordmark, then **one hero card** — `_HeroTrainingCard` for Chess Vision (purple → `/chess-vision`), badged "START HERE", with a bottom strip listing **all eight drills in two rows** — over **a row of two `_SecondaryTrainingCard`s**: Chess Notation (green → `/file-rank-trainer`) and Opening Explorer (orange → `/opening-trainer`, gated on `kEngineAvailable`). Info button → `/about`. |
| `features/about/screens/about_screen.dart` | 360 | About page: logo, **the real version** (`package_info_plus`), sections (incl. Credits and a Michael de la Maza tribute), and an **in-app feedback form** (500-character cap; sent via `feedbackServiceProvider`). |
| `features/tactics_trainer/screens/tactics_trainer_screen.dart` | 17 | Placeholder ("coming soon"). Routed at `/tactics-trainer` but **no in-app navigation reaches it.** |

---

## Core layer — `lib/core/`

| File | Purpose & key surface |
|---|---|
| `audio/audio_service.dart` | `audioServiceProvider`. **Owns all haptics.** Players split by layer: `_voicePlayer` (spoken prompts — one announcement at a time), `_correctPlayer`/`_incorrectPlayer` (blips, loaded once and rewound), `_cheerPlayer` (milestones and new records, layered over the voice). Multi-clip announcements (`speakSquare`, `speakMove`) re-check a sequence token after every await, so a newer announcement or **`stop()` cancels the rest** instead of splicing sentences. Configures the **ambient** audio session (mixes with other apps, obeys the silent switch) before the first sound. `speakFile/Rank/Square/Piece/Move`, `playCorrect/Incorrect/NewRecord/CheckCall/CheckmateCall`, **`playMilestone(streak)`** (haptic + `streak_5/10/15/20`), `playGameOver()` (haptic only), `speak(text)` (TTS fallback, ambient on iOS). Playback errors are logged and swallowed; asset paths are built from strings. |
| `services/personal_bests_service.dart` | `sharedPreferencesProvider` (overridden in `main()`; null → in-memory) and **`personalBestsProvider`** (app-lifetime `Notifier<Map<String,int>>`): `best(key)`, `submit(key, score, {lowerIsBetter})` → whether it was a record (saved as JSON under `personal_bests_v1`). A higher-is-better score of 0 never counts; an unreadable store is ignored. |
| `services/puzzle_service.dart` | `puzzleServiceProvider` / `mateInOnePuzzleServiceProvider`; `ParsedPuzzle` (+ `matches(NormalMove)`) and `getRandomPuzzle({exclude, sideToMove})` dealing from a no-repeat shuffled deck; memoized `loadPuzzles()`; `@visibleForTesting loadFromJson`; optional `Random`. |
| `services/scan_position_service.dart` | `scanPositionServiceProvider`; lazy per-`ScanSetKind {checks, captures, hanging}` loader of `assets/puzzles/scan_*.json` → `ScanPosition`. `load` throws and caches nothing when the asset is unreadable or has no playable positions (so Retry works); malformed entries are skipped; `getRandom(kind, {exclude})`. |
| `services/stockfish_service.dart` | **Engine entry point — the only engine file consumers import.** Re-exports `stockfish_engine_api.dart`, picks an implementation with a conditional import, exposes `stockfishServiceProvider` (one service for the app's lifetime), top-level `stockfishCleanupForRestart()` (debug-only call in `main()`), and **`kEngineAvailable`** (true on iOS, Android and web; the gates are the seam for a future engine-less target). |
| `services/stockfish_engine_api.dart` | Platform-neutral contract: `EvalResult` (incl. `depth`, `mateIn`), `ScoredMove`, `abstract class StockfishService` (`initialize`, `evaluate`, `getBestMove`, `getTopMoves`, `stopSearch`, **`disposeWhenIdle`**, `dispose`, `isBusy`), `SearchCancelledException`, `EngineUnavailableException`. Change a signature here and mirror it in **both** impls. |
| `services/stockfish_engine_io.dart` | Native impl. One native Stockfish per process (package rule). Ops are serialized (`isBusy` also covers a start in flight); **`disposeWhenIdle()`** releases the engine once nothing is running/queued/starting (any later call cancels the release); `stopSearch()` aborts the search and drops queued ops; a timed-out search sends `stop` and drains to its own `bestmove` (≤5s) before the next op — an engine that ignores `stop` is restarted; an engine that exits mid-search is replaced; a failed start is sticky until `initialize()` (Retry). `_doInitialize` works on a local engine and only a live, current engine is marked ready; an engine still starting when released is quit the moment it comes up. State is per-instance; `NativeStockfishService.forTesting(createEngine:, …)` is the fake-engine test seam. Scores normalized to **white's perspective**. |
| `services/stockfish_engine_web.dart` | **Web engine: Stockfish 19 Lite WASM in a Web Worker** (`web/stockfish/`, lite-single, no `SharedArrayBuffer`), via `dart:js_interop` with inline `extension type`s — no pub dependency. Worker created lazily on first `initialize()`; 45s handshake timeout, but a Worker error fails fast. ⚠️ Its UCI handling is a **deliberate duplicate** of the native impl — fix protocol bugs in both. |
| `services/opening_book_service.dart` | `openingBookServiceProvider`; `OpeningInfo`/`BookContinuation`; `getOpeningForPosition` / `isBookMove` / `getBookContinuations` / `getAllOpenings`. **Position-based & transposition-aware** index of ~3640 ECO lines (`assets/data/eco_openings.json`), built in **`compute()`** off the UI isolate; `_loadFuture ??=` memoizes concurrent loads. |
| `services/analytics_service.dart` | `analyticsServiceProvider`; **12** typed loggers — `log{FileRank,Letter,Move,Vision,Opening,Pieces}Drill{Started,Completed}` — plus `logScreenView` and **`ScreenViewObserver`** (router observer). Resolves `FirebaseAnalytics.instance` lazily, only after `analyticsAvailable`; `logEvent`'s async failures are caught. |
| `services/feedback_service.dart` | `feedbackServiceProvider`; `sendFeedback(message)` HTTP-GETs `https://secure.passports.com/funcs/etc/cct.cfc?method=feedback` (message in the query string — hence the 500-character cap on the form). **Used only by the About screen.** ⚠️ Name collides with `audio_service` but is unrelated. |
| `board_utils.dart` | `highlightFile/highlightRank/highlightSquare(index, color)` → `IMap<Square, SquareHighlight>`. |
| `theme/app_theme.dart` | `AppColors` + `AppTheme.light` (Material 3, Inter via google_fonts from the bundled assets). **No dark theme.** |
| `constants.dart` | `ChessConstants` (file/rank names, `squareName`, `allSquares`). (`TimerConstants` was removed — the live timers are in the providers.) |
| `widgets/trainer_layout.dart` | **`TrainerLayout(header, board: (ctx, size) => …, footer)`** — portrait: column with the board filling the middle; landscape (width ≥ 600 and > 1.15 × height): board on the left at full height, header+footer in a scrollable side panel. Public helpers `isLandscape`, `landscapeBoardSize`, `landscapePanelLeft`, `minPanelWidth`, `defaultPadding`. Header/footer must not use `Expanded`/`Spacer`. |
| `widgets/square_name_overlay.dart` | `SquareNameOverlay` + `SquareLabel` — square-name labels over the board (`IgnorePointer`). |

---

## Localization

**10 locales**, generated (not hand-written): **en, de, es, fr, it, ja, ko, pt, ru, zh**.

- Source of truth: `lib/l10n/app_*.arb` (template `app_en.arb`).
- Generated by `flutter gen-l10n` (config in `l10n.yaml`; `flutter: generate: true` in pubspec). Output `lib/l10n/app_localizations*.dart` **is committed**.
- **English is the fallback** for unsupported device languages: `l10n.yaml` sets `preferred-supported-locales: [en]` (gen-l10n would otherwise sort German first, and Flutter falls back to the first supported locale).
- Wired in `app.dart` via `AppLocalizations.localizationsDelegates` + `supportedLocales`. No `locale:` override. iOS declares the same 10 languages in `CFBundleLocalizations`.
- Voice clips and the TTS fallback are **English only**; BradBunR has no Cyrillic/CJK glyphs, so card titles fall back to the system font in ru/ja/ko/zh.
- After editing any `.arb`, run `flutter gen-l10n` (or just build).

---

## Routes — `lib/app.dart`

12 flat `GoRoute`s, `initialLocation: '/'`; any unknown path is sent to `/` (`onException`). The `name` column feeds `ScreenViewObserver` (screen-view names). Forward nav uses `context.push()`, back uses `context.pop()`. Every enum query param is parsed with `firstWhere(…, orElse:)`, so a bad value can't throw.

| Path | Screen | name | Query params |
|---|---|---|---|
| `/` | HomeScreen | `home` | — |
| `/file-rank-trainer` | FileRankMenuScreen | `file_rank_menu` | `subject`, `mode`, `hardMode` (optional) |
| `/file-rank-trainer/game` | FileRankGameScreen | `file_rank_game` | `subject` (def `files`), `mode` (def `explore`), `hardMode` |
| `/letter-trainer/game` | LetterGameScreen | `letter_game` | `mode` (def `explore`), `hardMode` |
| `/move-trainer` | MoveMenuScreen | `move_menu` | `mode`, `hardMode` (optional) |
| `/move-trainer/game` | MoveGameScreen | `move_game` | `mode` (def `practice`), `hardMode` |
| `/chess-vision` | ChessVisionMenuScreen | `chess_vision_menu` | `drill`, `piece`, `target`, `mode` (optional) |
| `/chess-vision/game` | ChessVisionGameScreen | `chess_vision_game` | `drill`, `piece`, `target`, `mode` (with defaults; the screen coerces via `effectiveMode`) |
| `/opening-trainer` | **OpeningGameScreen** | `opening_trainer` | **none** — hard-coded practice / easy / white |
| `/the-pieces/which-side-wins` | WhichSideWinsScreen | `which_side_wins` | `mode` (def `practice`) |
| `/tactics-trainer` | TacticsTrainerScreen | `tactics_trainer` | — (placeholder, unreachable from UI) |
| `/about` | AboutScreen | `about` | — |

There is **no `/opening-trainer/game` route** and **no menu route** for the opening trainer.

---

## Assets, data & tooling

| Path | Contents |
|---|---|
| `assets/images/` | `app_icon.png` (1024²), `internut_logo*.png`, home card art (`card_notation/vision/openings.png`, 1200 px) |
| `assets/fonts/BradBunR.ttf` | Display font for titles/labels |
| `assets/google_fonts/` | **Inter** Regular/Medium/SemiBold (the exact google_fonts files) + `OFL.txt` |
| `assets/sounds/` | ElevenLabs voice clips: `file_*.mp3` (a–h), `rank_*.mp3` (1–8), `piece_*.mp3` (6), `move_takes/check/checkmate.mp3`, `new_record.mp3`, **`streak_5/10/15/20.mp3` (milestone cheers)**; SFX `correct.m4a`/`incorrect.m4a`. Raw recording masters live in `resources/audio/` (outside the bundle). |
| `assets/puzzles/moves_puzzles.json` | 500 curated Lichess puzzles (CC0) → move trainer |
| `assets/puzzles/scan_{checks,captures,hanging}.json`, `mate_in_one_puzzles.json` | Chess Vision scanning drills |
| `assets/data/eco_openings.json` | ~3640 ECO openings (Lichess) → `OpeningBookService` |
| `scripts/curate_puzzles.py`, `scripts/curate_scanning_positions.py` | Puzzle/position curation |
| `scripts/build_web.sh` | The web build (see CLAUDE.md) |
| `scripts/build_ipa.sh` (+ `build_ipa.env.example`) | One-command iOS release: App Store Connect pre-checks (read-only API: app record, highest uploaded build, approved versions) → analyze/test → `flutter build ipa` (falls back to an API-key export if Xcode isn't signed in) → `xcrun altool --upload-app` → writes the build number back to `pubspec.yaml` |
| `scripts/deploy_play.sh` (+ `deploy_play.env.example`) | Android App Bundle → Google Play via fastlane supply |

**Build tooling:** `flutter_native_splash` (white Internut logo on `#1B5E20`; config in `pubspec.yaml`), `flutter_launcher_icons` (from `app_icon.png`, `min_sdk_android: 21`, iOS alpha removed), `flutterfire configure` (regenerates `firebase_options.dart`).

**Platform config worth knowing:** iOS `CFBundleDisplayName` is "Calvin Chess"; iPhone is portrait-only, iPad declares all four orientations (multitasking on); `AppDelegate.swift` raises the open-file soft limit to 4096 (see the engine gotcha in CLAUDE.md); Firebase's ad-ID, ad-personalization and IDFV collection are disabled in `Info.plist`, and the Android manifest strips `AD_ID` and the `ACCESS_ADSERVICES_*` permissions.

---

## Known Gaps & Cleanup

Read this before trusting a feature is "done." Verified against code on 2026-10-03.

**Built but not wired (decide: finish or remove):**
- **Opening trainer challenge UI.** `OpeningMenuScreen`, `LivesDisplay`, `MedalProgress`, `PrincipleCard`, and any game-over/medal overlay exist but are not in the live route or screen. Challenge mode, color/difficulty pick, lives, and medals are unreachable. The provider logic exists (and the engine's reply is now only applied to the position it was computed for); `OpeningMenuScreen` still pushes a route that doesn't exist, and ~28 of its l10n keys are unreferenced.

**Placeholder / unreachable:**
- `/tactics-trainer` is routed but no in-app navigation links to it.

**Latent risks to keep in mind:**
- **Native Stockfish leaks 4 file descriptors per engine start** (the `stockfish` package's glue never closes its pipes). The app starts one engine per Opening Explorer visit and `AppDelegate` raises the soft limit to 4096, so this only matters after ~1000 visits in one process. Fixing it at the source means patching/vendoring the package.
- `AudioService` swallows playback errors and builds asset paths from strings — renamed/missing clips fail silently.
- The feedback form sends the message in a GET query string to the passports.com endpoint (capped at 500 characters). A POST would be cleaner but needs the server confirmed.
- Kids Category: Firebase Analytics is third-party analytics under App Store guideline 1.3, and the iOS SPM product links the ad-ID-capable `FirebaseAnalytics` (ad-ID/IDFV collection is disabled in `Info.plist`). There is no crash reporting.
- `TextScaler.noScaling` ignores the user's Larger Text setting (a deliberate design choice).
- Three identical two-value `AnswerResult` enums (file-rank, letter, move) — harmless duplication.
- An auto-disposed provider renders its default state for one frame before the post-frame `startGame` (e.g. letters in speed mode briefly shows the explore grid).
- In portrait the milestone banner covers the bottom of the page (timer bar / vision footer buttons) for ~1.5s; taps pass through.

## Where to start (roadmap pointers)

- **Add a new trainer** → copy a feature folder; follow the Notifier pattern above (autoDispose, `ref.mounted`, bests via `personalBestsProvider`); lay the screen out with `TrainerLayout`; reuse the shared widget kit; register a route + `name` in `app.dart`; add a home card in `home_screen.dart`.
- **Progress beyond bests** → `personalBestsProvider` is the model: an app-lifetime provider over `sharedPreferencesProvider`. Cloud sync would need an account system (Firebase Auth/Firestore were removed as unused).
- **Finish the opening trainer** → wire `OpeningMenuScreen` to a real route (+ `/opening-trainer/game`), and mount `LivesDisplay`/`MedalProgress`/`PrincipleCard` into `opening_game_screen.dart`.
- **Touch the engines** → `chess_vision/services/` (fork_skewer is the hot path) and `core/services/stockfish_engine_io.dart` (the contract lives in `stockfish_engine_api.dart`, mirrored in the web impl).
- **Build the tactics trainer** → flesh out the placeholder and link a home card.

---

## Quick reference

> Consolidated lookup of the facts most often needed *exactly* right. Verified 2026-10-03 — the code is the source of truth for precise values.

### Providers (all of them)

| Provider | Kind | File | Role |
|---|---|---|---|
| `audioServiceProvider` | Provider | `core/audio/audio_service.dart` | voice clips, SFX, cheers, haptics, TTS |
| `analyticsServiceProvider` | Provider | `core/services/analytics_service.dart` | 12 typed Firebase drill events + screen views |
| `sharedPreferencesProvider` | Provider (overridden in `main()`) | `core/services/personal_bests_service.dart` | device key-value store, or null |
| `personalBestsProvider` | NotifierProvider (app lifetime) | `core/services/personal_bests_service.dart` | saved personal bests for every trainer |
| `puzzleServiceProvider` | Provider | `core/services/puzzle_service.dart` | move-trainer puzzles (`ParsedPuzzle`) |
| `mateInOnePuzzleServiceProvider` | Provider | `core/services/puzzle_service.dart` | same class, `mate_in_one_puzzles.json` |
| `scanPositionServiceProvider` | Provider | `core/services/scan_position_service.dart` | curated scanning positions |
| `stockfishServiceProvider` | Provider | `core/services/stockfish_service.dart` | the engine service (one per app; the engine itself starts per Opening visit) |
| `openingBookServiceProvider` | Provider | `core/services/opening_book_service.dart` | ECO names / book continuations |
| `feedbackServiceProvider` | Provider | `core/services/feedback_service.dart` | HTTP user feedback (About screen) |
| `fileRankGameProvider` | NotifierProvider.autoDispose | `features/file_rank_trainer/providers/` | files/ranks/squares drill logic |
| `letterGameProvider` | NotifierProvider.autoDispose | `features/letter_trainer/providers/` | piece-letter drill logic |
| `moveGameProvider` | NotifierProvider.autoDispose | `features/move_trainer/providers/` | move-from-notation logic |
| `chessVisionProvider` | NotifierProvider.autoDispose | `features/chess_vision/providers/` | all 8 vision drills |
| `openingGameProvider` | NotifierProvider.autoDispose | `features/opening_trainer/providers/` | engine-backed explorer |
| `whichSideWinsProvider` | NotifierProvider.autoDispose | `features/pieces/providers/` | piece-value drill |

### Enums (exact values — order matters where used as `.values`)

| Enum | Values | Defined in |
|---|---|---|
| `TrainerSubject` | `files, ranks, squares, moves, letters, pieceValue` (last three menu-only) | `file_rank_game_state.dart` |
| `TrainerMode` | `explore, practice, speed` | `file_rank_game_state.dart` |
| `LetterTrainerMode` | `explore, practice, speed` | `letter_game_state.dart` |
| `LetterQuestionDirection` | `letterToPiece, pieceToLetter` | `letter_game_state.dart` |
| `MoveTrainerMode` | `practice, speed` | `move_game_state.dart` |
| `VisionDrillType` | `forksAndSkewers, knightSight, knightFlight, pawnAttack, findChecks, findCaptures, hangingPieces, mateInOne` (+ `isScanDrill`/`isTapScanDrill`/`isKnightDrill`, `effectiveMode()`) | `chess_vision_state.dart` |
| `ScanSetKind` | `checks, captures, hanging` | `scan_position_service.dart` |
| `VisionMode` | `practice, speed, concentric` | `chess_vision_state.dart` |
| `WhitePiece` | `queen, rook, bishop, knight` | `chess_vision_state.dart` |
| `TargetPiece` | `rook, bishop, knight, queen` _(different order from WhitePiece)_ | `chess_vision_state.dart` |
| `OpeningDifficulty` | `easy, medium, hard` (carry `skillLevel`, `moveTimeMs`, `mistakeThresholdCp`, `lives`) | `opening_game_state.dart` |
| `OpeningMode` | `practice, challenge` | `opening_game_state.dart` |
| `MedalLevel` | `none, bronze, silver, gold` (thresholds 3/6/10 user moves) | `opening_game_state.dart` |
| `MoveClassification` | `brilliant, best, good, book, inaccuracy, mistake, blunder` | `opening_game_state.dart` |
| `GameEnd` | `checkmate, draw` (opening explorer verdict banner) | `opening_game_state.dart` |
| `PieceType` | `pawn(1), knight(3), bishop(3), rook(5), queen(9)` — no king | `which_side_wins_state.dart` |
| `WhichSideWinsMode` | `practice, speed` | `which_side_wins_state.dart` |

### Feedback delays & timers

Correct / incorrect feedback delay (ms) and the speed-round duration. **All hardcoded in each `*_provider.dart`.**

| Trainer | Practice (correct/incorrect) | Speed (correct/incorrect) | Speed timer |
|---|---|---|---|
| file / rank | 400 / 1200 | 200 / 600 | 30s |
| squares | **700** / 1200 | 200 / 600 | 30s |
| letters | 700 / 1200 | 200 / 600 | 30s |
| move | **700** / 1200 | 200 / 600 | 30s |
| pieces | 600 / 1400 | 300 / 800 | 30s |
| chess vision | drill-specific (forks reveal 1500, pawn round-end 800); a round is **credited when solved**, the delay only defers the next position | — | 60s (speed); stopwatch for pawn-timed & concentric |
| chess vision — scanning | tap drills: round-end 800, flash 400, skip-reveal 1500 · mate: 900 correct / 1500 wrong | tap drills: round-end 400 · mate: 500 correct / 800 wrong | 60s |

File/rank **explore** mode advances after 800ms. Personal bests update at game over (speed mode; concentric/timed-pawn times), **saved on device**.

### Asset & data paths

- **Voice:** `assets/sounds/{file_a..h, rank_1..8, piece_*, move_takes, move_check, move_checkmate, new_record, streak_5/10/15/20}.mp3` · **SFX:** `correct.m4a`, `incorrect.m4a`
- **Data:** `assets/puzzles/moves_puzzles.json` (move trainer) · `assets/puzzles/scan_{checks,captures,hanging}.json` + `mate_in_one_puzzles.json` (vision scanning drills) · `assets/data/eco_openings.json` (opening book)
- **Fonts:** `assets/fonts/BradBunR.ttf`, `assets/google_fonts/Inter-{Regular,Medium,SemiBold}.ttf`
- **Strings:** `lib/l10n/app_*.arb` (10 locales; `app_en.arb` is the template) → `flutter gen-l10n`

---

## Glossary

App-specific vocabulary that maps user language to code. Standard chess terms (FEN, SAN, fork, skewer, file, rank) keep their usual meanings.

| Term | In this codebase |
|---|---|
| **Trainer / feature** | One of the top-level modes under `lib/features/`. |
| **Subject** | The file-rank menu's drill type: `files`, `ranks`, `squares`, `letters`, `moves`, `pieceValue`. The last three hand off to sibling features. |
| **Mode** | `explore` (free play, no score), `practice` (streaks, no timer/end → no bests), `speed` (timed round — 30s, or 60s in Chess Vision — logs bests). Vision adds `concentric`; opening uses `practice`/`challenge`. |
| **Hard mode** | ⚠️ Polysemous: file-rank = flip board to Black's view; letters = black pieces; move trainer = control Black (puzzles filtered to black-to-move) **and** flip. |
| **Drill** | A Chess Vision exercise — eight of them: forks & skewers, knight sight, knight flight, pawn attack, find checks, find captures, hanging pieces, mate in 1. |
| **Concentric** | A forks-&-skewers mode that walks the target through a fixed 63-square spiral (`concentricPath`), filtered to targets that have solutions. |
| **None round** | A forks round with no fork or skewer — 15% of rounds; answered with the **None** button. |
| **Vision** | The Chess Vision feature — board-visualization drills, not gameplay. |
| **The Pieces** | The piece-value feature, route `/the-pieces/which-side-wins`. Surfaced as the **Piece Value** subject inside Chess Notation. |
| **Chess Notation** | Home-screen label for the file-rank, letter, move and piece-value trainers, route `/file-rank-trainer`. |
| **Streak / milestone** | Consecutive correct answers; a milestone fires every multiple of 5 (banner + haptic + a cheer at 5/10/15/20). |
| **Personal best** | Best speed-mode score (or fastest concentric/timed-pawn time), saved on the device via `personalBestsProvider`. |
| **Shared widget kit** | `StreakCounter` / `TimerBar` / `ResultsCard` / `MilestoneBanner` under `file_rank_trainer/widgets/`, reused app-wide. |
| **TrainerLayout** | `core/widgets/trainer_layout.dart` — portrait column, landscape board-left/panel-right. |
| **Engine** | Stockfish (FFI native, WASM on web) for the opening explorer; or the pure-Dart "engines" in `chess_vision/services/` and `pieces/services/`. |

---

## Keeping these docs in sync

Verified against code on **2026-10-03**. These docs describe the **map and patterns**, mostly avoiding line numbers — exact values live in code. **When you change code, update the doc in the same change** (CLAUDE.md says this too). To re-verify a feature, read its `*_state.dart` + `*_provider.dart` + `*_screen.dart` and reconcile this file. The most drift-prone spots, historically: feedback-delay constants, route wiring, and "built but not wired" UI.

## Project info

| | |
|---|---|
| Organization | Internut Education |
| Website | https://internut.education |
| Contact | dave@internut.education |
| Bundle ID | ⚠️ mismatched: iOS `education.internut.chesstrainer`, Android `education.internut.calvinchesstrainer` — reconcile before release (see Explanations → iOS Signing) |
| Repository | https://github.com/daveinternut/calvinchesstrainer (**public**) |
| Firebase project | `calvin-chess-trainer` |
| License | GPL-3.0 (required by chessground/dartchess) |
