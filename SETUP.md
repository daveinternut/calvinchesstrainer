# Developer Setup — Calvin Chess Trainer (macOS)

Complete setup from a clean Mac to running the app on an iOS simulator, an Android
emulator, a physical device, and the web. Follow the steps in order.

Target toolchain (matches the primary dev machine as of 2026-07-23):

| Tool | Version |
|---|---|
| Flutter | **3.35.7** (stable) |
| Dart | 3.9.2 (ships with Flutter) |
| Xcode | 26.6 (16.0 is the practical minimum) |
| CocoaPods | 1.16.2 |
| Android Studio | 2025.1 (Narwhal) or newer |
| Android SDK Platform | **36** (compileSdk/targetSdk 36, minSdk 24) |
| Android Build-Tools | 35.0.1 |
| Android NDK | **27.0.12077973** (required — Stockfish is native C++) |
| CMake | 3.22.1 |
| JDK | 21 (bundled with Android Studio — no separate install) |
| Gradle | 8.12 (via wrapper, auto-downloaded) |
| Android Gradle Plugin | 8.9.1 |
| Kotlin | 2.1.0 |
| iOS deployment target | 15.0 |

Expect **~40 GB** of disk for Xcode + simulator runtimes + Android SDK + Flutter,
and 1–2 hours mostly spent waiting on downloads.

---

## 0. Accounts and access

1. **GitHub account.** The repo is public, so read access needs nothing. To push,
   ask Dave for collaborator access on `daveinternut/calvinchesstrainer`.
2. **Apple ID.** Required to install Xcode and to sign builds for a physical
   iPhone/iPad. A free Apple ID is enough for personal-team device builds.
3. **Apple Developer Program team (optional).** Only needed to build under the
   project's real team (`U2V42G33C3`) or to ship to TestFlight/App Store.
   Simulator work needs none of this — see step 9.

---

## 1. macOS baseline

Confirm macOS 14 (Sonoma) or newer, on Apple Silicon or Intel.

```bash
sw_vers && uname -m
```

`arm64` = Apple Silicon, `x86_64` = Intel. The commands below assume Apple
Silicon; Intel differences are noted where they matter.

Install the Xcode command line tools and Rosetta (Rosetta is Apple Silicon only,
and still needed by some CocoaPods/Ruby native gems):

```bash
xcode-select --install
```

```bash
sudo softwareupdate --install-rosetta --agree-to-license
```

---

## 2. Homebrew

Skip if `brew --version` already works.

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Then follow the "Next steps" the installer prints — on Apple Silicon it tells you
to add Homebrew to your `PATH`:

```bash
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile && eval "$(/opt/homebrew/bin/brew shellenv)"
```

---

## 3. Git

macOS ships Git via the command line tools, but get a current one and set your
identity:

```bash
brew install git
```

```bash
git config --global user.name "Your Name" && git config --global user.email "you@example.com"
```

---

## 4. Flutter SDK — pinned to 3.35.7

Do **not** just grab the newest stable. This project is built and tested against
3.35.7; newer Flutter releases have broken `chessground`/`dartchess` in the past.
Clone the SDK and check out the exact tag:

```bash
mkdir -p ~/development && git clone https://github.com/flutter/flutter.git ~/development/flutter
```

```bash
cd ~/development/flutter && git checkout 3.35.7
```

Add it to your `PATH` (zsh is the macOS default shell):

```bash
echo 'export PATH="$HOME/development/flutter/bin:$PATH"' >> ~/.zshrc && source ~/.zshrc
```

Warm the toolchain — this downloads the Dart SDK and engine artifacts (a few
minutes):

```bash
flutter precache && flutter --version
```

You should see `Flutter 3.35.7 • channel stable` and `Dart 3.9.2`. Also add a
CocoaPods-friendly locale while you're editing `~/.zshrc` (CocoaPods warns
without it):

```bash
echo 'export LANG=en_US.UTF-8' >> ~/.zshrc && source ~/.zshrc
```

> **Alternative:** if you'd rather manage multiple Flutter versions, use
> [FVM](https://fvm.app) (`brew tap leoafarias/fvm && brew install fvm && fvm install 3.35.7`)
> and prefix commands with `fvm`. Avoid `brew install --cask flutter` — it always
> installs the newest stable and its install path goes stale after `flutter upgrade`.

---

## 5. Xcode and iOS simulators

1. Install **Xcode** from the Mac App Store (large — ~10 GB download, budget an
   hour). Xcode 16 or newer; 26.x is what the project is developed on.
2. Launch Xcode once and let it install its additional components.
3. Point the command line tools at the full Xcode and accept the license:

```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer && sudo xcodebuild -license accept
```

4. Install an **iOS simulator runtime**. Xcode 16+ no longer bundles one:

```bash
xcodebuild -downloadPlatform iOS
```

5. Verify a simulator boots:

```bash
open -a Simulator
```

If no device appears, open Xcode → **Window → Devices and Simulators →
Simulators → +** and create an iPhone (any recent model) on the runtime you just
downloaded.

---

## 6. CocoaPods

Required for the iOS build (the project has native pods: Stockfish, Firebase,
just_audio, flutter_tts).

```bash
brew install cocoapods
```

```bash
pod --version
```

Expect 1.16.x or newer. (Use Homebrew, not `sudo gem install` — the system Ruby
route breaks frequently on recent macOS.)

---

## 7. Android Studio and the Android SDK

1. Install Android Studio:

```bash
brew install --cask android-studio
```

2. Launch it and complete the setup wizard (accept the standard install; it
   places the SDK at `~/Library/Android/sdk`).
3. Open **Settings → Languages & Frameworks → Android SDK**.
   - **SDK Platforms** tab → check **Android 16 (API 36)**.
   - **SDK Tools** tab → tick *Show Package Details*, then check:
     - **Android SDK Build-Tools 35.0.1**
     - **NDK (Side by side) → 27.0.12077973** ← required, Stockfish compiles from C++
     - **CMake 3.22.1**
     - **Android SDK Command-line Tools (latest)**
     - **Android Emulator** and **Android SDK Platform-Tools**
   - Apply and let it download.
4. Install the Flutter and Dart plugins: **Settings → Plugins** → search
   "Flutter" → install (it pulls in Dart) → restart.
5. Create an emulator: **Device Manager → Add a new device** → pick a Pixel with
   API 36 → download the system image → Finish.
6. Accept the SDK licenses:

```bash
flutter doctor --android-licenses
```

Press `y` at each prompt. Flutter uses the JDK bundled inside Android Studio
automatically — you do not need a separate `brew install openjdk`.

---

## 8. Verify the toolchain

```bash
flutter doctor -v
```

Every entry should be a green check: Flutter, Android toolchain, Xcode, Chrome,
Android Studio, and your editor. Fix anything flagged before continuing — most
messages tell you the exact command to run.

---

## 9. Clone and build the project

```bash
git clone https://github.com/daveinternut/calvinchesstrainer.git ~/Dev/calvinchesstrainer
```

```bash
cd ~/Dev/calvinchesstrainer && flutter pub get
```

Generate the localizations (10 locales; also runs automatically on build):

```bash
flutter gen-l10n
```

Nothing else is needed to configure Firebase — `android/app/google-services.json`,
`ios/Runner/GoogleService-Info.plist`, and `lib/firebase_options.dart` are all
committed. **Do not run `flutterfire configure`**; it would rewrite them.

The Gradle wrapper (`android/gradlew`, `gradle-wrapper.jar`) is gitignored, but
Flutter injects it on the first Android build, so there's nothing to do.

---

## 10. Run it

List what's available:

```bash
flutter devices
```

**iOS simulator** — the quickest first run:

```bash
open -a Simulator && flutter run
```

**Android emulator** — start it from Android Studio's Device Manager, then:

```bash
flutter run
```

**Web:**

```bash
flutter run -d chrome
```

**Physical iPhone/iPad:** see step 11 first (signing).

The first iOS build runs `pod install` and compiles Stockfish from source, and
the first Android build compiles it via the NDK — both take **5–15 minutes**.
Subsequent builds are fast, and hot reload (`r` in the console) is instant.

---

## 11. iOS signing for a physical device

Simulator builds need no signing. For a real device:

`ios/Runner.xcodeproj/project.pbxproj` hardcodes `DEVELOPMENT_TEAM = U2V42G33C3`
(Dave's team). You will not be able to build to a device with that value unless
Dave adds you to that team. Two options:

**A — Dave adds you to the Apple Developer team** (preferred; keeps the project
file unchanged). Then just plug in the device and run.

**B — Use your own free personal team** (fine for local development):

1. Open the workspace (not the project):

```bash
open ios/Runner.xcworkspace
```

2. Select the **Runner** target → **Signing & Capabilities** → sign in with your
   Apple ID under Team, and pick *Your Name (Personal Team)*.
3. Change the **Bundle Identifier** to something unique to you, e.g.
   `education.internut.chesstrainer.yourname`. A personal team can't claim the
   existing ID.
4. **Do not commit these two changes.** Before committing, run
   `git checkout -- ios/Runner.xcodeproj/project.pbxproj`, or keep them staged
   locally only.

Also: on the device, enable **Settings → Privacy & Security → Developer Mode**,
then trust the developer certificate under **Settings → General → VPN & Device
Management** after the first install.

Note the known ID mismatch: iOS is `education.internut.chesstrainer`, Android is
`education.internut.calvinchesstrainer`. That's a pre-existing issue to reconcile
before store submission, not something to fix during setup.

---

## 12. Editor

Either works; both are already used on this project.

**VS Code** (lightest):

```bash
brew install --cask visual-studio-code
```

Then install the **Flutter** extension (it pulls in Dart). `.vscode/` is not
gitignored, so shared launch configs will show up if any are added.

**Android Studio** works out of the box once the Flutter plugin from step 7 is
installed — open the repo root as the project.

---

## 13. Confirm everything works

```bash
flutter analyze
```

```bash
flutter test
```

`flutter analyze` must be clean before you push — that's the project's bar for
"done". Tests cover the chess-vision engines and the opening book; coverage is
thin overall, so exercising the affected screen with `flutter run` is the real
verification step.

---

## 14. Optional extras

**Firebase CLI** — only if you touch Firebase config (you probably won't;
Analytics is the only live service):

```bash
brew install firebase-cli
```

**Python 3** — only for `scripts/curate_puzzles.py` (regenerates the Lichess
puzzle set) and `scripts/make_feature_graphic.py`:

```bash
brew install python
```

**Android release signing** — `android/key.properties` and the upload keystore
are deliberately not in the repo. Without them, release builds fall back to debug
signing, so `flutter run --release` still works. You only need the real keystore
to produce a Play Store AAB; ask Dave.

---

## 15. Gotchas worth knowing up front

- **Gradle heap.** `android/gradle.properties` requests `-Xmx8G`, needed to sign
  the release AAB. If you have a global `~/.gradle/gradle.properties` with a
  lower `org.gradle.jvmargs` cap, it overrides the project's and release builds
  die with OOM. Comment out any global cap.
- **Release AAB is ~525 MB.** That's Stockfish's NNUE weights, embedded at
  compile time. Not a bug.
- **Don't enable Gradle's configuration cache** — it's incompatible with
  Flutter's Gradle plugin.
- **First builds are slow** because Stockfish compiles from C++ on both
  platforms. Don't kill a build that looks hung at the native step.
- **Generated files you must never hand-edit:** `lib/firebase_options.dart`
  (regenerate with `flutterfire configure`) and `lib/l10n/app_localizations*.dart`
  (regenerate with `flutter gen-l10n`).
- **Adding UI text** means editing all 10 `lib/l10n/app_*.arb` files (template is
  `app_en.arb`), then running `flutter gen-l10n`.
- **No dark theme**, and OS font scaling is disabled — don't be surprised.

---

## 16. Read before writing code

1. **[CLAUDE.md](CLAUDE.md)** — the architecture control panel. Mental model,
   repo map, and a "to do X, start here" task router. Read this in full.
2. **[resources/000 Index.md](resources/000%20Index.md)** — the full code map,
   per-feature file tables, provider graph, and known gaps.
3. **[resources/000 Explanations.md](resources/000%20Explanations.md)** —
   narrative deep dives per subsystem.

The house rule: **when you change code these docs describe, update the doc in the
same commit.**
