# Vāk Sārathī

A teleprompter app for **iPhone, iPad and Android** that works fully offline. One codebase runs three ways: as an installable web app (PWA), as an Android APK, and as a native iOS app.

**Highlights**
- Smooth scrolling with a pace readout, countdown and reading line
- Mirroring for teleprompter glass
- `# sections`, `[PAUSE]` cues, `[notes]` and text formatting in scripts
- Camera behind the text with take recording
- Bluetooth page-turner and keyboard control
- **Offline voice scrolling** (built-in Vosk engine) that follows your speech, makes no system sounds and shares the camera's microphone

The full feature list, script formatting and platform notes are in [teleprompter/README.md](teleprompter/README.md).

## Repository layout

```
teleprompter/          The app: a single-page web app (no build step)
  index.html           all UI + logic
  sw.js, manifest…     offline + install support
  voice/               offline speech engine (vosk.js) + small English model (model-en-us.tgz)
android-app/           Capacitor wrapper that packages teleprompter/ as native apps
  android/             Android Studio project
  ios/                 Xcode project
  prepare-web.sh       copies teleprompter/ into www/ for the native builds
```

## Run / build

**Web (any device):** serve `teleprompter/` over HTTPS (e.g. Netlify, GitHub Pages), open it, and add it to the home screen.

```bash
cd teleprompter && python3 -m http.server 8765
```

**Android APK** (needs Android Studio's JDK and SDK). Output: `dist/VakSarathi.apk`.

```bash
cd android-app && npm install && npm run build:apk
```

Release builds are signed with `android-app/keystore/`, which is **not in this repository**. Keep your own backup. Without the original key, an update can't install over the existing app.

**iOS** (needs Xcode and an Apple ID signed into Xcode). Open `android-app/ios/App/App.xcodeproj`, choose your device and press ▶, or see the command in [teleprompter/README.md](teleprompter/README.md#iphone--ipad-app-native-fully-offline).

```bash
cd android-app && npm install && npm run sync:ios
```

After changing `teleprompter/index.html`, run `npm run sync` (Android) or `npm run sync:ios` before rebuilding.

## Updates

- **Android:** the app checks this repository's latest GitHub release when you open it (at most every 6 hours, and only on the library screen). When a newer version exists it offers **Update now**, downloads the APK and opens Android's installer. Android always asks you to tap Install. You can also check manually in Settings → About → Check for updates.
- **iPhone / iPad:** run `scripts/install-ios-autoupdate.sh` once on the Mac that builds the app. Every 3 hours it looks for your paired iPhone/iPad (USB or the same Wi-Fi), pulls the latest code and reinstalls when the free 7-day signature is under 3 days from expiring or the code has changed. Log: `~/Library/Logs/VakSarathi-ios-refresh.log`. Turn it off with `scripts/install-ios-autoupdate.sh --remove`.
- **Web app:** reloads the latest version whenever it's opened online.

**To publish a new version:**

```bash
scripts/release.sh 1.5 "What changed"
```

This bumps the version, builds the signed APK, pushes and creates the GitHub release.

## Third-party components

- [Capacitor](https://capacitorjs.com) (MIT): native wrapper and plugins
- [vosk-browser](https://github.com/ccoreilly/vosk-browser) (Apache-2.0): `teleprompter/voice/vosk.js`
- [Vosk small English model 0.15](https://alphacephei.com/vosk/models) by Alpha Cephei (Apache-2.0): `teleprompter/voice/model-en-us.tgz`

## License

MIT. See [LICENSE](LICENSE). Third-party components keep their own licences.
