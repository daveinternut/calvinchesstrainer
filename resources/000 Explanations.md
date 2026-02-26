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

**Interactive board** (move trainer): `Chessboard` with a `GameData` object provides drag-and-drop piece movement, legal move destination dots, promotion UI, check highlighting, last-move highlighting, and piece animation — all built in. Used by the move trainer for puzzle-based move execution.

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
    enableCoordinates: !isHardMode,
    colorScheme: ChessboardColorScheme.green,
    pieceAssets: PieceSet.cburnett.assets,
    animationDuration: Duration(milliseconds: 250),
    showValidMoves: true,               // destination dots
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

The `FileRankGameState.allHighlights` getter merges feedback highlights (correct/incorrect) and reverse-mode highlights (yellow target) into a single `IMap` for the board.

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

**API methods**:
- `speakFile(String file)` — plays file letter clip + haptic
- `speakRank(String rank)` — plays rank number clip + haptic
- `speakSquare(String file, String rank)` — plays file then rank with await sequencing
- `speakPiece(String pieceName)` — plays piece name clip (pawn/rook/bishop/knight/queen/king) + haptic
- `speakMove(String pieceName, String file, String rank)` — chains piece → file → rank clips with await sequencing. Example: "Queen b6" = piece_queen.mp3 → file_b.mp3 → rank_6.mp3
- `playCorrect()` / `playIncorrect()` — SFX + haptic
- `playStreakMilestone(int streak)` — milestone clip at 5/10/15/20
- `playNewRecord()` — "New record!" clip
- `speak(String text)` — flutter_tts fallback for dynamic text (used for castling prompts: "castle kingside")

**Adding new audio**: Place MP3/M4A files in `assets/sounds/`, add a method to AudioService. No pubspec changes needed (the directory is already declared).

**Regenerating voice clips**: Record a new script in ElevenLabs with 2+ seconds of silence between phrases. Split with:
```bash
ffmpeg -i "voice full.mp3" -af silencedetect=noise=-25dB:d=0.3 -f null - 2>&1 | grep silence
```
Then extract segments with `ffmpeg -ss START -to END`.

## File & Rank Trainer

### Game Modes

**Explore**: Free tap, no scoring. Tap any file/rank → hear its name, see it highlight green. No correct/incorrect concept. Purpose: build familiarity.

**Practice**: App prompts a random file/rank via audio + text. User taps the board (forward mode) or picks from A-H / 1-8 buttons (reverse mode). Streak-based scoring — tracks consecutive correct answers. Milestones at 5/10/15/20 with celebration audio. No timer, no end condition.

**Speed Round**: Same as Practice but with a 30-second countdown. Shorter feedback delays (200ms correct, 600ms incorrect vs 400ms/1200ms in practice). Results card overlay at game end showing total correct, accuracy %, best streak, and new record badge if applicable.

### Reverse Mode

Inverts the interaction direction:
- **Forward** (default): Audio says a letter/number → user taps the board
- **Reverse**: Board highlights a random file/rank in yellow → user picks the name from answer buttons below the board

Only available in Practice and Speed modes (not Explore).

### State Machine

`FileRankGameState` is immutable with a `copyWith` pattern. Key fields:
- `currentPrompt` / `currentTargetIndex` / `currentPromptIsFile` — the active question
- `streak` / `bestStreak` — consecutive correct answers
- `lastFeedback` — AnswerFeedback with result, tapped index, correct index, isFile. Used to compute board highlights.
- `isWaitingForNext` — true during the feedback delay before the next prompt. Blocks input.
- `isGameOver` — true when speed timer hits 0. Shows results overlay.
- `timeRemainingSeconds` — countdown for speed mode only.

Board highlights are computed by the `allHighlights` getter on the state object (not stored separately). It merges feedback highlights (correct green / incorrect red for the tapped and correct file/rank/square) with reverse-mode highlights (yellow for the target). The getter uses `highlightFile()`, `highlightRank()`, and `highlightSquare()` from `board_utils.dart` to convert our 0-based indices into chessground's `IMap<Square, SquareHighlight>` format.

### Provider Logic

`FileRankGameNotifier` manages:
- **Prompt generation**: Random file (0-7) or rank (0-7), avoids repeating same one twice. For "both" subject, randomly alternates between file and rank.
- **Answer evaluation**: Compares tapped index to target. Updates streak, plays audio, schedules auto-advance via `Timer`.
- **Timer**: `Timer.periodic` for speed mode countdown. Separate `Timer` for feedback-to-next-prompt delay.
- **Personal bests**: In-memory `Map<String, int>` keyed by `"{subject}_{mode}_{isReverse}"`. Checked at game over for speed mode.

## iOS Signing & Deployment

**Current state**: Signed under "DAVID GATES MARKLE (Personal Team)" via `dave@internut.education` Apple ID. Bundle ID temporarily set to `education.internut.calvinchesstrainer.dev` due to a conflict with a free personal team that accidentally registered the original ID. Revert to `education.internut.calvinchesstrainer` once the conflict expires or paid enrollment is fully active.

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

**Runtime parsing** (PuzzleService):
1. Loads JSON from assets
2. Parses each FEN via `Chess.fromSetup(Setup.parseFen(fen))`
3. Plays setup move (`moves[0]`) to reach puzzle position
4. Computes SAN via `position.makeSan(answerMove)` (e.g., "Qb6")
5. Extracts piece type from `position.board.pieceAt(move.from)`
6. Returns `ParsedPuzzle` with position, expected move, SAN, piece name, side to move

### Game Modes

**Practice**: Unlimited puzzles, no timer. Correct = 400ms delay, incorrect = 1200ms delay (shows green arrow to correct destination). Streak tracking with milestones.

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

## Planned Features (Not Yet Built)

- **Tactics Trainer**: Show positions with forks/pins/skewers, user identifies them. Will use Lichess puzzle database (same CC0 source as move trainer, different filtering). Interactive board via `Chessboard` + `GameData`.
- **Firebase**: Auth + Firestore for user profiles, progress persistence, leaderboards. Packages installed but not configured. Needs `flutterfire configure` with the Internut Education Firebase project.

## Project Info

| | |
|---|---|
| Organization | Internut Education |
| Website | https://internut.education |
| Contact | dave@internut.education |
| Bundle ID | education.internut.calvinchesstrainer (.dev suffix temporary) |
| Repository | https://github.com/daveinternut/calvinchesstrainer |
| Apple Team | DAVID GATES MARKLE (Personal Team) / U2V42G33C3 |
