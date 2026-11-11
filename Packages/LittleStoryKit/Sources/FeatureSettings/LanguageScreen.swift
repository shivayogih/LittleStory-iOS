import Common
import CoreUI
import DesignSystem
import SwiftUI

public struct LanguageRoute: View {
    @State private var viewModel: LanguageViewModel
    private let appLanguageTag: String
    private let onApplyAppLanguage: (String) -> Void
    private let onBack: () -> Void

    /// - Parameters:
    ///   - appLanguageTag: the language the app is shown in now.
    ///   - onApplyAppLanguage: switches the app language at once (the app's `Localizer`).
    public init(
        viewModel: @autoclosure @escaping () -> LanguageViewModel,
        appLanguageTag: String,
        onApplyAppLanguage: @escaping (String) -> Void,
        onBack: @escaping () -> Void,
    ) {
        _viewModel = State(wrappedValue: viewModel())
        self.appLanguageTag = appLanguageTag
        self.onApplyAppLanguage = onApplyAppLanguage
        self.onBack = onBack
    }

    public var body: some View {
        let viewModel = viewModel
        LanguageScreen(
            state: viewModel.state,
            appLanguageTag: appLanguageTag,
            onAppLanguage: onApplyAppLanguage,
            onStoryLanguage: { tag in Task { await viewModel.onStoryLanguageSelected(tag) } },
            onBack: onBack,
        )
        .task { await viewModel.start() }
    }
}

/// SCR-20: app language and story language, listed from the language registry.
struct LanguageScreen: View {
    let state: LanguageState
    let appLanguageTag: String
    let onAppLanguage: (String) -> Void
    let onStoryLanguage: (String) -> Void
    let onBack: () -> Void

    var body: some View {
        SettingsPage(title: UIText(SettingsStrings.Language.title), titleID: SettingsID.languageTitle, onBack: onBack) {
            group(
                UIText(SettingsStrings.Language.appGroup),
                selected: SupportedLanguages.language(forTag: appLanguageTag).tag,
                identifier: SettingsID.appLanguage,
                onSelect: onAppLanguage,
            )
            group(
                UIText(SettingsStrings.Language.storyGroup),
                selected: state.storyLanguageTag,
                identifier: SettingsID.storyLanguage,
                onSelect: onStoryLanguage,
            )
            NotesBanner(UIText(SettingsStrings.Language.fallbackNote), icon: .book)
        }
    }

    private func group(
        _ title: UIText,
        selected: String,
        identifier: @escaping (String) -> String,
        onSelect: @escaping (String) -> Void,
    ) -> some View {
        SettingsGroup(title: title) {
            ForEach(Array(state.languages.enumerated()), id: \.element.tag) { index, language in
                if index > 0 {
                    SettingsDivider()
                }
                SettingsChoiceRow(
                    label: language.nativeName,
                    selected: language.tag == selected,
                    identifier: identifier(language.tag),
                ) { onSelect(language.tag) }
            }
        }
    }
}
