#!/usr/bin/env bash
# Selects the Xcode pinned in .xcode-version (CI runners default to an older one).
set -euo pipefail
cd "$(dirname "$0")/.."
WANT=$(tr -d '[:space:]' < .xcode-version)
APP="/Applications/Xcode_${WANT}.app"
if [[ ! -d "$APP" ]]; then
  echo "error: Xcode ${WANT} is not installed on this machine. Installed:" >&2
  ls -d /Applications/Xcode*.app >&2 || true
  exit 1
fi
sudo xcode-select -s "$APP/Contents/Developer"
xcodebuild -version
