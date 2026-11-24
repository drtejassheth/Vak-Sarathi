#!/bin/bash
# Publishes a new version of Vāk Sārathī.
#   scripts/release.sh 1.5 "What changed in this version"
#
# - bumps the Android version (versionCode +1, versionName = given version)
# - builds the signed APK (needs android-app/keystore/)
# - commits, pushes, and creates GitHub release v<version> with the APK attached
# Installed Android apps find the new release and offer to update.
# iPhones/iPads pick it up through scripts/ios-refresh.sh on this Mac.
set -euo pipefail
VERSION="${1:?usage: scripts/release.sh <version> \"release notes\"}"
NOTES="${2:-Improvements and fixes.}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
GRADLE="$REPO/android-app/android/app/build.gradle"
cd "$REPO"

[ -f android-app/keystore/keystore.properties ] || { echo "Signing key missing (android-app/keystore/)."; exit 1; }
if git rev-parse "v$VERSION" >/dev/null 2>&1; then echo "v$VERSION already exists."; exit 1; fi

code=$(grep -E '^\s*versionCode [0-9]+' "$GRADLE" | grep -oE '[0-9]+')
next=$((code + 1))
sed -i '' -E "s/^([[:space:]]*versionCode )[0-9]+/\1$next/; s/^([[:space:]]*versionName )\"[^\"]*\"/\1\"$VERSION\"/" "$GRADLE"
echo "Version $VERSION (code $next)"

(cd android-app && npm run build:apk >/dev/null)
APK="$REPO/dist/VakSarathi-$VERSION.apk"
cp "$REPO/dist/VakSarathi.apk" "$APK"

git add -A
git commit -q -m "Release v$VERSION

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
git push -q origin main
gh release create "v$VERSION" "$APK" --target main --title "Vāk Sārathī $VERSION" --notes "$NOTES

**Android:** the app offers this update automatically (Settings → Check for updates), or download the APK below.
**iPhone/iPad:** installed automatically from the Mac running scripts/ios-refresh.sh."
echo "Published v$VERSION"
