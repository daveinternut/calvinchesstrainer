# Calvin Chess Trainer - Detailed Explanations

Back to [000 Index.md](000%20Index.md) for the quick reference.

## App Architecture

The app follows a **feature-based folder structure** with Riverpod for state management and GoRouter for navigation.

**Pattern**: Each feature is a self-contained folder with `screens/`, `widgets/`, `providers/`, and `models/` subdirectories. Screens are thin — they read state from providers and dispatch events. All business logic lives in Riverpod Notifiers.

**State management**: We use `Notifier<T>` from `flutter_riverpod` (not the deprecated StateNotifier or StateProvider). Each feature's notifier is provided via `NotifierProvider`. The audio service is a plain `Provider` since it's a singleton service.

**Routing**: GoRouter with flat routes (not nested/shell routes). The file-rank trainer passes game configuration via query parameters. Each training mode will follow the same pattern: menu screen → game screen with params.

## Plugin-First Architecture

**Core principle**: Always use lichess plugin methods instead of writing custom chess code. The `chessground` and `dartchess` packages cover board rendering, piece display, move validation, FEN/PGN parsing, game state detection, and more. We should never manually calculate legal moves, render piece images, determine square colors, draw coordinate labels, or implement drag-and-drop — the plugins handle all of this.

**What we build ourselves**: Game flow logic (prompts, scoring, timers, streaks), audio feedback, navigation, state management wiring, and the thin bridge layer in `board_utils.dart` that converts our trainer's file/rank highlight concepts into chessground's per-square format.

**When adding new features**, check [000 lichess documentation.md](000%20lichess%20documentation.md) first. For example:
- Need a playable board? Use `Chessboard` + `GameData`, not a custom gesture system.
- Need to validate a move? Use `position.isLegal(move)`, not manual rule checks.
- Need to show legal destinations? Pass `makeLegalMoves(position)` as `validMoves` in `GameData` — the dots render automatically.
- Need to load a puzzle position? Use `Chess.fromSetup(Setup.parseFen(fen))`.
- Need SAN notation like "Nf3"? Use `position.parseSan("Nf3")` and `position.makeSan(move)` (returns `(Position, String)`).

**GPL-3.0 note**: Both chessground and dartchess are GPL-3.0 licensed. Our app must also be GPL-3.0 if distributed.

## Chess Board (chessground)

We use lichess's `chessground` package for all board rendering. No custom board widget — the plugin handles everything.

**Static board** (file/rank/square trainers): `Chessboard.fixed` renders a non-interactive board from a FEN string. We pass `onTouchedSquare` for tap handling and `squareHighlights` for file/rank/square coloring.

**Interactive board** (move trainer, opening trainer, and the Chess Vision *Knight Flight* + *Pawn Attack* drills): `Chessboard` with a `GameData` object provides drag-and-drop piece movement, legal move destination dots, promotion UI, check highlighting, last-move highlighting, and piece animation — all built in. The two vision drills additionally keep `onTouchedSquare` for 1-tap-to-destination (see the Chess Vision → Board interaction section).

### How We Wire It

```dart
Chessboard.fixed(
  size: boardSize,                            // from LayoutBuilder
  orientation: Side.white,
  fen: kInitialBoardFEN,                      // dartchess constant
  settings: ChessboardSettings(
    enableCoordinates: !isHardMode,           // toggles a-h / 1-8 labels
    colorScheme: ChessboardColorScheme.green,
    pieceAssets: PieceSet.cburnett.assets,     // 28 sets available
    animationDuration: Duration(milliseconds: 200),
  ),
  squareHighlights: gameState.allHighlights,  // IMap<Square, SquareHighlight>
  onTouchedSquare: (square) {
    handleBoardTap(square.file, square.rank);  // File/Rank are ints 0-7
  },
)
```

### How We Wire the Interactive Board (Move Trainer)

```dart
Chessboard(
  size: boardSize,
  orientation: orientation,             // Side.white or Side.black based on puzzle
  fen: displayFen,                      // puzzle position FEN (or updated after correct move)
  lastMove: setupMove,                  // highlight opponent's last move
  settings: ChessboardSettings(
    enableCoordinates: false,           // coordinates ALWAYS hidden (not tied to hard mode)
    colorScheme: ChessboardColorScheme.green,
    pieceAssets: PieceSet.cburnett.assets,
    animationDuration: Duration(milliseconds: 250),
    showValidMoves: true,               // destination dots
    showLastMove: true,                 // highlight the from/to of the last move
    autoQueenPromotion: true,           // skip promotion dialog
  ),
  game: GameData(
    playerSide: PlayerSide.white,       // or .black based on puzzle
    sideToMove: sideToMove,
    validMoves: makeLegalMoves(position),
    isCheck: position.isCheck,
    promotionMove: null,
    onMove: (move, {viaDragAndDrop}) { /* evaluate move */ },
    onPromotionSelection: (_) {},
  ),
  shapes: feedbackShapes,               // green arrow on incorrect answer
  squareHighlights: squareHighlights,   // green from/to on correct answer
)
```

**Move evaluation**: On correct move, the FEN updates to the new position (piece stays at destination). On incorrect move, the FEN is NOT updated, so the piece snaps back to its origin automatically. A green arrow shape shows the correct move for feedback.

### Highlight System

chessground highlights individual squares via `squareHighlights: IMap<Square, SquareHighlight>`. To highlight entire files or ranks (which chessground doesn't natively support), we use helper functions in `lib/core/board_utils.dart`:

- `highlightFile(fileIndex, color)` → generates 8 square entries for the column
- `highlightRank(rankIndex, color)` → generates 8 square entries for the row
- `highlightSquare(fileIndex, rankIndex, color)` → generates 1 square entry

The `FileRankGameState.allHighlights` getter produces the feedback highlights (green for the correct file/rank/square, red for a wrong tap) as a single `IMap` for the board.

### Available Piece Sets

28 sets bundled in chessground: cburnett, merida, pirouetti, chessnut, chess7, alpha, reillycraig, companion, riohacha, kosal, leipzig, fantasy, spatial, celtic, california, caliente, pixel, firi, rhosgfx, maestro, fresca, cardinal, gioco, tatiana, staunty, governor, dubrovny, icpieces.

### Available Board Themes

25+ themes: brown, blue, blue2, blue3, blueMarble, canvas, green, greenPlastic, grey, horsey, ic, leather, maple, maple2, marble, metal, newspaper, olive, pinkPyramid, purple, purpleDiag, wood, wood2, wood3, wood4.

### Key Difference from Custom Board

chessground renders coordinates inside the edge squares (lichess-style), not as separate labels outside the grid. The board requires an explicit `size` in logical pixels — we compute this via `LayoutBuilder` using `min(constraints.maxWidth, constraints.maxHeight)`.

## Audio System

`lib/core/audio/audio_service.dart`

**Design**: Two separate `AudioPlayer` instances — `_voicePlayer` for speech clips and `_sfxPlayer` for sound effects. This allows a ding to play simultaneously with a letter without cutting each other off.

**Voice clips**: Pre-recorded via ElevenLabs, stored as MP3 in `assets/sounds/`. Named `file_{letter}.mp3` and `rank_{number}.mp3`. Generated by recording a full script and splitting with ffmpeg silence detection.

**Sound effects**: macOS system sounds (Glass.aiff → correct.m4a, Basso.aiff → incorrect.m4a) converted to M4A via afconvert.

**API methods** (all fire a haptic unless noted):
- `speakFile(String file)` — plays file letter clip
- `speakRank(String rank)` — plays rank number clip
- `speakSquare(String file, String rank)` — plays file then rank with await sequencing
- `speakPiece(String pieceName)` — plays piece name clip (pawn/rook/bishop/knight/queen/king)
- `speakMove(String pieceName, String file, String rank, {bool isCapture = false, bool isCheck = false, bool isCheckmate = false})` — chains piece → (optional `move_takes.mp3`) → file → rank → (optional `move_checkmate.mp3` / `move_check.mp3`). Example: "Queen takes b6 check" = piece_queen → move_takes → file_b → rank_6 → move_check.
- `playCorrect()` / `playIncorrect()` — SFX (`correct.m4a` / `incorrect.m4a`)
- `playNewRecord()` — "New record!" clip
- `playGameOver()` — **haptic only, plays no sound** (called at every game-over). Despite the name, there is no game-over audio clip.
- `speak(String text)` — flutter_tts fallback for dynamic text (no haptic; used for castling prompts: "castle kingside")

`AudioService` owns all haptics in the app. It builds asset paths from strings (`file_$file.mp3`, etc.) and **swallows playback errors** (logs to `dev.log`) — a missing or renamed clip fails silently, with no compile-time check.

**Milestone audio is currently unwired.** The four `streak_*.mp3` clips ship in `assets/sounds/` but no code plays them — `AudioService` has no milestone method, and `MilestoneBanner` fires only a haptic. Streak milestones are visual + haptic only. To add sound, give `AudioService` a `playStreak/playMilestone` method and call it from `milestone_banner.dart` (or delete the unused assets).

**Adding new audio**: Place MP3/M4A files in `assets/sounds/`, add a method to AudioService. No pubspec changes needed (the directory is already declared).

**Regenerating voice clips**: Record a new script in ElevenLabs with 2+ seconds of silence between phrases. Split with:
```bash
ffmpeg -i "voice full.mp3" -af silencedetect=noise=-25dB:d=0.3 -f null - 2>&1 | grep silence
```
Then extract segments with `ffmpeg -ss START -to END`.

## File & Rank Trainer

The menu covers six **subjects** — `files`, `ranks`, `squares`, `letters`, `moves`, `pieceValue` — selected as chips. Only files/ranks/squares run in this feature; the other three chips route away and are **never handled by `FileRankGameNotifier`**: `letters` → `/letter-trainer/game`, `moves` → `/move-trainer/game`, `pieceValue` → `/the-pieces/which-side-wins`. There is **no "reverse" mode, no answer buttons, and no "both" subject** — all input is by tapping the board.

### Why Piece Value lives here

Piece value ("Which Side Wins?") used to be its own home-screen card, **The Pieces**, with its own menu screen. It was a single drill sitting next to features that each hold four or more, so it was pulled in here as a subject chip and the home screen was re-ranked around Chess Vision. The `lib/features/pieces/` folder is untouched — only its entry point moved. `PiecesMenuScreen` and the `/the-pieces` route were deleted, since the notation menu's mode cards now do that job.

Piece Value is a **quiz-only** subject, like `moves`: `_subjectHasExplore()` hides Explore mode (there is nothing to tap around and discover), and it also hides the Hard Mode toggle, because Which Side Wins has no hard variant. Its `TrainerMode` is mapped down to `WhichSideWinsMode` on the way out — `speed` → `speed`, anything else → `practice`. Selecting the chip also swaps the Practice blurb for the piece-value one and shows a "Which Side Wins?" banner, so the handoff to a differently-shaped drill isn't a surprise.

### Game Modes

**Explore**: Free tap, no scoring. Tap any file/rank/square → hear its name, see it highlight green. No correct/incorrect concept. Purpose: build familiarity. Explore never advances prompts or sets `isWaitingForNext`; a tap just speaks and clears after 800ms.

**Practice**: App prompts a random file/rank/square via audio + text; the user taps the board. Streak-based scoring tracks consecutive correct answers, with a milestone celebration (visual banner + haptic) at every multiple of 5. No timer, no end condition — so practice **never logs a completion event and never updates a personal best**.

**Speed Round**: Same as Practice but with a 30-second countdown (hardcoded in the provider). Results card overlay at game end showing total correct, accuracy %, best streak, and a new-record badge if applicable.

**Feedback delays** (correct / incorrect, in ms):

| Subject | Practice | Speed |
|---|---|---|
| files, ranks | 400 / 1200 | 200 / 600 |
| squares | **700** / 1200 | 200 / 600 |

The squares practice-correct delay is longer (700ms) so the `SquareNameOverlay` label has time to be read. Explore always uses 800ms.

### State Machine

`FileRankGameState` is immutable with a `copyWith` pattern (nullable fields use the `T? Function()?` thunk idiom — pass `() => null` to clear). Key fields:
- `currentPrompt` / `currentTargetIndex` / `currentTargetRankIndex` / `currentPromptIsFile` — the active question (the rank index is used for squares)
- `streak` / `bestStreak` — consecutive correct answers
- `lastFeedback` — `AnswerFeedback` (result, tapped/correct file index, isFile, and tapped/correct rank index for squares). Used to compute board highlights.
- `isWaitingForNext` — true during the feedback delay before the next prompt. Blocks input (`handleBoardTap` early-returns).
- `isGameOver` — true when the speed timer hits 0. Shows the results overlay.
- `timeRemainingSeconds` — countdown for speed mode only.

Board highlights are computed by the `allHighlights` getter on the state object (not stored separately). It branches squares-vs-files/ranks and colors the correct target green and (on a wrong answer) the tapped target red — all at alpha 0.6 — via `highlightFile()` / `highlightRank()` / `highlightSquare()` from `board_utils.dart`, which convert our 0-based indices into chessground's `IMap<Square, SquareHighlight>`. There is no yellow-target highlight.

### Provider Logic

`FileRankGameNotifier` manages:
- **Prompt generation**: Random file/rank/square, avoids immediate repeats (squares require both file *and* rank to differ from the previous prompt).
- **Answer evaluation**: Compares the tapped square to the target. Updates streak, plays audio, schedules auto-advance via a feedback `Timer`.
- **Timer**: `Timer.periodic(1s)` for the speed countdown; a separate one-shot `Timer` for the feedback-to-next-prompt delay. Both are cancelled on `startGame`, game-over, and dispose.
- **Personal bests**: In-memory `Map<String, int>` keyed by `"{subject}_{mode}_{isHardMode}"` — e.g. `"squares_speed_true"`. Updated only at game-over (speed mode). Not persisted: bests reset on app restart.

## iOS Signing & Deployment

**Current state**: Signed under "DAVID GATES MARKLE (Personal Team)" via `dave@internut.education` Apple ID. As of the 2026-06-05 audit the bundle IDs in the project files are **iOS `education.internut.chesstrainer`** (`ios/Runner.xcodeproj/project.pbxproj`) and **Android `education.internut.calvinchesstrainer`** (`android/app/build.gradle`). ⚠️ Note these two **do not match** (the iOS ID dropped both the `.dev` suffix and the "calvin" prefix). Reconcile them before store submission — pick one canonical ID across platforms (and update `flutterfire configure` / Firebase app registrations to match).

**Building for device**:
```bash
flutter build ios --release
flutter install -d <device-id>
```
Or use Xcode: open `ios/Runner.xcworkspace`, select device, Product > Run.

**iOS deployment target**: 15.0 (set in both Podfile and project.pbxproj, required by cloud_firestore).

## Move Trainer

### Overview

The final step in the board notation learning progression: Files → Ranks → Squares → **Moves**. Users see real chess positions from the Lichess puzzle database and must execute a specific move described in notation (e.g., "Queen b6"). This teaches translating notation into board actions — not puzzle solving.

### Puzzle Data Pipeline

**Source**: Lichess puzzle database (CC0 license, 5.7M puzzles). Available at `https://database.lichess.org/lichess_db_puzzle.csv.zst`.

**CSV format**: `PuzzleId,FEN,Moves,Rating,RatingDeviation,Popularity,NbPlays,Themes,GameUrl,OpeningTags`

The `Moves` field is space-separated UCI: `moves[0]` is the opponent's setup move (played to reach the puzzle position), `moves[1]` is the first solution move (the answer the user must execute).

**Curation script** (`scripts/curate_puzzles.py`):
- Downloads and filters the Lichess CSV
- Filters: rating 600-1500, NbPlays > 500, no promotions, balanced across piece types
- Outputs ~500 puzzles as compact JSON to `assets/puzzles/moves_puzzles.json`
- Re-run to refresh the puzzle set: `python3 scripts/curate_puzzles.py lichess_db_puzzle.csv`

A second script, `scripts/curate_scanning_positions.py`, mines the **same CSV** for the Chess Vision scanning drills (see [Chess Vision → The scanning drills](#the-scanning-drills--curated-real-positions)). Unlike `curate_puzzles.py` it is **seeded and deterministic**, uses real python-chess move generation, and self-validates every entry before writing.

**Runtime parsing** (PuzzleService):
1. Loads JSON from assets
2. Parses each FEN via `Chess.fromSetup(Setup.parseFen(fen))`
3. Plays setup move (`moves[0]`) to reach puzzle position
4. Computes SAN via `position.makeSan(answerMove)` (e.g., "Qb6")
5. Extracts piece type from `position.board.pieceAt(move.from)`
6. Returns `ParsedPuzzle` with position, expected move, SAN, piece name, side to move

### Game Modes

**Practice**: Unlimited puzzles, no timer. Correct = 700ms delay, incorrect = 1200ms delay (shows green arrow to correct destination). Streak tracking with milestones. Like the file/rank trainer, practice never logs completion or updates a personal best (no end condition).

**Speed Round**: 30-second countdown. Correct = 200ms delay, incorrect = 600ms delay. Results card with score, accuracy, best streak, new record badge. Personal best tracking (keyed by mode+hardMode).

No explore mode. No reverse mode (doesn't apply to moves).

### Interactive Board

This is the first feature using chessground's interactive `Chessboard` with `GameData`. Key differences from the static `Chessboard.fixed` used by file/rank/square trainers:
- Pieces can be dragged and dropped (or tap-to-select, tap-to-place)
- Legal move destination dots shown automatically via `validMoves`
- Last-move highlighting via `lastMove` parameter
- Board orientation set based on puzzle's side to move
- Arrow shapes for feedback via `shapes` parameter

**Move evaluation flow**:
- User makes any legal move via drag-and-drop or tap
- If `move.from == expected.from && move.to == expected.to` → correct
- Correct: update FEN to new position (piece stays), green square highlights, advance
- Incorrect: DON'T update FEN (piece snaps back automatically), green arrow shows correct move, advance

### State Machine

`MoveGameState` follows the same immutable `copyWith` pattern as `FileRankGameState`. Key fields:
- `currentPuzzle` — ParsedPuzzle with position, expected move, SAN, piece info
- `displayFen` — current board FEN (updates on correct move)
- `sideToMove` — determines board orientation and which pieces are interactive
- `lastSetupMove` — opponent's last move, highlighted on board
- `feedbackShapes` getter — returns green arrow ISet<Shape> for incorrect feedback
- `squareHighlights` getter — returns green from/to highlights for correct feedback
- Standard scoring fields: streak, bestStreak, totalCorrect, totalAttempts, timeRemainingSeconds, isGameOver, isWaitingForNext

## Chess Vision

The most algorithm-heavy feature. **Eight drills run through one state class, one notifier, and one screen**, each branching on `VisionDrillType { forksAndSkewers, knightSight, knightFlight, pawnAttack, findChecks, findCaptures, hangingPieces, mateInOne }` (the last four are the *scanning drills*; the enum exposes `isScanDrill`/`isTapScanDrill` helpers). `ChessVisionState` carries every drill's fields (most are null/empty for any given drill), and `boardFen`, `allHighlights`, tap-routing, and config-generation each `switch` on the drill type. Adding a ninth drill means touching every switch — there is no per-drill polymorphism.

### The eight drills

- **Forks & Skewers**: a black king (fixed on **d5**) and a target piece sit on the board; tap every square where placing the chosen white piece wins the target by fork or skewer. A **None** button handles positions with no solution. Modes: practice / speed / concentric.
- **Knight Sight**: tap all squares a lone knight attacks. Configs alternate between central and edge knight squares.
- **Knight Flight**: move a knight to a target square in the fewest hops. Arriving on a non-optimal path offers **retry / skip**.
- **Pawn Attack**: navigate a piece to capture all black pawns without landing on a pawn-attacked square. Difficulty climbs **3 → 8** pawns. Modes: practice (endless cycle) / timed.
- **Find Checks** *(scanning)*: real position; tap every square where the side to move can deliver check. Found squares show a faded ghost of the checking piece and play the "Check!" voice clip.
- **Find Captures** *(scanning)*: tap every enemy piece that can be legally captured (pins already respected — an "attacked" piece guarded by a pin is not capturable).
- **Hanging Pieces** *(scanning)*: tap every **undefended** enemy piece (N/B/R/Q with zero defenders — whether you can capture it right now is deliberately irrelevant; the skill is spotting *loose* pieces, LPDO). Curation guarantees no undefended enemy *pawn* exists in these positions, so a kid tapping a genuinely loose pawn can never be marked wrong.
- **Mate in 1** *(scanning)*: interactive board; play any legal move that checkmates — judged **by result**, so alternate mates (and queen-promotion mates) count. Wrong tries snap back and reveal the solution with a green arrow. Speed mode is labeled **Blitz**.

### Board interaction

Two drills move a single piece — **Knight Flight** and **Pawn Attack** — and both use the interactive `Chessboard` + `GameData` wired for **three input styles at once**:

- **1-tap** — tap a destination square directly (via `onTouchedSquare`), including the very first move. The original drill feel and the fastest input.
- **tap-to-select, then tap a destination**, and
- **drag-and-drop** — both via `GameData` with a `validMoves` map (`KnightEngine.knightMoves` for the knight; `PawnAttackEngine.validMoves` for the pawn-attack piece).

Because both `onTouchedSquare` and `GameData` react to a tap, a select/drag move can call the move handler twice (once via `onMove`, once via `onTouchedSquare`). The handlers absorb this: **tapping the piece's own square is a no-op** — knight flight's `_handleKnightFlightTap` early-returns on `square == currentPos`, and pawn attack's `_handlePawnAttackTap` already early-returns on `square == from` — and after a move the piece *is* on that square, so the duplicate callback no-ops. Wrong-square taps still register as errors (that's the drill). Knight Flight shows legal-hop dots (`showValidMoves: true`); Pawn Attack hides them so the player still has to judge which squares are safe (threats are already shown in red), which also makes drag effectively *guided* — chessground won't let you drop on a threatened square (you can only err by tapping).

Forks & Skewers and Knight Sight mark arbitrary squares (no piece to move), so they keep the non-interactive `Chessboard.fixed` + `onTouchedSquare`. `_buildBoard` in `chess_vision_game_screen.dart` picks the board per drill; every input path funnels through the same `handleBoardTap(square)` entry point.

The Knight Flight destination is drawn as an **amber goal ring** (a chessground `Circle`, `scale: 1.0` — the max; the constructor asserts `0 < scale <= 1.0`) plus a soft `AppColors.goalAmber` landing-pad tint — deliberately *not* a knight, so the board only ever shows the single knight the player controls (it used to render a translucent ghost knight there, which players mistook for a second movable piece).

### The four engines (`services/`)

These are the high-value, high-risk files — pure functions, no Riverpod.

- **`fork_skewer_engine.dart`** — the crown jewel. `computeValidSquares(...)` brute-forces all 64 candidate squares. For each, it parks the white king in a safe corner, builds a 4-piece position in dartchess (white piece, white king, black king on d5, target), then enumerates **every** black legal reply and confirms the white piece captures the target uncapturable on every line (including a king recapture). It genuinely simulates and validates all escape lines — so it is correct but expensive: O(squares × legalMoves × 2 plies). Concentric mode pre-runs it 64 more times to filter the spiral path. Start here for any perf work (e.g. memoize per piece/target).
- **`knight_engine.dart`** — `knightMoves`, `isKnightMove`, and `shortestPath` (plain BFS; returns hop count, −1 if unreachable). The "max 6 hops" is an emergent fact about an 8×8 board, not a coded cap.
- **`pawn_attack_engine.dart`** — `pawnThreats` (black pawns attack their two *downward* diagonals), `validMoves` (knight L-moves + ray-cast sliders; a pawn blocks a ray but can be captured; a threatened empty square is an unsafe landing but does not stop the ray), and `generatePawns` (places pawns on ranks 2–7, dark-squares-only for the bishop, never threatening the piece's **a1** start).
- **`scan_engine.dart`** — ground truth for the scanning drills, straight dartchess: `checkTargets`/`checkTargetDetails`, `captureTargets`, `hangingTargets`, `matingMoves`/`isMatingMove`. See the next section for the contract that keeps it honest.

### The scanning drills — curated real positions

The scanning drills are built on one principle: **the engine is the truth, curation is the taste.** Positions ship as bare FENs (`assets/puzzles/scan_{checks,captures,hanging}.json`, `{fen, n}`) mined from the Lichess puzzle DB by `scripts/curate_scanning_positions.py`; at runtime `ScanEngine` recomputes the target squares from the FEN, so there is no stored answer key that can go stale. The script *selects* positions using **byte-equivalent python-chess predicates** — the same fixtures are asserted in `test/scan_engine_test.dart` and the script's `--self-test`, and the script re-validates every selected entry before writing (plus the provider debug-asserts engine targets == curated `n`). If the two implementations ever drift, something fails loudly.

What curation guarantees (so runtime can stay simple):
- **Real positions**: post-setup Lichess puzzle positions ("opponent just moved"), quality-gated (NbPlays ≥ 500, popularity ≥ 50, rating 600–1500, ≤ 24 pieces), never in check for the tap drills, 50/50 white/black to move, deduped against each other **and** the move-trainer set.
- **Unambiguous taps**: no two checking moves from different origins share a destination square (also what makes the per-square ghost piece well-defined); no en-passant in the captures set (the ep victim's square is never a move's destination — untappable); positions where *castling* gives check are rejected outright, because python-chess and dartchess encode castling differently, so `ScanEngine` skips castling and stays exactly in sync.
- **The honest-pawn rule**: hanging = **undefended** (zero defenders — capturability not required), and targets are pieces only (N/B/R/Q), so the curation additionally rejects any position containing an undefended enemy pawn — a kid who taps a genuinely loose pawn must never be told "wrong". Every shipped hanging position also contains a *defended* enemy piece as a distractor: the "defended ≠ loose" discrimination is the drill's whole point.
- **Determinism**: seeded RNG; same CSV + seed ⇒ byte-identical assets. Regeneration: download `lichess_db_puzzle.csv.zst` (see the script docstring), `pip install 'chess>=1.10,<2'`, run the script (~2 min), done.

Mate in 1 reuses the existing puzzle plumbing instead: `mate_in_one_puzzles.json` is byte-compatible with `moves_puzzles.json` (`{fen, moves}` — Lichess `mateIn1` theme, python-verified mates, rating 600–1200), loaded by a second `PuzzleService` instance (`mateInOnePuzzleServiceProvider` — the asset path is a constructor param). The drill judges **by result** (`ScanEngine.isMatingMove`: normalize → legal? → `playUnchecked(...).isCheckmate`), so the 17 puzzles with multiple mates accept any of them, and a queen-promotion mate delivered via `autoQueenPromotion` counts.

UI-wise the tap drills are the forks find-all machinery on real boards (green found-squares, 400 ms red flash on a miss, "All Clear!" beat, a **Skip** that reveals unfound targets for 1.5 s at the cost of the streak and counts nothing), and Mate in 1 is the move trainer's interactive board (setup-move highlight, snap-back + green solution arrow + square labels on a miss). One deliberate novelty: the board **orients to the side to move** — half the positions train the flipped-board view kids otherwise never practice — and a **side-to-play pill badge** ("White to play" / "Black to play") sits above the prompt on all four drills so the mover is unmistakable the moment a position loads.

### Gotchas

- **Fixed geometry**: black king is always d5, the white king is auto-parked in a corner, and the pawn-attack piece always starts on a1. The fork engine assumes this minimal world; `_isAttackedByPiece` ignores blockers (safe only because the boards are near-empty). Don't move these assumptions.
- **Mode is silently coerced** in `startGame`: knight drills are forced to practice; pawn-attack and the scanning drills are forced to speed/practice (concentric is forks-only). The menu hides the unavailable options, and the provider re-coerces defensively. "Blitz" (Mate in 1) is just `VisionMode.speed` with a different l10n label.
- **`startGame` is async** (scanning assets load lazily); a `_gameGeneration` token discards a load that a quick restart superseded, and the speed countdown starts only after the load.
- **Forks keeps ~25% of empty-solution positions** (`nextDouble() > 0.25`) so the None button gets exercised.
- **Personal-best metric flips**: pawn-attack-speed and concentric rank by *lowest elapsed time*; other speed drills rank by *highest configurations completed*. Bests are in-memory only.

## Opening Trainer

The only feature where you play real moves against an engine. `OpeningGameNotifier` (`opening_game_provider.dart`) is the sole consumer of `StockfishService` and `OpeningBookService` for live play.

> ⚠️ **What is actually wired today.** The live route `/opening-trainer` hard-codes `OpeningGameScreen(mode: practice, difficulty: easy, playerColor: white)` and parses **no** query params. `OpeningMenuScreen` (color/difficulty/mode selection) is **not registered in the router**, and the `LivesDisplay`, `MedalProgress`, and `PrincipleCard` widgets — plus any game-over/medal overlay — are **built but never mounted** in the game screen. So challenge mode, lives, and medals are currently unreachable even though the state/provider logic for them exists. Finishing this feature is mostly a wiring job, not new logic.

### Difficulty tuning

`OpeningDifficulty` carries the engine knobs (note: **move-time**, not search depth):

| Difficulty | skillLevel | moveTimeMs | mistakeThresholdCp | lives |
|---|---|---|---|---|
| easy | 3 | 200 | 150 | 3 |
| medium | 10 | 350 | 100 | 2 |
| hard | 18 | 500 | 50 | 1 |

In challenge mode, a player move whose centipawn drop exceeds `mistakeThresholdCp` costs a life; at 0 lives the game ends. Practice mode runs with 99 lives (effectively unlimited). Medals (`medalForMoves`) are bronze ≥3, silver ≥6, gold ≥10 user moves.

### Hints, eval, and move classification

- **Progressive hint search**: `_requestHints` runs `getTopMoves` in waves at fixed **depths `[8, 12, 16, 18]`** (depth-based searches are deterministic, so scores don't drift between views), refining the arrows as the engine deepens. **Practice requests 5 moves across 4 waves; challenge requests 3 across 1 wave.** The current depth streams into `engineDepth` and renders as a live "d12/18" readout (`thinking_indicator.dart`). `_hintFen` is the cancellation token — every wave bails if the position changed mid-search, and the depth readout is always cleared on exit.
- **Book moves**: shown instantly (before any engine work, `hasEval: false` → 📖 badge), and up to 2 popular book moves are merged in beside the engine's list so main-line theory stays visible even when the engine prefers other tries. Book detection is **position-based and transposition-aware** (see Opening Book below); continuations are ranked by how many ECO lines pass through the resulting position, so main lines outrank exotic sidelines.
- **What the badges show**: the **absolute post-move eval from white's perspective** (same convention as the eval bar), positioned on each arrow's shaft (collision-nudged so converging moves like Qf3/Nf3 both stay visible). The **loss vs. the best move** (`evalDelta`) drives only the *colors* — and a shade: arrows darken the further a move falls behind the best (`shadeForDelta`). The engine's #1 move gets the thick arrow and a 👑.
- **Eval bar** (`eval_bar.dart`): maps centipawns through a sigmoid `1/(1+e^(-cp/400))`.
- **Move classification** (`MoveClassification` in the state): `best` = the engine's #1 move (by rank), `book` = opening-theory membership; the rest via `classifyDelta` on loss vs. best — deliberately forgiving (good ≥ −0.4, inaccuracy ≥ −1.0, mistake ≥ −2.0, else blunder), since being 0.3 behind the engine's top choice is not an error. This grade drives every arrow and overlay color (`colorForClassification` in `eval_delta_overlay.dart`).
- **Lines & variations (practice)**: the move list is a set of `GameLine`s — main line plus variations, shown as rows in depth-first tree order (each variation directly beneath its parent line), every row displaying its complete sequence from move 1 with a shared left gutter so chips align across rows. Navigation is **non-destructive**: tapping any chip or the active row's back/forward buttons moves a cursor (`activeLineIndex`/`cursorPly`) without discarding moves; arrows/eval for revisited positions come from the `_hintsByFen` cache or the next record's `hintsBeforeMove`. Playing a move at the tip extends the active line; mid-line, a differing move branches a new variation underneath (which becomes active); a move that matches an existing continuation just navigates into it (`_findContinuation` — no duplicate lines). Only the active row is highlighted and has nav buttons; each row ends with an eval tag for its final position. **Eval tags are stamped by the analysis itself, keyed by FEN** (`_linesWithEvalForFen`): every completed hint wave writes its eval onto all records for the analyzed position, so a tag can never be misdirected by navigating mid-analysis, and picker-seeded records (which start at 0.0) self-correct the first time their position is analyzed.
- **Per-piece analysis**: tapping a piece classifies all of its legal destinations (backed by `evaluateSpecificMoves`), pausing the hint waves. Evaluation is **progressive**: passes at depths **8 → 12 → 18**, each evaluating every move *and the position itself at the same depth* (so deltas are apples-to-apples) — shallow numbers appear within a second, then each badge refines in place. Two per-square progress signals make this legible: squares awaiting their first number show an **animated bouncing-dots badge**, and (with scores on) each square carries a **depth chip — "d12" plus a rotating spinner while a deeper pass is still coming**, so a score that changes under the user is visibly provisional rather than mysterious. Both are driven by one shared ticker in `_PieceAnalysisOverlay`, which stops once nothing is pending or refining. The chip reports the depth the engine *actually reached* (a movetime cap can land it at d15 rather than d18). Results are memoized in an eval cache (`fen#depth`), so re-selecting a piece replays finished passes instantly. Deselecting cancels the session (`cancelPieceEvals`, generation token) and resumes the hint analysis; moves/undo/picker cancel it too.

### Opening Book (transposition-aware)

`OpeningBookService.load()` replays every line of `assets/data/eco_openings.json` (~3640 named ECO lines) with dartchess `parseSan` and indexes **positions**, not move strings:

- `_bookPositions` — every position reachable along any line; `isBookMove(position, move)` checks whether the move's *resulting position* is in the set. This makes book detection transposition-aware: 1.e4 c6 2.Nc3 d5 **3.d4** is book because the same position arises from the canonical 1.e4 c6 2.d4 d5 3.Nc3 order.
- Position keys are **pieces + side + castling** — the en-passant FEN field is deliberately dropped because transposed move orders produce different phantom ep squares (that's precisely the 3.d4 case).
- `_lineCount` — how many dataset lines pass through each position; `getBookContinuations` sorts by it, so main lines (big subtrees) outrank one-off exotic sidelines (e.g. the "St. Patrick's Attack" 3.h3).
- `getOpeningForPosition` names the position when a dataset line *ends* there (first entry wins); the provider keeps the previous name when leaving book.

### Engine lifecycle (important)

`StockfishService` wraps a single **process-wide native engine** (static state). Key facts about the `stockfish` package that shape this design: `Stockfish.dispose()` only *sends `'quit'`* — the package's static instance is cleared when the native process actually exits, and until then `Stockfish()` throws `'Multiple instances are not supported'` (which `_createWithRetry` handles with backoff).

- **All engine operations are serialized** through an internal queue (`_serialized` in the service; `isBusy` exposes it). UCI has no request ids, so an op's stdout listener would otherwise parse info/bestmove lines from another op's search — this also protects the fen-keyed eval cache from cross-position poisoning.
- **Never dispose a busy engine.** `StockfishService.dispose()` no-ops (just aborts the search) while ops are pending, and the provider's `_stopEngine()` additionally checks a `_pieceEvalSessions` claim. Quitting a live engine strands the pending op's completer (→ unhandled "StockfishService disposed") and forces the next initialize into multi-second 'Multiple instances' retry storms — this was the cause of the 20-30s "…" stalls in per-piece analysis.
- The provider calls `stopSearch()` (not dispose) when the user moves, so the engine is reused immediately; it disposes only when **truly idle** (hint pass finished, per-move evals finished, game over), so a lingering native isolate doesn't block Flutter hot-restart (`stockfishCleanupForRestart()` in `main()` is the companion to this).
- Fixed-depth searches carry a **movetime ceiling** (`go depth D movetime M`, per-wave caps + `_kEvalCapMs`) so a slow device can't run one away.
- `pauseHints()` must be awaited before navigating away (e.g. opening the opening picker), or a stale wave will mutate state.

## Planned / Unfinished Features

- **Tactics Trainer**: Show positions with forks/pins/skewers, user identifies them. Will use the Lichess puzzle database (same CC0 source as the move trainer, different filtering). Interactive board via `Chessboard` + `GameData`. Currently a placeholder screen routed at `/tactics-trainer` with no in-app navigation linking to it.
- **Opening Trainer wiring**: the engine, eval, hints, and line navigation all work, but challenge mode is unreachable — `OpeningMenuScreen` is not routed and the lives/medal/principle UI is not mounted (see the Opening Trainer section above). Finishing it = registering the menu route (+ a `/opening-trainer/game` route) and mounting the existing widgets. (The old review-mode code was removed — non-destructive scrubbing replaced it.)
- **Progress persistence**: every trainer keeps personal bests in an in-memory `Map<String,int>` (speed mode only) — nothing survives an app restart. `cloud_firestore` and `firebase_auth` are already dependencies, and `lib/features/auth/` + `lib/models/` are scaffolded (empty) for this. Firebase itself is configured and **Analytics is live** (screen views + per-drill events); only Auth/Firestore are unused.
- **Milestone audio**: `streak_*.mp3` assets ship but are never played (see the Audio System section).

## Project Info

| | |
|---|---|
| Organization | Internut Education |
| Website | https://internut.education |
| Contact | dave@internut.education |
| Bundle ID | education.internut.calvinchesstrainer (.dev suffix temporary) |
| Repository | https://github.com/daveinternut/calvinchesstrainer |
| Apple Team | DAVID GATES MARKLE (Personal Team) / U2V42G33C3 |
