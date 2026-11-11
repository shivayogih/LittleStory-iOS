import SwiftUI

/// Scales a control to the design's press scale while pressed; instant under Reduce Motion.
public struct LSPressStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? LSMotion.pressScale : 1)
            .animation(LSMotion.standard(LSMotion.press, reduceMotion: reduceMotion), value: configuration.isPressed)
    }
}

public enum LSButtonVariant: Sendable, CaseIterable {
    case primary
    case secondary
    case ghost
}

/// Full-width button. The design's 52 pt is a minimum height: long Kannada labels wrap and the
/// button grows. The title comes from the caller's String Catalog.
public struct LSButton: View {
    private let title: Text
    private let variant: LSButtonVariant
    private let leadingIcon: LSIcon?
    private let action: () -> Void
    @Environment(\.isEnabled) private var isEnabled

    public init(_ title: Text, variant: LSButtonVariant = .primary, leadingIcon: LSIcon? = nil, action: @escaping () -> Void) {
        self.title = title
        self.variant = variant
        self.leadingIcon = leadingIcon
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: LSSpacing.sm) {
                if let leadingIcon {
                    LSIconView(leadingIcon)
                }
                title
                    .lsTextStyle(.button)
                    .multilineTextAlignment(.center)
            }
            .foregroundStyle(contentColor)
            .padding(.horizontal, LSSpacing.lg)
            .padding(.vertical, LSSpacing.sm)
            .frame(maxWidth: .infinity, minHeight: LSDimens.buttonMinHeight)
            .background(containerColor, in: .rect(cornerRadius: LSRadius.button))
            .lsShadow(variant == .primary ? .primaryButton : .flat)
            .contentShape(.rect(cornerRadius: LSRadius.button))
        }
        .buttonStyle(LSPressStyle())
        .opacity(isEnabled ? 1 : LSDimens.disabledOpacity)
    }

    private var containerColor: Color {
        switch variant {
        case .primary: LSColor.primary
        case .secondary: LSColor.secondaryContainer
        case .ghost: .clear
        }
    }

    private var contentColor: Color {
        switch variant {
        case .primary: LSColor.onPrimary
        case .secondary: LSColor.onSecondaryContainer
        case .ghost: LSColor.primary
        }
    }
}

/// Circular icon button: a 42 pt disc inside a 44 pt hit target. The label is required because
/// the icon is the only content. `active` draws the favourite style (rose on pink).
public struct LSIconButton: View {
    private let icon: LSIcon
    private let label: Text
    private let active: Bool
    private let action: () -> Void
    @Environment(\.isEnabled) private var isEnabled

    public init(_ icon: LSIcon, label: Text, active: Bool = false, action: @escaping () -> Void) {
        self.icon = icon
        self.label = label
        self.active = active
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            LSIconView(icon)
                .foregroundStyle(active ? LSColor.favourite : LSColor.textPrimary)
                .frame(width: LSDimens.iconButtonVisual, height: LSDimens.iconButtonVisual)
                .background(
                    active ? LSColor.favouriteContainer : LSColor.surface.opacity(LSDimens.iconButtonSurfaceOpacity),
                    in: .circle,
                )
                .frame(minWidth: LSDimens.minTouchTarget, minHeight: LSDimens.minTouchTarget)
                .contentShape(.circle)
        }
        .buttonStyle(LSPressStyle())
        .opacity(isEnabled ? 1 : LSDimens.disabledOpacity)
        .accessibilityLabel(label)
        .accessibilityAddTraits(active ? .isSelected : [])
    }
}
