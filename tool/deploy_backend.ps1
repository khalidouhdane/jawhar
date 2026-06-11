<#
.SYNOPSIS
    Stopgap manual backend deploy for Jawhar (Cloud Functions + Firestore rules).

.DESCRIPTION
    Roadmap: docs/CLOUD_FIRST_MIGRATION_ROADMAP.md, Phase 0 task 3.
    Runs the functions test suite, then:
        firebase deploy --only functions,firestore:rules --project quran-app-e5e86

    - The Firebase project id is HARDCODED (there is no .firebaserc; a bare
      `firebase deploy` fails with "No currently active project").
    - Any gcloud invocation in this process uses the named "jawhar" gcloud
      configuration (account me@heykhalid.com / project quran-app-e5e86) via
      CLOUDSDK_ACTIVE_CONFIG_NAME. The machine's global/default gcloud
      configuration is NEVER touched - it belongs to other work.
    - Rules tests (test:rules) need the Firestore emulator, which needs Java.
      This machine has no standalone JDK (only Android Studio's JBR), so the
      script runs them only when `java` is on PATH; otherwise it warns and
      relies on CI (.github/workflows/deploy-backend.yml) to run them.

    NOTE on deleting functions: non-interactive deploys ABORT when a deployed
    function disappears from source. Before deploying such a commit, run:
        firebase functions:delete <name> --project quran-app-e5e86 --force
    Do NOT add a blanket --force to the deploy command here.

.PARAMETER SkipTests
    Skip npm ci / build / tests and go straight to deploy. Use sparingly.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File tool\deploy_backend.ps1
#>
[CmdletBinding()]
param(
    [switch]$SkipTests
)

$ErrorActionPreference = 'Stop'

$ProjectId = 'quran-app-e5e86'           # hardcoded on purpose - see .DESCRIPTION
$RepoRoot = Split-Path -Parent $PSScriptRoot
$FunctionsDir = Join-Path $RepoRoot 'functions'

# Bind any gcloud usage in this process to the jawhar named configuration.
# This does NOT mutate the machine's active gcloud configuration.
$env:CLOUDSDK_ACTIVE_CONFIG_NAME = 'jawhar'

function Invoke-Step {
    param(
        [string]$Name,
        [scriptblock]$Action
    )
    Write-Host ""
    Write-Host "==> $Name" -ForegroundColor Cyan
    & $Action
    if ($LASTEXITCODE -ne 0) {
        Write-Host "FAILED: $Name (exit $LASTEXITCODE)" -ForegroundColor Red
        exit $LASTEXITCODE
    }
}

if (-not (Test-Path (Join-Path $RepoRoot 'firebase.json'))) {
    Write-Host "ERROR: firebase.json not found at $RepoRoot - run from the repo." -ForegroundColor Red
    exit 1
}

if (-not $SkipTests) {
    Push-Location $FunctionsDir
    try {
        Invoke-Step 'npm ci (functions)' { npm ci }
        Invoke-Step 'npm run build (functions)' { npm run build }
        Invoke-Step 'npm run test:unit (functions)' { npm run test:unit }

        $javaCmd = Get-Command java -ErrorAction SilentlyContinue
        if ($null -ne $javaCmd) {
            Invoke-Step 'npm run test:rules (Firestore emulator)' { npm run test:rules }
        }
        else {
            Write-Host "WARN: 'java' not on PATH - skipping test:rules (emulator needs a JDK)." -ForegroundColor Yellow
            Write-Host "      Rules tests run in CI (deploy-backend.yml). Install Temurin 21+ to run them locally." -ForegroundColor Yellow
        }
    }
    finally {
        Pop-Location
    }
}
else {
    Write-Host "WARN: -SkipTests was passed - deploying without running tests." -ForegroundColor Yellow
}

# Prefer the version-pinned firebase-tools from functions/node_modules (installed
# by npm ci above); fall back to the global install.
$firebaseCmd = Join-Path $FunctionsDir 'node_modules\.bin\firebase.cmd'
if (-not (Test-Path $firebaseCmd)) {
    $firebaseCmd = 'firebase'
}

Push-Location $RepoRoot
try {
    Invoke-Step "firebase deploy --only functions,firestore:rules --project $ProjectId" {
        & $firebaseCmd deploy --only functions,firestore:rules --project $ProjectId --non-interactive
    }
}
finally {
    Pop-Location
}

Write-Host ""
Write-Host "Deploy complete ($ProjectId)." -ForegroundColor Green
