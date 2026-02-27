# Calvin Chess Trainer - Code Map

A Flutter chess training app for kids. Teaches board fundamentals (files, ranks, squares, moves) and chess vision (forks/skewers, knight movement, piece navigation) through interactive drills with audio feedback, streaks, and timed challenges. Built with Riverpod for state, GoRouter for navigation, just_audio for pre-recorded clips, and lichess's chessground/dartchess packages for all board UI and chess logic.

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
| Routing | GoRouter (declarative, push/pop navigation) |
| Audio | just_audio (pre-recorded clips), flutter_tts (fallback) |
| Chess board UI | chessground (lichess) — board widget, 28 piece sets, 25+ themes, drag-and-drop, animations |
| Chess logic | dartchess (lichess) — legal moves, FEN/PGN, SAN notation, game state, variants |
| Splash screen | flutter_native_splash — Internut Education logo (white) on dark green (#1B5E20) |
| App icons | flutter_launcher_icons — generated for iOS (21 sizes) and Android (5 mipmap densities) from 2048x2048 source |
| Custom font | BradBunR (assets/fonts/BradBunR.ttf) — playful font used for app title and card labels |
| Backend | Firebase (Auth, Firestore) — not yet configured |

## Architecture

Feature-based folder structure. Each feature has `screens/`, `widgets/`, `providers/`, `models/`. Core services live in `lib/core/`. App entry point is `main.dart` → `app.dart` (router + theme).

## File Map

### Entry & Routing
| File | Purpose |
|---|---|
| `lib/main.dart` | Entry point, wraps app in ProviderScope. Portrait-only orientation lock via `SystemChrome.setPreferredOrientations`. Splash screen preserve/remove lifecycle via `flutter_native_splash`. |
| `lib/app.dart` | MaterialApp.router, GoRouter routes, theme. All forward navigation uses `context.push()`, all back navigation uses `context.pop()` for proper slide animations. |

### Core Services
| File | Purpose |
|---|---|
| `lib/core/audio/audio_service.dart` | AudioService — plays pre-recorded MP3/M4A clips for letters, numbers, piece names, SFX, milestones. Uses two AudioPlayers (voice + sfx). `speakSquare()` chains file+rank clips; `speakMove()` chains piece+file+rank clips. Riverpod provider. |
| `lib/core/services/puzzle_service.dart` | PuzzleService + ParsedPuzzle — loads `assets/puzzles/moves_puzzles.json`, parses FEN with dartchess, computes SAN notation and piece info. `getRandomPuzzle(exclude, sideToMove)` serves random puzzles, optionally filtered by side to move (white default, black for hard mode). Riverpod provider. |
| `lib/core/board_utils.dart` | Highlight helpers — `highlightFile()`, `highlightRank()`, `highlightSquare()` convert our 0-based file/rank indices into chessground's `IMap<Square, SquareHighlight>` format |
| `lib/core/theme/app_theme.dart` | AppColors, AppTheme — Material 3 theme, feedback colors (correctGreen, incorrectRed, highlightYellow) |
| `lib/core/constants.dart` | ChessConstants — file/rank name arrays, squareName helper, timer durations |
| `lib/core/widgets/square_name_overlay.dart` | SquareNameOverlay + SquareLabel — overlays square name labels (e.g. "e4") on top of a chessboard during feedback. Used in squares mode (all modes) and move trainer to reinforce coordinate recognition. Positions labels using the same geometry as chessground. Wrapped in IgnorePointer so it doesn't intercept taps. |

### Chess Notation Trainer (main feature)
| File | Purpose |
|---|---|
| `lib/features/file_rank_trainer/models/file_rank_game_state.dart` | TrainerSubject (`files`/`ranks`/`squares`/`moves`), TrainerMode, AnswerFeedback + FileRankGameState immutable state class. Single `allHighlights` getter returns merged `IMap<Square, SquareHighlight>` for chessground, using `board_utils.dart` helpers. |
| `lib/features/file_rank_trainer/providers/file_rank_game_provider.dart` | FileRankGameNotifier — all game logic: prompt generation (including square prompts with file+rank targets), answer evaluation, streak tracking, countdown timer, personal best tracking (keyed by subject+mode+hardMode). Practice correct delay is 700ms for squares (to allow reading the square name label), 400ms for files/ranks. |
| `lib/features/file_rank_trainer/screens/file_rank_menu_screen.dart` | Mode selection: subject chips in two rows (Files, Ranks, Squares, Moves). Mode cards (explore/practice/speed), Hard Mode toggle (flips board to black's perspective; for moves, filters puzzles so user controls black). Accepts initial values via query params for state preservation on back-navigation. |
| `lib/features/file_rank_trainer/screens/file_rank_game_screen.dart` | Gameplay screen: `Chessboard.fixed` from chessground + prompt + streak + timer, results overlay. Uses `onTouchedSquare` for tap handling, `squareHighlights` for file/rank/square feedback. In squares mode, overlays `SquareNameOverlay` to show square names on tapped/correct squares during feedback. Coordinates always hidden (`enableCoordinates: false`). Hard mode flips board orientation to black's perspective. |
| `lib/features/file_rank_trainer/widgets/streak_counter.dart` | Animated streak display with pulse + milestone glow at 5/10/15/20 |
| `lib/features/file_rank_trainer/widgets/prompt_display.dart` | Shows contextual prompt text per subject and mode (explore hint or forward prompt like "Tap file", "Tap square") |
| `lib/features/file_rank_trainer/widgets/timer_bar.dart` | 30s countdown bar, green→yellow→red, pulse in last 5s |
| `lib/features/file_rank_trainer/widgets/results_card.dart` | End-of-round overlay: score, accuracy, best streak, new record badge |

### Move Trainer (interactive board — puzzle-based)
| File | Purpose |
|---|---|
| `lib/features/move_trainer/models/move_game_state.dart` | MoveTrainerMode (`practice`/`speed`), MoveFeedback, MoveGameState immutable state. `feedbackShapes` getter returns arrow shapes for incorrect answer feedback. `squareHighlights` getter returns green highlights for correct moves. |
| `lib/features/move_trainer/providers/move_game_provider.dart` | MoveGameNotifier — loads puzzles via PuzzleService (filtered by side: white default, black for hard mode), evaluates user moves against expected answer, manages scoring/streaks/timer. Practice correct delay is 700ms (to allow reading the square name label). Correct moves update the board FEN; incorrect moves leave FEN unchanged (piece snaps back) and show a green arrow to the correct destination. |
| `lib/features/move_trainer/screens/move_menu_screen.dart` | Mode selection: Practice and Speed Round cards, Hard Mode toggle ("User controls black!"), Start button. |
| `lib/features/move_trainer/screens/move_game_screen.dart` | Interactive board: `Chessboard` + `GameData` with drag-and-drop piece movement, legal move dots, last-move highlighting. Overlays `SquareNameOverlay` on destination squares during feedback (green for correct, red for wrong + green for correct destination). Board oriented as white by default, black in hard mode. Coordinates always hidden. Reuses StreakCounter, TimerBar, ResultsCard from file_rank_trainer. |
| `lib/features/move_trainer/widgets/move_prompt_display.dart` | Shows SAN notation prominently (e.g., "Qb6") with friendly subtitle (e.g., "Queen to b6"). |

### Chess Vision (4 drill types — board visualization training)
| File | Purpose |
|---|---|
| `lib/features/chess_vision/models/chess_vision_state.dart` | VisionDrillType (`forksAndSkewers`/`knightSight`/`knightFlight`/`pawnAttack`), VisionMode, WhitePiece, TargetPiece enums + ChessVisionState immutable state. Shared fields: streak, errors, configurations completed. Fork-specific: correctSquares, foundSquares, concentric index. Knight-specific: knightSquare, flightPath, flightTargetSquare, minimumMoves. Pawn Attack-specific: pieceSquare, remainingPawns, pawnThreatSquares, difficulty, move count. `boardFen` getter branches on drill type. `allHighlights` getter branches per drill (green found, red flash, yellow revealed, red threat zones for pawn attack). |
| `lib/features/chess_vision/services/fork_skewer_engine.dart` | ForkSkewerEngine — given a white piece type, king square, target square, and target role (rook/bishop/knight/queen), computes all squares where placing the piece creates a winning fork or skewer. Uses dartchess to simulate positions and validate all king escape lines. Handles all piece types for both attacker and target. |
| `lib/features/chess_vision/services/knight_engine.dart` | KnightEngine — `knightMoves(square)` returns all valid L-shaped destinations. `shortestPath(from, to)` uses BFS to find minimum knight moves between any two squares (max 6 on 8x8). `isKnightMove(from, to)` validates a single move. |
| `lib/features/chess_vision/services/pawn_attack_engine.dart` | PawnAttackEngine — `pawnThreats(pawns)` computes squares attacked by black pawns (diagonal downward). `validMoves(role, from, remainingPawns)` generates legal piece moves with ray-casting for sliding pieces (pawns block rays, can be captured). `generatePawns(count, random)` places random pawns on ranks 2-7, with dark-square-only mode for bishop. |
| `lib/features/chess_vision/providers/chess_vision_provider.dart` | ChessVisionNotifier — unified provider for all 4 drill types. Routes taps to drill-specific handlers. Forks & Skewers: random/concentric configurations with None button, pre-filtered concentric path. Knight Sight: alternates center/edge squares. Knight Flight: BFS shortest path, retry/skip for non-optimal paths. Pawn Attack: progressive difficulty (3→8 pawns), practice (cycling) and timed (stopwatch through all levels) modes. Shared: streak tracking, personal bests, audio SFX. |
| `lib/features/chess_vision/screens/chess_vision_menu_screen.dart` | Menu: 4 drill type chips in 2 rows. Forks & Skewers shows piece picker (board piece images), target piece picker, and 3 mode cards (Practice/Speed/Concentric). Pawn Attack shows piece picker + Practice/Timed modes. Knight drills hide all options (practice-only, knight-only). Start button routes to game screen. |
| `lib/features/chess_vision/screens/chess_vision_game_screen.dart` | Unified game screen branching on drill type. Forks: found-progress dots, None button, ghost pieces on found squares via `PieceShape`. Knight Sight: found-progress dots, ghost knights on found squares. Knight Flight: minimum/your-moves counter, ghost knight target, arrow trail, retry/skip buttons for non-optimal paths. Pawn Attack: pawns-remaining counter, pawn threat highlights (subtle red), stopwatch for timed mode, progressive difficulty display. All drills share streak counter, results overlay, app bar score. |
| `lib/features/chess_vision/widgets/found_progress_indicator.dart` | Shows "Found 2 of 4" with filled/empty dot indicators. Displays hint text when no solutions exist. Reused by Forks & Skewers and Knight Sight drills. |

### About
| File | Purpose |
|---|---|
| `lib/features/about/screens/about_screen.dart` | About page: app name/version, Internut Education branding, feature descriptions, credits (Lichess, ElevenLabs, Flutter). Accessible from home screen info button. |

### Core Widgets
| File | Purpose |
|---|---|
| `lib/core/widgets/square_name_overlay.dart` | Reusable overlay widget for displaying square names on the board |

### Other Features
| File | Purpose |
|---|---|
| `lib/features/home/screens/home_screen.dart` | Main menu: large app icon (200px), "Calvin Chess Trainer" in BradBunR font (72pt), 3 training cards with AI-generated illustrations overlaid with BradBunR labels. Chess Notation (green, active → `/file-rank-trainer`), Chess Vision (purple, active → `/chess-vision`, 4 drill types: Forks & Skewers, Knight Sight, Knight Flight, Pawn Attack), Opening Fundamentals (orange, coming soon/disabled). Info button links to About page. |
| `lib/features/tactics_trainer/screens/tactics_trainer_screen.dart` | Placeholder |

### Assets
| Path | Contents |
|---|---|
| `assets/images/app_icon.png` | App icon (2048x2048 PNG) — chess knight on dark green, used for launcher icons and home screen hero |
| `assets/images/internut_logo.png` | Internut Education logo (512x512, transparent background) — used on about page |
| `assets/images/internut_logo_white.png` | White knockout version of internut logo — used for native splash screen on dark green background |
| `assets/images/card_notation.png` | Home screen card illustration — chessboard with coordinates (transparent background) |
| `assets/images/card_vision.png` | Home screen card illustration — knight with movement arrows on purple board (transparent background) |
| `assets/images/card_openings.png` | Home screen card illustration — chess pieces lineup (transparent background) |
| `assets/fonts/BradBunR.ttf` | BradBunR font — playful display font for app title and card labels |
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
| `flutter_native_splash` (dev) | Run `dart run flutter_native_splash:create` to regenerate native splash screens from config in `pubspec.yaml`. |
| `flutter_launcher_icons` (dev) | Run `dart run flutter_launcher_icons` to regenerate iOS/Android app icons from `assets/images/app_icon.png`. |

### Empty Directories (ready for use)
- `lib/features/auth/` — for Firebase Auth screens/providers
- `lib/models/` — for shared data models (user profile, game result)

## App Configuration Notes

- **Portrait only** — orientation locked in `main.dart` via `SystemChrome.setPreferredOrientations`
- **Navigation** — forward navigation uses `context.push()`, back uses `context.pop()` for proper slide-forward/slide-back animations. Do NOT use `context.go()` for sub-screen navigation (causes incorrect "push on top" animation when returning).
- **Splash screen** — configured in `pubspec.yaml` under `flutter_native_splash:`. Uses white Internut logo on dark green (#1B5E20).
- **App icons** — configured in `pubspec.yaml` under `flutter_launcher_icons:`. Source: `assets/images/app_icon.png` (2048x2048). iOS alpha removed automatically.

## Routes

| Path | Screen | Params |
|---|---|---|
| `/` | HomeScreen | — |
| `/file-rank-trainer` | FileRankMenuScreen | `?subject=...&mode=...&hardMode=...` (optional, for state preservation) |
| `/file-rank-trainer/game` | FileRankGameScreen | `?subject=files\|ranks\|squares&mode=explore\|practice\|speed&hardMode=true\|false` |
| `/move-trainer` | MoveMenuScreen | `?mode=practice\|speed&hardMode=true\|false` (optional, for state preservation) |
| `/move-trainer/game` | MoveGameScreen | `?mode=practice\|speed&hardMode=true\|false` |
| `/chess-vision` | ChessVisionMenuScreen | `?drill=...&piece=...&target=...&mode=...` (optional, for state preservation) |
| `/chess-vision/game` | ChessVisionGameScreen | `?drill=forksAndSkewers\|knightSight\|knightFlight\|pawnAttack&piece=queen\|rook\|bishop\|knight&target=rook\|bishop\|knight\|queen&mode=practice\|speed\|concentric` |
| `/about` | AboutScreen | — |
| `/tactics-trainer` | TacticsTrainerScreen | — |
