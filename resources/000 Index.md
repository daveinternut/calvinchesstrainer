# Calvin Chess Trainer - Code Map

A Flutter chess training app for kids. Teaches board fundamentals (files, ranks, squares, moves) through interactive drills with audio feedback, streaks, and timed challenges. Built with Riverpod for state, GoRouter for navigation, just_audio for pre-recorded clips, and lichess's chessground/dartchess packages for all board UI and chess logic.

For detailed explanations of each topic, see [000 Explanations.md](000%20Explanations.md).

## Plugin-First Principle

**Always prefer plugin methods over custom code.** The lichess packages (`chessground` + `dartchess`) handle board rendering, piece display, move validation, FEN/PGN, and game state. We should never reimplement functionality that these packages already provide. See [000 lichess documentation.md](000%20lichess%20documentation.md) for the full API reference.

### Key Methods to Remember

**Board rendering** (chessground):
- `Chessboard.fixed(size, orientation, fen, settings, squareHighlights, onTouchedSquare)` — static board with tap handling (file/rank/square trainers)
- `Chessboard(size, orientation, fen, settings, game, lastMove, shapes)` — interactive board with drag-and-drop, move validation UI (move trainer)
- `ChessboardSettings(colorScheme, pieceAssets, enableCoordinates, animationDuration, blindfoldMode, ...)` — visual/behavior config
- `GameData(playerSide, sideToMove, validMoves, isCheck, promotionMove, onMove, onPromotionSelection)` — game state for interactive boards
- `ChessboardEditor(size, orientation, pieces, onDroppedPiece, onEditedSquare)` — position editor
- `readFen(fen)` / `writeFen(pieces)` — convert between FEN strings and piece maps

**Chess logic** (dartchess):
- `Chess.initial` / `Chess.fromSetup(Setup.parseFen(fen))` — create positions
- `position.legalMoves` / `makeLegalMoves(position)` — legal move generation
- `position.isLegal(move)` / `position.play(move)` — move validation and execution
- `position.parseSan("Nf3")` / `position.makeSan(move)` — SAN notation conversion (returns `(Position, String)` tuple)
- `position.isCheck` / `position.isCheckmate` / `position.isGameOver` — game state queries
- `position.fen` — export position as FEN string
- `PgnGame.parsePgn(pgn)` — parse PGN game records
- `Square.fromName("e4")` / `Square.fromCoords(File(4), Rank(3))` — square construction
- `NormalMove(from: Square.e2, to: Square.e4)` — move construction

**Our highlight helpers** (board_utils.dart):
- `highlightFile(fileIndex, color)` — highlight entire column (8 squares)
- `highlightRank(rankIndex, color)` — highlight entire row (8 squares)
- `highlightSquare(fileIndex, rankIndex, color)` — highlight single square

## Tech Stack

| Layer | Choice |
|---|---|
| Framework | Flutter / Dart |
| State | Riverpod (Notifier pattern) |
| Routing | GoRouter (declarative, query params) |
| Audio | just_audio (pre-recorded clips), flutter_tts (fallback) |
| Chess board UI | chessground (lichess) — board widget, 28 piece sets, 25+ themes, drag-and-drop, animations |
| Chess logic | dartchess (lichess) — legal moves, FEN/PGN, SAN notation, game state, variants |
| Backend | Firebase (Auth, Firestore) — not yet configured |

## Architecture

Feature-based folder structure. Each feature has `screens/`, `widgets/`, `providers/`, `models/`. Core services live in `lib/core/`. App entry point is `main.dart` → `app.dart` (router + theme).

## File Map

### Entry & Routing
| File | Purpose |
|---|---|
| `lib/main.dart` | Entry point, wraps app in ProviderScope |
| `lib/app.dart` | MaterialApp.router, GoRouter routes, theme |

### Core Services
| File | Purpose |
|---|---|
| `lib/core/audio/audio_service.dart` | AudioService — plays pre-recorded MP3/M4A clips for letters, numbers, piece names, SFX, milestones. Uses two AudioPlayers (voice + sfx). `speakSquare()` chains file+rank clips; `speakMove()` chains piece+file+rank clips. Riverpod provider. |
| `lib/core/services/puzzle_service.dart` | PuzzleService + ParsedPuzzle — loads `assets/puzzles/moves_puzzles.json`, parses FEN with dartchess, computes SAN notation and piece info. Serves random puzzles for the move trainer. Riverpod provider. |
| `lib/core/board_utils.dart` | Highlight helpers — `highlightFile()`, `highlightRank()`, `highlightSquare()` convert our 0-based file/rank indices into chessground's `IMap<Square, SquareHighlight>` format |
| `lib/core/theme/app_theme.dart` | AppColors, AppTheme — Material 3 theme, feedback colors (correctGreen, incorrectRed, highlightYellow) |
| `lib/core/constants.dart` | ChessConstants — file/rank name arrays, squareName helper, timer durations |

### Chess Notation Trainer (main feature)
| File | Purpose |
|---|---|
| `lib/features/file_rank_trainer/models/file_rank_game_state.dart` | TrainerSubject (`files`/`ranks`/`squares`/`moves`), TrainerMode, AnswerFeedback + FileRankGameState immutable state class. Single `allHighlights` getter returns merged `IMap<Square, SquareHighlight>` for chessground, using `board_utils.dart` helpers. |
| `lib/features/file_rank_trainer/providers/file_rank_game_provider.dart` | FileRankGameNotifier — all game logic: prompt generation (including square prompts with file+rank targets), answer evaluation, streak tracking, countdown timer, personal best tracking (keyed by subject+mode+reverse+hardMode) |
| `lib/features/file_rank_trainer/screens/file_rank_menu_screen.dart` | Mode selection: subject chips in two rows (Files, Ranks, Squares, Moves). Moves chip navigates to `/move-trainer`. Mode cards (explore/practice/speed), toggle cards for Reverse Mode and Hard Mode. Accepts initial values via query params for state preservation on back-navigation. |
| `lib/features/file_rank_trainer/screens/file_rank_game_screen.dart` | Gameplay screen: `Chessboard.fixed` from chessground + prompt + streak + timer + answer buttons, results overlay. Uses `onTouchedSquare` for tap handling, `squareHighlights` for file/rank/square feedback, `enableCoordinates` for hard mode. |
| `lib/features/file_rank_trainer/widgets/streak_counter.dart` | Animated streak display with pulse + milestone glow at 5/10/15/20 |
| `lib/features/file_rank_trainer/widgets/prompt_display.dart` | Shows contextual prompt text per subject and mode (e.g. "Tap file", "Tap square") |
| `lib/features/file_rank_trainer/widgets/timer_bar.dart` | 30s countdown bar, green→yellow→red, pulse in last 5s |
| `lib/features/file_rank_trainer/widgets/results_card.dart` | End-of-round overlay: score, accuracy, best streak, new record badge |
| `lib/features/file_rank_trainer/widgets/answer_buttons.dart` | A-H / 1-8 button row for reverse mode |

### Move Trainer (interactive board — puzzle-based)
| File | Purpose |
|---|---|
| `lib/features/move_trainer/models/move_game_state.dart` | MoveTrainerMode (`practice`/`speed`), MoveFeedback, MoveGameState immutable state. `feedbackShapes` getter returns arrow shapes for incorrect answer feedback. `squareHighlights` getter returns green highlights for correct moves. |
| `lib/features/move_trainer/providers/move_game_provider.dart` | MoveGameNotifier — loads puzzles via PuzzleService, evaluates user moves against expected answer, manages scoring/streaks/timer. Correct moves update the board FEN; incorrect moves leave FEN unchanged (piece snaps back) and show a green arrow to the correct destination. |
| `lib/features/move_trainer/screens/move_menu_screen.dart` | Mode selection: Practice and Speed Round cards, Hard Mode toggle, Start button. |
| `lib/features/move_trainer/screens/move_game_screen.dart` | First interactive board in the app: `Chessboard` + `GameData` with drag-and-drop piece movement, legal move dots, last-move highlighting. Board oriented based on puzzle's side to move. Reuses StreakCounter, TimerBar, ResultsCard from file_rank_trainer. |
| `lib/features/move_trainer/widgets/move_prompt_display.dart` | Shows SAN notation prominently (e.g., "Qb6") with friendly subtitle (e.g., "Queen to b6"). |

### Other Features
| File | Purpose |
|---|---|
| `lib/features/home/screens/home_screen.dart` | Main menu with 2 training mode cards (Chess Notation, Tactics) |
| `lib/features/tactics_trainer/screens/tactics_trainer_screen.dart` | Placeholder |

### Assets
| Path | Contents |
|---|---|
| `assets/sounds/file_*.mp3` | 8 ElevenLabs voice clips for file letters A-H (trimmed to ~0.3-0.5s) |
| `assets/sounds/rank_*.mp3` | 8 ElevenLabs voice clips for rank numbers 1-8 (trimmed to ~0.3-0.5s) |
| `assets/sounds/piece_*.mp3` | 6 voice clips for piece names: pawn, rook, bishop, knight, queen, king (trimmed to ~0.3-0.56s) |
| `assets/sounds/move_takes.mp3` | Voice clip for "takes" (~0.7s) |
| `assets/sounds/move_check.mp3` | Voice clip for "check" (~0.24s) |
| `assets/sounds/move_checkmate.mp3` | Voice clip for "checkmate" (~0.18s) |
| `assets/sounds/streak_*.mp3` | 4 milestone celebration clips |
| `assets/sounds/new_record.mp3` | "New record!" voice clip |
| `assets/sounds/correct.m4a` | macOS Glass system sound (ding) |
| `assets/sounds/incorrect.m4a` | macOS Basso system sound (thud) |
| `assets/puzzles/moves_puzzles.json` | 500 curated Lichess puzzles (CC0 license) for the move trainer. Each entry has `fen` and `moves` (UCI). Generated by `scripts/curate_puzzles.py`. |

### Build Tools
| Path | Purpose |
|---|---|
| `scripts/curate_puzzles.py` | Filters the Lichess puzzle CSV (5.7M puzzles) into a compact JSON subset for the move trainer. Filters by rating 600-1500, NbPlays > 500, no promotions, balanced across piece types. Input: `lichess_db_puzzle.csv`. Output: `assets/puzzles/moves_puzzles.json`. |

### Empty Directories (ready for use)
- `lib/features/auth/` — for Firebase Auth screens/providers
- `lib/models/` — for shared data models (user profile, game result)

## Routes

| Path | Screen | Params |
|---|---|---|
| `/` | HomeScreen | — |
| `/file-rank-trainer` | FileRankMenuScreen | `?subject=...&mode=...&reverse=...&hardMode=...` (optional, for state preservation) |
| `/file-rank-trainer/game` | FileRankGameScreen | `?subject=files\|ranks\|squares&mode=explore\|practice\|speed&reverse=true\|false&hardMode=true\|false` |
| `/move-trainer` | MoveMenuScreen | `?mode=practice\|speed&hardMode=true\|false` (optional, for state preservation) |
| `/move-trainer/game` | MoveGameScreen | `?mode=practice\|speed&hardMode=true\|false` |
| `/tactics-trainer` | TacticsTrainerScreen | — |
