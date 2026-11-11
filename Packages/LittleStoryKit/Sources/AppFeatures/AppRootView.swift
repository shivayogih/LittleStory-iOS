import CoreUI
import DesignSystem
import SwiftUI

/// Accessibility identifiers for UI tests; never user-facing text.
public enum AppAccessibilityID {
    public static let launchTitle = "app.launch.title"
    public static let launchTagline = "app.launch.tagline"
}

/// Root of the app. Phase I0 shows a placeholder; later phases switch between onboarding and the
/// tab shell (`AppRouter`, LLD §6).
public struct AppRootView: View {
    public init() {}

    public var body: some View {
        AdaptiveRoot {
            LaunchPlaceholder()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(LSColor.background)
        }
        // One light theme with night surfaces (Android ADR-013) until a dark palette is designed.
        .preferredColorScheme(.light)
    }
}

private struct LaunchPlaceholder: View {
    var body: some View {
        VStack(spacing: LSSpacing.md) {
            Text(CoreUIStrings.appName)
                .lsTextStyle(.displayOnboarding)
                .accessibilityIdentifier(AppAccessibilityID.launchTitle)
                .accessibilityAddTraits(.isHeader)
            Text(CoreUIStrings.launchTagline)
                .lsTextStyle(.bodyLarge)
                .foregroundStyle(LSColor.textSecondary)
                .multilineTextAlignment(.center)
                .accessibilityIdentifier(AppAccessibilityID.launchTagline)
        }
        .foregroundStyle(LSColor.textPrimary)
        .padding(LSSpacing.screenHorizontal)
        .frame(maxWidth: LayoutTokens.readableMaxWidth)
    }
}

#Preview("iPhone") {
    AppRootView()
}
