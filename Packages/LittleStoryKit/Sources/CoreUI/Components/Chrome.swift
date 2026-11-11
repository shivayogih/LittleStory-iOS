import Common
import DesignSystem
import SwiftUI

/// Brand mark: a rounded book tile with a sparkle, then the name. `light` is for night backgrounds.
public struct BrandMark: View {
    private let light: Bool
    @Environment(\.locale) private var locale

    public init(light: Bool = false) {
        self.light = light
    }

    public var body: some View {
        HStack(spacing: LSSpacing.sm) {
            LSIconView(.book)
                .padding(LSSpacing.xs)
                .overlay(RoundedRectangle(cornerRadius: LSRadius.small).strokeBorder(lineWidth: LSDimens.selectedBorderWidth))
                .overlay(alignment: .topTrailing) {
                    Sparkle().fill(LSColor.highlight).frame(width: LSSpacing.md, height: LSSpacing.md)
                }
            LText(UIText(CoreUIStrings.brandName))
                .lsTextStyle(.brandName)
        }
        .foregroundStyle(light ? LSColor.onNight : LSColor.primary)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

/// Green "Private & parent-managed" style banner with an icon.
public struct NotesBanner: View {
    private let text: UIText
    private let icon: LSIcon

    public init(_ text: UIText, icon: LSIcon) {
        self.text = text
        self.icon = icon
    }

    public var body: some View {
        HStack(spacing: LSSpacing.sm) {
            LSIconView(icon, size: LSDimens.iconSizeSmall)
            LText(text).lsTextStyle(.chip)
        }
        .foregroundStyle(LSColor.success)
        .padding(.horizontal, LSSpacing.md)
        .padding(.vertical, LSSpacing.sm)
        .background(LSColor.successContainer, in: .capsule)
    }
}

/// A primary button pinned above the home indicator, on the screen background.
public struct StickyActionBar: View {
    private let title: UIText
    private let enabled: Bool
    private let identifier: String
    private let action: () -> Void
    @Environment(\.locale) private var locale

    public init(_ title: UIText, enabled: Bool = true, identifier: String, action: @escaping () -> Void) {
        self.title = title
        self.enabled = enabled
        self.identifier = identifier
        self.action = action
    }

    public var body: some View {
        LSButton(title.text(locale), action: action)
            .disabled(!enabled)
            .accessibilityIdentifier(identifier)
            .padding(.horizontal, LSSpacing.screenHorizontal)
            .padding(.top, LSSpacing.md)
            .padding(.bottom, LSSpacing.sm)
            .background(LSColor.background)
    }
}

/// A child's drawn avatar on a rounded tile; `tone` picks one of the designed looks.
public struct Avatar: View {
    private let tone: Int
    private let selected: Bool
    private let size: CGFloat
    private static let faceRatio = 0.64
    private static let hairRatio = 0.3
    private static let tones: [Color] = [LSColor.Illustration.skin, LSColor.Illustration.skinLight, LSColor.Illustration.terracotta]

    public init(tone: Int, selected: Bool = false, size: CGFloat = LSDimens.avatarSize) {
        self.tone = tone
        self.selected = selected
        self.size = size
    }

    public var body: some View {
        ZStack(alignment: .top) {
            LSColor.warmAccent
            Circle()
                .fill(Self.tones[abs(tone) % Self.tones.count])
                .frame(width: size * Self.faceRatio, height: size * Self.faceRatio)
                .overlay(alignment: .top) {
                    UnevenRoundedRectangle(topLeadingRadius: size, topTrailingRadius: size)
                        .fill(LSColor.Illustration.hair)
                        .frame(height: size * Self.hairRatio)
                }
                .clipShape(.circle)
                .offset(y: size * (1 - Self.faceRatio) / 2)
        }
        .frame(width: size, height: size)
        .clipShape(.rect(cornerRadius: LSRadius.avatar))
        .padding(selected ? LSDimens.focusRingWidth : 0)
        .overlay(
            RoundedRectangle(cornerRadius: LSRadius.avatarLarge)
                .strokeBorder(selected ? LSColor.accent : .clear, lineWidth: LSDimens.focusRingWidth),
        )
        .accessibilityHidden(true)
    }
}

/// Shows a spinner only after `AppConfig.UI.loadingIndicatorDelay`, so fast loads never flash it.
public struct LoadingIndicator: View {
    @State private var visible = false
    @Environment(\.locale) private var locale

    public init() {}

    public var body: some View {
        ProgressView()
            .tint(LSColor.primary)
            .frame(maxWidth: .infinity, minHeight: LSDimens.loadingIndicatorSize)
            .opacity(visible ? 1 : 0)
            .accessibilityLabel(UIText(CoreUIStrings.stateLoading))
            .task {
                try? await Task.sleep(for: AppConfig.UI.loadingIndicatorDelay)
                visible = true
            }
    }
}

/// Icon, title, text and an optional action, centred.
public struct EmptyState: View {
    private let icon: LSIcon
    private let title: UIText
    private let message: UIText
    private let actionTitle: UIText?
    private let action: () -> Void
    @Environment(\.locale) private var locale

    public init(icon: LSIcon, title: UIText, message: UIText, actionTitle: UIText? = nil, action: @escaping () -> Void = {}) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }

    public var body: some View {
        VStack(spacing: LSSpacing.md) {
            LSIconView(icon, size: LSDimens.iconSize)
                .foregroundStyle(LSColor.primary)
                .frame(width: LSDimens.emptyStateIconSize, height: LSDimens.emptyStateIconSize)
                .background(LSColor.secondaryContainer, in: .circle)
            LText(title)
                .lsTextStyle(.homeTitle)
                .foregroundStyle(LSColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
            LText(message)
                .lsTextStyle(.body)
                .foregroundStyle(LSColor.textSecondary)
            if let actionTitle {
                LSButton(actionTitle.text(locale), variant: .secondary, action: action)
            }
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: LayoutTokens.readableMaxWidth)
        .padding(LSSpacing.xxl)
    }
}

/// Placeholder for screens that later phases build, so every tap in the app goes somewhere.
public struct ComingSoonView: View {
    public init() {}

    public var body: some View {
        EmptyState(icon: .moon, title: UIText(CoreUIStrings.comingSoonTitle), message: UIText(CoreUIStrings.comingSoonText))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(LSColor.background)
            .accessibilityIdentifier(ComingSoonView.identifier)
    }

    public static let identifier = "app.coming_soon"
}
