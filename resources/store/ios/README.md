# App Store (iOS) store assets — Calvin Chess Trainer

Rendered 2026-10-04 for 1.6.0 by [`tool/store_assets/store_assets_test.dart`](../../../tool/store_assets/store_assets_test.dart), which shows the app's real screens with seeded game state in a device-sized window and puts each under a caption on brand green. Regenerate everything (both stores, the icon) with:

```bash
flutter test tool/store_assets/store_assets_test.dart
```

Every file is pixel-exact and has **no alpha channel** (App Store Connect rejects screenshots that have one).

## What goes where in App Store Connect

| Slot | Accepted sizes | Files |
|---|---|---|
| **iPhone 6.5" Display** | 1242×2688, 1284×2778 (or landscape) | the six in `iphone/` (1284×2778) |
| **iPad 13" Display** | 2064×2752, 2048×2732 (or landscape) | the six in `ipad/` (2752×2064, landscape) |

App Store Connect scales these down for the smaller device classes. The App Store icon comes from the build (`assets/images/app_icon.png` → `flutter_launcher_icons`), not from an upload. Listing text: [`../listing.md`](../listing.md).

## The six screenshots (same order on both devices)

1. `01-home.png` — "Train what puzzles skip": the daily warm-up, Continue, the drill tiles with bests
2. `02-find-checks.png` — "See every check": two of four checks found, named in notation
3. `03-forks-and-skewers.png` — "Spot double attacks": a queen fork found
4. `04-name-the-square.png` — "Know every square": a Speed Round, 7 in a row
5. `05-read-moves.png` — "Read notation fluently": Bxf7# in a full middlegame
6. `06-opening-explorer.png` — "Explore the openings": the Ruy Lopez with book-move arrows and the eval bar

The iPad set is landscape, iPad's main orientation, so the board and its panel sit side by side.

The Opening Explorer scene uses a stand-in engine that answers the shown position with plausible Stockfish lines (+0.3, 5. O-O). The real engine only runs on a device.
