#!/bin/bash
# SessionStart hook for Claude Code on the web.
#
# The remote container ships Node and Python but no Dart toolchain, so a fresh
# cloud session cannot run `flutter analyze`, `flutter test`, or the pure-Dart
# suites in packages/hifz_core and server/api. This installs the Flutter SDK
# (which bundles Dart), resolves the pub workspace, and materializes the .env
# that AGENTS.md §6 requires for every compile/run/test.
#
# Local machines are untouched: the hook exits immediately unless it is running
# in a remote environment.
set -euo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

REPO_DIR="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
FLUTTER_DIR="${JAWHAR_FLUTTER_DIR:-/opt/flutter}"
RELEASES_URL="https://storage.googleapis.com/flutter_infra_release/releases/releases_linux.json"

log() { echo "[session-start] $*"; }

# --- 1. Flutter SDK -----------------------------------------------------------
# quality.yml pins `channel: stable`, so resolve whatever stable currently is
# rather than hardcoding a version that silently rots. Set JAWHAR_FLUTTER_VERSION
# in the environment to pin a specific release instead.
if [ -x "$FLUTTER_DIR/bin/flutter" ]; then
  log "Flutter already present at $FLUTTER_DIR ($("$FLUTTER_DIR/bin/flutter" --version 2>/dev/null | head -1))"
else
  log "Resolving Flutter stable release..."
  ARCHIVE_URL="$(
    curl -fsSL --retry 3 --retry-delay 2 --max-time 120 "$RELEASES_URL" |
      JAWHAR_FLUTTER_VERSION="${JAWHAR_FLUTTER_VERSION:-}" python3 -c '
import json, os, sys

data = json.load(sys.stdin)
pin = os.environ.get("JAWHAR_FLUTTER_VERSION") or None
target = data["current_release"]["stable"]

for release in data["releases"]:
    if release.get("channel") != "stable":
        continue
    matches = (release["version"] == pin) if pin else (release["hash"] == target)
    if matches:
        print(data["base_url"] + "/" + release["archive"])
        break
else:
    sys.exit("no matching stable Flutter release found")
'
  )"

  log "Downloading ${ARCHIVE_URL##*/}"
  TMP_ARCHIVE="$(mktemp -d)/flutter.tar.xz"
  curl -fsSL --retry 3 --retry-delay 2 -o "$TMP_ARCHIVE" "$ARCHIVE_URL"

  log "Extracting to $FLUTTER_DIR"
  mkdir -p "$(dirname "$FLUTTER_DIR")"
  rm -rf "$FLUTTER_DIR"
  tar -xf "$TMP_ARCHIVE" -C "$(dirname "$FLUTTER_DIR")"
  rm -rf "$(dirname "$TMP_ARCHIVE")"
fi

export PATH="$FLUTTER_DIR/bin:$FLUTTER_DIR/bin/cache/dart-sdk/bin:$PATH"

# Flutter shells out to git against its own checkout; the container's git
# refuses unowned repos without this.
git config --global --add safe.directory "$FLUTTER_DIR" 2>/dev/null || true

# Keep the SDK from prompting, animating, or phoning home in a headless session.
flutter config --no-analytics >/dev/null 2>&1 || true
dart --disable-analytics >/dev/null 2>&1 || true
export FLUTTER_SUPPRESS_ANALYTICS=true

# Warms the tool snapshot and the flutter_tester binary the test harness runs
# on. Desktop/mobile build artifacts are left out — this container tests and
# analyzes, it does not produce release binaries.
log "Precaching build artifacts..."
flutter precache --universal >/dev/null

# --- 2. .env ------------------------------------------------------------------
# AGENTS.md §6: every compile/run/test needs --dart-define-from-file=.env, and
# the file is gitignored. CI feeds it from the ENV_FILE secret; mirror that here
# so cloud sessions behave the same when ENV_FILE is set on the environment.
# Without it, write an empty file: --dart-define-from-file needs the path to
# exist, and every suite passes without real values (verified 439/439) because
# the tests inject their own doubles rather than reading dart-defines. Cloud
# environments have no secrets store, so do NOT set ENV_FILE to a .env holding
# DESKTOP_OAUTH_CLIENT_SECRET / QURAN_API_CLIENT_SECRET just to run tests.
cd "$REPO_DIR"
if [ -n "${ENV_FILE:-}" ]; then
  printf '%s' "$ENV_FILE" > .env
  log ".env written from the ENV_FILE environment variable"
elif [ -s .env ]; then
  log ".env already present, leaving it alone"
else
  : > .env
  log "no ENV_FILE set — wrote an empty .env (all suites pass without one)"
fi

# --- 3. Dependencies ----------------------------------------------------------
# The repo root is the pub workspace root, so one resolve covers the app plus
# packages/hifz_core, packages/lucide_icons, and server/api.
log "Resolving pub workspace..."
flutter pub get

# The Next.js marketing site auto-deploys to Vercel on push to main, so being
# able to lint and build it here is worth the install. Use `npm ci`, not
# `npm install`: this container's npm is older than the one that wrote the
# lockfile and rewrites it on install (stripping the per-arch `libc` fields),
# which would show up as spurious churn in a tracked, deploy-critical file.
# Non-fatal — a hiccup on the website deps should not block a Dart session.
if [ -f website/package.json ]; then
  log "Installing website dependencies..."
  if [ -f website/package-lock.json ]; then
    (cd website && npm ci --no-audit --no-fund) || log "WARNING: website npm ci failed"
  else
    (cd website && npm install --no-audit --no-fund) || log "WARNING: website npm install failed"
  fi
fi

# functions/ is frozen for editing (AGENTS.md §2) but its devDependencies carry
# firebase-tools, which provides the Firestore emulator that server/api's
# contract suite (replay, kill-mid-drain, A->B isolation) runs against. The
# container does ship JDK 21, so those suites work here — install the deps.
if [ -f functions/package.json ]; then
  log "Installing functions dependencies (firebase-tools for the emulator)..."
  (cd functions && npm ci --no-audit --no-fund) || log "WARNING: functions npm ci failed"
fi

# --- 4. Browser driving for integration_test ----------------------------------
# `flutter drive ... -d web-server --browser-name=chrome` is the only real-engine
# target available here: there is no /dev/kvm, so an Android emulator would fall
# back to software rendering and is not worth the wall clock. Three things stand
# between a stock container and a working WebDriver session.
CHROME_WRAPPER=/usr/bin/google-chrome
CHROME_BIN="$(ls -d /opt/pw-browsers/chromium-*/chrome-linux/chrome 2>/dev/null | sort -V | tail -1 || true)"

if [ -n "$CHROME_BIN" ]; then
  # (1) chromedriver probes standard names on PATH and never finds Playwright's
  # versioned directory. (2) Chrome refuses to start as root without
  # --no-sandbox, and chromedriver cannot inject launch flags — so they live in
  # the wrapper.
  cat > "$CHROME_WRAPPER" <<WRAPPER
#!/bin/sh
exec $CHROME_BIN --no-sandbox --disable-dev-shm-usage --disable-gpu "\$@"
WRAPPER
  chmod +x "$CHROME_WRAPPER"

  # (3) The preinstalled chromedriver tracks a different Chrome major than the
  # bundled Chromium and refuses the session outright. Fetch the matching build.
  CHROME_VERSION="$("$CHROME_WRAPPER" --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' || true)"
  DRIVER_DIR="$FLUTTER_DIR/.chromedriver"
  if [ -n "$CHROME_VERSION" ] && [ ! -x "$DRIVER_DIR/chromedriver" ]; then
    DRIVER_URL="https://storage.googleapis.com/chrome-for-testing-public/${CHROME_VERSION}/linux64/chromedriver-linux64.zip"
    if curl -fsSL --retry 2 --max-time 180 -o /tmp/chromedriver.zip "$DRIVER_URL" 2>/dev/null; then
      mkdir -p "$DRIVER_DIR"
      unzip -oqj /tmp/chromedriver.zip 'chromedriver-linux64/chromedriver' -d "$DRIVER_DIR"
      chmod +x "$DRIVER_DIR/chromedriver"
      rm -f /tmp/chromedriver.zip
      log "chromedriver $CHROME_VERSION installed for browser-driven integration tests"
    else
      log "WARNING: no chromedriver for Chrome $CHROME_VERSION; browser-driven runs will fail"
    fi
  fi
fi

# --- 4. Persist the toolchain for the session ---------------------------------
# The Firestore emulator needs JAVA_HOME. The container ships JDK 21 but leaves
# the variable unset, and AGENTS.md §4 warns it must point at a real JDK rather
# than the Android Studio JBR.
JAVA_HOME_DETECTED=""
for candidate in /usr/lib/jvm/java-21-openjdk-amd64 /usr/lib/jvm/openjdk-21 "${JAVA_HOME:-}"; do
  if [ -n "$candidate" ] && [ -x "$candidate/bin/java" ]; then
    JAVA_HOME_DETECTED="$candidate"
    break
  fi
done
if [ -n "$JAVA_HOME_DETECTED" ]; then
  log "JDK found at $JAVA_HOME_DETECTED (Firestore emulator suites available)"
else
  log "WARNING: no JDK found — the emulator-backed server/api suite will skip"
fi

if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
  {
    echo "export PATH=\"$FLUTTER_DIR/bin:$FLUTTER_DIR/bin/cache/dart-sdk/bin:$REPO_DIR/functions/node_modules/.bin:\$PATH\""
    echo "export FLUTTER_SUPPRESS_ANALYTICS=true"
    if [ -x "$CHROME_WRAPPER" ]; then
      echo "export CHROME_EXECUTABLE=\"$CHROME_WRAPPER\""
    fi
    if [ -x "$FLUTTER_DIR/.chromedriver/chromedriver" ]; then
      echo "export CHROMEDRIVER=\"$FLUTTER_DIR/.chromedriver/chromedriver\""
    fi
    if [ -n "$JAVA_HOME_DETECTED" ]; then
      echo "export JAVA_HOME=\"$JAVA_HOME_DETECTED\""
    fi
  } >> "$CLAUDE_ENV_FILE"
fi

log "Ready — $(flutter --version 2>/dev/null | head -1)"
