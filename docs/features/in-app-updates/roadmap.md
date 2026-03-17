# 🔄 In-App Updates — Feature Roadmap

> **Status:** Planned (Phase 3)
> **Platform:** Android only (APK distribution via GitHub Releases)

---

## Overview

Implement an in-app update system that checks for new releases on GitHub, prompts the user to update, and handles APK download + installation on Android.

## 📋 Planned

- [ ] GitHub Release version check on app launch
- [ ] Update available dialog with version info and changelog
- [ ] APK download with progress indicator
- [ ] Install APK via Android intent
- [ ] "Skip this version" option
- [ ] Background check with configurable frequency

## Technical Approach

1. **Version source**: GitHub Releases API (`GET /repos/{owner}/{repo}/releases/latest`)
2. **Comparison**: Compare `tag_name` against current app version from `pubspec.yaml`
3. **Download**: HTTP download of the APK asset from the release
4. **Install**: Use `android_intent_plus` or `open_filex` to trigger APK install
5. **Storage**: Download to app's cache directory, clean up after install

## Notes
- Windows/macOS/Linux: Not applicable (users update via other means)
- iOS: Updates go through the App Store
- Web: Auto-updates on deploy
