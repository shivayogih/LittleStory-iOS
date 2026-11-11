import CoreUI
import Foundation

/// Typed keys for this target's `Localizable.xcstrings` (Profile and the screens it opens).
enum SettingsStrings {
    private static func key(_ name: String) -> LocalizedKey {
        LocalizedKey(name, bundle: .module)
    }

    enum Profile {
        static let title = key("profile.title")
        static let family = key("profile.family")
        static let privateNote = key("profile.private_note")
        static let editChild = key("profile.edit_child")
        static let addChild = key("profile.add_child")
        static let groupChildren = key("profile.group_children")
        static let manageChildren = key("profile.manage_children")
        static let childrenCount = key("profile.children_count")
        static let language = key("profile.language")
        static let languageSplit = key("profile.language_split")
        static let groupExperience = key("profile.group_experience")
        static let reminder = key("profile.reminder")
        static let reminderEveryDay = key("profile.reminder_every_day")
        static let reminderSomeDays = key("profile.reminder_some_days")
        static let reminderOff = key("profile.reminder_off")
        static let notifications = key("profile.notifications")
        static let notificationsSubtitle = key("profile.notifications_subtitle")
        static let audio = key("profile.audio")
        static let audioSubtitle = key("profile.audio_subtitle")
        static let downloads = key("profile.downloads")
        static let downloadsWifi = key("profile.downloads_wifi")
        static let downloadsAny = key("profile.downloads_any")
        static let groupApp = key("profile.group_app")
        static let subscription = key("profile.subscription")
        static let subscriptionSubtitle = key("profile.subscription_subtitle")
        static let privacy = key("profile.privacy")
        static let privacySubtitle = key("profile.privacy_subtitle")
        static let help = key("profile.help")
        static let helpSubtitle = key("profile.help_subtitle")
        static let footer = key("profile.footer")
    }

    enum Children {
        static let title = key("children.title")
        static let add = key("children.add")
        static let banner = key("children.banner")
        static let ageLanguage = key("children.age_language")
        static let interestSeparator = key("children.interest_separator")
        static let active = key("children.active")
        static let switchTo = key("children.switch")
        static let edit = key("children.edit")
        static let addAnother = key("children.add_another")
        static let addAnotherBody = key("children.add_another_body")
    }

    enum Notifications {
        static let title = key("notifications.title")
        static let markAll = key("notifications.mark_all")
        static let today = key("notifications.today")
        static let earlier = key("notifications.earlier")
        static let unread = key("notifications.unread")
        static let emptyTitle = key("notifications.empty_title")
        static let emptyText = key("notifications.empty_text")
    }

    enum Language {
        static let title = key("language.title")
        static let appGroup = key("language.app_group")
        static let storyGroup = key("language.story_group")
        static let fallbackNote = key("language.fallback_note")
    }

    enum Help {
        static let title = key("help.title")
        static let groupQuestions = key("help.group_questions")
        static let groupAbout = key("help.group_about")
        static let versionTitle = key("help.version_title")
        static let versionBody = key("help.version_body")
        static let licencesTitle = key("help.licences_title")
        static let licencesBody = key("help.licences_body_ios")
        /// Question and answer keys, in order.
        static let questions: [(LocalizedKey, LocalizedKey)] = ["stories", "offline", "language", "children"].map {
            (key("help.q_\($0)"), key("help.a_\($0)"))
        }
    }
}

/// Accessibility identifiers for UI tests; never user-facing.
public enum SettingsID {
    public static let profileTitle = "profile.title"
    public static let childCard = "profile.child_card"
    public static let children = "profile.children"
    public static let language = "profile.language"
    public static let reminder = "profile.reminder"
    public static let notifications = "profile.notifications"
    public static let audio = "profile.audio"
    public static let downloads = "profile.downloads"
    public static let subscription = "profile.subscription"
    public static let privacy = "profile.privacy"
    public static let help = "profile.help"
    public static func toggle(_ row: String) -> String { "\(row).toggle" }

    public static let back = "settings.back"
    public static let childrenTitle = "children.title"
    public static let addChild = "children.add"
    public static let addChildRow = "children.add_row"
    public static func child(_ id: String) -> String { "children.child.\(id)" }
    public static func switchChild(_ id: String) -> String { "children.switch.\(id)" }
    public static func editChild(_ id: String) -> String { "children.edit.\(id)" }

    public static let notificationsTitle = "notifications.title"
    public static let markAll = "notifications.mark_all"
    public static let notificationsEmpty = "notifications.empty"
    public static func notification(_ id: String) -> String { "notifications.item.\(id)" }

    public static let languageTitle = "language.title"
    public static func appLanguage(_ tag: String) -> String { "language.app.\(tag)" }
    public static func storyLanguage(_ tag: String) -> String { "language.story.\(tag)" }

    public static let helpTitle = "help.title"
    public static let version = "help.version"
}
