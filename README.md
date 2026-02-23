# Calvin Chess Trainer

A chess learning app that teaches fundamentals through interactive drills and timed challenges. Built by [Internut Education](https://internut.education).

## Training Modes

- **File & Rank Trainer** — Audio calls out a file or rank; tap the correct one on the board
- **Square Trainer** — Identify squares by name with timed challenge modes
- **Move Trainer** — Given notation like "Qb6", make the correct move on the board
- **Tactics Trainer** — Identify forks, pins, and skewers in positions

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter (Dart) |
| State Management | Riverpod |
| Backend | Firebase (Auth, Firestore) |
| Audio | just_audio, flutter_tts |
| Chess Logic | chess (Dart) |
| Puzzle Content | Lichess puzzle database (CC0) |

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

### Prerequisites

- Flutter SDK (stable channel)
- Xcode (for iOS builds)
- Android Studio (for Android builds)
- Chrome (for web builds)
- Firebase CLI + FlutterFire CLI

### Getting Started

```bash
git clone https://github.com/daveinternut/calvinchesstrainer.git
cd calvinchesstrainer
flutter pub get
flutter run
```

## License

Proprietary — Internut Education. All rights reserved.
