#!/bin/bash
# Turns on automatic iPhone/iPad renewal on this Mac: runs scripts/ios-refresh.sh
# at login and every 3 hours. Undo with:  scripts/install-ios-autoupdate.sh --remove
set -e
LABEL="com.vaksarathi.ios-refresh"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"
SCRIPT="$(cd "$(dirname "$0")" && pwd)/ios-refresh.sh"

launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
if [ "${1:-}" = "--remove" ]; then rm -f "$PLIST"; echo "Automatic iPhone/iPad renewal turned off."; exit 0; fi

chmod +x "$SCRIPT"
mkdir -p "$HOME/Library/LaunchAgents"
cat >"$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>$LABEL</string>
  <key>ProgramArguments</key><array><string>/bin/bash</string><string>$SCRIPT</string></array>
  <key>RunAtLoad</key><true/>
  <key>StartInterval</key><integer>10800</integer>
  <key>ProcessType</key><string>Background</string>
</dict>
</plist>
EOF
launchctl bootstrap "gui/$(id -u)" "$PLIST"
echo "Automatic iPhone/iPad renewal is on (every 3 hours). Log: ~/Library/Logs/VakSarathi-ios-refresh.log"
