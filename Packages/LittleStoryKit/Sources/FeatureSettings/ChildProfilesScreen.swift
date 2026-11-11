import Common
import CoreUI
import DesignSystem
import SwiftUI

/// Where Child Profiles sends the parent; the app maps these to routes.
public struct ChildProfilesNavigation {
    public var back: () -> Void
    public var edit: (String) -> Void
    public var add: () -> Void

    public init(back: @escaping () -> Void, edit: @escaping (String) -> Void, add: @escaping () -> Void) {
        self.back = back
        self.edit = edit
        self.add = add
    }
}

public struct ChildProfilesRoute: View {
    @State private var viewModel: ChildProfilesViewModel
    private let navigation: ChildProfilesNavigation

    public init(viewModel: @autoclosure @escaping () -> ChildProfilesViewModel, navigation: ChildProfilesNavigation) {
        _viewModel = State(wrappedValue: viewModel())
        self.navigation = navigation
    }

    public var body: some View {
        let viewModel = viewModel
        ChildProfilesScreen(
            state: viewModel.state,
            navigation: navigation,
            onSwitch: { id in Task { await viewModel.onSwitch(childID: id) } },
        )
        .task { await viewModel.start() }
    }
}

/// SCR-14: the privacy note, a card per child (active one outlined) and "Add another child".
struct ChildProfilesScreen: View {
    let state: ChildProfilesState
    let navigation: ChildProfilesNavigation
    let onSwitch: (String) -> Void

    var body: some View {
        SettingsPage(
            title: UIText(SettingsStrings.Children.title),
            titleID: SettingsID.childrenTitle,
            onBack: navigation.back,
        ) {
            Button(action: navigation.add) {
                LText(SettingsStrings.Children.add)
                    .lsTextStyle(.chip)
                    .foregroundStyle(LSColor.primary)
                    .frame(minHeight: LSDimens.minTouchTarget)
            }
            .buttonStyle(LSPressStyle())
            .accessibilityIdentifier(SettingsID.addChild)
        } content: {
            NotesBanner(UIText(SettingsStrings.Children.banner), icon: .check)
            if state.loading, state.children.isEmpty {
                LoadingIndicator()
            } else {
                ForEach(state.children) { child in
                    ChildCardView(child: child, onSwitch: { onSwitch(child.id) }, onEdit: { navigation.edit(child.id) })
                }
                AddRow(onAdd: navigation.add)
            }
        }
    }
}

private struct ChildCardView: View {
    let child: ChildCard
    let onSwitch: () -> Void
    let onEdit: () -> Void
    @Environment(\.locale) private var locale

    var body: some View {
        HStack(spacing: LSSpacing.md) {
            Avatar(tone: child.avatarTone, selected: child.active)
            VStack(alignment: .leading, spacing: LSSpacing.xxs) {
                Text(child.name)
                    .lsTextStyle(.itemTitle)
                    .foregroundStyle(LSColor.textPrimary)
                LText(child.ageLanguage)
                    .lsTextStyle(.chip)
                    .foregroundStyle(LSColor.textSecondary)
                if !interests.isEmpty {
                    Text(interests)
                        .lsTextStyle(.chip)
                        .foregroundStyle(LSColor.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
            if child.active {
                HStack(spacing: LSSpacing.xxs) {
                    LSIconView(.check, size: LSDimens.iconSizeSmall)
                    LText(SettingsStrings.Children.active).lsTextStyle(.chip)
                }
                .foregroundStyle(LSColor.primary)
                .padding(.horizontal, LSSpacing.sm)
                .padding(.vertical, LSSpacing.xs)
                .background(LSColor.secondaryContainer, in: .capsule)
            } else {
                Button(action: onSwitch) {
                    LText(SettingsStrings.Children.switchTo)
                        .lsTextStyle(.chip)
                        .foregroundStyle(LSColor.primary)
                        .padding(.horizontal, LSSpacing.md)
                        .frame(minHeight: LSDimens.minTouchTarget)
                }
                .buttonStyle(LSPressStyle())
                .accessibilityIdentifier(SettingsID.switchChild(child.id))
            }
            LSIconButton(.edit, label: child.editLabel.text(locale), action: onEdit)
                .accessibilityIdentifier(SettingsID.editChild(child.id))
        }
        .padding(LSSpacing.lg)
        .background(LSColor.surface, in: .rect(cornerRadius: LSRadius.large))
        .overlay(
            RoundedRectangle(cornerRadius: LSRadius.large)
                .strokeBorder(
                    child.active ? LSColor.accent : LSColor.outline,
                    lineWidth: child.active ? LSDimens.selectedBorderWidth : LSDimens.borderWidth,
                ),
        )
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(SettingsID.child(child.id))
    }

    /// "Animals · Cricket" in the app language.
    private var interests: String {
        child.interestIDs
            .map { UIText(CoreUIStrings.interest($0)).resolved(for: locale) }
            .joined(separator: UIText(SettingsStrings.Children.interestSeparator).resolved(for: locale))
    }
}

private struct AddRow: View {
    let onAdd: () -> Void

    var body: some View {
        Button(action: onAdd) {
            HStack(spacing: LSSpacing.md) {
                LSIconView(.plus)
                    .foregroundStyle(LSColor.primary)
                VStack(alignment: .leading, spacing: LSSpacing.xxs) {
                    LText(SettingsStrings.Children.addAnother)
                        .lsTextStyle(.itemTitle)
                        .foregroundStyle(LSColor.textPrimary)
                    LText(SettingsStrings.Children.addAnotherBody)
                        .lsTextStyle(.chip)
                        .foregroundStyle(LSColor.textSecondary)
                }
                .multilineTextAlignment(.leading)
                Spacer(minLength: LSSpacing.none)
            }
            .padding(LSSpacing.lg)
            .overlay(RoundedRectangle(cornerRadius: LSRadius.large).strokeBorder(LSColor.accent, lineWidth: LSDimens.borderWidth))
            .contentShape(.rect)
        }
        .buttonStyle(LSPressStyle())
        .accessibilityIdentifier(SettingsID.addChildRow)
    }
}
