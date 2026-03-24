---
description: Push code to GitHub and create a new release with APK
---

# Push to GitHub & Create Release

// turbo-all

## Prerequisites
- All changes committed locally
- Version bumped in `pubspec.yaml`
- Changes confirmed/tested by the user

## Steps

1. Check current version in pubspec.yaml:
```powershell
Select-String -Path "pubspec.yaml" -Pattern "^version:"
```

2. Check git status to make sure everything is clean:
```powershell
git status
```

3. If there are uncommitted changes, stage and commit them:
```powershell
git add -A
git commit -m "v{VERSION} - {DESCRIPTION}"
```
> Replace `{VERSION}` with the version from step 1 (e.g., `1.3.0`).
> Replace `{DESCRIPTION}` with a brief summary of changes.

4. Push to GitHub:
```powershell
git push origin main
```

5. Build the release APK:
```powershell
flutter build apk --release
```
> The APK will be at: `build\app\outputs\flutter-apk\app-release.apk`

6. Create a GitHub Release with the APK attached:
```powershell
gh release create v{VERSION} "build\app\outputs\flutter-apk\app-release.apk" --title "v{VERSION}" --notes "{RELEASE_NOTES}"
```
> Replace `{VERSION}` with the version (e.g., `1.3.0`).
> Replace `{RELEASE_NOTES}` with a bullet-point summary of what's new.
> Use `--latest` flag if this should be marked as the latest release.

7. Verify the release was created:
```powershell
gh release view v{VERSION}
```

## Notes
- The `gh` CLI must be authenticated (`gh auth login` if not).
- Users with the app installed will see the update dialog on next launch via `UpdateProvider`.
- If the APK build fails, check `flutter doctor` for environment issues.
