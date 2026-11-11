#!/usr/bin/env bash
# Installs SwiftLint and SwiftFormat at the versions pinned in Tools/versions.env into .tools/bin.
set -euo pipefail
cd "$(dirname "$0")/.."
source Tools/versions.env
BIN=".tools/bin"
mkdir -p "$BIN"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

if [[ ! -x "$BIN/swiftlint" ]] || [[ "$("$BIN/swiftlint" version)" != "$SWIFTLINT_VERSION" ]]; then
  curl -fsSL -o "$TMP/swiftlint.zip" \
    "https://github.com/realm/SwiftLint/releases/download/${SWIFTLINT_VERSION}/portable_swiftlint.zip"
  unzip -o -q "$TMP/swiftlint.zip" -d "$TMP/swiftlint"
  install -m 0755 "$TMP/swiftlint/swiftlint" "$BIN/swiftlint"
fi

if [[ ! -x "$BIN/swiftformat" ]] || [[ "$("$BIN/swiftformat" --version)" != "$SWIFTFORMAT_VERSION" ]]; then
  curl -fsSL -o "$TMP/swiftformat.zip" \
    "https://github.com/nicklockwood/SwiftFormat/releases/download/${SWIFTFORMAT_VERSION}/swiftformat.zip"
  unzip -o -q "$TMP/swiftformat.zip" -d "$TMP/swiftformat"
  install -m 0755 "$TMP/swiftformat/swiftformat" "$BIN/swiftformat"
fi

echo "swiftlint $("$BIN/swiftlint" version), swiftformat $("$BIN/swiftformat" --version)"
