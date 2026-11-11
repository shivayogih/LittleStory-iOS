# LittleStory iOS documentation

| Document | What it covers |
| --- | --- |
| [High-level design](architecture/high-level-design.md) ([PDF](architecture/high-level-design.pdf)) | Scope, the native SwiftUI decision, tech stack and versions, layers and modules, screens and navigation, iPhone and iPad layouts, localization, mocked AI, CI, testing, delivery plan, risks |
| [Low-level design](architecture/low-level-design.md) ([PDF](architecture/low-level-design.pdf)) | Package targets, models and protocols, SwiftData schema, view model and navigation patterns, adaptive layout code, key flows, error handling, screen catalogue, tests, CI workflow, Android → iOS mapping, proposed ADRs |

Both are drafts for owner review. The diagrams are Mermaid, so they render on GitHub; the PDFs have them drawn in for offline reading.

## Decisions so far

| Id | Decision | Date |
| --- | --- | --- |
| D-iOS-1 | Native Swift + SwiftUI, not Kotlin or Compose Multiplatform | 11 Nov 2026 |
| D-iOS-2 | One universal app for iPhone and iPad with adaptive layouts | 11 Nov 2026 |
| D-iOS-3 | Use the newest stable toolchain and libraries (Xcode 27.2, Swift 6.4.2, iOS 27.2 SDK), pinned and kept current | 11 Nov 2026 |

Still open: minimum iOS 26 (proposed), bundle identifier, repository visibility for free CI.
