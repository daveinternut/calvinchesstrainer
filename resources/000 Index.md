# Calvin Chess Trainer — Code Map

> **The index.** This file is the single entry point for understanding the codebase. It is written to be read top-to-bottom by a human or an AI agent: orientation → architecture → entry flow → feature maps → core layer → routes → known gaps. For deeper narrative on individual subsystems see [000 Explanations.md](000%20Explanations.md); for the chessground/dartchess API reference see [000 lichess documentation.md](000%20lichess%20documentation.md).
>
> **Verified against code on 2026-06-05.** Where docs and code disagreed, code won. Known divergences (dead code, built-but-unwired UI) are called out in [Known Gaps & Cleanup](#known-gaps--cleanup) — read that section before assuming a feature is fully shipped.
>
> **Jump to:** [System map](#system-map) · [Features](#features) · [Core layer](#core-layer--libcore) · [Routes](#routes--libappdart) · [Quick reference](#quick-reference) · [Glossary](#glossary) · [Known gaps](#known-gaps--cleanup). For "which file do I edit to do X?", the **task router** lives in [CLAUDE.md](../CLAUDE.md) (auto-loaded each session).

## What this is

A Flutter chess-training app for kids. It teaches board fundamentals and chess vision through short, audio-rich, gamified drills — not by playing full games (except the opening trainer). Five trainers ship today:

| Trainer | What it teaches | Route hub |
|---|---|---|
| **The Pieces** | Relative piece values ("which side wins?") | `/the-pieces` |
| **Chess Notation** | Files, ranks, squares, and executing moves from notation | `/file-rank-trainer` (the "Moves" subject hands off to `/move-trainer/game`) |
| **Chess Vision** | Forks/skewers, knight sight, knight flight, pawn-attack navigation | `/chess-vision` |
| **Opening Fundamentals** | Playing sound opening moves against Stockfish | `/opening-trainer` |
| _Tactics_ | _placeholder only — routed but unreachable_ | `/tactics-trainer` |

## Tech stack

| Layer | Choice | Notes |
|---|---|---|
| Framework | Flutter / Dart | `sdk: ^3.9.2`; app version `1.3.0+4` |
| State | **Riverpod** `flutter_riverpod ^3.2.1` | `Notifier`/`NotifierProvider` pattern (not StateNotifier) |
| Routing | **GoRouter** `^17.1.0` | 12 flat routes, `context.push()`/`context.pop()` |
| Board UI | **chessground** `^8.0.1` (lichess) | board widget, 28 piece sets, 25+ themes, drag-and-drop, animation — GPL-3.0 |
| Chess logic | **dartchess** `^0.12.1` (lichess) | legal moves, FEN/PGN, SAN, game state — GPL-3.0 |
| Engine | **stockfish** `^1.8.1` | Stockfish via FFI/UCI; powers the opening trainer only |
| Audio | **just_audio** `^0.10.5` + **flutter_tts** `^4.2.5` | pre-recorded clips; TTS is a fallback for dynamic phrases |
| Fonts | **google_fonts** `^8.0.2` (Inter) + bundled **BradBunR** | BradBunR is the playful display font for titles/labels |
| Backend | **Firebase** core/auth/firestore/analytics | project `calvin-chess-trainer`; analytics is wired, auth/firestore are **not used yet** |
| Localization | `flutter_localizations` + `intl`, gen-l10n | **10 locales** — see [Localization](#localization) |
| Misc | `fast_immutable_collections ^11.1.0`, `http ^1.6.0` | FIC is required by chessground; `http` powers the feedback form |

**GPL-3.0 note:** chessground and dartchess are GPL-3.0, so the distributed app must be GPL-3.0.

## How to run

```bash
flutter pub get
flutter run                       # device/emulator/Chrome
flutter gen-l10n                  # regenerate localizations after editing lib/l10n/*.arb (also runs on build)
flutter build ios --release       # iOS 15.0 min target (cloud_firestore requirement)
```

Firebase is configured for **web, android, iOS** (macOS/Windows/Linux throw `UnsupportedError`). Regenerate platform config with `flutterfire configure`.

---

## Architecture & conventions

**Feature-first folders.** Each trainer is a self-contained folder under `lib/features/<feature>/` with `models/`, `providers/`, `screens/`, `widgets/` (and `services/` for the algorithm-heavy ones). Cross-cutting code lives in `lib/core/`.

**The Notifier pattern (read this — every trainer follows it).** Each trainer is one immutable state class + one `Notifier` that owns *all* game logic. Screens are thin: they `watch` the state and forward taps/moves to the notifier. The recurring shape:

- **State class** (`*_state.dart`) — immutable, `copyWith`, plus computed getters that produce board coloring (`allHighlights`, `feedbackShapes`, `squareHighlights`, `boardFen`). **Gotcha:** `copyWith` uses the `T? Function()?` thunk idiom for nullable fields — pass `() => null` to *clear* a field; omitting the arg *keeps* it.
- **Notifier** (`*_provider.dart`) — `startGame()`, a tap/move handler, two `Timer`s (feedback-delay + speed countdown), streak/best tracking, analytics calls. Input is gated by `isWaitingForNext` / `isGameOver` during feedback delays.
- **Screen** (`*_screen.dart`) — `Chessboard`/`Chessboard.fixed` + the shared UI widgets; starts the game in a post-frame callback; stops audio on dispose.

**Plugin-first.** Never hand-roll chess logic or board rendering — chessground + dartchess cover board UI, piece art, move validation, FEN/PGN, SAN, and game-state detection. We build only game flow, scoring, audio, navigation, and a thin highlight bridge ([board_utils.dart](#core-layer--libcore)). See [000 Explanations.md](000%20Explanations.md#plugin-first-architecture).

**Personal bests are ephemeral.** Every trainer stores bests in an in-memory `Map<String,int>` on its notifier — **nothing is persisted** to disk or Firebase, so bests reset on app restart. They are also tracked in **speed mode only** (practice has no end condition, so it never logs completion or updates a best). This is the obvious place to add persistence (Firestore is already a dependency).

**Shared UI kit lives under `file_rank_trainer/widgets/`.** Four widgets there — `StreakCounter`, `TimerBar`, `ResultsCard`, `MilestoneBanner` — are imported directly by the move, pieces, and chess-vision screens. Treat that directory as app-wide shared UI: a change there is cross-cutting. (A reasonable future refactor: promote them to `lib/core/widgets/`.)

### Entry-point flow

`main.dart` → `app.dart` → router → screens.

1. **`lib/main.dart`** — in order: `stockfishCleanupForRestart()` (frees a lingering native engine thread so hot-restart works) → `WidgetsFlutterBinding.ensureInitialized()` → `FlutterNativeSplash.preserve(...)` → `await Firebase.initializeApp(...)` → portrait-only lock (`SystemChrome.setPreferredOrientations`) → `FlutterNativeSplash.remove()` → `runApp(ProviderScope(child: CalvinChessTrainerApp()))`.
2. **`lib/app.dart`** — `CalvinChessTrainerApp` builds `MaterialApp.router`: `theme: AppTheme.light` (light only — no dark theme), the GoRouter config, l10n delegates, and a `builder` that locks `textScaler: TextScaler.noScaling` (OS font-scaling is disabled app-wide). The top-level `_router` registers a single `FirebaseAnalyticsObserver` that auto-logs a screen view per route using each route's `name` — built defensively (`_buildObservers`): if Firebase isn't initialized (widget tests), the app renders without analytics instead of crashing.
3. **`lib/firebase_options.dart`** — FlutterFire-generated; do not hand-edit.

---

## System map

### Boot sequence

```
main.dart
 ├─ stockfishCleanupForRestart()          free a lingering native engine thread (hot-restart safety)
 ├─ Firebase.initializeApp()              awaited, before runApp
 ├─ portrait lock + native splash remove
 └─ runApp( ProviderScope( CalvinChessTrainerApp ) )
      └─ app.dart → MaterialApp.router
           ├─ AppTheme.light            (light theme only; textScaler locked to noScaling)
           ├─ AppLocalizations          (10 locales)
           └─ GoRouter _router          12 routes + FirebaseAnalyticsObserver (screen views by route name)
                 └─ <Feature>Screen     watches its provider, renders the board
```

### Per-screen runtime loop

The board is a **pure function of provider state** — nothing game-related is stored on the widget.

```
user taps a square / drags a piece
 └─ Screen forwards to the feature Notifier   (handleBoardTap / handleMove / handleAnswer)
      ├─ Notifier mutates immutable state via copyWith
      ├─ calls core services: AudioService (speak/SFX/haptics), AnalyticsService (drill events), engine
      └─ schedules Timers: feedback-delay (auto-advance) + speed countdown
 └─ Riverpod emits new state → Screen rebuilds → board reads state.allHighlights / feedbackShapes / boardFen
```

Input is gated while `isWaitingForNext` or `isGameOver` is true (the handler early-returns).

### Feature notifier → core service dependencies

| Notifier (provider) | Audio | Analytics | Other services / engines |
|---|:---:|:---:|---|
| `fileRankGameProvider` | ✅ | ✅ | — |
| `moveGameProvider` | ✅ | ✅ | `puzzleServiceProvider` |
| `chessVisionProvider` | ✅ | ✅ | `ForkSkewerEngine` · `KnightEngine` · `PawnAttackEngine` (static, pure) |
| `openingGameProvider` | ✅ | ✅ | `stockfishServiceProvider` · `openingBookServiceProvider` |
| `whichSideWinsProvider` | ✅ | ✅ | `PieceValueEngine` (instance) |

`feedbackServiceProvider` is standalone (About screen only). **Only the opening trainer uses Stockfish.**

### Shared-widget graph

```
file_rank_trainer/widgets/ ──┬─ StreakCounter ─┐
                             ├─ TimerBar       ├─ imported by → move_trainer, chess_vision, pieces
                             ├─ ResultsCard    │
                             └─ MilestoneBanner┘   (move_trainer + chess_vision)
core/widgets/SquareNameOverlay ── imported by → file_rank_trainer, move_trainer
```

Treat `file_rank_trainer/widgets/` as the app-wide UI kit: a change there ripples across trainers.

---

## Features

Ordered as they appear on the home screen. For each: where it's reached, its key files, the load-bearing logic, and gotchas.

### The Pieces — `lib/features/pieces/`

"Which Side Wins?" — compare two groups of pieces by total value and tap the stronger side.

| File | ~LoC | Purpose & key logic |
|---|---|---|
| `models/which_side_wins_state.dart` | 100 | `PieceType` enum (pawn 1 / knight 3 / bishop 3 / rook 5 / queen 9 — **no king**); `WhichSideWinsMode {practice, speed}`; `AnswerSide`; `PieceGroupPuzzle` (two `List<PieceType>` + `correctSide`, with `leftValue`/`rightValue` getters); immutable `WhichSideWinsState`. |
| `services/piece_value_engine.dart` | 151 | **Key file.** `generate(difficulty)` builds puzzles at 5 levels: L1 = 1v1, value gap ≥4; L2 = 1v1, gap 1–3; L3 = 2–3 pieces, gap ≥3; L4 = 2–3 pieces, gap 1–2; L5 = 3–4 pieces, gap 1–3. Retries ≤100× to hit the gap window; sides never equal; random left/right assignment. |
| `providers/which_side_wins_provider.dart` | 173 | `whichSideWinsProvider`. **Progressive difficulty (practice only):** +1 level every 3 correct (cap 5), −1 on any wrong (floor 1). **Speed:** random level 1–5 per puzzle, 30s countdown. Delays: speed 300/800ms, practice 600/1400ms. Best keyed by `mode.name`, speed-only. |
| `screens/pieces_menu_screen.dart` | 231 | Header card + Practice/Speed cards → `/the-pieces/which-side-wins?mode=`. |
| `screens/which_side_wins_screen.dart` | 215 | Two `PieceGroupPanel`s + `VsDivider`; tap to answer; practice shows a 5-dot difficulty indicator. **Reuses** `StreakCounter`/`TimerBar`/`ResultsCard`. |
| `widgets/piece_group_panel.dart` | 76 | Renders a group of piece images (`PieceSet.cburnett.assets`), responsive sizing by count, animated feedback tint. |
| `widgets/vs_divider.dart` | 36 | Circular "VS" badge (BradBunR). |

### Chess Notation — `lib/features/file_rank_trainer/` + `lib/features/move_trainer/`

The home "Chess Notation" card opens the **file-rank menu**, which has four subject chips: **Files, Ranks, Squares, Moves**. Files/Ranks/Squares run in the file-rank trainer; selecting **Moves pushes `/move-trainer/game`**. So `FileRankMenuScreen` is the shared entry point for both features — the move trainer has no menu of its own reachable from home.

#### file_rank_trainer (static board, tap-to-answer)

| File | ~LoC | Purpose & key logic |
|---|---|---|
| `models/file_rank_game_state.dart` | 175 | `TrainerSubject {files, ranks, squares, moves}`, `TrainerMode {explore, practice, speed}`, `AnswerResult`, `AnswerFeedback`, immutable `FileRankGameState`. **`allHighlights` getter** branches squares-vs-files/ranks and merges green-correct / red-incorrect square coloring (all alpha 0.6) via `board_utils`. There is **no reverse mode and no yellow target** (legacy docs claimed both — they don't exist). |
| `providers/file_rank_game_provider.dart` | 325 | `fileRankGameProvider`. Prompt generation avoids immediate repeats; speaks the answer via `AudioService`; schedules auto-advance. **Delays:** explore 800ms; files/ranks practice 400/1200ms, speed 200/600ms; **squares** practice **700**/1200ms (longer so the square-name label can be read), speed 200/600ms. Speed countdown hardcoded 30s. Best key = `{subject}_{mode}_{isHardMode}`, speed-only. **`moves` is never handled here** — the menu routes it to the move trainer. |
| `screens/file_rank_game_screen.dart` | 243 | **The routed screen.** `Chessboard.fixed` (`enableCoordinates: false` always), `onTouchedSquare` → `handleBoardTap`. Hard mode flips orientation to `Side.black`. Squares mode overlays `SquareNameOverlay`. Composes `PromptDisplay`, `StreakCounter`, `TimerBar`, `MilestoneBanner`, `ResultsCard`. |
| `screens/file_rank_menu_screen.dart` | 308 | Subject chips (incl. Moves) + mode cards + Hard Mode toggle. **Routes by subject** — Moves → `/move-trainer/game`, else → `/file-rank-trainer/game`. |
| `widgets/streak_counter.dart` | 159 | **Shared.** Animated streak number; elastic pulse each increment, green-glow milestone at every multiple of 5. |
| `widgets/timer_bar.dart` | 103 | **Shared.** Countdown bar (default 30s), green→yellow→red, pulses + "Hurry" under 5s. |
| `widgets/results_card.dart` | 137 | **Shared.** End-of-round overlay: NEW RECORD badge, Correct / Accuracy% / Best streak, Menu / Play Again. |
| `widgets/milestone_banner.dart` | 191 | **Shared, and absent from the old index.** Full-width top celebration banner at every 5-streak; fires `HapticFeedback.heavyImpact()` + a 2.2s animation. Visual + haptic only — **no audio** (see milestone-audio note in Known Gaps). |
| `widgets/prompt_display.dart` | 68 | Prompt text above the board. **Not shared** (move trainer has its own). |
| `screens/file_rank_screen.dart` | 2 | **DEAD CODE** — barrel re-exporting the two screens; imported nowhere. Delete candidate. |

#### move_trainer (interactive board, puzzle-based)

| File | ~LoC | Purpose & key logic |
|---|---|---|
| `models/move_game_state.dart` | 141 | `MoveTrainerMode {practice, speed}`, `MoveFeedback`/`MoveFeedbackResult`, immutable `MoveGameState`. `feedbackShapes` → green `Arrow` only on **incorrect**; `squareHighlights` → green from/to only on **correct**. |
| `providers/move_game_provider.dart` | 204 | `moveGameProvider`. Loads puzzles via `puzzleServiceProvider`; hard mode filters puzzle side to `Side.black` (user controls black). Correctness = `from==expected.from && to==expected.to`. **Correct** → `displayFen` updated (piece stays); **incorrect** → FEN unchanged (piece snaps back) + green arrow to the right square. **Delays:** practice **700**/1200ms, speed 200/600ms. Speaks the move via `AudioService.speakMove` (TTS for castling). |
| `screens/move_game_screen.dart` | 257 | **The routed screen.** Interactive `Chessboard` + `GameData` (drag-and-drop, legal-move dots, `showLastMove`, `autoQueenPromotion`, `enableCoordinates: false`). `SquareNameOverlay` on destination squares during feedback. **Reuses** `MilestoneBanner`/`StreakCounter`/`TimerBar`/`ResultsCard`. |
| `screens/move_menu_screen.dart` | 254 | Practice/Speed + Hard Mode → `/move-trainer/game`. (Reachable directly via `/move-trainer`, but the live UI path is the file-rank menu's Moves chip.) |
| `widgets/move_prompt_display.dart` | 76 | Shows SAN prominently (e.g. "Qb6") + a friendly subtitle; special-cases castling. |
| `screens/move_trainer_screen.dart` | 17 | **DEAD CODE** — "coming soon" stub; not routed/imported. Delete candidate. |

#### Puzzle pipeline

Puzzles come from the Lichess puzzle DB (CC0). `scripts/curate_puzzles.py` filters the 5.7M-row CSV (rating 600–1500, NbPlays > 500, no promotions, piece-balanced) into `assets/puzzles/moves_puzzles.json`. `PuzzleService` parses each at runtime into a `ParsedPuzzle` (plays the setup move, derives SAN/role/side, capture/check flags). See [000 Explanations.md](000%20Explanations.md#move-trainer).

### Chess Vision — `lib/features/chess_vision/`

**The most algorithm-heavy feature.** Four drills run through **one** unified state + provider + screen, each branching on `VisionDrillType {forksAndSkewers, knightSight, knightFlight, pawnAttack}`. The three engines under `services/` are the high-risk, high-value files.

| File | ~LoC | Purpose & key logic |
|---|---|---|
| `services/fork_skewer_engine.dart` | 158 | **Crown jewel.** `computeValidSquares(...)` brute-forces all 64 candidate squares; for each it builds a 4-piece position in dartchess (white piece, white king parked in a safe corner, black king pinned at **d5**, target), then enumerates **every** black legal reply and verifies the white piece wins the target uncapturable on every line (incl. king recapture). O(squares × legalMoves × 2 plies); concentric mode pre-runs it 64 more times. |
| `services/knight_engine.dart` | 51 | `knightMoves`, `isKnightMove`, `shortestPath` (BFS; returns hop count, −1 if unreachable). The "max 6" is an emergent fact, not a coded cap. |
| `services/pawn_attack_engine.dart` | 142 | `pawnThreats` (black pawns attack the two downward diagonals); `validMoves` (knight + ray-cast sliders; pawns block rays / can be captured; threatened empty squares are unsafe landings but don't stop a ray); `generatePawns(count, …, darkSquaresOnly)` places pawns on ranks 2–7 (never threatening the piece's a1 start). |
| `models/chess_vision_state.dart` | 300 | Single state for all 4 drills (most fields null per drill). `VisionMode {practice, speed, concentric}`, `WhitePiece` (queen/rook/bishop/knight), `TargetPiece` (rook/bishop/knight/queen — note the different order). `boardFen` and `allHighlights` branch per drill. Constants: black king `d5`, top-level `concentricPath` (64-square spiral from d4). |
| `providers/chess_vision_provider.dart` | 628 | `chessVisionProvider`. Routes taps to four handlers; **coerces mode** (knight drills → practice, pawn → speed/practice); 4 timers incl. a stopwatch for pawn-timed & concentric; forks keep ~25% of empty-solution positions to exercise the **None** button; knight-flight offers retry/skip on non-optimal arrival; pawn difficulty climbs **3→8**. Best metric flips: lowest-time for pawn-speed & concentric, highest-count otherwise. |
| `screens/chess_vision_game_screen.dart` | ~900 | Single screen branching every region per drill: found-dots, flight counter, pawn counter, ghost-piece `PieceShape`s, arrows, bespoke results cards. **Reuses** shared widgets + `MilestoneBanner`. `_buildBoard` picks the board per drill: **Knight Flight & Pawn Attack use the interactive `Chessboard` + `GameData` *plus* `onTouchedSquare`** — a 3-way input hybrid (1-tap-to-destination, tap-to-select, drag), `validMoves` from `KnightEngine.knightMoves` / `PawnAttackEngine.validMoves`; handlers no-op on a tap of the piece's own square so the duplicate callback can't double-count. Knight Flight's target is an **amber goal ring** (`Circle`), not a ghost knight. Forks & Knight Sight stay on `Chessboard.fixed` + `onTouchedSquare`. |
| `screens/chess_vision_menu_screen.dart` | 411 | Drill chips (2 rows); forks shows piece + target + 3 mode cards; pawn shows piece + practice/timed; knight drills hide all options. |
| `widgets/found_progress_indicator.dart` | 96 | "Found N of M" dots; shared by forks & knight-sight. |

There is currently **no Explanations.md narrative for this feature** despite it being the densest — see [000 Explanations.md](000%20Explanations.md#chess-vision) for the section added during the audit.

### Opening Fundamentals — `lib/features/opening_trainer/`

Play opening moves against Stockfish with a live eval bar and progressive hint arrows. **The only engine-backed gameplay in the app.**

> ⚠️ **Routing & UI reality (important).** The live route `/opening-trainer` hard-codes `OpeningGameScreen(mode: practice, difficulty: easy, playerColor: white)` — it takes **no query params**. `OpeningMenuScreen`, and the `LivesDisplay` / `MedalProgress` / `PrincipleCard` / game-over-medal widgets, are **built but not wired into the live screen.** Challenge mode, color/difficulty selection, lives, and medals are therefore unreachable today. See [Known Gaps](#known-gaps--cleanup).

| File | ~LoC | Purpose & key logic |
|---|---|---|
| `providers/opening_game_provider.dart` | ~870 | **Key file.** `openingGameProvider`. Sole consumer of `stockfishServiceProvider` + `openingBookServiceProvider` for live play. `handlePlayerMove` evaluates via Stockfish, computes the centipawn drop, and (challenge) deducts a life when drop > `mistakeThresholdCp`. `_engineMove` plays `getBestMove(movetime, skillLevel)`. **Progressive hints:** `_requestHints` runs multi-wave `getTopMoves` at fixed **depths `[8,12,16,18]`** (deterministic; live depth streamed to `engineDepth`) — **practice requests 5 / 4 waves, challenge 3 / 1**; book moves show instantly (`hasEval:false`) and up to 2 popular book moves are merged in beside the engine's list. **Eval cache:** `_evalCached` memoizes `evaluate()` by `fen#depth` (only full-depth results). `evaluateSpecificMoves` (selected-piece analysis) runs **progressive passes at depths [8,12,18]** — every move (and the root, at the same depth per pass, so deltas stay comparable) gets a quick number first, then each badge refines in place via `onResult`; cancellable via `cancelPieceEvals()` (generation token). Also: `startFromOpening(pgn)`, `pauseHints`/`resumeHints` (deselecting a piece resumes), `undoMove`, review. **Engine lifecycle:** disposes the engine only when **truly idle** (`_stopEngine` checks `_pieceEvalSessions` + `stockfish.isBusy` — disposing under a live op strands completers and triggers 'Multiple instances' re-init storms), `stopSearch()` on user moves; `_hintFen` is the search-cancellation token; the depth readout is always cleared when a hint pass exits. |
| `models/opening_game_state.dart` | ~300 | `OpeningDifficulty(skillLevel, **moveTimeMs**, mistakeThresholdCp, lives)` — easy(3,200,150,3), medium(10,350,100,2), hard(18,500,50,1). *(Move-time = CPU opponent only; analysis is depth-based.)* `OpeningMode {practice, challenge}`; `MedalLevel` via `medalForMoves` (bronze ≥3, silver ≥6, gold ≥10). **`MoveClassification`**: `best` = engine's #1 (by rank), `book` = theory membership; the rest via `classifyDelta` on **loss vs. the best move** (good ≥ −0.4, inaccuracy ≥ −1.0, mistake ≥ −2.0, else blunder — deliberately forgiving). `SuggestedMove` carries absolute white-perspective `centipawns` (what badges display) + `evalDelta` (colors only) + `isBook`/`isBest`/`hasEval`; `MoveEval` is the per-move analysis result; `formatEval` renders "+0.3"/"M3". State has `engineDepth`/`engineTargetDepth` for the live depth readout. Practice runs with 99 lives (effectively unlimited). |
| `models/opening_principles.dart` | 14 | `openingPrinciples` — 12 beginner tips. **Currently unused** (no `PrincipleCard` is shown). |
| `screens/opening_game_screen.dart` | 679 | `Chessboard` + `GameData`, `EvalBar` + `ThinkingIndicator`, `MoveHistoryPanel` + undo, review controls. AppBar: **opening picker**, flip board, toggle score labels. Hosts a tap-a-piece **per-move analysis overlay** (classifies every legal destination). **No** lives/medal HUD, **no** game-over overlay, **no** principle card are rendered. |
| `screens/opening_menu_screen.dart` | 332 | Color + difficulty + Practice/Challenge cards → would push `/opening-trainer/game?...`. **Not wired into the router.** |
| `widgets/eval_bar.dart` | 86 | White/dark bar, sigmoid `1/(1+e^(-cp/400))`, mate label. |
| `widgets/eval_delta_overlay.dart` | ~180 | Move badges rendered **on each arrow's shaft** (past-midpoint, with collision nudging so converging moves like Qf3/Nf3 both stay visible). Badges show the **absolute post-move eval** (white's perspective, matching the eval bar); a 👑 marks the engine's #1 move. Exports the shared `colorForClassification`/`classificationStyle` palette + `shadeForDelta` (arrows darken with loss vs. best). |
| `widgets/opening_picker.dart` | 211 | **Was undocumented.** Searchable opening browser (popular list + ECO A–E from `OpeningBookService`); returns a PGN; launched from the AppBar. |
| `widgets/thinking_indicator.dart` | ~110 | Animated brain + live **"d12/18" depth readout** of the current search (replaced the wave dots). |
| `widgets/move_history_panel.dart` | 170 | Horizontal SAN list, auto-scroll, tappable in review. |
| `widgets/lives_display.dart` | 84 | Heart row. **Built, not wired into the screen.** |
| `widgets/medal_progress.dart` | 100 | Bronze/silver/gold circles (3/6/10). **Built, not wired.** |
| `widgets/principle_card.dart` | 90 | "Opening Tip" overlay. **Built, not constructed anywhere.** |

### Standalone screens

| File | ~LoC | Status |
|---|---|---|
| `features/home/screens/home_screen.dart` | 289 | **Nav hub.** Hero icon + BradBunR title (72pt) + 4 cards: The Pieces (blue → `/the-pieces`), Chess Notation (green → `/file-rank-trainer`), Chess Vision (purple → `/chess-vision`), Opening Fundamentals (orange → `/opening-trainer`). Info button → `/about`. No card for the move or tactics trainers. |
| `features/about/screens/about_screen.dart` | 342 | About page: logo, **hardcoded version "1.0.0"**, sections (incl. Credits: Lichess, ElevenLabs, Flutter), a Michael de la Maza tribute, and an **in-app feedback form** (posts via `feedbackServiceProvider`). |
| `features/tactics_trainer/screens/tactics_trainer_screen.dart` | 17 | Placeholder ("coming soon"). Routed at `/tactics-trainer` but **no in-app navigation reaches it.** |
| `features/square_trainer/screens/square_trainer_screen.dart` | 17 | **DEAD CODE.** Placeholder; not routed/imported. Square training is delivered by the file-rank trainer's `squares` subject. Delete candidate. |

---

## Core layer — `lib/core/`

| File | Purpose & key surface |
|---|---|
| `audio/audio_service.dart` | `audioServiceProvider`. Two `AudioPlayer`s (voice + sfx) + `flutter_tts` fallback + haptics. `speakFile/Rank/Square/Piece`; **`speakMove(piece, file, rank, {isCapture, isCheck, isCheckmate})`** chains piece→(takes)→file→rank→(check/checkmate) clips; `playCorrect/Incorrect/NewRecord`; **`playGameOver()` is haptic-only (no sound)**; `speak(text)` for dynamic phrases (castling). **Owns all haptics.** Playback errors are swallowed (string-built asset paths fail silently). |
| `services/puzzle_service.dart` | `puzzleServiceProvider`; `ParsedPuzzle` + `getRandomPuzzle({exclude, sideToMove})`. Loads `assets/puzzles/moves_puzzles.json`. |
| `services/stockfish_service.dart` | `stockfishServiceProvider`; `EvalResult` (incl. reported `depth`)/`ScoredMove`; `evaluate` / `getBestMove(skillLevel)` / `getTopMoves(count, onDepth)`. **Ops are serialized** (one search at a time; `isBusy`) so listeners never parse another search's output; `dispose()` **refuses to quit a busy engine** (aborts the search instead — prevents stranded completers + 'Multiple instances' re-init storms). `getTopMoves` returns **one consistent depth iteration** and streams depth via `onDepth`; `go depth D movetime M` combines as a runaway ceiling. All scores normalized to **white's perspective**. Engine state is a **process-wide `static` singleton**. Top-level `stockfishCleanupForRestart()` must be called in `main()` for hot-restart. |
| `services/opening_book_service.dart` | `openingBookServiceProvider`; `OpeningInfo`/`BookContinuation`; `getOpeningForPosition` / `isBookMove(Position, move)` / `getBookContinuations(Position, legalSans)` / `getAllOpenings`. **Position-based & transposition-aware:** `load()` replays all ~3640 ECO lines (`assets/data/eco_openings.json`) via `parseSan` and indexes every position (pieces+side+castling; ep field deliberately dropped), so e.g. 1.e4 c6 2.Nc3 d5 3.d4 is book via the 2.d4 move order. Continuations are ranked by how many dataset lines pass through the resulting position (main lines ≫ exotic sidelines). |
| `services/analytics_service.dart` | `analyticsServiceProvider`; **10** typed loggers — `log{FileRank,Move,Vision,Opening,Pieces}Drill{Started,Completed}`. `*Completed` computes accuracy; some params stringified. |
| `services/feedback_service.dart` | **Was undocumented.** `feedbackServiceProvider`; `sendFeedback(message)` HTTP-GETs `https://secure.passports.com/funcs/etc/cct.cfc?method=feedback`. **Used only by the About screen.** ⚠️ Name collides with `audio_service` but is unrelated (it is *not* haptics/audio). |
| `board_utils.dart` | `highlightFile/highlightRank/highlightSquare(index, color)` → `IMap<Square, SquareHighlight>` — the bridge from our 0-based indices to chessground's per-square map. |
| `theme/app_theme.dart` | `AppColors` (correctGreen `0xFF4CAF50`, incorrectRed `0xFFE53935`, highlightYellow, primary `0xFF1B5E20`, …) + `AppTheme.light` (Material 3, Inter). **No dark theme.** |
| `constants.dart` | `ChessConstants` (file/rank names, `squareName`, `allSquares`) + `TimerConstants`. ⚠️ `TimerConstants` appears **orphaned** — the live 30s speed timers are hardcoded in the providers, not read from here. |
| `widgets/square_name_overlay.dart` | `SquareNameOverlay` + `SquareLabel` — paints square-name labels over the board (wrapped in `IgnorePointer`); shared by the file-rank and move trainers. |

---

## Localization

**10 locales**, generated (not hand-written): **de, en, es, fr, it, ja, ko, pt, ru, zh**.

- Source of truth: `lib/l10n/app_*.arb` (template `app_en.arb`).
- Generated by `flutter gen-l10n` (config in `l10n.yaml`; `flutter: generate: true` in pubspec). Output `lib/l10n/app_localizations*.dart` **is committed**.
- Wired in `app.dart` via `AppLocalizations.localizationsDelegates` + `supportedLocales`. No `locale:` override (follows the device). Screens read strings through `AppLocalizations.of(context)`.
- After editing any `.arb`, run `flutter gen-l10n` (or just build).

---

## Routes — `lib/app.dart`

12 flat `GoRoute`s, `initialLocation: '/'`. The `name` column feeds the `FirebaseAnalyticsObserver` (screen-view names). Forward nav uses `context.push()`, back uses `context.pop()`.

| Path | Screen | name | Query params |
|---|---|---|---|
| `/` | HomeScreen | `home` | — |
| `/file-rank-trainer` | FileRankMenuScreen | `file_rank_menu` | `subject`, `mode`, `hardMode` (optional) |
| `/file-rank-trainer/game` | FileRankGameScreen | `file_rank_game` | `subject` (def `files`), `mode` (def `explore`), `hardMode` |
| `/move-trainer` | MoveMenuScreen | `move_menu` | `mode`, `hardMode` (optional) |
| `/move-trainer/game` | MoveGameScreen | `move_game` | `mode` (def `practice`), `hardMode` |
| `/chess-vision` | ChessVisionMenuScreen | `chess_vision_menu` | `drill`, `piece`, `target`, `mode` (optional) |
| `/chess-vision/game` | ChessVisionGameScreen | `chess_vision_game` | `drill`, `piece`, `target`, `mode` (with defaults) |
| `/opening-trainer` | **OpeningGameScreen** | `opening_trainer` | **none** — hard-coded practice / easy / white |
| `/the-pieces` | PiecesMenuScreen | `pieces_menu` | `mode` (optional) |
| `/the-pieces/which-side-wins` | WhichSideWinsScreen | `which_side_wins` | `mode` (def `practice`) |
| `/tactics-trainer` | TacticsTrainerScreen | `tactics_trainer` | — (placeholder, unreachable from UI) |
| `/about` | AboutScreen | `about` | — |

There is **no `/opening-trainer/game` route** and **no menu route** for the opening trainer.

---

## Assets, data & tooling

| Path | Contents |
|---|---|
| `assets/images/` | `app_icon.png` (2048²), `internut_logo*.png`, home card art (`card_notation/vision/openings.png`) |
| `assets/fonts/BradBunR.ttf` | Display font for titles/labels |
| `assets/sounds/` | ElevenLabs voice clips: `file_*.mp3` (a–h), `rank_*.mp3` (1–8), `piece_*.mp3` (6), `move_takes/check/checkmate.mp3`, `new_record.mp3`; SFX `correct.m4a`/`incorrect.m4a`. ⚠️ `streak_*.mp3` exist but are **never played** (milestones are visual + haptic only). |
| `assets/puzzles/moves_puzzles.json` | ~500 curated Lichess puzzles (CC0) → move trainer |
| `assets/data/eco_openings.json` | ~3640 ECO openings (Lichess) → `OpeningBookService` |
| `scripts/curate_puzzles.py` | Filters the Lichess puzzle CSV → `moves_puzzles.json` |

**Build tooling:** `flutter_native_splash` (white Internut logo on `#1B5E20`; config in `pubspec.yaml`), `flutter_launcher_icons` (from `app_icon.png`, `min_sdk_android: 21`, iOS alpha removed), `flutterfire configure` (regenerates `firebase_options.dart`).

---

## Known Gaps & Cleanup

Read this before trusting a feature is "done." All verified against code on 2026-06-05.

**Built but not wired (decide: finish or remove):**
- **Opening trainer challenge UI.** `OpeningMenuScreen`, `LivesDisplay`, `MedalProgress`, `PrincipleCard`, and any game-over/medal overlay exist as widgets but are not in the live route or screen. Challenge mode, color/difficulty pick, lives, and medals are unreachable. The state/provider logic for lives/medals exists; only the wiring is missing.
- **Milestone audio.** `assets/sounds/streak_*.mp3` ship but no code plays them; `AudioService` has no milestone method. Either add one and call it from `milestone_banner.dart`, or drop the assets.

**Dead code (delete candidates):**
- `features/file_rank_trainer/screens/file_rank_screen.dart` (unused barrel)
- `features/move_trainer/screens/move_trainer_screen.dart` (unused stub)
- `features/square_trainer/screens/square_trainer_screen.dart` (unused; superseded by the `squares` subject)

**Placeholder / unreachable:**
- `/tactics-trainer` is routed but no in-app navigation links to it.

**Empty scaffolding:**
- `lib/features/auth/{screens,providers}/` (empty — for future Firebase Auth)
- `lib/models/` (empty — for future shared models)
- `lib/services/` (empty top-level — distinct from the populated `lib/core/services/`)

**Latent risks to keep in mind:**
- Personal bests are **in-memory only** and **speed-mode only** across every trainer — no persistence.
- `TimerConstants` in `constants.dart` is not the source of the live 30s timers (hardcoded in providers).
- `AudioService` swallows playback errors and builds asset paths from strings — renamed/missing clips fail silently.
- The about screen's version string is hardcoded `"1.0.0"`, independent of `pubspec` (`1.3.0+4`).

## Where to start (roadmap pointers)

- **Add a new trainer** → copy a feature folder; follow the Notifier pattern above; reuse the shared widget kit under `file_rank_trainer/widgets/`; register a route + `name` in `app.dart`; add a home card in `home_screen.dart`.
- **Persist progress / add leaderboards** → bests are the in-memory `Map<String,int>` on each notifier; Firestore + `lib/features/auth/` are already scaffolded.
- **Finish the opening trainer** → wire `OpeningMenuScreen` to a real route (+ `/opening-trainer/game`), and mount `LivesDisplay`/`MedalProgress`/`PrincipleCard` into `opening_game_screen.dart`.
- **Touch the engines** → start in `chess_vision/services/` (fork_skewer is the hot path) and `core/services/stockfish_service.dart` (one shared native engine).
- **Build the tactics trainer** → flesh out the placeholder and link a home card.

---

## Quick reference

> Consolidated lookup of the facts most often needed *exactly* right (so an agent doesn't have to grep or guess). Verified 2026-06-05 — the code is the source of truth for precise values.

### Providers (all of them)

| Provider | Kind | File | Role |
|---|---|---|---|
| `audioServiceProvider` | Provider | `core/audio/audio_service.dart` | voice clips, SFX, haptics, TTS |
| `analyticsServiceProvider` | Provider | `core/services/analytics_service.dart` | 10 typed Firebase drill events |
| `puzzleServiceProvider` | Provider | `core/services/puzzle_service.dart` | move-trainer puzzles (`ParsedPuzzle`) |
| `stockfishServiceProvider` | Provider | `core/services/stockfish_service.dart` | engine (opening trainer only) |
| `openingBookServiceProvider` | Provider | `core/services/opening_book_service.dart` | ECO names / book continuations |
| `feedbackServiceProvider` | Provider | `core/services/feedback_service.dart` | HTTP user feedback (About screen) |
| `fileRankGameProvider` | NotifierProvider | `features/file_rank_trainer/providers/` | files/ranks/squares drill logic |
| `moveGameProvider` | NotifierProvider | `features/move_trainer/providers/` | move-from-notation logic |
| `chessVisionProvider` | NotifierProvider | `features/chess_vision/providers/` | all 4 vision drills |
| `openingGameProvider` | NotifierProvider | `features/opening_trainer/providers/` | engine gameplay |
| `whichSideWinsProvider` | NotifierProvider | `features/pieces/providers/` | piece-value drill |

### Enums (exact values — order matters where used as `.values`)

| Enum | Values | Defined in |
|---|---|---|
| `TrainerSubject` | `files, ranks, squares, moves` | `file_rank_game_state.dart` |
| `TrainerMode` | `explore, practice, speed` | `file_rank_game_state.dart` |
| `MoveTrainerMode` | `practice, speed` | `move_game_state.dart` |
| `VisionDrillType` | `forksAndSkewers, knightSight, knightFlight, pawnAttack` | `chess_vision_state.dart` |
| `VisionMode` | `practice, speed, concentric` | `chess_vision_state.dart` |
| `WhitePiece` | `queen, rook, bishop, knight` | `chess_vision_state.dart` |
| `TargetPiece` | `rook, bishop, knight, queen` _(note: different order from WhitePiece)_ | `chess_vision_state.dart` |
| `OpeningDifficulty` | `easy, medium, hard` (carry `skillLevel`, `moveTimeMs`, `mistakeThresholdCp`, `lives`) | `opening_game_state.dart` |
| `OpeningMode` | `practice, challenge` | `opening_game_state.dart` |
| `MedalLevel` | `none, bronze, silver, gold` (thresholds 3/6/10 user moves) | `opening_game_state.dart` |
| `MoveClassification` | `brilliant, best, good, book, inaccuracy, mistake, blunder` | `opening_game_state.dart` |
| `PieceType` | `pawn(1), knight(3), bishop(3), rook(5), queen(9)` — no king | `which_side_wins_state.dart` |
| `WhichSideWinsMode` | `practice, speed` | `which_side_wins_state.dart` |

### Feedback delays & timers

Correct / incorrect feedback delay (ms) and the speed-round duration. **All hardcoded in each `*_provider.dart`** — `constants.dart`'s `TimerConstants` is not the live source.

| Trainer | Practice (correct/incorrect) | Speed (correct/incorrect) | Speed timer |
|---|---|---|---|
| file / rank | 400 / 1200 | 200 / 600 | 30s |
| squares | **700** / 1200 | 200 / 600 | 30s |
| move | **700** / 1200 | 200 / 600 | 30s |
| pieces | 600 / 1400 | 300 / 800 | 30s |
| chess vision | drill-specific (forks reveal 1500, pawn round-end 800) | — | 60s (speed); stopwatch for pawn-timed & concentric |

File/rank **explore** mode advances after 800ms. Personal bests update at game-over in **speed mode only**, in-memory.

### Asset & data paths

- **Voice:** `assets/sounds/{file_a..h, rank_1..8, piece_*, move_takes, move_check, move_checkmate, new_record}.mp3` · **SFX:** `correct.m4a`, `incorrect.m4a` · ⚠️ `streak_*.mp3` exist but are unplayed
- **Data:** `assets/puzzles/moves_puzzles.json` (move trainer) · `assets/data/eco_openings.json` (opening book)
- **Strings:** `lib/l10n/app_*.arb` (10 locales; `app_en.arb` is the template) → `flutter gen-l10n`

---

## Glossary

App-specific vocabulary that maps user language to code. Standard chess terms (FEN, SAN, fork, skewer, file, rank) keep their usual meanings.

| Term | In this codebase |
|---|---|
| **Trainer / feature** | One of the five top-level modes under `lib/features/`. |
| **Subject** | The file-rank trainer's drill type: `files`, `ranks`, `squares`, `moves`. Picking **Moves** hands off to the move trainer. |
| **Mode** | `explore` (free play, no score), `practice` (streaks, no timer/end → no bests logged), `speed` (30s round, logs bests). Vision adds `concentric`; opening uses `practice`/`challenge`. |
| **Hard mode** | ⚠️ Polysemous: file-rank = flip board to Black's view; move trainer = control Black (puzzles filtered to black-to-move) **and** flip. Other trainers have no hard mode. |
| **Drill** | A Chess Vision exercise: forks & skewers, knight sight, knight flight, or pawn attack. |
| **Concentric** | A forks-&-skewers mode that walks the target through a fixed 64-square spiral (`concentricPath`). |
| **Vision** | The Chess Vision feature — board-visualization drills, not gameplay. |
| **The Pieces** | The piece-value feature ("which side wins?"), route `/the-pieces`. |
| **Chess Notation** | Home-screen label for the file-rank + move trainers, route `/file-rank-trainer`. |
| **Streak / milestone** | Consecutive correct answers; a milestone fires every multiple of 5 (banner + haptic, **no audio**). |
| **Personal best** | Highest speed-mode score; in-memory per trainer, **not persisted**. |
| **Shared widget kit** | `StreakCounter` / `TimerBar` / `ResultsCard` / `MilestoneBanner` under `file_rank_trainer/widgets/`, reused app-wide. |
| **Engine** | Stockfish (FFI) for the opening trainer; or the pure-Dart "engines" in `chess_vision/services/` and `pieces/services/`. |

---

## Keeping these docs in sync

Verified against code on **2026-06-05**. These docs describe the **map and patterns**, deliberately avoiding line numbers — exact values live in code. **When you change code, update the doc in the same change** (CLAUDE.md says this too). To re-verify a feature, read its `*_state.dart` + `*_provider.dart` + `*_screen.dart` and reconcile this file. The most drift-prone spots, historically: feedback-delay constants, route wiring, and "built but not wired" UI.

## Project info

| | |
|---|---|
| Organization | Internut Education |
| Website | https://internut.education |
| Contact | dave@internut.education |
| Bundle ID | ⚠️ mismatched: iOS `education.internut.chesstrainer`, Android `education.internut.calvinchesstrainer` — reconcile before release (see Explanations → iOS Signing) |
| Repository | https://github.com/daveinternut/calvinchesstrainer |
| Firebase project | `calvin-chess-trainer` |
| License | GPL-3.0 (required by chessground/dartchess) |
