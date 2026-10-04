# App Store (iOS) store assets — Calvin Chess Trainer

Generated 2026-07-23 from a **release-mode simulator build** (no Flutter debug banner;
the app already sets `debugShowCheckedModeBanner: false`). Captured at native resolution
with `xcrun simctl io … screenshot`, so every file is pixel-exact.

## What goes where in App Store Connect

| Slot | Accepted sizes | Use these files | Status |
|---|---|---|---|
| **iPhone** (6.5"/6.7") | 1242×2688, 2688×1242, 1284×2778, 2778×1284 | all 4 in `iphone/` | ✅ 1284×2778 (6.7") |
| **iPad** (12.9"/13") | 2064×2752, 2752×2064, 2048×2732, 2732×2048 | all 4 in `ipad/` | ✅ 2048×2732 (12.9") |

A 6.7" iPhone set and a 12.9" iPad set are the two required uploads; App Store Connect
down-fills smaller device classes from these. All shots are flattened to RGB with **no
alpha channel** (Apple rejects screenshots that carry transparency).

## Contents

### `iphone/` — 1284×2778 (iPhone 14 Plus, 6.7")
1. `01-home.png` — home screen with the Chess Vision "START HERE" hero card
2. `02-forks-and-skewers.png` — Chess Vision, Queen forks drill
3. `03-name-the-square.png` — Chess Notation → Squares practice ("Tap square a1/a6")
4. `04-opening-explorer.png` — play vs Stockfish: eval bar + book-move arrows + engine depth

### `ipad/` — 2048×2732 (iPad Pro 12.9", 6th gen)
1. `01-home.png` — home screen (hero layout, full card artwork)
2. `02-forks-and-skewers.png` — Chess Vision, Queen forks drill
3. `03-name-the-square.png` — Chess Notation → Squares practice
4. `04-opening-explorer.png` — play vs Stockfish, eval bar + arrows

## How these were produced

Two purpose-built simulators were created at exact App Store resolutions (the pre-existing
sims — iPhone 15/16, iPad Pro 11"/13" M4 — are all the *wrong* sizes and would be rejected):

```
AppStore_iPhone  = iPhone 14 Plus            -> 1284×2778
AppStore_iPad    = iPad Pro (12.9-inch, 6th) -> 2048×2732
```

Clean status bars (9:41, full battery/signal) via `xcrun simctl status_bar … override`.
Release simulator build: `flutter build ios --simulator`; installed with `simctl install`;
navigated with the iOS-simulator control tool; captured with `simctl io … screenshot`.

## ⚠️ IMPORTANT: the Android screenshots are now stale

These iOS shots reflect the **current** app: a Chess Vision **hero** home (3 cards, "START
HERE") and **8** Chess Vision drills (Forks & Skewers, Pawn Attack, Knight Sight, Knight
Flight, Find Checks, Find Captures, Hanging Pieces, Mate in 1). "The Pieces" now lives inside
Chess Notation as the **Piece Value** subject.

The screenshots in `resources/store/android/` were captured earlier from **older code** — they
show a 4-card home (with a separate "The Pieces" card) and only 4 Chess Vision drills. They no
longer match the shipping app and **should be regenerated** before uploading to Google Play.

## Still to do

- Regenerate the Android screenshots to match the current hero-home / 8-drill layout.
- Optional: re-capture drill screenshots mid-streak so score counters aren't all `0`.
