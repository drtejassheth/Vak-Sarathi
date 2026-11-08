#!/bin/sh
# Copies the web app (../teleprompter) into www/ and adds Capacitor's bridge script.
set -e
cd "$(dirname "$0")"
rm -rf www
mkdir www
cp -R ../teleprompter/index.html ../teleprompter/manifest.webmanifest ../teleprompter/icons ../teleprompter/voice www/
cp node_modules/@capacitor/core/dist/capacitor.js www/
echo "web assets ready in www/"
