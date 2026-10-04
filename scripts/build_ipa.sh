#!/usr/bin/env bash
#
# One command to ship Calvin Chess Trainer to the App Store (via TestFlight):
#
#   1. Finds your App Store Connect API key (scripts/build_ipa.env).
#   2. Asks App Store Connect, read-only, for the app record, the highest build
#      number already uploaded and which versions are already approved — then
#      picks the next build number, and stops early if the version is closed.
#   3. Runs flutter analyze + flutter test.
#   4. flutter build ipa --release  (App Store export, automatic signing; if
#      Xcode isn't signed in, retries the export using the API key instead).
#   5. Uploads the .ipa with `xcrun altool` and writes the build number it used
#      back into pubspec.yaml (version: X.Y.Z+N) — commit that change.
#
#   Then the build appears in App Store Connect -> TestFlight once Apple has
#   processed it (5–15 min). Submitting it for review happens in App Store
#   Connect (see "Releasing" in README.md).
#
# One-time setup:
#   1. App Store Connect -> Users and Access -> Integrations -> App Store Connect
#      API -> Team Keys -> "+": a key with "App Manager" access. Download
#      AuthKey_<KEYID>.p8 (Apple lets you download it only once).
#   2. mkdir -p ~/.appstoreconnect/private_keys
#      mv ~/Downloads/AuthKey_<KEYID>.p8 ~/.appstoreconnect/private_keys/
#      chmod 600 ~/.appstoreconnect/private_keys/AuthKey_<KEYID>.p8
#      Never put the key inside this repo (it is public on GitHub).
#   3. cp scripts/build_ipa.env.example scripts/build_ipa.env   (gitignored)
#      and fill in ASC_KEY_ID and ASC_ISSUER_ID.
#   4. Xcode -> Settings -> Accounts: signed in with an Apple ID on the
#      Internut team (U2V42G33C3), so automatic signing can make the
#      distribution certificate/profile.
#
# Usage:
#   scripts/build_ipa.sh                     # check, test, build, upload
#   scripts/build_ipa.sh --check             # only verify key + App Store Connect state
#   scripts/build_ipa.sh --no-upload         # build the .ipa only
#   scripts/build_ipa.sh --skip-tests        # skip flutter analyze/test
#   scripts/build_ipa.sh --build-name 1.5.0  # override the version (default: pubspec)
#   scripts/build_ipa.sh --build-number 12   # override the build number
#   scripts/build_ipa.sh --wait              # after uploading, wait for Apple's processing
#   scripts/build_ipa.sh --dry-run           # print the plan; no network, build or upload
#   Any other argument is passed through to `flutter build ipa`.
#
set -euo pipefail

# macOS's python3 refuses to start under some locale settings (e.g. LC_ALL=en_US
# without an encoding); UTF-8 mode sidesteps the locale entirely.
export PYTHONUTF8=1

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO"

# Keys that were exposed and must never be used again.
REVOKED_KEY_IDS=(SBLPQJZA2Q)

DO_CHECK_ONLY=0; DO_UPLOAD=1; DO_TESTS=1; DO_WAIT=0; DRY_RUN=0
BUILD_NAME_OVERRIDE=""; BUILD_NUMBER_OVERRIDE=""
FLUTTER_ARGS=()
while [ $# -gt 0 ]; do
  case "$1" in
    --check)          DO_CHECK_ONLY=1; shift ;;
    --no-upload)      DO_UPLOAD=0; shift ;;
    --skip-tests)     DO_TESTS=0; shift ;;
    --wait)           DO_WAIT=1; shift ;;
    --dry-run)        DRY_RUN=1; shift ;;
    --build-name)     BUILD_NAME_OVERRIDE="${2:?--build-name needs a value}"; shift 2 ;;
    --build-name=*)   BUILD_NAME_OVERRIDE="${1#*=}"; shift ;;
    --build-number)   BUILD_NUMBER_OVERRIDE="${2:?--build-number needs a value}"; shift 2 ;;
    --build-number=*) BUILD_NUMBER_OVERRIDE="${1#*=}"; shift ;;
    -h|--help)        sed -n '2,/^set -euo/p' "$0" | sed '$d' | sed 's/^# \{0,1\}//'; exit 0 ;;
    *)                FLUTTER_ARGS+=("$1"); shift ;;
  esac
done

say()  { printf '▸ %s\n' "$*"; }
warn() { printf '⚠ %s\n' "$*" >&2; }
die()  { printf '✗ %s\n' "$*" >&2; exit 1; }

# --- config ------------------------------------------------------------------
ENV_FILE="${ASC_ENV_FILE:-$REPO/scripts/build_ipa.env}"
[ -f "$ENV_FILE" ] || [ -n "${ASC_ENV_FILE:-}" ] || ENV_FILE="$REPO/scripts/upload_ios.env"   # older name
# shellcheck disable=SC1090
[ -f "$ENV_FILE" ] && source "$ENV_FILE"
# The variable names PassportsGo's build_ipa.sh uses work too.
ASC_KEY_ID="${ASC_KEY_ID:-${APPSTORE_API_KEY_ID:-}}"
ASC_ISSUER_ID="${ASC_ISSUER_ID:-${APPSTORE_API_ISSUER_ID:-}}"

need_key=$(( DO_UPLOAD || DO_CHECK_ONLY ))

# --- app identity, from the project itself -----------------------------------
PBXPROJ="$REPO/ios/Runner.xcodeproj/project.pbxproj"
BUNDLE_ID="$(grep -E 'PRODUCT_BUNDLE_IDENTIFIER = ' "$PBXPROJ" | grep -v RunnerTests \
  | head -1 | sed -E 's/.*= *"?([^";]+)"?;.*/\1/')"
TEAM_ID="$(grep -E 'DEVELOPMENT_TEAM = ' "$PBXPROJ" | head -1 | sed -E 's/.*= *"?([^";]+)"?;.*/\1/')"
PUBSPEC_VERSION="$(grep -E '^version:' pubspec.yaml | head -1 | awk '{print $2}')"
PUBSPEC_NAME="${PUBSPEC_VERSION%%+*}"
PUBSPEC_NUMBER="${PUBSPEC_VERSION#*+}"
[ "$PUBSPEC_NUMBER" != "$PUBSPEC_VERSION" ] || PUBSPEC_NUMBER=1
BUILD_NAME="${BUILD_NAME_OVERRIDE:-$PUBSPEC_NAME}"

say "App:          $BUNDLE_ID  (team $TEAM_ID)"
say "pubspec:      $PUBSPEC_VERSION"

# --- the API key ---------------------------------------------------------------
KEY_FILE=""
if [ "$need_key" = 1 ]; then
  [ -n "$ASC_ISSUER_ID" ] || die "ASC_ISSUER_ID is not set. cp scripts/build_ipa.env.example scripts/build_ipa.env and fill it in (see the header of this script)."
  KEY_DIRS=("$HOME/.appstoreconnect/private_keys" "$HOME/private_keys" "$HOME/.private_keys" "$REPO/private_keys")
  if [ -n "${ASC_KEY_FILE:-}" ]; then
    KEY_FILE="${ASC_KEY_FILE/#\~/$HOME}"
    [ -n "$ASC_KEY_ID" ] || { ASC_KEY_ID="$(basename "$KEY_FILE" .p8)"; ASC_KEY_ID="${ASC_KEY_ID#AuthKey_}"; }
  elif [ -n "$ASC_KEY_ID" ]; then
    for d in "${KEY_DIRS[@]}"; do
      [ -f "$d/AuthKey_${ASC_KEY_ID}.p8" ] && { KEY_FILE="$d/AuthKey_${ASC_KEY_ID}.p8"; break; }
    done
    [ -n "$KEY_FILE" ] || die "AuthKey_${ASC_KEY_ID}.p8 not found in: ${KEY_DIRS[*]}"
  else
    die "ASC_KEY_ID is not set in $ENV_FILE. (Several teams' keys can live in ~/.appstoreconnect/private_keys, so the script won't guess.)"
  fi
  [ -f "$KEY_FILE" ] || die "Key file not found: $KEY_FILE"

  for revoked in "${REVOKED_KEY_IDS[@]}"; do
    [ "$ASC_KEY_ID" != "$revoked" ] || die "Key $revoked was exposed on GitHub and must be revoked. Create a new key (see the header of this script)."
  done
  case "$(cd "$(dirname "$KEY_FILE")" && pwd)/" in
    "$REPO"/*)
      if git ls-files --error-unmatch "$KEY_FILE" >/dev/null 2>&1; then
        die "$KEY_FILE is tracked by git — this repo is public. Move the key to ~/.appstoreconnect/private_keys/ and untrack it."
      fi
      warn "The key lives inside the repo ($KEY_FILE). It's gitignored, but ~/.appstoreconnect/private_keys/ is safer."
      ;;
  esac
  say "API key:      $ASC_KEY_ID  ($KEY_FILE)"
  say "Issuer:       ${ASC_ISSUER_ID:0:8}…"
fi

# --- App Store Connect API (read-only) -----------------------------------------
# A short-lived ES256 token with exactly the fields Apple documents
# (iss, iat, exp ≤ 20 min, aud). openssl signs; python converts the DER
# signature to the raw r||s form JWT needs.
asc_jwt() {
  python3 - "$ASC_KEY_ID" "$ASC_ISSUER_ID" "$KEY_FILE" <<'PY'
import base64, json, subprocess, sys, time
kid, iss, key = sys.argv[1:4]
def b64(data): return base64.urlsafe_b64encode(data).rstrip(b"=").decode()
now = int(time.time())
head = b64(json.dumps({"alg": "ES256", "kid": kid, "typ": "JWT"}, separators=(",", ":")).encode())
body = b64(json.dumps({"iss": iss, "iat": now - 30, "exp": now + 15 * 60,
                       "aud": "appstoreconnect-v1"}, separators=(",", ":")).encode())
der = subprocess.run(["openssl", "dgst", "-sha256", "-sign", key],
                     input=f"{head}.{body}".encode(), capture_output=True, check=True).stdout
def integer(buf, i):  # DER INTEGER -> 32 big-endian bytes
    assert buf[i] == 0x02, "unexpected DER"
    n = buf[i + 1]
    return buf[i + 2:i + 2 + n].lstrip(b"\0").rjust(32, b"\0"), i + 2 + n
r, i = integer(der, 2)   # skip SEQUENCE tag + (short-form) length
s, _ = integer(der, i)
print(f"{head}.{body}.{b64(r + s)}")
PY
}

ASC_BODY=""; ASC_ERROR=""
asc_get() {  # $1 = path+query; sets ASC_BODY; returns 0 on HTTP 200
  local out code
  out="$(curl -sS -g -w $'\n%{http_code}' -H "Authorization: Bearer $JWT" \
    "https://api.appstoreconnect.apple.com$1")" || { ASC_ERROR="network error"; return 1; }
  code="${out##*$'\n'}"; ASC_BODY="${out%$'\n'*}"
  [ "$code" = 200 ] || { ASC_ERROR="HTTP $code: $(printf '%s' "$ASC_BODY" | head -c 400)"; return 1; }
}

APP_ID=""; LATEST_BUILD=""; CLOSED_VERSIONS=""; LIVE_VERSION=""
if [ "$need_key" = 1 ] && [ "$DRY_RUN" = 0 ]; then
  say "Asking App Store Connect about ${BUNDLE_ID}…"
  JWT="$(asc_jwt)" || die "Could not sign a token with $KEY_FILE (is it a valid .p8?)."

  if ! asc_get "/v1/apps?filter[bundleId]=$BUNDLE_ID&fields[apps]=name,bundleId&limit=1"; then
    case "$ASC_ERROR" in
      "HTTP 401"*) die "App Store Connect rejected the key (revoked key, wrong ASC_ISSUER_ID, or the wrong .p8). $ASC_ERROR" ;;
      *REQUIRED_AGREEMENTS*) die "The key works, but Apple is blocking App Store Connect until the team's Account Holder accepts an updated agreement or renews the membership. Sign in at https://appstoreconnect.apple.com/business (Agreements) and https://developer.apple.com/account (Membership), accept/renew, then run this again." ;;
      *) die "App Store Connect request failed. $ASC_ERROR" ;;
    esac
  fi
  read -r APP_ID APP_NAME < <(printf '%s' "$ASC_BODY" | python3 -c '
import json, sys
d = json.load(sys.stdin).get("data", [])
print(d[0]["id"], d[0]["attributes"]["name"]) if d else print("")')
  [ -n "$APP_ID" ] || die "No App Store Connect app with bundle ID $BUNDLE_ID is visible to key $ASC_KEY_ID. Either the app record doesn't exist yet (App Store Connect -> Apps -> + -> New App, bundle ID $BUNDLE_ID), or this key belongs to a different team."
  say "App record:   $APP_NAME  (Apple ID $APP_ID)"

  # Highest build number ever uploaded (expired and invalid builds still count).
  if asc_get "/v1/builds?filter[app]=$APP_ID&sort=-uploadedDate&limit=200&fields[builds]=version,uploadedDate,processingState"; then
    read -r LATEST_BUILD LATEST_INFO < <(printf '%s' "$ASC_BODY" | python3 -c '
import json, sys
builds = json.load(sys.stdin).get("data", [])
def key(v):
    return tuple(int(p) if p.isdigit() else 0 for p in v.split("."))
if builds:
    top = max(builds, key=lambda b: key(b["attributes"]["version"]))
    a = top["attributes"]
    print(a["version"], "(uploaded %s, %s)" % (a.get("uploadedDate", "?")[:10],
                                               a.get("processingState", "?")))
else:
    print("")')
    if [ -n "$LATEST_BUILD" ]; then say "Last build:   $LATEST_BUILD $LATEST_INFO"; else say "Last build:   none uploaded yet"; fi
  else
    warn "Couldn't list builds ($ASC_ERROR); falling back to the pubspec build number."
  fi

  # Versions Apple has already approved can't take new builds.
  if asc_get "/v1/apps/$APP_ID/appStoreVersions?filter[platform]=IOS&limit=50&fields[appStoreVersions]=versionString,appStoreState,appVersionState"; then
    read -r LIVE_VERSION CLOSED_VERSIONS < <(printf '%s' "$ASC_BODY" | python3 -c '
import json, sys
closed_states = {"READY_FOR_SALE", "READY_FOR_DISTRIBUTION", "PENDING_DEVELOPER_RELEASE",
                 "PENDING_APPLE_RELEASE", "PROCESSING_FOR_APP_STORE", "PROCESSING_FOR_DISTRIBUTION",
                 "ACCEPTED", "REPLACED_WITH_NEW_VERSION", "REMOVED_FROM_SALE",
                 "DEVELOPER_REMOVED_FROM_SALE"}
live_states = {"READY_FOR_SALE", "READY_FOR_DISTRIBUTION"}
def vkey(s):
    return tuple(int(p) if p.isdigit() else 0 for p in s.split("."))
live, closed = None, []
for v in json.load(sys.stdin).get("data", []):
    a = v["attributes"]
    states = {a.get("appStoreState"), a.get("appVersionState")}
    if states & closed_states: closed.append(a["versionString"])
    # Every past release keeps a "ready for sale" state; the live one is the highest.
    if states & live_states and (live is None or vkey(a["versionString"]) > vkey(live)):
        live = a["versionString"]
print(live or "-", ",".join(closed))')
    say "Live version: ${LIVE_VERSION/-/none yet}"
  else
    warn "Couldn't list App Store versions ($ASC_ERROR)."
  fi
fi

ver_gt() {  # ver_gt A B: is dotted version A greater than B?
  python3 -c '
import sys
a, b = (tuple(int(x) for x in v.split(".")) for v in sys.argv[1:3])
sys.exit(0 if a > b else 1)' "$1" "$2"
}

case ",$CLOSED_VERSIONS," in
  *",$BUILD_NAME,"*)
    die "Version $BUILD_NAME is already approved on the App Store, so Apple won't take new builds for it. Bump the version in pubspec.yaml (e.g. version: ${BUILD_NAME%.*}.$(( ${BUILD_NAME##*.} + 1 ))+$PUBSPEC_NUMBER) or pass --build-name." ;;
esac
if [ -n "$LIVE_VERSION" ] && [ "$LIVE_VERSION" != "-" ] && ! ver_gt "$BUILD_NAME" "$LIVE_VERSION"; then
  die "Version $BUILD_NAME must be higher than the live version $LIVE_VERSION. Bump it in pubspec.yaml or pass --build-name."
fi

# --- build number: never reuse one Apple has seen ------------------------------
if [ -n "$BUILD_NUMBER_OVERRIDE" ]; then
  BUILD_NUMBER="$BUILD_NUMBER_OVERRIDE"
  if [ -n "$LATEST_BUILD" ] && [[ "$LATEST_BUILD" =~ ^[0-9]+$ ]] && [ "$BUILD_NUMBER" -le "$LATEST_BUILD" ]; then
    die "--build-number $BUILD_NUMBER is not higher than the last uploaded build ($LATEST_BUILD)."
  fi
else
  BUILD_NUMBER="$PUBSPEC_NUMBER"
  if [ -n "$LATEST_BUILD" ] && [[ "$LATEST_BUILD" =~ ^[0-9]+$ ]] && [ "$BUILD_NUMBER" -le "$LATEST_BUILD" ]; then
    BUILD_NUMBER=$(( LATEST_BUILD + 1 ))
  fi
fi
say "Will build:   $BUILD_NAME ($BUILD_NUMBER)"

if [ "$DO_CHECK_ONLY" = 1 ]; then
  echo "✓ Key works and App Store Connect is ready for $BUILD_NAME ($BUILD_NUMBER)."
  exit 0
fi

if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
  warn "Uncommitted changes — this build includes them. Commit first if you want the build to match a commit."
fi

run() {  # print (issuer ID shortened), then run unless --dry-run
  local shown="$*"
  [ -z "$ASC_ISSUER_ID" ] || shown="${shown//$ASC_ISSUER_ID/${ASC_ISSUER_ID:0:8}…}"
  printf '  $ %s\n' "$shown"
  [ "$DRY_RUN" = 1 ] || "$@"
}

# --- checks --------------------------------------------------------------------
if [ "$DO_TESTS" = 1 ]; then
  say "Analyzing and testing…"
  run flutter analyze --no-fatal-infos
  run flutter test
fi

# --- build -------------------------------------------------------------------
START_TS="$(date +%s)"
say "Building the App Store .ipa…"
build_ok=1
run flutter build ipa --release --export-method app-store \
  --build-name "$BUILD_NAME" --build-number "$BUILD_NUMBER" \
  ${FLUTTER_ARGS[@]+"${FLUTTER_ARGS[@]}"} || build_ok=0

ARCHIVE="$REPO/build/ios/archive/Runner.xcarchive"
newest_ipa() { ls -t "$REPO"/build/ios/ipa/*.ipa 2>/dev/null | head -1 || true; }
fresh() { [ -e "$1" ] && [ "$(stat -f %m "$1")" -ge "$START_TS" ]; }

if [ "$DRY_RUN" = 0 ] && { [ "$build_ok" = 0 ] || ! fresh "$(newest_ipa)"; }; then
  # Flutter archives first and exports second; export is where missing
  # distribution certificates/profiles bite. Retry it with the API key, which
  # lets Xcode create them in the cloud without an Xcode account sign-in.
  if fresh "$ARCHIVE" && [ -n "$KEY_FILE" ]; then
    warn "The export step failed; retrying it with the App Store Connect API key…"
    EXPORT_PLIST="$(mktemp -d)/ExportOptions.plist"
    cat > "$EXPORT_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>method</key><string>app-store-connect</string>
  <key>teamID</key><string>$TEAM_ID</string>
  <key>signingStyle</key><string>automatic</string>
  <key>destination</key><string>export</string>
  <key>uploadSymbols</key><true/>
</dict>
</plist>
PLIST
    EXPORT_LOG="$(dirname "$EXPORT_PLIST")/export.log"
    if ! xcodebuild -exportArchive -archivePath "$ARCHIVE" -exportPath "$REPO/build/ios/ipa" \
      -exportOptionsPlist "$EXPORT_PLIST" -allowProvisioningUpdates \
      -authenticationKeyPath "$KEY_FILE" -authenticationKeyID "$ASC_KEY_ID" \
      -authenticationKeyIssuerID "$ASC_ISSUER_ID" 2>&1 | tee "$EXPORT_LOG"; then :; fi
    if [ -z "$(newest_ipa)" ] || ! fresh "$(newest_ipa)"; then
      if grep -q "Cloud signing permission error" "$EXPORT_LOG"; then
        die "Signing failed: Xcode isn't signed in to an Apple ID, and this API key (App Manager) isn't allowed to use Apple's cloud-managed distribution certificates. Fix: Xcode -> Settings -> Accounts -> + -> Apple ID, sign in with the Apple ID on team $TEAM_ID (Account Holder/Admin), then run this again. (Alternatives: install a local Apple Distribution certificate, or use an Admin-role API key.)"
      fi
      die "Signing failed. Open ios/Runner.xcworkspace in Xcode, sign in under Settings -> Accounts with an Apple ID on team $TEAM_ID, check Runner -> Signing & Capabilities (Automatically manage signing), then run this again."
    fi
  else
    die "flutter build ipa failed (see above)."
  fi
fi

IPA="$(newest_ipa)"
if [ "$DRY_RUN" = 0 ]; then
  [ -n "$IPA" ] && fresh "$IPA" || die "No new .ipa in build/ios/ipa/."
  say "IPA:          $IPA"
fi

if [ "$DO_UPLOAD" = 0 ]; then
  echo "✓ Built $BUILD_NAME ($BUILD_NUMBER) — not uploaded (--no-upload)."
  exit 0
fi

# --- upload --------------------------------------------------------------------
AUTH=(--apiKey "$ASC_KEY_ID" --apiIssuer "$ASC_ISSUER_ID")
# altool finds AuthKey_<id>.p8 in the standard folders by itself; only point it
# at a key kept somewhere else.
case "$(dirname "$KEY_FILE")" in
  "$HOME/.appstoreconnect/private_keys"|"$HOME/private_keys"|"$HOME/.private_keys"|"$REPO/private_keys") ;;
  *) AUTH+=(--p8-file-path "$KEY_FILE") ;;
esac
say "Uploading to App Store Connect…"
run xcrun altool --upload-app -f "${IPA:-build/ios/ipa/<app>.ipa}" -t ios "${AUTH[@]}"

if [ "$DRY_RUN" = 0 ] && { [ "$BUILD_NUMBER" != "$PUBSPEC_NUMBER" ] || [ "$BUILD_NAME" != "$PUBSPEC_NAME" ]; }; then
  sed -i '' -E "s/^version: .*/version: ${BUILD_NAME}+${BUILD_NUMBER}/" pubspec.yaml
  say "pubspec.yaml is now version: ${BUILD_NAME}+${BUILD_NUMBER} — commit it."
fi

if [ "$DO_WAIT" = 1 ] && [ -n "$APP_ID" ]; then
  say "Waiting for Apple to finish processing…"
  run xcrun altool --build-status --apple-id "$APP_ID" --bundle-version "$BUILD_NUMBER" \
    --bundle-short-version-string "$BUILD_NAME" --platform ios --wait "${AUTH[@]}"
fi

if [ "$DRY_RUN" = 1 ]; then
  echo "✓ Dry run — nothing was built or uploaded."
  exit 0
fi
echo "✓ Uploaded $BUILD_NAME ($BUILD_NUMBER)."
echo "  Next: App Store Connect -> Apps -> ${APP_NAME:-the app} -> TestFlight shows it once processed"
echo "  (5–15 min). To release it: App Store tab -> the $BUILD_NAME version -> pick this build"
echo "  -> fill in What's New -> Add for Review -> Submit."
