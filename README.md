# Just Wait 🎣

> A fisherman's patience for your attention span.

---

## What it does

When you try to open a guarded app (TikTok, Instagram, etc), Just Wait intercepts
it using Android's Accessibility Service and shows you a fish memory test.

- **Pass** → hook animation pulls the overlay up, app opens with full session time
- **Fail** → hook snaps back broken, app opens with half session time
- **Each attempt** → one more fish card added (caps at 8, resets daily at midnight)

---

## Setup (do this once)

### 1. Install Flutter
```
https://flutter.dev/docs/get-started/install/linux
```
Follow the Linux instructions. You're on Artix so use the tar.xz method.

Add flutter to PATH in your shell config:
```bash
export PATH="$PATH:/path/to/flutter/bin"
```

### 2. Install Android Studio OR just the SDK tools
You only need the command line tools for building. Install via:
```bash
yay -S android-sdk android-sdk-platform-tools
```
Or download Android Studio from https://developer.android.com/studio

### 3. Set up your Redmi for USB debugging
- Settings → About Phone → tap MIUI/HyperOS version 7 times
- Developer Options → USB Debugging → ON
- Plug in via USB, accept the debug prompt on your phone

### 4. Check Flutter can see your device
```bash
flutter doctor
flutter devices
```

### 5. Get dependencies and run
```bash
cd just_wait
flutter pub get
flutter run
```

---

## Project structure

```
lib/
  main.dart                    → App entry, routes
  screens/
    gate_screen.dart           → THE MAIN SCREEN - memory test + hook animation
    home_screen.dart           → Status, stats, blocked apps list
    settings_screen.dart       → Add/remove guarded apps, set session time
    session_screen.dart        → Countdown timer after passing the gate
  widgets/
    fish_painter.dart          → All 8 fish drawn with CustomPainter + FishCard widget
    hook_animation.dart        → Hook widget (used internally by gate_screen)
  services/
    storage_service.dart       → SharedPreferences wrapper, daily reset logic
    accessibility_service.dart → Method channel bridge to native Kotlin service
  models/
    fish_data.dart             → Fish type definitions

android/
  app/src/main/kotlin/com/justwait/app/
    MainActivity.kt                    → Method/Event channel handlers
    JustWaitAccessibilityService.kt    → THE INTERCEPTOR - watches app launches
  app/src/main/res/xml/
    accessibility_service_config.xml   → Tells Android what events to watch
  app/src/main/AndroidManifest.xml     → Declares accessibility service
```

---

## Enabling the Accessibility Service (on your Redmi)

After installing the app:
1. Open Just Wait
2. Tap the red status card
3. It opens Accessibility Settings
4. Find "Just Wait" in the list
5. Enable it
6. Accept the permission prompt

The status card turns green when active.

---

## Adding apps to guard

1. Open Just Wait → Settings
2. Tap "+ add"
3. Search for TikTok (or any app)
4. Tap to guard it
5. Done — next time you open TikTok, Just Wait intercepts it

---

## Publishing to Google Play

When you're ready to publish:

1. Create a Google Play Developer account at play.google.com/console
   - One-time $25 USD fee
   - Requires a real identity verification

2. Build a release APK:
```bash
flutter build apk --release
```
Output: build/app/outputs/flutter-apk/app-release.apk

3. Or build an App Bundle (preferred by Play Store):
```bash
flutter build appbundle --release
```

4. In Play Console:
   - Create new app
   - Upload the .aab file
   - Fill in store listing (description, screenshots, privacy policy)
   - Set content rating
   - Submit for review

**Important for Play Store:** Apps using Accessibility Service require a privacy
policy explaining why you use it. Be honest: "Used to detect when a guarded app
is opened so Just Wait can show the attention gate." No data leaves the device.

---

## Known things to finish

- [ ] App icon (replace default Flutter icon)
- [ ] Onboarding screen explaining how to enable accessibility
- [ ] Fish card shuffle animation (cards flip face-down before arrange phase)
- [ ] Haptic feedback on correct/incorrect placement
- [ ] iOS version (needs different intercept method - Screen Time API)
- [ ] Statistics screen (track your pass/fail rate over time)

---

## The philosophy

You built this because you understood the hook before you named it.

Every time Just Wait makes you wait, it's just the fisherman's patience
applied to your own attention. The fish don't come to you.
You wait for them.

— built from a banana theory and a bike ride home
