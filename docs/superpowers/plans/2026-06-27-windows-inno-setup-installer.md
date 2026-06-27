# Windows Inno Setup Installer Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the `jawhar-windows.zip` portable archive with a proper `jawhar-setup.exe` Inno Setup installer so Windows users get a normal double-click-to-install experience.

**Architecture:** A committed Inno Setup script (`windows/installer/jawhar.iss`) compiles the Flutter Windows release output (`build\windows\x64\runner\Release\*`) into a single `jawhar-setup.exe`. The `windows.yml` GitHub Actions workflow installs Inno Setup via Chocolatey, extracts the version from `pubspec.yaml`, runs `iscc`, and uploads the installer to the GitHub release in place of the zip. The website's download page Windows link is updated to point at the new asset.

**Tech Stack:** Flutter (Windows desktop), Inno Setup 6 (`iscc`), GitHub Actions (`windows-latest` runner, Chocolatey), Next.js website.

**Spec:** `docs/superpowers/specs/2026-06-27-windows-inno-setup-installer-design.md`

---

## File Structure

| File | Action | Responsibility |
|---|---|---|
| `windows/installer/jawhar.iss` | Create | Inno Setup script: defines installer metadata, source files, shortcuts, uninstall, code-sign placeholder. |
| `.github/workflows/windows.yml` | Modify | Replace zip step with Inno Setup install + compile; change release artifact. |
| `website/app/download/page.js` | Modify | Update Windows card action label + href to the installer. |
| `website/scripts/check-landing-content.mjs` | Modify (if needed) | Add an assertion that the download page references the installer asset name, so the content-check gate stays meaningful. |

**Facts the implementer must know:**
- The built Windows executable is named `quran_app.exe` (set via `BINARY_NAME` in `windows/CMakeLists.txt:7`). Renaming it is out of scope — the Inno script references `quran_app.exe`.
- Flutter Windows release output lands at `build\windows\x64\runner\Release\` and contains `quran_app.exe`, `flutter_windows.dll`, other DLLs, and a `data/` folder.
- The repo is on Windows; paths in commands use backslashes for PowerShell and forward slashes for bash steps in the workflow (the existing workflow uses `shell: bash` for some steps and PowerShell for others — match each step's shell).
- `pubspec.yaml` line: `version: 1.9.0+25`. The display version is the part before `+`.
- Icon file: `windows/runner/resources/app_icon.ico`.
- All `flutter` commands need `--dart-define-from-file=.env` (per AGENTS.md §6). Local validation requires a `.env` at the repo root (gitignored).

---

### Task 1: Create the Inno Setup script

**Files:**
- Create: `windows/installer/jawhar.iss`

- [ ] **Step 1: Create the installer directory**

Run (PowerShell, repo root):
```powershell
New-Item -ItemType Directory -Path "windows\installer" -Force | Out-Null
```
Expected: directory exists, no error.

- [ ] **Step 2: Write the Inno Setup script**

Create `windows/installer/jawhar.iss` with this exact content:

```innosetup
; Jawhar Windows installer
; Compiled by iscc in CI (windows.yml) and locally.
; Source: build\windows\x64\runner\Release\* (quran_app.exe + DLLs + data/)
; Output: jawhar-setup.exe

#ifndef AppVersion
  #define AppVersion "1.0.0"
#endif

[Setup]
AppName=Jawhar
AppVersion={#AppVersion}
AppPublisher=Alphafoundr
AppPublisherURL=https://jawhar.alphafoundr.com
AppSupportURL=https://jawhar.alphafoundr.com
AppUpdatesURL=https://github.com/khalidouhdane/jawhar/releases
DefaultDirName={autopf}\Jawhar
DefaultGroupName=Jawhar
DisableProgramGroupPage=yes
OutputDir=..\..\
OutputBaseFilename=jawhar-setup
Compression=lzma2/ultra64
SolidCompression=yes
PrivilegesRequired=admin
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64
UninstallDisplayIcon={app}\quran_app.exe
UninstallDisplayName=Jawhar
WizardStyle=modern
; Icon reused from the Flutter Windows project
SetupIconFile=..\runner\resources\app_icon.ico

; --- Code signing placeholder (future) ---
; Uncomment and set SignTool when a code-signing certificate is obtained.
; SignTool=signtool sign /f $fCertPath /p $fCertPassword /tr http://timestamp.digicert.com /td sha256 /fd sha256 $f
; SignedOutput=yes

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; The Flutter release build output (exe + DLLs + data/). Everything recursed.
Source: "..\..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\Jawhar"; Filename: "{app}\quran_app.exe"; IconFilename: "{app}\quran_app.exe"
Name: "{group}\{cm:UninstallProgram,Jawhar}"; Filename: "{uninstallexe}"
Name: "{commondesktop}\Jawhar"; Filename: "{app}\quran_app.exe"; IconFilename: "{app}\quran_app.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\quran_app.exe"; Description: "{cm:LaunchProgram,Jawhar}"; Flags: nowait postinstall skipifsilent
```

Notes for the implementer:
- `OutputDir=..\..\` is relative to the `.iss` location (`windows/installer/`), so it resolves to `windows/` — but CI runs `iscc` from the repo root with the path `windows/installer/jawhar.iss`, so the working directory of `iscc` is the repo root. Inno Setup resolves `OutputDir` and `Source` relative to the `.iss` file's directory, NOT the CWD. So `OutputDir=..\..\` → `windows/` (correct — but we want it at `build/windows/`; see Step 3 for the exact output path reconciliation). Actually, to match the workflow's expected artifact path `build\windows\jawhar-setup.exe`, set `OutputDir` to an absolute-ish path. We'll override with `iscc`'s `/O` flag in CI for reliability (Step 3 of Task 2). Keep `OutputDir=..\..\` here as a sane local default.

- [ ] **Step 3: Commit the script**

```bash
git add windows/installer/jawhar.iss
git commit -m "build(windows): add Inno Setup installer script"
```

---

### Task 2: Update the Windows CI workflow

**Files:**
- Modify: `.github/workflows/windows.yml`

- [ ] **Step 1: Read the current workflow**

Run: read `.github/workflows/windows.yml` (65 lines). Confirm the `Package Windows Build` step (lines 55-58) and `Upload to Release` step (lines 60-64) are the ones to replace.

- [ ] **Step 2: Add the Inno Setup install step**

In `.github/workflows/windows.yml`, insert a new step immediately after the `Build Windows App` step (after line 53) and before the existing `Package Windows Build` step:

```yaml
      - name: Install Inno Setup
        run: choco install innosetup --no-progress
```

- [ ] **Step 3: Replace the Package step with the Build Installer step**

Replace this block (the existing `Package Windows Build` step):

```yaml
      - name: Package Windows Build
        shell: powershell
        run: |
          Compress-Archive -Path build\windows\x64\runner\Release\* -DestinationPath build\windows\jawhar-windows.zip
```

with this block:

```yaml
      - name: Build Installer
        shell: bash
        run: |
          # Extract display version (e.g. "1.9.0" from "version: 1.9.0+25")
          APP_VERSION=$(grep -E '^version:' pubspec.yaml | head -1 | sed -E 's/^version:[[:space:]]*([0-9]+\.[0-9]+\.[0-9]+).*/\1/')
          echo "Version: $APP_VERSION"
          # Compile the installer; /O forces output into build/windows
          iscc //DAppVersion="$APP_VERSION" //O"build/windows" "windows/installer/jawhar.iss"
          test -f "build/windows/jawhar-setup.exe" || { echo "ERROR: jawhar-setup.exe was not produced"; exit 1; }
          echo "Produced build/windows/jawhar-setup.exe"
```

Notes:
- `//D` and `//O` are the double-slash forms required when invoking `iscc` from a bash shell on Windows (single slash would be misinterpreted as a path). This is the documented Inno Setup workaround for Git Bash.
- `choco install innosetup` puts `iscc.exe` on the PATH.

- [ ] **Step 4: Change the release artifact**

In the `Upload to Release` step, change the `files:` value:

From:
```yaml
          files: build/windows/jawhar-windows.zip
```
To:
```yaml
          files: build/windows/jawhar-setup.exe
```

- [ ] **Step 5: Verify the full workflow file**

Read `.github/workflows/windows.yml` end to end and confirm:
- `Install Inno Setup` step exists after `Build Windows App`.
- `Build Installer` step exists where `Package Windows Build` was.
- `Upload to Release` `files:` is `build/windows/jawhar-setup.exe`.
- No other steps (checkout, Flutter setup, `.env`, tests, coverage, CMake env) were modified.

- [ ] **Step 6: Commit**

```bash
git add .github/workflows/windows.yml
git commit -m "ci(windows): build jawhar-setup.exe installer instead of zip"
```

---

### Task 3: Update the website download page

**Files:**
- Modify: `website/app/download/page.js` (the Windows entry in the `platforms` array, around lines 9-15)

- [ ] **Step 1: Update the Windows platform entry**

In `website/app/download/page.js`, replace:

```javascript
  {
    icon: Monitor,
    name: "Windows",
    action: "Download ZIP",
    href: "https://github.com/khalidouhdane/jawhar/releases/latest/download/jawhar-windows.zip",
    available: true,
  },
```

with:

```javascript
  {
    icon: Monitor,
    name: "Windows",
    action: "Install for Windows",
    href: "https://github.com/khalidouhdane/jawhar/releases/latest/download/jawhar-setup.exe",
    available: true,
  },
```

- [ ] **Step 2: Verify the content-check script still passes**

The existing `website/scripts/check-landing-content.mjs` asserts the download page contains `"Closed source for now"` and does NOT contain `"fully open source"` or `"View on GitHub"`. None of these are touched. To guard the new asset name, add an assertion.

In `website/scripts/check-landing-content.mjs`, after the existing `download` assertions (around line 36-38), add:

```javascript
assert(
  download.includes("jawhar-setup.exe") && !download.includes("jawhar-windows.zip"),
  "Download page should serve the jawhar-setup.exe installer, not the zip"
);
```

- [ ] **Step 3: Run the content check**

Run (PowerShell, `website/` dir):
```powershell
npm run check:content
```
Expected: no output (script throws on failure; silence = pass). If it throws, fix the assertion or the page.

- [ ] **Step 4: Lint the edited files**

Run:
```powershell
npx eslint app/download/page.js scripts/check-landing-content.mjs
```
Expected: no errors. (Pre-existing errors in unrelated files like `ThemeToggle.js` are ignored — only run against the two edited files.)

- [ ] **Step 5: Commit**

```bash
git add website/app/download/page.js website/scripts/check-landing-content.mjs
git commit -m "web(download): point Windows card at the jawhar-setup.exe installer"
```

---

### Task 4: Local validation (manual, before tagging a release)

**Files:** none modified.

This task verifies the end-to-end build locally. It requires Flutter desktop enabled and a `.env` file at the repo root. If the environment can't run Flutter Windows builds, skip to Task 5 (CI is the real gate) but note the skip.

- [ ] **Step 1: Build the Windows app**

Run (PowerShell, repo root):
```powershell
flutter config --enable-windows-desktop
$env:CMAKE_POLICY_VERSION_MINIMUM="3.5"
flutter build windows --release --dart-define-from-file=.env
```
Expected: completes, `build\windows\x64\runner\Release\quran_app.exe` exists.

- [ ] **Step 2: Install Inno Setup locally (if not present)**

```powershell
choco install innosetup --no-progress
```
(Requires admin / an elevated PowerShell. If Chocolatey isn't installed or admin isn't available, download Inno Setup from https://jrsoftware.org/isdl.php and add `iscc` to PATH.)

- [ ] **Step 3: Compile the installer**

```powershell
$version = (Select-String -Path pubspec.yaml -Pattern '^version:').Line -replace '^version:\s*',''
$display = ($version -split '\+')[0]
iscc /DAppVersion="$display" /O"build/windows" "windows/installer/jawhar.iss"
Test-Path "build/windows/jawhar-setup.exe"
```
Expected: `iscc` compiles with no errors; `build\windows\jawhar-setup.exe` exists; the last command prints `True`.

- [ ] **Step 4: Run the installer on a clean Windows account**

Double-click `build\windows\jawhar-setup.exe`. Verify:
- UAC elevation prompt appears (expected — per-machine install).
- Installer wizard runs, installs to `C:\Program Files\Jawhar`.
- Start Menu → Jawhar shortcut launches the app.
- Settings → Add or remove programs shows "Jawhar" with uninstall option.
- Uninstall removes the folder and shortcuts.

- [ ] **Step 5: No commit (validation only)**

No code changes in this task. If anything failed, go back and fix Tasks 1-3.

---

### Task 5: Smoke-test the website change locally

**Files:** none modified (the dev server may already be running from earlier work).

- [ ] **Step 1: Start the website dev server (if not running)**

Run (PowerShell, `website/` dir):
```powershell
npm run dev
```
Expected: Next.js dev server starts on http://localhost:3001.

- [ ] **Step 2: Verify the Windows card**

Open http://localhost:3001/download in a browser. Verify:
- The Windows card's button reads "Install for Windows" (not "Download ZIP").
- The link href is `https://github.com/khalidouhdane/jawhar/releases/latest/download/jawhar-setup.exe` (right-click → copy link to verify). It will 404 until the first release with the new artifact ships — that's expected.

- [ ] **Step 3: Stop the dev server when done**

Stop the `npm run dev` process (Ctrl+C in its window, or the PID started earlier).

---

## Self-Review

**Spec coverage:**
- ✅ Inno Setup script (spec §1) → Task 1.
- ✅ Version extraction (spec §2) → Task 2 Step 3 (`grep`/`sed` in bash) + Task 4 Step 3 (PowerShell local).
- ✅ CI workflow changes (spec §3) → Task 2.
- ✅ Website changes (spec §4) → Task 3.
- ✅ Code-sign placeholder (spec §1) → in the `.iss` as commented `SignTool`.
- ✅ Out-of-scope items (macOS, code signing, binary rename) → explicitly not in any task.
- ✅ Testing (spec §Testing) → Tasks 4 (local) and 5 (website); CI is the real gate via Task 2.

**Placeholder scan:** No TBD/TODO. Every step has concrete code or commands. The code-sign block is intentionally commented out (it's the documented placeholder, per spec) — not a placeholder in the plan sense.

**Type/name consistency:** The binary is consistently `quran_app.exe` across the `.iss`, workflow, and validation steps. The installer output is consistently `jawhar-setup.exe`. The website href matches. The content-check assertion matches the href string.

One correction applied during review: the workflow's `Build Installer` step uses `iscc //D` and `//O` (double-slash) because it runs in `shell: bash` — single slashes would be parsed as paths by Git Bash. This matches Inno Setup's documented Git Bash workaround. ✓
