#!/usr/bin/env bash
# Everything CI runs, for a Mac with Xcode 27.2: format, lint, checks, build and tests on an
# iPhone and an iPad simulator. Usage: Tools/verify.sh
set -euo pipefail
cd "$(dirname "$0")/.."

python3 Tools/check-dependencies.py
python3 Tools/check-hardcoding.py
python3 Tools/check-translations.py
python3 Tools/check-tokens.py

Tools/install-lint-tools.sh
.tools/bin/swiftformat --lint .
.tools/bin/swiftlint lint --strict --quiet

command -v xcodegen >/dev/null || brew install xcodegen
xcodegen generate --quiet

IPHONE=$(python3 Tools/pick-simulator.py iphone)
IPAD=$(python3 Tools/pick-simulator.py ipad)

( cd Packages/LittleStoryKit && xcodebuild test -quiet -scheme LittleStoryKit-Package \
    -destination "$IPHONE" SWIFT_TREAT_WARNINGS_AS_ERRORS=YES )

xcodebuild test -quiet -project LittleStory.xcodeproj -scheme LittleStory \
  -destination "$IPHONE" -destination "$IPAD" CODE_SIGNING_ALLOWED=NO
