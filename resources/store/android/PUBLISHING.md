# Publishing to Google Play — runbook

Written 2026-10-04 for 1.5.0 (7). Android package: `education.internut.calvinchesstrainer`
(iOS uses `education.internut.chesstrainer`; the two stores don't care that they differ).

## Where things stand

| | |
|---|---|
| Signed release bundle | ✅ `build/app/outputs/bundle/release/app-release.aab`: 1.5.0 (versionCode 7), 548 MB, signed with the upload key |
| Upload script | ✅ `scripts/deploy_play.sh`. Needs a service-account key (step 4) |
| Icon + feature graphic | ✅ `icon-512.png`, `feature-graphic-1024x500.png` (this folder) |
| Screenshots | ⚠️ `phone/` and `tablet/` still show the old 4-card home and only 4 vision drills. Regenerate them before the listing goes out ([README.md](README.md) explains how they were made) |
| Privacy policy | ✅ https://www.internut.education/privacy (the same one the App Store uses). Add a line about the feedback form (see Data safety) |
| Play Console | ✅ The app already exists there, and 1.4 (versionCode 5) was released in July. Steps 0–1 are done, so you're at step 2. The listing's screenshots and text are probably still the 1.4 ones and need refreshing for 1.5.0 |

## The path

0. **Developer account** (one-time; identity checks can take days, so start here)
1. **Create the app** and answer the "Set up your app" questions (one sitting)
2. **Closed test** on the Alpha track. Do the first upload by hand, then keep **12+ testers opted in for 14 days in a row**
3. **Apply for production**, then promote the same build
4. After that, every upload is one command: `./scripts/deploy_play.sh --track …`

Step 2 is required only for **personal** developer accounts created after 13 Nov 2023. Organization accounts skip it.

## 0. Developer account

Go to https://play.google.com/console and sign in with the Google account that should own the app.
The Firebase project `calvin-chess-trainer` lives under dave@internut.education, so putting Play there too keeps everything in one place.

- **Already have an account?** Settings (gear icon) → Developer account → account details show whether it is *Personal* or *Organization*.
  If Calvin is already under **All apps**, skip "Create app" in step 1.
- **New account:** $25, one-time.
  - *Personal:* verify your identity and your contact email and phone.
    Then do the Home-page task **"Verify that you have access to an Android mobile device"**: install the Play Console app on a real Android 10+ phone and sign in.
    This account type needs the 14-day closed test.
  - *Organization:* needs a D-U-N-S number for Internut Education (free from Dun & Bradstreet, but it can take weeks) and verification of the business.
    It skips the closed-test requirement.
    The Apple account is individual (the seller is "DAVID MARKLE"), so there is no existing D-U-N-S number to reuse.

## 1. Create the app and finish setup

Go to **All apps → Create app** and fill it in:
- Name: `Calvin Chess Trainer`
- Default language: English (United States)
- Type: **App**
- Price: **Free**. A free app can never be made paid later.
- Tick both declarations.

Then work through the Dashboard's **Set up your app** list:

| Task | Answer |
|---|---|
| Privacy policy | `https://www.internut.education/privacy` |
| App access | All functionality is available without special access |
| Ads | No, my app does not contain ads |
| Content rating | Category: reference / news / educational. Answer "No" to violence, fear, sexual content, language, controlled substances, crude humour and gambling. Users interact with each other: **No** (the feedback form reaches only you). Shares location: No. Digital purchases: No. Expect Everyone / PEGI 3. |
| Target audience and content | Pick the ages you mean. It's a kids' app, so include the under-13 bands. That puts the app under Google's **Families policy**, and the code already meets it: no ads; no Advertising ID (the `AD_ID` permission is stripped and Analytics' ad-ID collection is off, both checked in the 1.5.0 (7) merged manifest); privacy policy in place. |
| Data safety | See below |
| Advertising ID | No |
| Government apps / Financial features / Health / News | No / None / No / No |
| Store settings | Category **Education**. Contact email is required and shown publicly; your policy already lists privacy@internut.education. Website: https://www.internut.education |
| Store listing | See below |

### Data safety

This is my read of what the app sends. Check the Firebase rows against
[Firebase's own guide](https://firebase.google.com/docs/android/play-data-disclosure), which is the authority on what the SDK collects.

- Collects or shares required data: **Yes**. Encrypted in transit: **Yes**: Firebase and the feedback endpoint both use HTTPS. The app has no accounts.
- **App activity → App interactions:** Firebase Analytics screen views and drill start/finish events. Collected, not shared, required. Purpose: **Analytics**.
- **Device or other IDs:** Firebase's app-instance ID. Collected, not shared, required. Purpose: **Analytics**.
- **App activity → Other user-generated content:** the About screen's feedback message, sent as text only to `secure.passports.com`. Collected, not shared, **optional**. Purpose: **App functionality**.

The privacy policy (updated 2026-02-27) covers Firebase Analytics and COPPA but not the feedback form.
Add a sentence about the form so the policy and the Data safety form agree.

### Store listing (Grow users → Store presence → Main store listing)

- **App name:** Calvin Chess Trainer
- **Short description** (73 of 80 characters): `Fun chess drills for kids: board vision, notation, tactics, and openings.`
- **Full description:** the text below
- **App icon:** `icon-512.png`
- **Feature graphic:** `feature-graphic-1024x500.png`
- **Phone screenshots:** `phone/`
- **7-inch and 10-inch tablet screenshots:** `tablet/`. Use the same files in both slots.
- ⚠️ Regenerate the screenshots first.

The full description is the App Store text brought up to date. The App Store copy still says "four unique drills" and "25+ board themes and 28 piece sets", and the app no longer matches either claim.

```
Master the chessboard from the ground up! Calvin Chess Trainer turns chess fundamentals into short, hands-on drills designed for young learners.

CHESS VISION — eight drills that teach you to see the whole board
• Forks & Skewers: find the square where one piece attacks two targets at once
• Knight Sight: spot every square a knight can reach in one jump
• Knight Flight: steer a knight to its target in the fewest moves
• Pawn Attack: guide a piece safely through a field of enemy pawns
• Find Checks, Find Captures and Hanging Pieces: scan real game positions for every check, every capture and every undefended piece
• Mate in 1: 400 curated checkmate puzzles

CHESS NOTATION — learn the language of chess
• Files, ranks and squares: tap the board and hear each square spoken aloud
• Piece letters: learn the letter for every piece, with a memory trick for each
• Moves: read a move in chess notation and play it on the board, with 500 puzzles from real Lichess games
• Piece Value: decide which side comes out ahead
• Explore at your own pace, Practice to build confidence, or race the clock in a Speed Round

OPENING FUNDAMENTALS
• Play the first moves of a game against the Stockfish chess engine, with an evaluation bar and arrows that show the book moves

BUILT FOR KIDS
• Squares and piece names spoken aloud
• A streak counter that celebrates every 5 in a row
• Personal bests saved on your device
• Hard Mode flips the board to Black's side for an extra challenge
• Available in 10 languages

No ads. No in-app purchases. No account needed. Just chess.

Whether your child is just learning the names of the squares or sharpening their tactical vision, Calvin Chess Trainer makes every drill feel like a game.

From Internut Education.
```

## 2. The closed test (the "beta round")

1. **Open the track.** Go to **Test and release → Testing → Closed testing**, pick "Closed testing - Alpha" and click **Manage track**.
   Its API name is `alpha`, which is what `deploy_play.sh --track alpha` targets. `beta` is the *open* test, which anyone can join.
2. **Countries/regions:** add the countries where your testers live, or all of them.
3. **Testers:** create an email list of Google accounts (Gmail and so on), or point the track at a Google Group so people can join themselves. Add a feedback email.
   - Recruit 15–20 people, not 12. If the opted-in count drops below 12 at any point, the 14-day clock starts over.
   - Every tester needs an Android phone.
   - **Calvin's track uses the Google Group `calvin-chess-trainer-testers@googlegroups.com`.** Testers join at https://groups.google.com/g/calvin-chess-trainer-testers (drop any `/u/N/` from your own browser's URL), then opt in with the track's **Join on the web** link, which has the form `https://play.google.com/apps/testing/education.internut.calvinchesstrainer`.
   - In the group's settings, set *Who can join* to **Anyone can join**, *Who can view members* to **Group managers** (so testers can't see each other's emails), and *Who can post* to **Group managers** (so it can't fill with spam).
4. **Create new release:**
   - **Signing:** keep the default, where Google Play signs the app. The key you hold (`~/calvinchesstrainer-upload-keystore.jks`) becomes the *upload* key.
   - **Upload** `build/app/outputs/bundle/release/app-release.aab`. 548 MB is fine: the Stockfish net is compiled in, and each device downloads about 124 MB.
   - **Release notes:** for example `First release on Google Play.`
   - **Submit:** click **Next → Save**, then **Publishing overview → Send changes for review**. A new app's first review can take several days.
5. **Invite testers.** Once the release is approved, open the Testers tab, click **Copy link** and send it out.
   Each tester opens the link on their phone while signed in with the listed account, taps **Become a tester**, then installs from the Play Store link on that page.
6. **Wait 14 days.** Keep 12+ testers opted in for 14 days in a row.
   Ask them to really use the app and send feedback, because the production application asks about both.

You can ship an update during the test, and it helps the application because it shows you acted on feedback.
Bump the pubspec version, then run `./scripts/deploy_play.sh --track alpha` (once step 4 below is set up).

## 3. Production

After 14 days, **Apply for production** unlocks on the Dashboard.
It asks how you recruited testers, how they used the app, what feedback you got, what you changed, and why the app is ready. Expect an answer in about a week.

Once production access is granted:
1. Go to **Test and release → Production → Create new release → Add from library** and pick `7 (1.5.0)` or a newer build.
2. Add release notes.
3. Click **Next → Save → Send changes for review**.

A staged rollout (for example 20%, then 100%) is optional.

## 4. One-command uploads (service account, one-time)

Use the existing Firebase project; every Firebase project is also a Google Cloud project.

1. **Enable the API.** At https://console.cloud.google.com, open project **calvin-chess-trainer** (signed in as dave@internut.education).
   Go to APIs & Services → Library → **Google Play Android Developer API** → Enable.
2. **Create the service account.** Go to IAM & Admin → Service Accounts → **Create service account** (for example `play-publisher`). Skip the optional role and user-access steps.
3. **Download its key.** Open the account → **Keys → Add key → Create new key → JSON**.
   Move the download to `~/.config/play/play-service-account.json` and run `chmod 600` on it.
   **Never put it inside this repo. The repo is public.**
4. **Invite it to Play Console.** Go to **Users and permissions → Invite new users**, paste the service account's email, then **App permissions → Add app → Calvin Chess Trainer**. Grant:
   - View app information (read-only)
   - Release apps to testing tracks
   - Manage testing tracks and edit tester lists
   - Release to production, but only if the script should push live releases

   Click **Invite user**. It can take several hours, occasionally a day, before the API accepts the new account.
5. **Point the script at the key.** Run `cp scripts/deploy_play.env.example scripts/deploy_play.env`. The default key path already matches step 3.
6. **Test it.** Run `./scripts/deploy_play.sh --no-build --track alpha --validate`. It uploads and validates without releasing anything.

### Every release after that

```bash
# First bump `version:` in pubspec.yaml. The +N is shared with iOS (build_ipa.sh writes it back too).
./scripts/deploy_play.sh --track alpha        # closed test
./scripts/deploy_play.sh --track production   # live; asks you to type "yes"
```

`--draft` creates the release as a draft that you roll out by hand. `--no-build` reuses the last bundle.

## Troubleshooting

- **"Only releases with status draft may be created on draft app":** the app has never had a published release. Do the first one by hand (step 2), or pass `--draft`.
- **403 "The caller does not have permission":** the service-account invite hasn't taken effect yet, or it is missing the app permissions from step 4.
- **"Version code 7 has already been used":** bump the `+N` in pubspec.
- **"…version is lower than Flutter's minimum supported version":** Flutter raises its minimum Gradle, AGP and Kotlin versions over time.
  - As of Flutter 3.47 the minimums are Gradle 8.14, AGP 8.11.1 and Kotlin 2.2.20. `android/` uses exactly these, as PassportsGo does.
  - Flutter already warns that AGP 9, Gradle 9.1 and Kotlin 2.3.20 will be required next.
  - The `android.newDsl=false` and `android.builtInKotlin=false` lines in `android/gradle.properties` are Flutter's own opt-outs for AGP 9. Leave them in place.
- **Lost upload key:** because Google Play signs the app, you can request an upload-key reset under Play Console → Test and release → App integrity. Back up the `.jks` and its password anyway.
