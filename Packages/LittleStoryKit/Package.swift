// swift-tools-version: 6.2
// Toolchain: Xcode 27.2 (Swift 6.4.2). The manifest format only needs 6.2 (first with .iOS(.v26)),
// so CI images that are a point release behind can still read it. Targets and allowed imports: docs/architecture/low-level-design.md §1.
import PackageDescription

let featureDependencies: [Target.Dependency] = ["CoreUI", "DesignSystem", "Domain", "Common"]

let package = Package(
    name: "LittleStoryKit",
    defaultLocalization: "en",
    platforms: [.iOS(.v26)],
    products: [
        .library(name: "AppFeatures", targets: ["AppFeatures"]),
        .library(name: "DataLayer", targets: ["DataLayer"]),
    ],
    targets: [
        // Pure Swift layers
        .target(name: "Common"),
        .target(name: "Domain", dependencies: ["Common"]),
        // Named DataLayer, not Data, so it never clashes with Foundation.Data.
        .target(name: "DataLayer", dependencies: ["Domain", "Common"]),

        // UI foundations
        .target(name: "DesignSystem"),
        .target(name: "CoreUI", dependencies: ["DesignSystem", "Domain", "Common"], resources: [.process("Resources")]),

        // Features: never depend on each other or on DataLayer
        .target(name: "FeatureOnboarding", dependencies: featureDependencies),
        .target(name: "FeatureHome", dependencies: featureDependencies),
        .target(name: "FeatureDiscover", dependencies: featureDependencies),
        .target(name: "FeatureCreate", dependencies: featureDependencies),
        .target(name: "FeatureReader", dependencies: featureDependencies),
        .target(name: "FeatureLibrary", dependencies: featureDependencies),
        .target(name: "FeatureSettings", dependencies: featureDependencies),
        .target(
            name: "AppFeatures",
            dependencies: [
                "FeatureOnboarding", "FeatureHome", "FeatureDiscover", "FeatureCreate",
                "FeatureReader", "FeatureLibrary", "FeatureSettings", "CoreUI", "DesignSystem",
            ]
        ),

        // Test helpers
        .target(name: "TestSupport", dependencies: ["Domain", "Common"]),

        .testTarget(name: "CommonTests", dependencies: ["Common", "TestSupport"]),
        .testTarget(name: "DesignSystemTests", dependencies: ["DesignSystem"]),
        .testTarget(name: "CoreUITests", dependencies: ["CoreUI"]),
    ],
    swiftLanguageModes: [.v6]
)
