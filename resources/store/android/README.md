# Google Play store assets — Calvin Chess Trainer

Rendered 2026-10-04 for 1.6.0 by [`tool/store_assets/store_assets_test.dart`](../../../tool/store_assets/store_assets_test.dart), from the app's real screens; see [`../ios/README.md`](../ios/README.md) for how it works. Regenerate with:

```bash
flutter test tool/store_assets/store_assets_test.dart
```

## What goes where in the Play Console

All of it is on **Grow users → Store presence → Main store listing**, in the **Graphics** section below the text fields.

| Play Console field | Files | Spec |
|---|---|---|
| **App icon** | `icon-512.png` | 512×512 |
| **Feature graphic** | `feature-graphic-1024x500.png` | 1024×500 |
| **Phone screenshots** | the six in `phone/` | 1080×1920 (9:16) |
| **7-inch tablet screenshots** | the six in `tablet/` | 2560×1440 (16:9) |
| **10-inch tablet screenshots** | the same six in `tablet/` | 2560×1440 (16:9) |

Phone shots are 9:16, the shape Play asks for; the app window inside each one is a 16:9 phone. The tablet shots are landscape because Android tablets rotate as of 1.6.0. Both sets have six shots at 1080 px or more, which meets Play's bar for promotion. Listing text: [`../listing.md`](../listing.md).

The six screenshots match the iOS set: home, Find Checks, Forks & Skewers, a Squares Speed Round, Read Moves and the Opening Explorer.

## The icon

`icon-512.png` is the app icon (the LogoMark: a knight's L-move to an amber square) at Play's size; Play rounds the corners itself. The launcher icon in the app comes from `assets/images/app_icon.png` plus the adaptive layers in `resources/icon/` via `dart run flutter_launcher_icons`.

## The feature graphic

The icon and the name on brand green, with the faint checkerboard from the home screen's warm-up card. Per Google's guidance it has no device frames, screenshots or badges.
