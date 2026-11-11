import CoreUI
import DesignSystem
import SwiftUI

/// A titled white card of settings rows separated by hairlines (SCR-13).
struct SettingsGroup<Content: View>: View {
    let title: UIText
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: LSSpacing.sm) {
            LText(title)
                .lsTextStyle(.eyebrow)
                .foregroundStyle(LSColor.textSecondary)
                .padding(.leading, LSSpacing.xs)
                .accessibilityAddTraits(.isHeader)
            VStack(spacing: LSSpacing.none) {
                content()
            }
            .frame(maxWidth: .infinity)
            .background(LSColor.surface, in: .rect(cornerRadius: LSRadius.large))
        }
    }
}

struct SettingsDivider: View {
    var body: some View {
        LSColor.outline
            .frame(height: LSDimens.borderWidth)
            .padding(.horizontal, LSSpacing.lg)
    }
}

/// One settings row: icon tile, title, live subtitle. The row body opens its screen when `onOpen`
/// is set; a toggle is a separate target beside it, so nothing interactive is nested.
struct SettingsRow: View {
    let icon: LSIcon
    let title: UIText
    let subtitle: UIText
    let identifier: String
    var onOpen: (() -> Void)?
    var toggle: Bool?
    var onToggle: (Bool) -> Void = { _ in }

    var body: some View {
        HStack(spacing: LSSpacing.none) {
            if let onOpen {
                Button(action: onOpen) { label }
                    .buttonStyle(LSPressStyle())
                    .accessibilityIdentifier(identifier)
            } else {
                label
                    .accessibilityElement(children: .combine)
                    .accessibilityIdentifier(identifier)
            }
            if let toggle {
                Toggle(isOn: Binding(get: { toggle }, set: onToggle)) {
                    LText(title)
                }
                .labelsHidden()
                .tint(LSColor.primary)
                .padding(.trailing, LSSpacing.lg)
                .accessibilityIdentifier(SettingsID.toggle(identifier))
            }
        }
    }

    private var label: some View {
        HStack(spacing: LSSpacing.md) {
            LSIconView(icon, size: LSDimens.iconSizeSmall)
                .foregroundStyle(LSColor.primary)
                .frame(width: LSDimens.settingsIconTile, height: LSDimens.settingsIconTile)
                .background(LSColor.secondaryContainer, in: .rect(cornerRadius: LSRadius.small))
            VStack(alignment: .leading, spacing: LSSpacing.xxs) {
                LText(title)
                    .lsTextStyle(.itemTitle)
                    .foregroundStyle(LSColor.textPrimary)
                LText(subtitle)
                    .lsTextStyle(.chip)
                    .foregroundStyle(LSColor.textSecondary)
            }
            .multilineTextAlignment(.leading)
            Spacer(minLength: LSSpacing.none)
            if onOpen != nil, toggle == nil {
                LSIconView(.chevron, size: LSDimens.iconSizeSmall)
                    .foregroundStyle(LSColor.textPrimary)
                    .flipsForRightToLeftLayoutDirection(true)
            }
        }
        .padding(LSSpacing.lg)
        .frame(minHeight: LSDimens.minTouchTarget)
        .contentShape(.rect)
    }
}

/// A single-choice row: the whole row is the target and a check marks the selection (SCR-20).
struct SettingsChoiceRow: View {
    let label: String
    let selected: Bool
    let identifier: String
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack {
                Text(label)
                    .lsTextStyle(.itemTitle)
                    .foregroundStyle(LSColor.textPrimary)
                Spacer(minLength: LSSpacing.sm)
                if selected {
                    LSIconView(.check, size: LSDimens.iconSizeSmall)
                        .foregroundStyle(LSColor.primary)
                }
            }
            .padding(LSSpacing.lg)
            .frame(minHeight: LSDimens.minTouchTarget)
            .contentShape(.rect)
        }
        .buttonStyle(LSPressStyle())
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityIdentifier(identifier)
    }
}

/// Plain explanatory text inside a settings card.
struct SettingsParagraph: View {
    let title: UIText
    let text: UIText

    var body: some View {
        VStack(alignment: .leading, spacing: LSSpacing.xxs) {
            LText(title)
                .lsTextStyle(.itemTitle)
                .foregroundStyle(LSColor.textPrimary)
            LText(text)
                .lsTextStyle(.chip)
                .foregroundStyle(LSColor.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(LSSpacing.lg)
        .accessibilityElement(children: .combine)
    }
}

/// Back button, centred title and an optional trailing action, above a scrolling settings page.
struct SettingsPage<Trailing: View, Content: View>: View {
    let title: UIText
    let titleID: String
    let onBack: () -> Void
    @ViewBuilder let trailing: () -> Trailing
    @ViewBuilder let content: () -> Content
    @Environment(\.locale) private var locale

    var body: some View {
        VStack(spacing: LSSpacing.none) {
            HStack(spacing: LSSpacing.sm) {
                LSIconButton(.back, label: CoreUIStrings.actionBack.text(locale), action: onBack)
                    .accessibilityIdentifier(SettingsID.back)
                LText(title)
                    .lsTextStyle(.topBarTitle)
                    .foregroundStyle(LSColor.textPrimary)
                    .frame(maxWidth: .infinity)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier(titleID)
                trailing()
                    .frame(minWidth: LSDimens.minTouchTarget, minHeight: LSDimens.minTouchTarget)
            }
            .padding(.horizontal, LSSpacing.screenHorizontal)
            .frame(minHeight: LSDimens.topBarHeight)
            ScrollView {
                VStack(alignment: .leading, spacing: LSSpacing.xl) {
                    content()
                }
                .frame(maxWidth: LayoutTokens.readableMaxWidth)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, LSSpacing.screenHorizontal)
                .padding(.vertical, LSSpacing.md)
            }
        }
        .background(LSColor.background)
        .toolbar(.hidden, for: .navigationBar)
    }
}

extension SettingsPage where Trailing == EmptyView {
    init(title: UIText, titleID: String, onBack: @escaping () -> Void, @ViewBuilder content: @escaping () -> Content) {
        self.init(title: title, titleID: titleID, onBack: onBack, trailing: { EmptyView() }, content: content)
    }
}
