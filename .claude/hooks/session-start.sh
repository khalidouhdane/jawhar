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
# Without it, write an empty file so the test harness still runs — suites that
# need real credentials will fail loudly rather than the whole command aborting.
cd "$REPO_DIR"
if [ -n "${ENV_FILE:-}" ]; then
  printf '%s' "$ENV_FILE" > .env
  log ".env written from the ENV_FILE environment variable"
elif [ -s .env ]; then
  log ".env already present, leaving it alone"
else
  : > .env
  log "WARNING: no ENV_FILE set — wrote an empty .env. Auth, cloud sync, and"
  log "         content-loading tests will fail until it is populated."
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

# functions/ is deliberately skipped: AGENTS.md §2 freezes it, and its
# test:rules gate needs JDK 21 for the Firestore emulator, which this container
# does not carry.

# --- 4. Persist the toolchain for the session ---------------------------------
if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
  {
    echo "export PATH=\"$FLUTTER_DIR/bin:$FLUTTER_DIR/bin/cache/dart-sdk/bin:\$PATH\""
    echo "export FLUTTER_SUPPRESS_ANALYTICS=true"
  } >> "$CLAUDE_ENV_FILE"
fi

log "Ready — $(flutter --version 2>/dev/null | head -1)"
