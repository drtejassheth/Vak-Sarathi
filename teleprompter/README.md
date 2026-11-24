# Vāk Sārathī: a teleprompter for iPhone, iPad and Android

A single installable web app (PWA). One codebase runs on all three platforms, installs to the home screen, opens full-screen and works offline. There are no build steps and no dependencies.

```
teleprompter/
├── index.html            the whole app (UI + logic)
├── manifest.webmanifest  install metadata (name, icons, colours)
├── sw.js                 offline cache
└── icons/                home-screen icons (iOS + Android)
```

## Features

**Scripts**
- Library with search, word count, estimated read time, duplicate, delete with undo
- Editor with autosave, word/character stats and one-tap formatting buttons
- Import `.txt` / `.md` files; export a script as `.txt`; back up and restore everything as `.json`
- Saved on the device (nothing is uploaded anywhere)

**Prompting**
- Smooth scrolling with eased start and stop; speed from 0.5 to 40 with a live words-per-minute readout
- 3-2-1 countdown (0–10 s)
- Reading line with arrows, adjustable position, and dimming of text away from the line
- Tap to play/pause, drag to scroll, flick to coast, pinch to resize text
- Progress bar you can drag to seek; elapsed time and time remaining
- Section headings (`# Title`) with a jump-to-section list
- `[PAUSE]` cues that stop the scroll; `[notes]` shown in a different colour
- Bold, highlight and italic text; ALL CAPS option; right-to-left scripts
- Text size, line spacing, text width, 6 fonts, alignment, 6 colour themes plus custom colours
- Horizontal and vertical mirroring for beam-splitter teleprompter glass
- Loop at end; screen stays awake while prompting; full screen (Android/iPad)

**Voice scrolling.** The script follows your voice as you read, at your own pace.
- **Built-in offline engine** (Vosk, English) runs inside the app. No system beeps, no internet, and it listens on the same microphone stream the camera records, so it never interrupts a recording.
- **Recognition is limited to your script's words**, which makes it very accurate. It understands numbers ("2024" = "twenty twenty-four").
- **Smooth motion:** the text glides along each line at your measured speaking pace, holds still when you pause, and picks up again when you resume. Ad-libs are ignored, and if you skip ahead or go back a paragraph it finds you again.
- **Other languages** (Hindi, Gujarati, Marathi, Tamil, Telugu, Bengali and more) use the phone's speech service. Choose it under Settings → Voice engine. That service can beep between phrases on Android.
- Engine files: `voice/vosk.js` (Apache-2.0) and `voice/model-en-us.tgz` (Vosk small English model, Apache-2.0). They add about 46 MB.

**Camera and recording**
- Front or back camera live behind the text, with adjustable darkening
- Record takes with sound; the prompter starts automatically when you hit record
- Save to Photos/Files (iOS), share or download (Android)

**Remotes and keyboards.** Bluetooth page-turner remotes and keyboards work out of the box:

| Key | Action |
|---|---|
| Space / Enter | Play / pause |
| ↑ / ↓ | Faster / slower |
| ← / → or PgUp / PgDn | Back / forward one line |
| Home / End | Start / end |
| + / − | Text size |
| M / V | Mirror horizontal / vertical |
| S · C · R | Voice · camera · record |
| L · F · , | Sections · full screen · settings |

## Script formatting

```
# Section title        → heading you can jump to
[PAUSE]                → scrolling stops here
[smile, slow down]     → note to yourself (not read aloud)
**bold**  ==highlight==  _italic_
(blank line)           → new paragraph
```

## Putting it on your devices

The camera, microphone and offline install all require **HTTPS**, so host the folder somewhere that serves HTTPS. Any static host works, and all of these are free:

- **Netlify Drop** (easiest, about 1 minute): open https://app.netlify.com/drop and drag the `teleprompter` folder onto the page. You get an `https://….netlify.app` link.
- **GitHub Pages**, **Cloudflare Pages** or **Vercel**: upload the folder as a static site.

Then open the link on each device:

- **iPhone / iPad (Safari):** Share button → **Add to Home Screen**.
- **Android (Chrome):** tap **Install** in the app's header, or ⋮ menu → **Install app**. (Or use the APK below.)

From then on it opens like a native app, with no browser bars, and works without internet.

### iPhone / iPad: fully offline, including voice scrolling

1. Open the HTTPS link in **Safari** and tap **Share → Add to Home Screen**.
2. Open **Vāk Sārathī from the Home Screen icon** once while on Wi-Fi and leave it open for about a minute. It saves the voice engine (46 MB) in the background.
3. To check, open a script → Settings → Voice scrolling. **Offline voice engine** should say *"Saved on this device — works offline ✓"*. If it says *Not saved yet*, tap **Save**.

After that, everything works in flight mode. On iPhone/iPad the app uses the built-in offline engine for English by default. Other languages use Apple's speech service, which needs internet.

The Home Screen app keeps its scripts separately from Safari tabs. To move scripts, use Backup in one, then Import in the other.

**Try it on this Mac first:**

```bash
cd teleprompter && python3 -m http.server 8765
```

Then open http://localhost:8765. The camera and microphone work on `localhost` too.

## Android app (APK, fully offline)

`android-app/` wraps this same `index.html` into a native Android app with Capacitor. All files are inside the APK, including the offline voice engine, so it never needs internet. Inside the app, recordings save to `Movies/Vak Sarathi`, backups and exports save to `Documents/Vak Sarathi`, and full screen hides the status and navigation bars.

**Install:** copy `dist/VakSarathi.apk` to the phone (or download it there), tap it, and allow "Install unknown apps" for the app you opened it from.

**Rebuild after changing `teleprompter/index.html`:** raise `versionCode` in `android-app/android/app/build.gradle` (so it installs over the old version), then run:

```bash
cd android-app && npm run build:apk
```

This writes a new `dist/VakSarathi.apk`. The signing key is in `android-app/keystore/`. **Back it up**: updates must be signed with the same key, or you'd have to uninstall first, which deletes your scripts.

## iPhone / iPad app (native, fully offline)

`android-app/ios/` is the native iOS build of the same app, made with Capacitor. The voice engine is inside the app, so everything works without internet. It's signed with the free Apple ID team set in Xcode (bundle ID `com.drtejas.prompter`).

**Install or reinstall** (phone plugged into this Mac, unlocked, Developer Mode on):

```bash
cd android-app && npm run sync:ios && xcodebuild -project ios/App/App.xcodeproj -scheme App -configuration Release -destination 'id=<DEVICE-ID>' -derivedDataPath ios/build -allowProvisioningUpdates -allowProvisioningDeviceRegistration build && xcrun devicectl device install app --device <DEVICE-ID> ios/build/Build/Products/Release-iphoneos/App.app
```

Or open `android-app/ios/App/App.xcodeproj` in Xcode, pick the iPhone at the top, and press ▶.

- **First install only:** on the phone, go to Settings → General → VPN & Device Management → your Apple Development account → **Trust**.
- **Free Apple ID:** Apple stops the app opening after **7 days**. Reinstall with the command above; your scripts are kept. A paid Apple Developer account ($99/yr) extends this to a year and allows TestFlight and the App Store.
- Find `<DEVICE-ID>` with `xcrun devicectl list devices`. For an iPad, enable Developer Mode the same way.
- **Automatic renewal:** `scripts/install-ios-autoupdate.sh` sets this Mac to reinstall the latest version every few days (see the main README).

## Updating the app

After changing any file, bump `CACHE = 'prompter-v1'` in `sw.js` (to `v2` and so on) and re-upload. Installed copies pick up the update the next time they're opened online.

## Platform notes

- **Voice scrolling** uses the device's speech recognition: Safari on iOS 14.5+ and Chrome on Android. On iOS it may need internet. On some iPhones the mic can't be used for voice scrolling and video recording at the same time; use speed scrolling while recording if that happens.
- **Full screen:** iPhone Safari has no full-screen API. Installing to the Home Screen gives you the full-screen view.
- **Recordings** are MP4 on iOS and MP4 or WebM on Android, depending on the device.
- **Storage:** scripts live in the browser's storage on each device. Use the back-up button now and then, and import that file to move scripts to another device.

## Possible next steps

- **App Store / Play Store builds:** wrap this folder with [Capacitor](https://capacitorjs.com) (`npx cap add ios` / `android`). Publishing needs an Apple developer account ($99/yr) and a Google Play account ($25 one-time).
- **Phone-as-remote** (control the iPad prompter from your phone): needs a small relay server.
- **Cloud sync** of scripts between devices.
- **.docx / Google Docs import.**
