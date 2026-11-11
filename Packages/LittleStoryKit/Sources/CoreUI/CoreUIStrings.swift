import Foundation

/// Typed keys for CoreUI's `Localizable.xcstrings` (shared actions, story metadata, tabs).
public enum CoreUIStrings {
    private static func key(_ name: String) -> LocalizedKey {
        LocalizedKey(name, bundle: .module)
    }

    public static var appName: LocalizedStringResource { resource("app.name") }
    public static var launchTagline: LocalizedStringResource { resource("launch.tagline") }

    public static let actionContinue = key("action.continue")
    public static let actionSkip = key("action.skip")
    public static let actionBack = key("action.back")
    public static let actionTryAgain = key("action.try_again")
    public static let stateLoading = key("state.loading")
    public static let errorGeneric = key("error.generic")
    public static let metaMinutes = key("meta.minutes")
    public static let storyCardMeta = key("story.card_meta")
    public static let storyListMeta = key("story.list_meta")
    public static let storyOffline = key("story.offline")
    public static let storyFavouriteAdd = key("story.favourite_add")
    public static let storyFavouriteRemove = key("story.favourite_remove")
    public static let brandName = key("app.name")
    public static let comingSoonTitle = key("coming_soon.title")
    public static let comingSoonText = key("coming_soon.text")

    public enum ParentalGate {
        public static let title = key("parental.gate_title")
        public static let body = key("parental.gate_body")
        public static let question = key("parental.gate_question")
        public static let answer = key("parental.gate_answer")
        public static let wrong = key("parental.gate_wrong")
        public static let clear = key("parental.gate_clear")
        public static let cancel = key("parental.gate_cancel")
    }

    public enum Tab {
        public static let home = key("nav.home")
        public static let discover = key("nav.discover")
        public static let create = key("nav.create")
        public static let stories = key("nav.stories")
        public static let profile = key("nav.profile")
    }

    /// Label of a Setup interest or Create theme chip; unknown ids show the id's English source.
    public static func interest(_ id: String) -> LocalizedKey {
        key("interest.\(id)")
    }

    /// Same key resolved for a specific language, used by tests and the in-app language override.
    static func resource(_ key: String.LocalizationValue, locale: Locale = .current) -> LocalizedStringResource {
        LocalizedStringResource(key, locale: locale, bundle: .atURL(Bundle.module.bundleURL))
    }
}
