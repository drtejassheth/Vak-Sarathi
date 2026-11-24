#!/bin/bash
# Turns on automatic iPhone/iPad renewal on this Mac.
# Keeps a copy of the public GitHub repo in ~/Library/Application Support/VakSarathi
# (macOS doesn't let background jobs read your Desktop/Documents) and runs its
# scripts/ios-refresh.sh at login and every 3 hours.
# Undo with:  scripts/install-ios-autoupdate.sh --remove
set -e
LABEL="com.vaksarathi.ios-refresh"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"
WORK="$HOME/Library/Application Support/VakSarathi"
CLONE="$WORK/repo"
URL="https://github.com/drtejassheth/Vak-Sarathi.git"
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
if [ "${1:-}" = "--remove" ]; then rm -f "$PLIST"; echo "Automatic iPhone/iPad renewal turned off. (The copy in $CLONE can be deleted.)"; exit 0; fi

mkdir -p "$WORK"
if [ -d "$CLONE/.git" ]; then git -C "$CLONE" pull --ff-only -q; else git clone -q "$URL" "$CLONE"; fi
echo "Installing build tools in the background copy (one time)…"
(cd "$CLONE/android-app" && npm ci --silent >/dev/null)
shasum "$CLONE/android-app/package-lock.json" | cut -c1-12 >"$WORK/deps-hash"

mkdir -p "$HOME/Library/LaunchAgents"
cat >"$PLIST" <<PL
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>$LABEL</string>
  <key>ProgramArguments</key><array><string>/bin/bash</string><string>$CLONE/scripts/ios-refresh.sh</string></array>
  <key>RunAtLoad</key><true/>
  <key>StartInterval</key><integer>10800</integer>
  <key>ProcessType</key><string>Background</string>
</dict>
</plist>
PL
launchctl bootstrap "gui/$(id -u)" "$PLIST"
echo "Automatic iPhone/iPad renewal is on (every 3 hours). Log: ~/Library/Logs/VakSarathi-ios-refresh.log"
