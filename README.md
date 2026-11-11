# LittleStory for iOS

Native iPhone and iPad app for LittleStory, the storytelling app for children aged 3–12 and their parents. It is the iOS companion of the Android app in [shivayogih/LittleStory](https://github.com/shivayogih/LittleStory).

- Swift 6.4 and SwiftUI, built with Xcode 27.2, minimum iOS / iPadOS 26
- English and Kannada, designed for more languages
- No paid services: AI features are simulated and clearly labelled
- Design documents: [`docs/`](docs/README.md)

## Branches

`development` is where work lands (pull requests target it), `staging` holds release candidates and `main` holds stable releases. Only the owner merges promotions and releases.

## Build and run (Mac)

1. Install Xcode 27.2 (macOS 26.6 or newer) and [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`).
2. `xcodegen generate` creates `LittleStory.xcodeproj` (it is not committed).
3. Open the project, pick an iPhone or iPad simulator and run. A free Apple ID is enough to run on your own device.
4. `Tools/verify.sh` runs everything CI runs: format, lint, rule checks, package tests and UI tests on an iPhone and an iPad simulator.
