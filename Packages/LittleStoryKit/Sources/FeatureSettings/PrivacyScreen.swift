import Common
import CoreUI
import DesignSystem
import SwiftUI

public struct PrivacyRoute: View {
    @State private var viewModel: PrivacyViewModel
    private let onBack: () -> Void
    private let onDeleted: () -> Void

    /// - Parameter onDeleted: runs after all local data is gone; the app restarts the first-run flow.
    public init(viewModel: @autoclosure @escaping () -> PrivacyViewModel, onBack: @escaping () -> Void, onDeleted: @escaping () -> Void) {
        _viewModel = State(wrappedValue: viewModel())
        self.onBack = onBack
        self.onDeleted = onDeleted
    }

    public var body: some View {
        let viewModel = viewModel
        PrivacyScreen(
            state: viewModel.state,
            onBack: onBack,
            onDelete: viewModel.onDeleteTapped,
            onConfirm: { Task { await viewModel.onConfirmDelete() } },
            onDismiss: viewModel.onConfirmDismissed,
        )
        .task {
            for await effect in viewModel.effects where effect == .deleted {
                onDeleted()
            }
        }
    }
}

/// SCR-21, built from settings components until a design exists (Android D10).
struct PrivacyScreen: View {
    let state: PrivacyState
    let onBack: () -> Void
    let onDelete: () -> Void
    let onConfirm: () -> Void
    let onDismiss: () -> Void
    @Environment(\.locale) private var locale

    var body: some View {
        SettingsPage(title: UIText(SettingsStrings.Privacy.title), titleID: SettingsID.privacyTitle, onBack: onBack) {
            NotesBanner(UIText(SettingsStrings.Privacy.banner), icon: .check)
            if state.showDraftNotice {
                NotesBanner(UIText(SettingsStrings.Privacy.draftNotice), icon: .edit)
                    .accessibilityIdentifier(SettingsID.draftNotice)
            }
            paragraphs(UIText(SettingsStrings.Privacy.groupData), SettingsStrings.Privacy.data)
            SettingsGroup(title: UIText(SettingsStrings.Privacy.groupSafety)) {
                SettingsParagraph(
                    title: UIText(SettingsStrings.Privacy.audienceTitle),
                    text: SettingsStrings.Privacy.audienceBody(
                        .number(AppConfig.Setup.ageRange.lowerBound),
                        .number(AppConfig.Setup.ageRange.upperBound),
                    ),
                )
                ForEach(SettingsStrings.Privacy.safety.indices, id: \.self) { index in
                    SettingsDivider()
                    SettingsParagraph(
                        title: UIText(SettingsStrings.Privacy.safety[index].0),
                        text: UIText(SettingsStrings.Privacy.safety[index].1),
                    )
                }
            }
            paragraphs(UIText(SettingsStrings.Privacy.groupPolicy), SettingsStrings.Privacy.policy)
            SettingsGroup(title: UIText(SettingsStrings.Privacy.groupControls)) {
                SettingsParagraph(title: UIText(SettingsStrings.Privacy.deleteTitle), text: UIText(SettingsStrings.Privacy.deleteBody))
                LSButton(SettingsStrings.Privacy.deleteAction.text(locale), variant: .secondary, action: onDelete)
                    .disabled(state.deleting)
                    .padding([.horizontal, .bottom], LSSpacing.lg)
                    .accessibilityIdentifier(SettingsID.deleteAll)
            }
        }
        .alert(
            SettingsStrings.Privacy.confirmTitle.text(locale),
            isPresented: Binding(get: { state.confirmOpen }, set: { open in
                if !open {
                    onDismiss()
                }
            }),
        ) {
            Button(role: .destructive, action: onConfirm) {
                SettingsStrings.Privacy.confirmAction.text(locale)
            }
            .accessibilityIdentifier(SettingsID.confirmDelete)
            Button(role: .cancel, action: onDismiss) {
                SettingsStrings.Privacy.cancel.text(locale)
            }
        } message: {
            SettingsStrings.Privacy.confirmBody.text(locale)
        }
    }

    private func paragraphs(_ title: UIText, _ items: [(LocalizedKey, LocalizedKey)]) -> some View {
        SettingsGroup(title: title) {
            ForEach(items.indices, id: \.self) { index in
                if index > 0 {
                    SettingsDivider()
                }
                SettingsParagraph(title: UIText(items[index].0), text: UIText(items[index].1))
            }
        }
    }
}
