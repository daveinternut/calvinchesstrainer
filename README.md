# Calvin Chess Trainer

A chess learning app that teaches fundamentals through interactive drills and timed challenges. Built by [Internut Education](https://internut.education).

## Training Modes

- **The Pieces** — Compare two groups of pieces by value and pick the stronger side ("which side wins?")
- **Chess Notation** — Audio calls out a file, rank, or square; tap it on the board. Plus a move drill: given notation like "Qb6", make the move
- **Chess Vision** — Spot forks & skewers, knight sight, knight flight, and pawn-attack navigation
- **Opening Fundamentals** — Play sound opening moves against the Stockfish engine, with a live evaluation bar and hint arrows
- _Tactics Trainer — placeholder, not yet built_

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter (Dart) |
| State Management | Riverpod |
| Routing | GoRouter |
| Board & Chess Logic | chessground + dartchess (lichess, GPL-3.0) |
| Engine | Stockfish (via FFI) |
| Backend | Firebase — Analytics (Auth/Firestore scaffolded, not yet used) |
| Audio | just_audio, flutter_tts |
| Puzzle / Opening Content | Lichess puzzle database + ECO openings (CC0) |

## Platforms

- iOS (iPhone & iPad)
- Android
- Web

## Project Info

| | |
|---|---|
| Organization | Internut Education |
| Website | https://internut.education |
| Contact | dave@internut.education |
| Bundle ID prefix | education.internut |
| Repository | https://github.com/daveinternut/calvinchesstrainer |

## Development Setup

**Setting up a new machine? Follow [SETUP.md](SETUP.md)** — step-by-step from a clean Mac through iOS simulators, Android emulator, device signing, and pinned tool versions.

### Prerequisites

- Flutter **3.35.7** (stable) / Dart 3.9.2 — pin this version
- Xcode 16+ with an iOS simulator runtime, CocoaPods 1.16+ (iOS builds)
- Android Studio with SDK Platform 36, Build-Tools 35.0.1, **NDK 27.0.12077973** (Android builds)
- Chrome (web builds)

Firebase config files are committed — do **not** run `flutterfire configure`.

### Getting Started

```bash
git clone https://github.com/daveinternut/calvinchesstrainer.git
cd calvinchesstrainer
flutter pub get
flutter run
```

### Architecture & documentation

New to the codebase (human or AI agent)? Start with **[CLAUDE.md](CLAUDE.md)** (mental model, repo map, task router) and **[resources/000 Index.md](resources/000%20Index.md)** (the full code map). Deeper dives live in [resources/000 Explanations.md](resources/000%20Explanations.md); the chessground/dartchess API reference is [resources/000 lichess documentation.md](resources/000%20lichess%20documentation.md).

## License

Proprietary — Internut Education. All rights reserved.
