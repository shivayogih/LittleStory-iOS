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
        // Mock JSON is copied as a folder so the files keep the same names as on Android.
        .target(name: "DataLayer", dependencies: ["Domain", "Common"], resources: [.copy("Resources/Mock")]),

        // UI foundations
        .target(name: "DesignSystem", resources: [.process("Resources")]),
        .target(name: "CoreUI", dependencies: ["DesignSystem", "Domain", "Common"], resources: [.process("Resources")]),

        // Features: never depend on each other or on DataLayer
        .target(name: "FeatureOnboarding", dependencies: featureDependencies, resources: [.process("Resources")]),
        .target(name: "FeatureHome", dependencies: featureDependencies, resources: [.process("Resources")]),
        .target(name: "FeatureDiscover", dependencies: featureDependencies, resources: [.process("Resources")]),
        .target(name: "FeatureCreate", dependencies: featureDependencies, resources: [.process("Resources")]),
        .target(name: "FeatureReader", dependencies: featureDependencies, resources: [.process("Resources")]),
        .target(name: "FeatureLibrary", dependencies: featureDependencies),
        .target(name: "FeatureSettings", dependencies: featureDependencies),
        .target(
            name: "AppFeatures",
            dependencies: [
                "FeatureOnboarding", "FeatureHome", "FeatureDiscover", "FeatureCreate",
                "FeatureReader", "FeatureLibrary", "FeatureSettings", "CoreUI", "DesignSystem", "Domain", "Common",
            ],
        ),

        // Test helpers
        .target(name: "TestSupport", dependencies: ["Domain", "Common"]),

        .testTarget(name: "CommonTests", dependencies: ["Common", "TestSupport"]),
        .testTarget(name: "DomainTests", dependencies: ["Domain", "Common", "TestSupport"]),
        .testTarget(name: "DataLayerTests", dependencies: ["DataLayer", "Domain", "Common", "TestSupport"]),
        .testTarget(name: "DesignSystemTests", dependencies: ["DesignSystem"]),
        .testTarget(name: "CoreUITests", dependencies: ["CoreUI", "Domain", "TestSupport"]),
        .testTarget(name: "FeatureOnboardingTests", dependencies: ["FeatureOnboarding", "CoreUI", "Domain", "Common", "TestSupport"]),
        .testTarget(name: "FeatureHomeTests", dependencies: ["FeatureHome", "CoreUI", "Domain", "Common", "TestSupport"]),
        .testTarget(name: "FeatureDiscoverTests", dependencies: ["FeatureDiscover", "CoreUI", "Domain", "Common", "TestSupport"]),
        .testTarget(name: "FeatureCreateTests", dependencies: ["FeatureCreate", "CoreUI", "Domain", "Common", "TestSupport"]),
        .testTarget(name: "FeatureReaderTests", dependencies: ["FeatureReader", "CoreUI", "Domain", "Common", "TestSupport"]),
        .testTarget(name: "AppFeaturesTests", dependencies: ["AppFeatures", "CoreUI", "Domain", "Common", "TestSupport"]),
    ],
    swiftLanguageModes: [.v6],
)
