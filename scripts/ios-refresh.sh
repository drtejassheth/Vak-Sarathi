#!/bin/bash
# Keeps Vāk Sārathī installed and up to date on your iPhone / iPad.
#
# With a free Apple ID, Apple lets a self-installed app open for only 7 days.
# This script (run every few hours by launchd, see scripts/install-ios-autoupdate.sh):
#   - pulls the latest code from GitHub,
#   - rebuilds with a fresh signature when a device's copy expires within 3 days
#     or when the code has changed,
#   - reinstalls on every paired iPhone/iPad it can reach (USB or the same Wi-Fi).
# A device that is locked or away is retried on the next run.
#
# Usage: scripts/ios-refresh.sh [--force]

set -u
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
export DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"

REPO="$(cd "$(dirname "$0")/.." && pwd)"
APPDIR="$REPO/android-app"
BUNDLE_ID="com.drtejas.prompter"
STATE="$HOME/Library/Application Support/VakSarathi"
LOG="$HOME/Library/Logs/VakSarathi-ios-refresh.log"
APP="$APPDIR/ios/build/Build/Products/Release-iphoneos/App.app"
RENEW_BEFORE=$((3 * 24 * 3600))   # renew when less than 3 days remain
FORCE=0; [ "${1:-}" = "--force" ] && FORCE=1

mkdir -p "$STATE/devices"
exec >>"$LOG" 2>&1
log() { echo "$(date '+%Y-%m-%d %H:%M:%S')  $*"; }
notify() { osascript -e "display notification \"$1\" with title \"Vāk Sārathī\"" >/dev/null 2>&1 || true; }

# one run at a time
if ! mkdir "$STATE/lock" 2>/dev/null; then
  if [ -n "$(find "$STATE/lock" -maxdepth 0 -mmin +120 2>/dev/null)" ]; then rmdir "$STATE/lock"; mkdir "$STATE/lock"; else exit 0; fi
fi
trap 'rmdir "$STATE/lock" 2>/dev/null' EXIT

now=$(date +%s)
profile_expiry() {  # epoch seconds when the built app's signature expires (0 if unknown)
  local d; d=$(security cms -D -i "$APP/embedded.mobileprovision" 2>/dev/null | plutil -extract ExpirationDate raw -o - - 2>/dev/null) || { echo 0; return; }
  date -j -u -f "%Y-%m-%dT%H:%M:%SZ" "$d" +%s 2>/dev/null || echo 0
}

# 1. reachable iPhones / iPads
devices=$(xcrun devicectl list devices --json-output /dev/stdout 2>/dev/null | python3 -c '
import json,sys
t=sys.stdin.read(); d=json.loads(t[t.find("{"):])
for x in d.get("result",{}).get("devices",[]):
    hw=x.get("hardwareProperties",{}); cp=x.get("connectionProperties",{}); dp=x.get("deviceProperties",{})
    if hw.get("reality")!="physical" or hw.get("platform")!="iOS": continue
    if cp.get("pairingState")!="paired" or cp.get("tunnelState")=="unavailable": continue
    print(hw.get("udid"), dp.get("name","device").replace(" ","_"))
' 2>/dev/null)
if [ -z "$devices" ]; then exit 0; fi   # nothing nearby; try again next run

# 2. does any reachable device need a new copy?
git -C "$REPO" pull --ff-only -q 2>/dev/null || log "git pull skipped (offline or local changes)"
head=$(git -C "$REPO" rev-parse --short HEAD)
need_any=0
while read -r udid name; do
  read -r dcommit dexp 2>/dev/null <"$STATE/devices/$udid" || { dcommit=none; dexp=0; }
  if [ $FORCE = 1 ] || [ "$dcommit" != "$head" ] || [ $((dexp - now)) -lt $RENEW_BEFORE ]; then need_any=1; fi
done <<<"$devices"
[ $need_any = 0 ] && exit 0

# 3. build (fresh signature if the current one is close to expiring)
built_commit=$(cat "$STATE/build-commit" 2>/dev/null || echo none)
exp=$(profile_expiry)
if [ $FORCE = 1 ] || [ "$built_commit" != "$head" ] || [ $((exp - now)) -lt $RENEW_BEFORE ]; then
  if [ $((exp - now)) -lt $RENEW_BEFORE ]; then
    # remove this app's old provisioning profiles so Xcode issues a new 7-day one
    for dir in "$HOME/Library/Developer/Xcode/UserData/Provisioning Profiles" "$HOME/Library/MobileDevice/Provisioning Profiles"; do
      [ -d "$dir" ] || continue
      for f in "$dir"/*.mobileprovision; do
        [ -f "$f" ] && security cms -D -i "$f" 2>/dev/null | grep -q "\.$BUNDLE_ID<" && rm -f "$f"
      done
    done
  fi
  log "building $head"
  cd "$APPDIR" || exit 1
  if ! { ./prepare-web.sh >/dev/null && npx cap sync ios >/dev/null 2>&1 &&
         xcodebuild -project ios/App/App.xcodeproj -scheme App -configuration Release \
           -destination 'generic/platform=iOS' -derivedDataPath ios/build \
           -allowProvisioningUpdates -allowProvisioningDeviceRegistration build >"$STATE/last-build.log" 2>&1; }; then
    log "BUILD FAILED (see $STATE/last-build.log)"
    notify "Couldn't rebuild for iPhone/iPad. Open Xcode once to check your Apple ID sign-in."
    exit 1
  fi
  echo "$head" >"$STATE/build-commit"
  exp=$(profile_expiry)
  log "built $head, signature valid until $(date -r "$exp" '+%d %b %H:%M')"
fi

# 4. install on each device that needs it
while read -r udid name; do
  read -r dcommit dexp 2>/dev/null <"$STATE/devices/$udid" || { dcommit=none; dexp=0; }
  if [ $FORCE = 0 ] && [ "$dcommit" = "$head" ] && [ $((dexp - now)) -ge $RENEW_BEFORE ]; then continue; fi
  out=$(xcrun devicectl device install app --device "$udid" "$APP" 2>&1)
  if echo "$out" | grep -q "bundleID: $BUNDLE_ID"; then
    echo "$head $exp" >"$STATE/devices/$udid"
    log "installed on $name ($udid), valid until $(date -r "$exp" '+%d %b %H:%M')"
  else
    reason=$(echo "$out" | grep -m1 -E "ERROR|error" | cut -c1-160)
    log "install on $name failed: $reason"
    if [ $((dexp - now)) -lt $((24 * 3600)) ]; then
      notify "Unlock your ${name//_/ } near this Mac so Vāk Sārathī can renew (it stops opening soon)."
    fi
  fi
done <<<"$devices"
exit 0
