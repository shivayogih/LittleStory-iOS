#!/usr/bin/env bash
# Selects the Xcode pinned in .xcode-version. On CI, when that exact version is not on the runner
# image yet, falls back to the newest installed Xcode of the same major version and warns, so the
# build still uses the 27 SDK. Locally (no CI variable) a missing pinned Xcode is an error.
set -euo pipefail
cd "$(dirname "$0")/.."
WANT=$(tr -d '[:space:]' < .xcode-version)
MAJOR=${WANT%%.*}
APP="/Applications/Xcode_${WANT}.app"

if [[ ! -d "$APP" ]]; then
  echo "Installed Xcode versions:"; ls -d /Applications/Xcode*.app || true
  if [[ -z "${CI:-}" ]]; then
    echo "error: Xcode ${WANT} is not installed" >&2
    exit 1
  fi
  APP=$(ls -d /Applications/Xcode_"${MAJOR}"*.app 2>/dev/null | sort -V | tail -1 || true)
  if [[ -z "$APP" ]]; then
    echo "error: no Xcode ${MAJOR}.x on this runner" >&2
    exit 1
  fi
  echo "::warning title=Xcode fallback::Xcode ${WANT} is not on this runner image yet; using $(basename "$APP")"
fi
sudo xcode-select -s "$APP/Contents/Developer"
xcodebuild -version
