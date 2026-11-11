import Common
import Domain
import Observation

public struct LanguageState: Sendable, Hashable {
    public var languages = SupportedLanguages.enabled
    public var storyLanguageTag = SupportedLanguages.fallback.tag
}

/// Language preferences (SCR-20). The story language is a preference; the app language belongs to
/// the app's `Localizer`, so the screen gets it and a way to change it from the app.
@MainActor
@Observable
public final class LanguageViewModel {
    public private(set) var state = LanguageState()
    @ObservationIgnored private let preferences: any PreferencesRepository

    public init(preferences: any PreferencesRepository) {
        self.preferences = preferences
    }

    public func start() async {
        for await tag in preferences.contentLanguageTag() {
            state.storyLanguageTag = SupportedLanguages.language(forTag: tag).tag
        }
    }

    public func onStoryLanguageSelected(_ tag: String) async {
        await preferences.setContentLanguageTag(SupportedLanguages.language(forTag: tag).tag)
    }
}
