import SwiftUI

/// How much room a screen has. Chosen from the window width, never from the device model, so
/// iPhone, iPad split screen and resized iPad windows all follow the same rules (HLD §6A).
public enum LayoutClass: Sendable, Equatable, CaseIterable {
    case compact
    case medium
    case expanded

    public init(width: CGFloat, sizeClass: UserInterfaceSizeClass?, dynamicTypeSize: DynamicTypeSize) {
        if sizeClass == .compact {
            self = .compact
            return
        }
        let base: LayoutClass = switch width {
        case ..<LayoutTokens.mediumMinWidth: .compact
        case ..<LayoutTokens.expandedMinWidth: .medium
        default: .expanded
        }
        // Accessibility text sizes need more room per item: step down one class so long
        // Kannada text never truncates.
        self = dynamicTypeSize.isAccessibilitySize ? base.smaller : base
    }

    /// One step less room; compact stays compact.
    public var smaller: LayoutClass {
        switch self {
        case .compact, .medium: .compact
        case .expanded: .medium
        }
    }

    /// iPad sidebar and list + detail layouts.
    public var usesSplitView: Bool { self != .compact }

    /// Reader shows two pages side by side.
    public var showsReaderSpread: Bool { self == .expanded }
}

public extension EnvironmentValues {
    /// Set once at the root by `AdaptiveRoot`; every screen reads it.
    @Entry var layoutClass: LayoutClass = .compact
}

/// Measures the window and publishes `layoutClass` to everything inside it.
public struct AdaptiveRoot<Content: View>: View {
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var width: CGFloat = 0
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        content
            .environment(
                \.layoutClass,
                LayoutClass(width: width, sizeClass: sizeClass, dynamicTypeSize: dynamicTypeSize)
            )
            .onGeometryChange(for: CGFloat.self) { proxy in
                proxy.size.width
            } action: { newWidth in
                width = newWidth
            }
    }
}
