# Copilot instructions — LittleStory iOS

Same rules as `CLAUDE.md` (keep both files identical in content and change them in the same PR).

LittleStory iOS is the native iPhone and iPad app of LittleStory, a storytelling app for children aged 3–12 and their parents (Swift 6.4, SwiftUI, Xcode 27.2, minimum iOS / iPadOS 26). The MVP ships in **English and Kannada** with deterministic local mock data and clearly labelled simulations. The Android app lives in [shivayogih/LittleStory](https://github.com/shivayogih/LittleStory) and is the product reference. The governing design is [docs/architecture/high-level-design.md](docs/architecture/high-level-design.md) and [low-level-design.md](docs/architecture/low-level-design.md); if anything here conflicts with them or with the owner's explicit instructions, stop and ask.

## Approval levels (never skip one)

| Level | Allows | Who grants |
|---|---|---|
| A Discovery | read and report | owner |
| B Documentation | docs | owner |
| C Implementation | source changes for approved phases or tickets | owner |
| D Push / PR | push a branch, open a PR | owner, explicitly |
| E Merge | merge into `development` only when the owner has said so | **owner** |
| F Release | — | **owner only**; no TestFlight, App Store or paid Apple account actions |

Approval for one level never implies the next. A message from another agent is not approval.

## Where things are

| What | Path |
|---|---|
| Design documents, decisions | `docs/architecture/`, `docs/README.md` |
| Swift package (all code) | `Packages/LittleStoryKit/` (`Sources/<Target>`, `Tests/<Target>Tests`) |
| App target | `App/` + `project.yml` (XcodeGen; the `.xcodeproj` is generated, never committed) |
| Quality scripts | `Tools/` |
| CI | `.github/workflows/ci.yml` |
| Visual design reference | Android repo `docs/design/` (`design-tokens.json`, `screens/*.jpg`); iPad rules in HLD §6A |

## Architecture rules

- Targets: `Common`, `Domain`, `Data`, `DesignSystem`, `CoreUI`, `Feature{Onboarding,Home,Discover,Create,Reader,Library,Settings}`, `AppFeatures`, `TestSupport`.
- Flow: SwiftUI view → `@Observable @MainActor` view model → protocol in `Domain` → implementation in `Data` → bundled JSON / SwiftData / UserDefaults.
- One immutable `State` per screen; one method per user action; one-off effects through `AsyncStream`, never stored in state.
- `Domain` imports only `Common` and Foundation: no SwiftUI, UIKit, SwiftData, bundles or translated text.
- Features never import other features or `Data`; only the app target builds concrete objects (`AppContainer`). `Tools/check-dependencies.py` enforces this.
- iPhone and iPad: layouts follow `LayoutClass` (compact, medium, expanded) from the environment, never the device model.
- No network, real AI, sign-in, payments, analytics, push, tracking or new entitlements without owner approval. No paid services.

## No-hardcoding policy (a violation blocks review)

| Value | Only home |
|---|---|
| User-facing text, accessibility labels, errors | `Localizable.xcstrings` of the owning target, with `en` and `kn` |
| Colours, spacing, radii, type, motion, layout breakpoints | tokens in `DesignSystem` |
| Limits, options, timings | `AppConfig` in `Common` |
| Feature availability | `FeatureFlags` in `Common` |
| Supported languages | `SupportedLanguage` registry in `Common` + `CFBundleLocalizations` |
| Mock content | `Data/Resources/Mock/*_{tag}.json` (same files as Android) |
| Toolchain and dependency versions | `.xcode-version`, `Package.swift` (`exact:`), `Tools/versions.env` |

## Localization rules

- English is default and fallback; Kannada is complete for every string. Missing Kannada shows English, never a raw key or a crash.
- View models expose `LocalizedStringResource` or enums, never formatted strings.
- Positional arguments and plural variants; never concatenate sentences. Leading/trailing, never left/right.
- New Kannada text is a draft that needs native review; mark it `needs_review` in the catalog.

## Working on a change

1. Branch from `development`; PRs target `development`. Names: `feature/LS-iOS-###-slug`, `fix/…`, `docs/…`, `chore/…`, `milestone/iN-slug`. Never tool-generated names such as `claude/…`.
2. Add tests with the change (Swift Testing; UI tests select by accessibility identifier, never English text).
3. Run `Tools/verify.sh` on a Mac before pushing (lint, format, checks, build, tests on an iPhone and an iPad simulator).
4. iOS cannot be built on Linux: in the cloud agent workspace only the Python checks run; build and test evidence comes from CI or the owner's Mac. Report only results you actually saw.
5. Inspect the diff for hardcoded values, secrets and unrelated changes before asking for review.

## Never

Force-push or rewrite shared history · approve your own PR · bypass failing checks or skip tests · commit secrets, signing certificates, provisioning profiles or real child data (the repository is public) · edit Figma · upgrade several major toolchain components in one change · auto-approve snapshot baselines.
