# Calvin Chess Trainer

A chess training app for the skills puzzles take for granted: board vision and notation, through short timed drills. Built by [Internut Education](https://internut.education).

## What's in it

- **Daily warm-up** — five quick timed drills (about five minutes): checks, loose pieces, forks, squares from Black's side, and a mate in one
- **Vision** — eight drills: find checks, find captures and hanging pieces on curated real-game positions, forks & skewers, knight sight, knight flight, pawn attack, and mate in 1
- **Notation** — squares and files & ranks (with spoken coordinates), read a move in notation and play it, piece letters, and piece values ("which side wins?")
- **Opening Explorer** — play through openings with book moves, Stockfish hint arrows, a live evaluation bar and variations
- Each drill remembers its setup, home's Continue card resumes the last one, and personal bests are saved on the device. Tablets (iPad and Android) rotate, and every screen lays out both ways; phones stay in portrait.
- _Tactics Trainer — placeholder, not yet built_

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter (Dart) |
| State Management | Riverpod |
| Routing | GoRouter |
| Board & Chess Logic | chessground + dartchess (lichess, GPL-3.0) |
| Engine | Stockfish (via FFI) |
| Backend | Firebase Analytics (no accounts, no cloud storage) |
| Audio | just_audio + audio_session, flutter_tts |
| Puzzle / Opening Content | Lichess puzzle database + ECO openings (CC0) |

## Platforms

- iOS (iPhone & iPad)
- Android
- Web — [calvin-chess-trainer.web.app](https://calvin-chess-trainer.web.app). **WebAssembly
  only**, with every trainer including Opening Fundamentals: native Stockfish is
  `dart:ffi` and has no web build, so the browser runs **Stockfish 19 Lite compiled to
  WASM** in a Web Worker instead (`web/stockfish/`). Requires a WasmGC browser:
  Chrome/Edge 119+, Firefox 120+, Safari 18.2+ / iOS 18.2+. Build it with
  [`scripts/build_web.sh`](scripts/build_web.sh) — plain `flutter build web` cannot
  build this app; the script's header explains why.

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

## Releasing

**iOS — App Store / TestFlight, one command.** One-time setup is in the header of [`scripts/build_ipa.sh`](scripts/build_ipa.sh): an App Store Connect API key in `~/.appstoreconnect/private_keys/` (never in this repo — it is public) and its IDs in `scripts/build_ipa.env` (gitignored; template in `scripts/build_ipa.env.example`).

```bash
./scripts/build_ipa.sh --check   # read-only: key works? app record? last build? version still open?
./scripts/build_ipa.sh           # analyze + test → build the .ipa → upload to App Store Connect
```

It picks the build number for you (one above the highest build App Store Connect has seen, or pubspec's if that is higher), refuses a version Apple has already approved, and writes the number it used back to `pubspec.yaml` — commit that. Then: App Store Connect → the app → **TestFlight** (processing takes 5–15 min) → **App Store** tab → the version → pick the build → What's New → **Add for Review** → **Submit**. Other flags: `--no-upload`, `--skip-tests`, `--build-name 1.5.0`, `--wait`, `--dry-run`.

**Android — Google Play:** `./scripts/deploy_play.sh --track alpha|production` (setup in its header; it uses the same `+N` from `pubspec.yaml`). The first release, the closed test new personal accounts must run (12+ testers for 14 days), the Play Console answers and the listing text are in [`resources/store/android/PUBLISHING.md`](resources/store/android/PUBLISHING.md).

**Web — Firebase Hosting:**

```bash
./scripts/build_web.sh          # → build/web (always rebuild right before deploying)
firebase deploy --only hosting
```

### Architecture & documentation

New to the codebase (human or AI agent)? Start with **[CLAUDE.md](CLAUDE.md)** (mental model, repo map, task router) and **[resources/000 Index.md](resources/000%20Index.md)** (the full code map). Deeper dives live in [resources/000 Explanations.md](resources/000%20Explanations.md); the chessground/dartchess API reference is [resources/000 lichess documentation.md](resources/000%20lichess%20documentation.md).

## License

Proprietary — Internut Education. All rights reserved.
