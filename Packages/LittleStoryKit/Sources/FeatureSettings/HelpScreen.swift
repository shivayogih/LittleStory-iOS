import Common
import CoreUI
import DesignSystem
import SwiftUI

/// SCR-22: questions and answers, the version and the open-source licences.
public struct HelpRoute: View {
    private let appInfo: AppInfo
    private let onBack: () -> Void

    public init(appInfo: AppInfo, onBack: @escaping () -> Void) {
        self.appInfo = appInfo
        self.onBack = onBack
    }

    public var body: some View {
        SettingsPage(title: UIText(SettingsStrings.Help.title), titleID: SettingsID.helpTitle, onBack: onBack) {
            SettingsGroup(title: UIText(SettingsStrings.Help.groupQuestions)) {
                ForEach(Array(SettingsStrings.Help.questions.enumerated()), id: \.offset) { index, pair in
                    if index > 0 {
                        SettingsDivider()
                    }
                    SettingsParagraph(title: UIText(pair.0), text: UIText(pair.1))
                }
            }
            SettingsGroup(title: UIText(SettingsStrings.Help.groupAbout)) {
                SettingsParagraph(
                    title: UIText(SettingsStrings.Help.versionTitle),
                    text: SettingsStrings.Help.versionBody(.text(appInfo.version), .number(Int(appInfo.build) ?? 0)),
                )
                .accessibilityIdentifier(SettingsID.version)
                SettingsDivider()
                SettingsParagraph(
                    title: UIText(SettingsStrings.Help.licencesTitle),
                    text: SettingsStrings.Help.licencesBody(.text(Self.fontNames)),
                )
            }
        }
    }

    /// Bundled font families, by their published names (not translated).
    private static var fontNames: String {
        LSFontFamily.allCases.map(\.displayName).sorted().joined(separator: ", ")
    }
}
