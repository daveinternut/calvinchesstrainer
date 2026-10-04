# Calvin Chess Trainer - Detailed Explanations

Back to [000 Index.md](000%20Index.md) for the quick reference.

## App Architecture

The app follows a **feature-based folder structure** with Riverpod for state management and GoRouter for navigation.

**Pattern**: Each feature is a self-contained folder with `screens/`, `widgets/`, `providers/`, and `models/` subdirectories. Screens are thin — they read state from providers and dispatch events. All business logic lives in Riverpod Notifiers.

**State management**: We use `Notifier<T>` from `flutter_riverpod` (not the deprecated StateNotifier or StateProvider). Each game's notifier is provided via **`NotifierProvider.autoDispose`**, so a round — its timers, engine work and pending audio — ends when its screen closes; every notifier cancels its timers in `ref.onDispose` and checks `ref.mounted` after each `await`. State that must outlive a screen lives in app-lifetime providers: the audio service, the engine service, and `personalBestsProvider` (personal bests, saved with shared_preferences). Before this split, every game provider lived for the whole app, so an abandoned speed round kept counting down off-screen and finished on its own — playing "New record!" on another screen and saving a best for a round nobody finished.

**Layout**: board screens arrange themselves with `TrainerLayout` (`core/widgets/trainer_layout.dart`) — a column in portrait, board-left/panel-right in landscape (and in any window shorter than 360 pt, like the web app on a phone held sideways). Tablets rotate and phones stay portrait (see the orientation note in CLAUDE.md), so every screen must work both ways.

**Routing**: GoRouter with flat routes (not nested/shell routes). Every drill follows the same path: home or a section screen → the drill's setup panel → its game route, with the configuration in query parameters (built by the drill catalog's `location()`).

## Design System

The look was rebuilt from scratch in October 2026 (v1.6). The earlier UI mixed three styles: a cartoon display face (BradBunR), AI-generated card art with English baked into the images (so the 10-language app could never translate its own home screen), and stock Material controls. It also used colour without meaning: purple/green/orange cards, and a "selected" state that was green, grey, blue or purple depending on the control. The rules now:

- **One accent, with meaning.** Brand green (`AppColors.brand`) is for actions and "found / correct". Amber marks targets (Knight Flight's goal, the forks preview square). Vermilion marks misses and loose pieces. Everything else is a cool, near-neutral ground, so the board and the feedback carry the screen.
- **A pale sage board** (`AppColors.boardLight/boardDark`, via `AppBoard.colorScheme`). On a green board, green "found" highlights would disappear; on sage, green, amber and vermilion all read.
- **Coordinates outside the board.** `BoardFrame` draws rank numbers down the left and files along the bottom, in Geist Mono, flipped with the board, like a precision instrument. Chessground's own in-square coordinates are off everywhere (`AppBoard.settings`). Drills that *test* coordinates (squares, files & ranks, read moves) pass `showCoordinates: false`, and the board then takes the whole square.
- **Type.** Bricolage Grotesque for display and UI. Geist Mono only for notation: "e3", "Nf3", "Bxf7+", the piece letters, board coordinates and the found-answer chips. Scores, streaks and timers use Bricolage with tabular figures (`AppText.number`), because Geist Mono's slashed zero reads as "Ø" in a big "0". Both fonts are bundled (`pubspec.yaml` `fonts:`, static instances from the Google Fonts API) and never downloaded; google_fonts was removed. Neither has Cyrillic or CJK, so those locales render in the platform font, as CJK always did.
- **Glyphs, not illustrations.** Each drill's icon is a `DrillGlyph`: its idea drawn on a 5×5 corner of a real board (two arrows into a king for Find Checks, a knight's eight dots for Knight Sight, a dotted route to an amber square for Knight Flight). They use the app's own pieces and colours and contain no words, so nothing needs translating. The app mark (`LogoMark`) is a knight's L-move on a 3×3 grid; the launcher icon is unchanged.
- **Components** live in `core/ui/`: pill buttons, the `SegmentedPicker` (a grey well; the choice lifts out as a white chip with a green ring), hairline `SurfaceCard`s, `StatTile`, `NotationChip` (found / missed / empty), `PlayTopBar`. Screens compose these instead of styling Material widgets one by one.

## Drills, Home & the Warm-up

**One catalog.** `features/drills/drill_catalog.dart` describes all 13 drills once: name, description, glyph, modes (and what each mode is called for that drill — Pawn Attack's speed mode is "Timed", Mate in 1's is "Blitz"), options, how a choice is coerced (`normalize`), where it plays (`location`) and where its best is kept (`bestKey`). Home, the section screens, Continue and the warm-up all read from it, so a drill can't be described two ways. The best keys come from each provider's public static `bestKeyFor`, the same function the provider saves under.

**Sections and setup.** The two section screens replace the old form-style menus (drill, then piece, then target, then mode, then Start). The list groups drills by skill (Scan the board / Geometry / Finish; The board / Moves / Pieces). On an iPad (≥ 760 pt) the selected drill's **setup panel** sits beside the list at full height. A large glyph preview is shown only when every option still fits above Start; otherwise a smaller glyph sits beside the title. On a phone the panel slides up as a sheet. The panel opens on **the setup used last time** (`drillPrefsProvider`, saved as `drill_prefs_v1`), so most visits are one tap on Start. Each drill keeps its own setup: switching from Forks (Concentric) to Pawn Attack does not carry the mode over.

**Continue.** Starting a drill from a setup panel, or from Continue itself, records it as `lastPlayed`; home's Continue card resumes it with one tap. Before the first drill, the card suggests Find Checks ("Start here"). Warm-up steps don't overwrite Continue.

**The daily warm-up** (`warmupProvider`) is five timed rounds, about five minutes: Find Checks, Hanging Pieces, Forks & Skewers (its piece rotates by weekday), Squares from Black's side, and Mate in 1 — the habits puzzles take for granted. Each step is an ordinary game route with `warmup=1`. The game screen shows "Warm-up · N of 5" in its top bar, and its results offer **Next: {drill}** (or **Finish warm-up**) and **End warm-up** (`roundActions`). Steps replace each other on the navigation stack (`pushReplacement`), so Back from any step returns home. The last step opens `/warm-up/done`, which lists every step's score.

**Missed answers.** The squares/files/ranks and read-moves trainers record what was answered wrong (`state.missed`), and their speed-round results list it as chips.

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
BoardFrame(                                   // coordinates outside the board
  size: size,                                 // from TrainerLayout
  orientation: Side.white,
  showCoordinates: false,                     // naming squares IS this drill
  builder: (context, boardSize) => Chessboard.fixed(
    size: boardSize,                          // the board inside the frame
    orientation: Side.white,
    fen: kInitialBoardFEN,                    // dartchess constant
    settings: AppBoard.settings(),            // sage scheme, cburnett, rounded
    squareHighlights: gameState.allHighlights, // IMap<Square, SquareHighlight>
    onTouchedSquare: (square) {
      handleBoardTap(square.file, square.rank); // File/Rank are ints 0-7
    },
  ),
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

chessground can render coordinates inside the edge squares (lichess-style); we turn that off (`AppBoard.settings`) and draw them outside the grid with `BoardFrame`. The board requires an explicit `size` in logical pixels — `TrainerLayout` computes it, and `BoardFrame.boardSizeFor` gives the board's side inside the frame (overlays like `SquareNameOverlay` must use that inner size).

## Audio System

`lib/core/audio/audio_service.dart`

**Design**: one `AudioPlayer` per layer, so layers never cut each other off:
- `_voicePlayer` — spoken prompts and answers. **One announcement at a time**: starting a new one (or calling `stop()`) cancels the rest of the old one.
- `_correctPlayer` / `_incorrectPlayer` — the answer blips. Each loads its clip once and rewinds (`seek(0)`) on replay, so rapid taps don't reload an asset every time.
- `_cheerPlayer` — milestone and new-record cheers, layered over the voice.

**Cancellable announcements**: multi-clip announcements (`speakSquare`, `speakMove`) play their clips back to back, waiting out each clip's duration. Every step re-checks a sequence token (`_voiceSequence`) after each await; `stop()` and every new announcement bump it. Before this, `stop()` only silenced the clip that was playing — the rest of the sentence still played after you left a screen, and a fast speed-mode answer spliced two sentences together ("knight… takes… e… b… 4… 6").

**Audio session**: configured once, before the first sound, as **ambient** (iOS `AVAudioSessionCategoryAmbient` + mix-with-others; Android `game` usage, transient-may-duck focus). The app mixes with other apps' audio — a parent's music keeps playing — and obeys the silent switch. Unconfigured, just_audio falls back to the "music" configuration (playback, non-mixing), which stops other audio on the first sound effect. TTS is put on the same ambient category on iOS.

**Voice clips**: Pre-recorded via ElevenLabs, stored as MP3 in `assets/sounds/`. Named `file_{letter}.mp3`, `rank_{number}.mp3`, `piece_{name}.mp3`, `move_*.mp3`, `new_record.mp3`, `streak_{5,10,15,20}.mp3`. Generated by recording a full script and splitting with ffmpeg silence detection; the raw recordings live in `resources/audio/` (outside the bundle — they used to ship in every build).

**Sound effects**: macOS system sounds (Glass.aiff → correct.m4a, Basso.aiff → incorrect.m4a) converted to M4A via afconvert.

**API methods** (all fire a haptic unless noted):
- `speakFile(String file)` / `speakRank(String rank)` / `speakPiece(String pieceName)` — single clips (still announcements: they cancel any sentence in flight)
- `speakSquare(String file, String rank)` — file then rank
- `speakMove(String pieceName, String file, String rank, {bool isCapture = false, bool isCheck = false, bool isCheckmate = false})` — chains piece → (optional `move_takes.mp3`) → file → rank → (optional `move_checkmate.mp3` / `move_check.mp3`). Example: "Queen takes b6 check".
- `playCheckCall()` / `playCheckmateCall()` — the "Check!" / "Checkmate!" voice lines (no haptic)
- `playCorrect()` / `playIncorrect()` — SFX
- `playNewRecord()` — "New record!" on the cheer player
- `playMilestone(int streak)` — heavy haptic at every milestone, plus `streak_{5,10,15,20}.mp3` at those exact streaks; called by `MilestoneBanner` when it appears
- `playGameOver()` — **haptic only, plays no sound**
- `speak(String text)` — flutter_tts fallback for dynamic text (castling prompts: "castle kingside"); cancels any clip sequence first
- `stop()` — silences every player and TTS and cancels any announcement; called by every game screen's `dispose`

`AudioService` owns all haptics in the app. It builds asset paths from strings and **swallows playback errors** (logs to `dev.log`) — a missing or renamed clip fails silently, with no compile-time check.

**Adding new audio**: Place MP3/M4A files in `assets/sounds/`, add a method to AudioService. No pubspec changes needed (the directory is already declared).

**Regenerating voice clips**: Record a new script in ElevenLabs with 2+ seconds of silence between phrases. Split with:
```bash
ffmpeg -i "resources/audio/voice full.mp3" -af silencedetect=noise=-25dB:d=0.3 -f null - 2>&1 | grep silence
```
Then extract segments with `ffmpeg -ss START -to END`.

## File & Rank Trainer

The Notation section offers five drills. Two run in this feature — **Squares** and **Files & Ranks** (one kind of line at a time: subject `files` or `ranks`) — and the other three run elsewhere: Piece Letters → `/letter-trainer/game`, Read Moves → `/move-trainer/game`, Piece Values → `/the-pieces/which-side-wins`. `TrainerSubject` still lists `letters`, `moves` and `pieceValue`, but `FileRankGameNotifier` never handles them. There is **no "reverse" mode, no answer buttons, and no "both" subject** — all input is by tapping the board.

### Why Piece Value lives here

Piece value ("Which Side Wins?") used to be its own home-screen card, **The Pieces**, with its own menu screen. It was a single drill sitting next to features that each hold four or more, so it became part of Notation — today the **Piece Values** drill. The `lib/features/pieces/` folder is untouched; only its entry point moved.

Piece Values is **quiz-only**, like Read Moves: the catalog gives it no Explore mode (there is nothing to tap around and discover) and no Board side option, because Which Side Wins has no hard variant. Its practice blurb explains the rising difficulty.

### Game Modes

**Explore**: Free tap, no scoring. Tap any file/rank/square → hear its name, see it highlight green. No correct/incorrect concept. Purpose: build familiarity. Explore never advances prompts or sets `isWaitingForNext`; a tap just speaks and clears after 800ms.

**Practice**: App prompts a random file/rank/square via audio + text; the user taps the board. Streak-based scoring tracks consecutive correct answers, with a milestone celebration (visual banner + haptic) at every multiple of 5. No timer, no end condition — so practice **never logs a completion event and never updates a personal best**.

**Speed Round**: Same as Practice but with a 30-second countdown (hardcoded in the provider). Results card overlay at game end showing total correct, accuracy %, best streak, the prompts that were **missed** (`state.missed`), and a new-record badge if applicable. The badge reads `state.isNewRecord`, set at game over from `personalBestsProvider.submit` — it used to be a notifier getter evaluated on the next frame, after the new best had already been saved, so it compared the score with itself and never showed.

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
- **Timer**: `Timer.periodic(1s)` for the speed countdown; a separate one-shot `Timer` for the feedback-to-next-prompt delay. Both are cancelled on `startGame`, game-over, and — because the provider is autoDispose — when the screen closes.
- **Personal bests**: `personalBestsProvider` under the key `"fileRank.{subject}_{mode}_{isHardMode}"` — e.g. `"fileRank.squares_speed_true"`. Submitted only at game-over (speed mode), **saved on the device**.

## iOS Signing & Deployment

**Current state**: Signed under "DAVID GATES MARKLE (Personal Team)" via `dave@internut.education` Apple ID. As of the 2026-06-05 audit the bundle IDs in the project files are **iOS `education.internut.chesstrainer`** (`ios/Runner.xcodeproj/project.pbxproj`) and **Android `education.internut.calvinchesstrainer`** (`android/app/build.gradle`). ⚠️ Note these two **do not match** (the iOS ID dropped both the `.dev` suffix and the "calvin" prefix). Reconcile them before store submission — pick one canonical ID across platforms (and update `flutterfire configure` / Firebase app registrations to match).

**Building for device**:
```bash
flutter build ios --release
flutter install -d <device-id>
```
Or use Xcode: open `ios/Runner.xcworkspace`, select device, Product > Run.

**iOS deployment target**: 15.0 (set in both Podfile and project.pbxproj; originally required by cloud_firestore, which has since been removed).

**Display name and orientations**: `CFBundleDisplayName` is "Calvin Chess" (it was the generated "Calvinchesstrainer"). iPhone is portrait-only; iPad declares all four orientations without `UIRequiresFullScreen`, so it supports multitasking — which means iPadOS ignores any programmatic orientation lock (iPadOS 26 refuses programmatic orientation changes outright, logging *"The current windowing mode does not allow for programmatic changes to interface orientation"*). Apple deprecated `UIRequiresFullScreen` in iPadOS 26 (TN3192), so the app supports landscape instead of opting out. Android matches: `MainActivity.kt` holds phones (smallest width under 600 dp) in portrait and lets tablets rotate; the Dart side sets no orientation at all.

**Open-file limit**: `AppDelegate.swift` raises the process's soft `RLIMIT_NOFILE` from iOS's default 256 to 4096 at launch, because the `stockfish` plugin leaks four descriptors per engine start (see Opening Trainer → Engine lifecycle).

## Web Build (WebAssembly)

The app ships to the browser as **WebAssembly only**. Two separate walls made web
impossible before; understanding both explains why the build looks odd.

### Wall 1 — Stockfish is native

The `stockfish` package is a native binary driven over `dart:ffi`, and it declares only
`android`/`ios` plugin platforms. `dart:ffi` does not exist in a web build. Worse, the
FFI call sat in the boot path — `main()`'s first line is `stockfishCleanupForRestart()`,
which calls `DynamicLibrary.open`. So the *whole app* failed to compile for web over one
trainer.

**Fix: a compile-time split.** `stockfish_service.dart` is now a thin entry point that
re-exports a platform-neutral contract and picks an implementation:

```dart
import 'stockfish_engine_io.dart'
    if (dart.library.js_interop) 'stockfish_engine_web.dart' as impl;

const bool kEngineAvailable = impl.kEngineAvailable;
```

Native keeps the real FFI engine (`stockfish_engine_io.dart`, unchanged logic — including
the hot-restart cleanup and the "Multiple instances" retry loop, which have no web analog).
Consumers did not change — they still import `stockfish_service.dart` and use
`StockfishService`.

Web initially got a stub that threw, with the Opening Fundamentals card hidden and
`/opening-trainer` redirecting to `/`. It now gets a **real engine** instead: see
*The web engine* below. The `kEngineAvailable` gates remain in place as the seam for any
future engine-less target.

### Wall 2 — dartchess needs 64-bit integers

dartchess represents the board as **64-bit bitboards** (`SquareSet(0xffffffffffffffff)`).
dart2js has no 64-bit ints — JS numbers are doubles, and its bitwise operators are 32-bit —
so those literals do not even compile, and the arithmetic could not be correct if they did.
That is why lichess declares no web platform for dartchess. It is not an oversight.

**dart2wasm has real `i64`**, so the identical code is exact there. Verified directly:
dartchess compiled to wasm and run under Node returned the same answers as native (20 legal
first moves, `SquareSet.full.size == 64`, correct FEN after 1.e4). pub.dev tags the package
`is:wasm-ready` for this reason.

### Why `flutter build web` cannot be used

`flutter build web --wasm` compiles **twice** — dart2wasm plus a dart2js fallback for
browsers without WasmGC — and hardcodes both configs (`build_web.dart`, `compilerConfigs`).
There is no flag to skip the fallback, and `flutter assemble` does not expose the web
targets. The dart2js half fails on dartchess every time, which fails the whole build.

`flutter run -d web-server --wasm` uses a **single** compiler config
(`resident_web_runner.dart`), so it compiles wasm only and writes a complete bundle to
`build/web`. That is what **`scripts/build_web.sh`** drives. Its one weakness is that
`flutter run` does not strip or minify the wasm the way `flutter build` does (9.0 MB vs
2.8 MB), so the script also harvests the stripped artifacts from the *failed*
`flutter build web --wasm` and drops them in. Revisit the script if Flutter adds a
wasm-only build or dartchess gains dart2js support — either collapses it to one command.

### Consequences to know

- **WasmGC is required**: Chrome/Edge 119+, Firefox 120+, **Safari 18.2+ / iOS 18.2+**.
  There is no JS fallback, so an older iPad gets the loader's "no compatible build" error
  rather than a degraded app. For a kids' app on hand-me-down hardware this is the main
  reason to think twice about web-first.
- **First load is ~5.5 MB live** (28 requests, measured over CDP against the deployed
  site with a cold cache). Firebase compresses on the wire, which a local static server
  does not — the wasm goes 2.84 MB -> 0.81 MB and MaterialIcons 1.57 MB -> 0.41 MB. PNGs
  are already compressed, so they do not shrink further and now dominate the load.
  Getting here took two fixes, both in `scripts/build_web.sh` or the assets themselves:
  - **Card art resized.** The three card PNGs were 2500-2700 px wide (~4 MB each) against
    a ~330 pt render; they are now 1200 px. `app_icon.png` went 2048 -> 1024, which is
    exactly what the iOS App Store icon needs, so `flutter_launcher_icons` still generates
    losslessly from it. 13.3 MB -> 2.9 MB, visually identical at display size. The
    unreferenced 1.5 MB `internut.ai` master moved to `resources/art/`, out of every
    platform bundle.
  - **chessground assets pruned.** The package bundles 40 piece sets (27 MB, 1904 files)
    and 25 board textures; Flutter cannot tree-shake a package's declared assets, so all of
    it landed in `build/web`. The app uses `PieceSet.cburnett` (532 KB) and
    `ChessboardColorScheme.green`, which is `SolidColorChessboardBackground` — no texture
    at all. The prune removes ~1880 files, taking the deploy from **2028 files to 147**.
    That file count, not the byte count, is what made the first Firebase deploy time out
    mid-upload. The keep-list is derived from `PieceSet.*` in `lib/` so it cannot rot, and
    board textures are only dropped while `green` is the only scheme in use.

- **Everything else was already web-clean**: `just_audio` and `flutter_tts` declare web
  implementations, `firebase_options.dart` already had a `kIsWeb` branch, and a web app was
  already registered in the Firebase project (`measurementId: G-LZK9E0VDNN`), so Analytics
  reports into the same property as iOS/Android with no extra setup.

### The web engine

The browser runs **Stockfish 19 Lite compiled to WebAssembly**, in a Web Worker. Binary
and rationale live in `web/stockfish/README.md`; the Dart side is
`stockfish_engine_web.dart`.

**No pub dependency.** The one package that declares web support
(`flutter_stockfish_plugin`) is marked experimental, ships no `.wasm` (you must install
emscripten and compile it yourself), has **no iOS** support, and would put a second
Stockfish in the dependency graph alongside the native one — a real risk of Android
symbol conflicts. Instead the Worker is driven through `dart:js_interop` from the SDK,
with a handful of `extension type` declarations for `Worker`/`MessageEvent`. Native
resolution is completely unaffected: `pubspec.yaml` did not change.

**Which build.** `stockfish` npm ships four variants. The full-net builds are 94.5 MB —
unusable over the wire. `lite-single` is **1.7 MB** and contains no `SharedArrayBuffer`
reference at all, so it needs no cross-origin isolation, which in turn means CanvasKit can
keep loading from the gstatic CDN and `firebase.json` needs no COOP/COEP headers.
(Measured: every cross-origin dependency the app already uses — gstatic, fonts.gstatic,
googletagmanager — does send `cross-origin-resource-policy: cross-origin`, so isolation
*would* have been viable; it just is not needed.) Verified in a browser Worker at **depth
15 in 500 ms, ~814k nps** — comfortably past the hardest difficulty (skill 18, 500 ms).

**Lazy.** The Worker is created on the first `initialize()`, which `OpeningGameNotifier`
calls from `startGame()`. The home screen makes 17 requests and fetches none of the
engine; opening the trainer then pulls the `.js` and `.wasm`. Confirmed with a
request-logging static server.

**Duplicated on purpose.** The UCI handling in `stockfish_engine_web.dart` — search
commands, score parsing, white-perspective normalisation, the MultiPV depth snapshot, the
op queue, start/release and the timeout drain — is a deliberate copy of
`stockfish_engine_io.dart` rather than a shared base class. Native play is the shipping
product; refactoring it to accommodate web risked destabilising it for no user-visible
gain. (Neither side sets `Threads`, so both run Stockfish's default single thread.) The
cost is that **a protocol bug must be fixed in both files**, which the headers of both
call out.

**What practice mode actually does.** Worth knowing before testing: in
`OpeningMode.practice` the notifier sets `isPlayerTurn: isPractice` after a move, so the
engine never replies — it is an *explorer* where you play both sides while Stockfish
supplies the eval bar and the hint arrows. `_engineMove()` only runs in challenge mode,
which is still unreachable (see Known Gaps). A web test that waits for a black reply after
1.e4 will wait forever; look at the eval bar and arrows instead.

### Two web-only failure modes worth knowing

Both were found by testing the deployed site, not the local build.

**1. Firebase could strand the app on the splash screen.** `main()` originally did a bare
`await Firebase.initializeApp(...)` before `FlutterNativeSplash.remove()` and `runApp()`.
On web the Firebase SDK is a runtime `import()` from gstatic, and ad blockers, privacy
extensions and DNS filters block it routinely. The rejection surfaces as an **unhandled JS
promise**, not a Dart error, so `initializeApp()` neither completes nor throws — the await
hangs forever and the app never starts. A `try`/`catch` alone does **not** fix this; you
cannot catch a hang. The first fix was a `.timeout(Duration(seconds: 8))` inside the catch,
which still made every blocked visitor wait 8 seconds on the splash. Now Firebase
initializes **in the background**: `main()` starts it (still with the timeout) and calls
`runApp()` immediately; `markFirebaseReady()` flips `analyticsAvailable` when it lands.

`AnalyticsService` needed hardening too: reading `FirebaseAnalytics.instance` throws when
Firebase never initialised. The service now resolves the instance lazily, only once
`analyticsAvailable` is true, so events (and `ScreenViewObserver`'s screen views) are simply
dropped until then; all 12 typed events route through one guarded `_logEvent`, which also
catches `logEvent`'s asynchronous failures (a `try`/`catch` around an un-awaited Future
catches nothing).

Reproduce either with Chrome DevTools request blocking on `*googletagmanager.com*` and
`*firebase-analytics*`, or over CDP with `Network.setBlockedURLs`.

**2. Cache headers can pin visitors to a stale build.** Flutter's web output is **not
content-hashed** — `main.dart.wasm`, `flutter_bootstrap.js`, `index.html` and every file
under `assets/` keep their names forever. An early version of `firebase.json` served them
`max-age=31536000, immutable`, which meant a returning visitor would never see a new
deploy. They are now `no-cache`: still stored, but revalidated, so an unchanged file costs
a ~100-byte 304. Only `web/stockfish/**` is cached hard, since its version is part of the
filename.

Headers alone were not enough, though. **Changing `Cache-Control` does not evict what a
browser already stored** — visitors served the old `immutable` response stayed pinned to
that build, and a hard refresh did not dislodge it (confirmed in a real browser:
`main.dart.wasm` came back with `transferSize: 0` at 2,982,586 bytes while the server was
serving 2,996,545). The only reliable escape is a **different URL**, so `build_web.sh` now
stamps `mainWasmPath` and `jsSupportRuntimePath` in `flutter_bootstrap.js` with a content
hash (`main.dart.wasm?v=<hash>`). The bootstrap is itself `no-cache`, so it is always
fresh and always points at the current build. That un-stuck the pinned browser on an
ordinary navigation, with no cache clearing.

Note that **Firebase applies the last matching `headers` entry**, not the first — verified
live. With `/stockfish/**` listed before the `**` catch-all, the catch-all won and the
specific rule did nothing. Catch-all first, overrides after.

### Hosting

Firebase Hosting, configured in `firebase.json` (`public: build/web`, SPA rewrite to
`/index.html`, long-lived immutable caching for hashed assets, `no-cache` for
`index.html` / `flutter_bootstrap.js` so a deploy takes effect at once).

```bash
./scripts/build_web.sh
firebase deploy --only hosting
```

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

**Practice**: Unlimited puzzles, no timer. Correct = 700ms delay, incorrect = 1200ms delay (shows green arrow to correct destination). Streak tracking with milestones. Like the file/rank trainer, practice never logs completion or updates a personal best (no end condition). Puzzles are dealt from a shuffled deck, so none repeats until the whole set (filtered by side for hard mode) has been seen.

**Speed Round**: 30-second countdown. Correct = 200ms delay, incorrect = 600ms delay. Results card with score, accuracy, best streak, new record badge. Personal best saved under `move.{mode}_{hardMode}`.

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
- If `puzzle.matches(move)` → correct (origin and destination compared after dartchess `normalizeMove`, so dropping the king onto its rook counts as castling)
- Correct: update FEN to new position (piece stays), green square highlights, advance; side-to-move and the check highlight follow the position on screen
- The subtitle ("Queen to c8") takes the square from the expected move and a localized piece name — parsing it out of SAN used to show "Queen to fc8" for disambiguated moves
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

- **Forks & Skewers**: a black king (fixed on **d5**) and a target piece sit on the board; tap every square where placing the chosen white piece wins the target by fork or skewer. A **None** button handles positions with no solution — **15% of rounds** by design (a wrong None reveals the answer and is not counted). Knight vs knight is blocked in the setup panel: a knight attacking a knight is always captured back, so that pairing has no solutions anywhere. Modes: practice / speed / concentric.
- **Knight Sight**: tap all squares a lone knight attacks. Configs alternate between central and edge knight squares.
- **Knight Flight**: move a knight to a target square in the fewest hops. Arriving on a non-optimal path offers **retry / skip**.
- **Pawn Attack**: navigate a piece to capture all black pawns without landing on a pawn-attacked square. Difficulty climbs **3 → 8** pawns. Modes: practice (endless cycle) / timed. Every board is dealt **solvable for the piece that plays it**, and a **Start over** button resets the current board (it turns amber when the piece has no safe move left) — about 1–3% of knight boards used to leave the knight with no legal first move, and there was no way out.
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

- **`fork_skewer_engine.dart`** — the crown jewel. `computeValidSquares(...)` brute-forces all 64 candidate squares. For each, it places the white king on a **neutral square**, builds a 4-piece position in dartchess (white piece, white king, black king on d5, target), then enumerates **every** black legal reply and confirms the white piece captures the target uncapturable on every line (including a king recapture). The white king goes in a corner when one is safe — judged with real attacks (`board.attacksTo`, blockers included) — and otherwise on any square ≥3 from the black king, ≥2 from the piece, target and block squares, and off the piece–target line. (It used to try corners only, with an attack check that ignored blockers, so with the target in a corner valid squares were silently dropped: Qh1 marked wrong against a rook on a8, or "None" when Qf3/Qg2/Qh1 all skewer a queen on a8. `fork_skewer_engine_test.dart` now checks all 16 pairs × 63 targets against a brute-force reference.) It is correct but not free: the provider precomputes the solution sets for all 63 targets at game start (a few ms).
- **`knight_engine.dart`** — `knightMoves`, `isKnightMove`, and `shortestPath` (plain BFS; returns hop count, −1 if unreachable). The "max 6 hops" is an emergent fact about an 8×8 board, not a coded cap.
- **`pawn_attack_engine.dart`** — `pawnThreats` (black pawns attack their two *downward* diagonals), `validMoves` (knight L-moves + ray-cast sliders; a pawn blocks a ray but can be captured; a threatened empty square is an unsafe landing but does not stop the ray), `isSolvable` (breadth-first search over piece square × remaining pawns, ≤64×256 states), and `generatePawns(count, rng, {required Role role})` (places pawns on ranks 2–7, dark-squares-only for the bishop, never threatening the **a1** start, and keeps only boards `isSolvable` says the piece can clear).
- **`scan_engine.dart`** — ground truth for the scanning drills, straight dartchess: `checkTargets`/`checkTargetDetails`, `captureTargets`, `hangingTargets`, `matingMoves`/`isMatingMove`. See the next section for the contract that keeps it honest.

### The scanning drills — curated real positions

The scanning drills are built on one principle: **the engine is the truth, curation is the taste.** Positions ship as bare FENs (`assets/puzzles/scan_{checks,captures,hanging}.json`, `{fen, n}`) mined from the Lichess puzzle DB by `scripts/curate_scanning_positions.py`; at runtime `ScanEngine` recomputes the target squares from the FEN, so there is no stored answer key that can go stale. The script *selects* positions using **byte-equivalent python-chess predicates** — the same fixtures are asserted in `test/scan_engine_test.dart` and the script's `--self-test`, and the script re-validates every selected entry before writing (plus the provider debug-asserts engine targets == curated `n`). If the two implementations ever drift, something fails loudly.

What curation guarantees (so runtime can stay simple):
- **Real positions**: post-setup Lichess puzzle positions ("opponent just moved"), quality-gated (NbPlays ≥ 500, popularity ≥ 50, rating 600–1500, ≤ 24 pieces), never in check for the tap drills, 50/50 white/black to move, deduped against each other **and** the move-trainer set.
- **Unambiguous taps**: no two checking moves from different origins share a destination square (also what makes the per-square ghost piece well-defined); no en-passant in the captures set (the ep victim's square is never a move's destination — untappable); positions where *castling* gives check are rejected outright, because python-chess and dartchess encode castling differently, so `ScanEngine` skips castling and stays exactly in sync.
- **The honest-pawn rule**: hanging = **undefended** (zero defenders — capturability not required), and targets are pieces only (N/B/R/Q), so the curation additionally rejects any position containing an undefended enemy pawn — a kid who taps a genuinely loose pawn must never be told "wrong". Every shipped hanging position also contains a *defended* enemy piece as a distractor: the "defended ≠ loose" discrimination is the drill's whole point.
- **Determinism**: seeded RNG; same CSV + seed ⇒ byte-identical assets. Regeneration: download `lichess_db_puzzle.csv.zst` (see the script docstring), `pip install 'chess>=1.10,<2'`, run the script (~2 min), done.

Mate in 1 reuses the existing puzzle plumbing instead: `mate_in_one_puzzles.json` is byte-compatible with `moves_puzzles.json` (`{fen, moves}` — Lichess `mateIn1` theme, python-verified mates, rating 600–1200), loaded by a second `PuzzleService` instance (`mateInOnePuzzleServiceProvider` — the asset path is a constructor param). The drill judges **by result** (`ScanEngine.isMatingMove`: normalize → legal? → `playUnchecked(...).isCheckmate`), so the 14 puzzles with multiple mates accept any of them, and a queen-promotion mate delivered via `autoQueenPromotion` counts. After a correct mate the mated position stays on screen with the king highlighted.

UI-wise the tap drills are the forks find-all machinery on real boards (green found-squares, 400 ms red flash on a miss, "All Clear!" beat, a **Skip** that reveals unfound targets for 1.5 s at the cost of the streak and counts nothing), and Mate in 1 is the move trainer's interactive board (setup-move highlight, snap-back + green solution arrow + square labels on a miss). One deliberate novelty: the board **orients to the side to move** — half the positions train the flipped-board view kids otherwise never practice — and a **side-to-play pill badge** ("White to play" / "Black to play") sits above the prompt on all four drills so the mover is unmistakable the moment a position loads.

### Gotchas

- **Fixed geometry**: black king is always d5, the white king is auto-placed on a neutral square, and the pawn-attack piece always starts on a1. The fork engine assumes this minimal world. Don't move these assumptions.
- **Mode coercion is one rule**: `VisionDrillType.effectiveMode()` — knight drills are practice; pawn-attack and the scanning drills are speed/practice (concentric is forks-only). The menu, the provider and the screen all use it (the screen used to trust the raw route param, so Pawn Attack launched with a stale "concentric" mode showed concentric UI over a timed game). "Blitz" (Mate in 1) is just `VisionMode.speed` with a different l10n label.
- **`startGame` is async** (scanning assets load lazily); a `_gameGeneration` token discards a load that a quick restart superseded, `ref.mounted` guards a load that outlives the screen, and the speed countdown starts only after the load. A failed load shows an error with Retry instead of spinning forever.
- **A round is credited when it is solved**; only loading the next position waits for the feedback beat — otherwise game-over cancelled the pending advance and a last-second solve didn't count.
- **Personal-best metric flips**: pawn-attack-speed and concentric rank by *lowest elapsed time* (`lowerIsBetter`); other speed drills rank by *highest configurations completed*. Bests are saved on the device.

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

- **Progressive hint search**: `_requestHints` runs `getTopMoves` in waves at fixed **depths `[8, 12, 16, 18]`** (depth-based searches are deterministic, so scores don't drift between views), refining the arrows as the engine deepens. **Practice requests 5 moves across 4 waves; challenge requests 3 across 1 wave.** The current depth streams into `engineDepth` and renders as a live "d12/18" readout (`thinking_indicator.dart`). `_hintFen` is the cancellation token — every wave bails if the position changed mid-search, and the depth readout is always cleared on exit. The hint cache remembers the last completed wave per position, so revisiting a partly analysed position resumes the deeper waves instead of keeping its depth-8 arrows forever. Move keys go through `uci_move.dart` (`toUci`): castling is always `e1g1`/`e1c1` and promotions carry their suffix (`e7e8q`), so book moves, engine moves and badges match (no duplicate O-O arrow, no e1→h1 arrow, and promotion squares get real badges). Mate scores are carried through to the eval bar and line tags (`#` once the game is over).
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

`StockfishService` wraps the process's single **native engine** (the `stockfish` package allows one at a time). Key facts about the package that shape this design: `Stockfish.dispose()` only *sends `'quit'`* — the package's static instance is cleared when the native side actually exits, and until then `Stockfish()` throws `'Multiple instances are not supported'` (which `_createWithRetry` handles with backoff). And its native glue opens **two new pipes per start without closing the old ones**: four file descriptors leaked per engine start.

- **One engine per Opening Explorer visit.** The engine starts on demand and stays up for the whole screen session; the screen's provider (autoDispose) hands it back with **`disposeWhenIdle()`** when it closes, which releases it once nothing is running, queued or starting (any later engine call cancels a pending release). It used to be disposed whenever it went idle — after every completed hint pass — and restarted on the next move, so every "wait for the arrows, then move" leaked four descriptors; against iOS's default limit of 256 that eventually breaks every file open in the app (measured on the simulator: 4 per restart, never reclaimed). `AppDelegate.swift` also raises the soft limit to 4096, so the one-start-per-visit leak would take ~1000 visits to matter.
- **All engine operations are serialized** through an internal queue (`isBusy` also covers a start in flight). UCI has no request ids, so an op's stdout listener would otherwise parse info/bestmove lines from another op's search — this also protects the fen-keyed eval cache from cross-position poisoning.
- **`stopSearch()`** aborts the running search and drops queued ops (they throw `SearchCancelledException`); the provider calls it when the user moves and when the screen closes, so leaving mid-analysis frees the CPU within a second (it used to keep a core at 100% for ~20 s).
- **Timeouts drain.** A search that times out sends `stop` and waits (≤5 s) for its *own* `bestmove` before the next op runs; otherwise a late `bestmove` would land in the next op and shift every later result by one (e.g. after the iPad slept mid-search). Draining on `bestmove`, not `readyok`, because Stockfish answers `isready` immediately even mid-search. An engine that ignores `stop` is restarted; one that exits mid-search is detected (stdout closes) and replaced.
- **Start/release races are closed.** A start in flight counts as busy, so a release waits for it; `_doInitialize` works on a local engine and only a live, still-current engine is marked ready (a release landing during the handshake used to leave `_isReady == true` with no engine); an engine still *starting* when released is quit the moment it comes up — the package refuses `quit` before then, and an un-quit engine kept the one-engine slot taken until the app was killed.
- **A failed start is sticky** (`EngineUnavailableException`) until `initialize()` is called again — the screen shows "The chess engine didn't start." with **Retry**. The web Worker fails fast on an error instead of waiting out its 45 s handshake.
- **App lifecycle:** the screen's `AppLifecycleListener` stops the search when the app is hidden and resumes analysis of the current position when it returns.
- Fixed-depth searches carry a **movetime ceiling** (`go depth D movetime M`, per-wave caps) so a slow device can't run one away.
- Engine state is per-instance; `NativeStockfishService.forTesting(createEngine:, …)` drives a fake `Stockfish` in `test/stockfish_engine_io_test.dart`. `stockfishCleanupForRestart()` (debug builds only, in `main()`) frees a native engine left over from before a hot restart.

## Planned / Unfinished Features

- **Tactics Trainer**: Show positions with forks/pins/skewers, user identifies them. Will use the Lichess puzzle database (same CC0 source as the move trainer, different filtering). Interactive board via `Chessboard` + `GameData`. Currently a placeholder screen routed at `/tactics-trainer` with no in-app navigation linking to it.
- **Opening Trainer wiring**: the engine, eval, hints, and line navigation all work, but challenge mode is unreachable — `OpeningMenuScreen` is not routed and the lives/medal/principle UI is not mounted (see the Opening Trainer section above). Finishing it = registering the menu route (+ a `/opening-trainer/game` route) and mounting the existing widgets. (The old review-mode code was removed — non-destructive scrubbing replaced it.)
- **Progress beyond personal bests**: bests are saved on the device (`personalBestsProvider`); nothing else is (no per-drill history, no cloud sync). Firebase Auth/Firestore and the empty `auth/`/`models/` scaffolding were removed as unused; cloud progress would need them back. **Analytics is live** (screen views + per-drill events).

## Project Info

| | |
|---|---|
| Organization | Internut Education |
| Website | https://internut.education |
| Contact | dave@internut.education |
| Bundle ID | education.internut.calvinchesstrainer (.dev suffix temporary) |
| Repository | https://github.com/daveinternut/calvinchesstrainer |
| Apple Team | DAVID GATES MARKLE (Personal Team) / U2V42G33C3 |
