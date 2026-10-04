#!/usr/bin/env bash
#
# Build the Android App Bundle and upload it to Google Play via fastlane supply.
#
# ---------------------------------------------------------------------------
# ONE-TIME SETUP (all on Google's side — must be done before this script works)
#
#   1. Google Cloud Console -> create/pick a project -> enable the
#      "Google Play Android Developer API".
#   2. Create a Service Account, then Keys -> Add key -> JSON -> download it.
#      Save it OUTSIDE this repo, e.g.  ~/.config/play/play-service-account.json
#   3. Play Console -> Users and permissions -> Invite user -> paste the service
#      account's email -> grant this app "Release to testing tracks" (and
#      "Release to production" if you'll push there).
#   4. Upload the FIRST bundle MANUALLY through the Play Console UI. Google
#      rejects API uploads for an app that has never had a manual release.
#   5. cp scripts/deploy_play.env.example scripts/deploy_play.env
#      and set PLAY_JSON_KEY to your key path.
#
# NOTE: every upload needs a HIGHER versionCode than anything previously
# uploaded. Bump the "+N" in pubspec.yaml (version: 1.4.0+5) before each release.
# ---------------------------------------------------------------------------
#
# Usage:
#   scripts/deploy_play.sh                      # build + upload to internal track
#   scripts/deploy_play.sh --track beta         # closed testing
#   scripts/deploy_play.sh --track production   # live (careful!)
#   scripts/deploy_play.sh --no-build           # reuse the existing .aab
#   scripts/deploy_play.sh --validate           # upload + validate, do NOT release
#   scripts/deploy_play.sh --draft              # create as draft instead of live
#   scripts/deploy_play.sh --dry-run            # print the command, change nothing
#
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO"

TRACK="internal"; DO_BUILD=1; DRY_RUN=0; VALIDATE=0; STATUS="completed"
while [ $# -gt 0 ]; do
  case "$1" in
    --track)     TRACK="${2:?--track needs a value}"; shift 2 ;;
    --track=*)   TRACK="${1#*=}"; shift ;;
    --no-build)  DO_BUILD=0; shift ;;
    --dry-run)   DRY_RUN=1; shift ;;
    --validate)  VALIDATE=1; shift ;;
    --draft)     STATUS="draft"; shift ;;
    --complete)  STATUS="completed"; shift ;;
    -h|--help)   grep '^#' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown option: $1 (try --help)" >&2; exit 2 ;;
  esac
done

# --- config ------------------------------------------------------------------
ENV_FILE="$REPO/scripts/deploy_play.env"
# shellcheck disable=SC1090
[ -f "$ENV_FILE" ] && source "$ENV_FILE"
: "${PLAY_JSON_KEY:?Missing PLAY_JSON_KEY — copy scripts/deploy_play.env.example to scripts/deploy_play.env and set it}"
PLAY_JSON_KEY="${PLAY_JSON_KEY/#\~/$HOME}"
[ -f "$PLAY_JSON_KEY" ] || { echo "Service account key not found: $PLAY_JSON_KEY" >&2; exit 1; }
case "$PLAY_JSON_KEY" in
  "$REPO"/*) echo "WARNING: your service-account key lives inside the repo. Move it out (e.g. ~/.config/play/) so it can never be committed." >&2 ;;
esac

PKG="${PLAY_PACKAGE:-$(grep -o 'applicationId = "[^"]*"' android/app/build.gradle.kts | head -1 | cut -d'"' -f2)}"
[ -n "$PKG" ] || { echo "Could not determine applicationId" >&2; exit 1; }

VER="$(grep -E '^version:' pubspec.yaml | head -1 | awk '{print $2}')"
VNAME="${VER%%+*}"; VCODE="${VER##*+}"

command -v fastlane >/dev/null 2>&1 || export PATH="$HOME/.rbenv/shims:$PATH"
command -v fastlane >/dev/null 2>&1 || { echo "fastlane not found on PATH" >&2; exit 1; }

echo "▸ Package:      $PKG"
echo "▸ Version:      $VNAME (versionCode $VCODE)"
echo "▸ Track:        $TRACK"
echo "▸ Release:      $([ "$VALIDATE" = 1 ] && echo 'validate only (nothing published)' || echo "$STATUS")"
echo "▸ Key:          $PLAY_JSON_KEY"

# --- build -------------------------------------------------------------------
if [ "$DO_BUILD" = 1 ]; then
  echo "▸ Building App Bundle…"
  [ "$DRY_RUN" = 1 ] && echo "  (dry-run) flutter build appbundle" || flutter build appbundle
fi

AAB="$(ls -t "$REPO"/build/app/outputs/bundle/release/*.aab 2>/dev/null | head -1 || true)"
[ -n "$AAB" ] || { echo "No .aab in build/app/outputs/bundle/release/. Run without --no-build." >&2; exit 1; }
echo "▸ Bundle:       $AAB"

# --- upload ------------------------------------------------------------------
cmd=(fastlane supply
     --package_name "$PKG"
     --aab "$AAB"
     --track "$TRACK"
     --json_key "$PLAY_JSON_KEY"
     --release_status "$STATUS"
     --skip_upload_metadata true
     --skip_upload_images true
     --skip_upload_screenshots true
     --skip_upload_changelogs true)
[ "$VALIDATE" = 1 ] && cmd+=(--validate_only true)

if [ "$TRACK" = "production" ] && [ "$VALIDATE" = 0 ] && [ "$DRY_RUN" = 0 ]; then
  echo ""
  read -r -p "!! This publishes to PRODUCTION with status '$STATUS'. Type 'yes' to continue: " ok
  [ "$ok" = "yes" ] || { echo "aborted."; exit 1; }
fi

echo "▸ Uploading to Google Play…"
if [ "$DRY_RUN" = 1 ]; then printf '  (dry-run) %s\n' "${cmd[*]}"; else "${cmd[@]}"; fi

echo "✓ Done. Check Play Console -> Testing/Release for the new build."
echo "  Remember to bump the +N in pubspec.yaml before the next upload."
