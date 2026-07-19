# CLAUDE.md

The always-loaded control panel for this repo. Read this in full; it's built to get an agent productive fast. For depth, follow the pointers to `resources/`.

## What this is

**Calvin Chess Trainer** — a Flutter chess-training app for kids. Five trainers: **The Pieces** (piece values), **Chess Notation** (file/rank/square + move-from-notation), **Chess Vision** (forks/skewers, knight sight/flight, pawn attack), **Opening Fundamentals** (play vs Stockfish), and a Tactics placeholder.

Stack: Flutter/Dart · **Riverpod** (`Notifier`) · **GoRouter** · **chessground + dartchess** (lichess, GPL-3.0) · **stockfish** (FFI) · Firebase (Analytics live; Auth/Firestore unused) · just_audio/flutter_tts · gen-l10n (10 locales).

## Documentation (where to go for depth)

| File | Use it for |
|---|---|
| **CLAUDE.md** (this) | Always loaded. Mental model, repo map, task router, conventions, gotchas, commands. |
| **[resources/000 Index.md](resources/000%20Index.md)** | The full code map: system map (data flow + provider→service graph), per-feature file tables with key logic, routes, **Quick reference** (providers/enums/timing), **Glossary**, **Known Gaps**. Read for any non-trivial task. |
| **[resources/000 Explanations.md](resources/000%20Explanations.md)** | Narrative deep dives per subsystem (audio, each trainer, the vision engines, iOS signing). |
| **[resources/000 lichess documentation.md](resources/000%20lichess%20documentation.md)** | chessground/dartchess API reference. |

**Rule: when you change code these docs describe, update the doc in the same change.**

## Mental model

Feature-first. **Each trainer = one immutable `*_state.dart` + one Riverpod `Notifier` (`*_provider.dart`) that owns all game logic + a thin `*_screen.dart`.** The board is a *pure function of provider state* (the state exposes highlight getters — `allHighlights`, `feedbackShapes`, `boardFen`). Cross-cutting code (audio, analytics, engine, puzzles, opening book, board helpers) lives in `lib/core/`. Follow this shape for new work. (Full data-flow: Index → System map.)

## Repo map

```
lib/
  main.dart              boot: stockfish cleanup → Firebase.initializeApp → portrait lock → runApp(ProviderScope)
  app.dart               MaterialApp.router · GoRouter (12 routes, each named) · FirebaseAnalyticsObserver
  firebase_options.dart  generated — DO NOT edit
  core/
    audio/audio_service.dart       voice clips + SFX + haptics + TTS  (owns ALL haptics)
    services/
      puzzle_service.dart          move-trainer puzzles (ParsedPuzzle)
      stockfish_service.dart       FFI/UCI engine, one process-wide native instance
      opening_book_service.dart    ECO opening names + book moves
      analytics_service.dart       10 typed Firebase drill events
      feedback_service.dart        HTTP user-feedback form (NOT audio, despite the name)
    board_utils.dart               file/rank/square index → chessground highlight map
    theme/  constants/  widgets/   AppTheme.light (no dark), constants, SquareNameOverlay
  features/<trainer>/    models/ · providers/ · screens/ · widgets/   (+ services/ for vision & pieces)
    pieces/              "which side wins?"               → /the-pieces
    file_rank_trainer/   files/ranks/squares + Moves chip → /file-rank-trainer   (hosts the shared widget kit)
    move_trainer/        move from notation (puzzles)     → /move-trainer/game    (entered via the Moves chip)
    chess_vision/        4 drills; 3 pure engines         → /chess-vision
    opening_trainer/     play vs Stockfish                → /opening-trainer       (partly wired — see Gotchas)
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
| Touch the engine / eval bar / hint arrows | `core/services/stockfish_service.dart` + `features/opening_trainer/providers/opening_game_provider.dart` |
| Puzzle loading / regenerate puzzle set | `core/services/puzzle_service.dart`, `assets/puzzles/`, `scripts/curate_puzzles.py` |
| Opening names / book moves | `core/services/opening_book_service.dart`, `assets/data/eco_openings.json` |
| Audio clips or haptics | `core/audio/audio_service.dart` |
| Add or translate UI text | `lib/l10n/app_*.arb` → `flutter gen-l10n` |
| Add/change a route or navigation | `lib/app.dart` |
| Analytics events | `core/services/analytics_service.dart` (called from the providers) |
| Theme / colors / fonts | `core/theme/app_theme.dart` |

## Conventions (do these)

- **Notifier pattern** as above — keep screens thin; logic in the notifier.
- **`copyWith` nullable idiom:** nullable fields take a `T? Function()?` thunk — pass `() => null` to *clear*, omit to *keep*. (Used in every `*_state.dart`.)
- **Plugin-first:** never hand-roll chess logic or board rendering — use dartchess (`position.isLegal`, `makeLegalMoves`, SAN, FEN) and chessground (`Chessboard` / `Chessboard.fixed`).
- **Navigation:** forward = `context.push()`, back = `context.pop()`. Every route gets a `name` (feeds Analytics screen views).
- **Shared UI kit:** `StreakCounter` / `TimerBar` / `ResultsCard` / `MilestoneBanner` live under `file_rank_trainer/widgets/` and are reused by other trainers — edits there are cross-cutting.
- **Localize new strings:** add to all `lib/l10n/app_*.arb`, then `flutter gen-l10n`; read via `AppLocalizations.of(context)`.

## Gotchas (know before you trust the code)

- **Personal bests are in-memory and speed-mode only** — nothing persists across restarts (Firestore is available but unused).
- **Opening trainer is partly wired:** `/opening-trainer` hard-codes practice/easy/white; `OpeningMenuScreen` + the `LivesDisplay`/`MedalProgress`/`PrincipleCard` widgets are **built but never mounted**; there is no `/opening-trainer/game` route. Challenge mode, lives, and medals are unreachable.
- **Dead code** (ignore / deletion candidates): `file_rank_trainer/screens/file_rank_screen.dart`, `move_trainer/screens/move_trainer_screen.dart`, `square_trainer/screens/square_trainer_screen.dart`. Square training is the `squares` *subject* in the file-rank trainer.
- **`feedback_service.dart` is HTTP feedback, not audio/haptics** — name collides with `audio_service.dart`. Haptics live in `AudioService`, which also **swallows playback errors** and builds asset paths from strings (renames fail silently).
- **Milestone audio is unwired** (`streak_*.mp3` ship but never play).
- **No dark theme;** OS font-scaling is disabled (`TextScaler.noScaling`).
- **iOS/Android bundle IDs currently mismatch** (Index → Project info; Explanations → iOS Signing).

## Commands & verifying a change

```bash
flutter pub get
flutter run                  # device / emulator / Chrome — the main way to verify (test coverage is thin)
flutter analyze              # lint/type check before declaring done
flutter test                 # unit/widget tests under test/
flutter gen-l10n             # after editing lib/l10n/*.arb (also runs on build)
flutter build ios --release  # iOS 15.0 min target
```

To verify a gameplay change, `flutter run` and exercise the affected screen (see the Task router for which feature). Prefer this over assuming — the board's behavior is state-driven and easy to eyeball.

## Do NOT hand-edit (generated)

- `lib/firebase_options.dart` → regenerate via `flutterfire configure`
- `lib/l10n/app_localizations*.dart` → regenerate via `flutter gen-l10n`
