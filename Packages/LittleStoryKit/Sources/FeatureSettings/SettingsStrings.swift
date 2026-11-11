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

    enum Reminder {
        static let title = key("reminder.title")
        static let panelTitle = key("reminder.panel_title")
        static let panelBody = key("reminder.panel_body")
        static let toggle = key("reminder.toggle")
        static let toggleHint = key("reminder.toggle_hint")
        static let time = key("reminder.time")
        static let repeatOn = key("reminder.repeat")
        static let quietTitle = key("reminder.quiet_title")
        static let quietBody = key("reminder.quiet_body")
        static let save = key("reminder.save")
        static let saved = key("reminder.saved")
    }

    enum Privacy {
        static let title = key("privacy.title")
        static let banner = key("privacy.banner")
        static let draftNotice = key("privacy.draft_notice")
        static let groupData = key("privacy.group_data")
        static let groupSafety = key("privacy.group_safety")
        static let groupPolicy = key("privacy.group_policy")
        static let groupControls = key("privacy.group_controls")
        static let audienceTitle = key("privacy.audience_title")
        static let audienceBody = key("privacy.audience_body")
        static let deleteTitle = key("privacy.delete_title")
        static let deleteBody = key("privacy.delete_body")
        static let deleteAction = key("privacy.delete_action")
        static let confirmTitle = key("privacy.confirm_title")
        static let confirmBody = key("privacy.confirm_body")
        static let confirmAction = key("privacy.confirm_action")
        static let cancel = key("profile.cancel")
        /// "What we keep", "What leaves the device", "Story creation".
        static let data = pairs(["stored", "shared", "creation"])
        /// After the audience paragraph.
        static let safety = pairs(["no_ads", "gate", "content"])
        /// The draft policy; "keep" has iOS wording (iOS backs app data up with the device).
        static let policy = [
            (key("privacy.policy_children_title"), key("privacy.policy_children_body")),
            (key("privacy.policy_keep_title"), key("privacy.policy_keep_body_ios")),
            (key("privacy.policy_rights_title"), key("privacy.policy_rights_body")),
            (key("privacy.policy_changes_title"), key("privacy.policy_changes_body")),
            (key("privacy.policy_contact_title"), key("privacy.policy_contact_body")),
        ]

        private static func pairs(_ names: [String]) -> [(LocalizedKey, LocalizedKey)] {
            names.map { (key("privacy.\($0)_title"), key("privacy.\($0)_body")) }
        }
    }

    enum Subscription {
        static let kicker = key("subscription.kicker")
        static let title = key("subscription.title")
        static let body = key("subscription.body")
        static let bestValue = key("subscription.best_value")
        static let note = key("subscription.note")
        static let choose = key("subscription.choose")
        static let dialogTitle = key("subscription.dialog_title")
        static let dialogText = key("subscription.dialog_text")
        static let dialogDone = key("subscription.dialog_done")
        static let periodFree = key("subscription.period_free")
        static let periodMonth = key("subscription.period_month")
        static let periodYear = key("subscription.period_year")
        static let periodFamily = key("subscription.period_family")
        static let benefits = ["personalised", "collections", "narration", "offline", "profiles", "weekly"].map {
            key("subscription.benefit_\($0)")
        }

        static func planName(_ id: String) -> LocalizedKey {
            key("subscription.plan_\(id)")
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

    public static let reminderTitle = "reminder.title"
    public static let reminderToggle = "reminder.toggle"
    public static let reminderTime = "reminder.time"
    public static let reminderSave = "reminder.save"
    public static let reminderSaved = "reminder.saved"
    public static func day(_ isoWeekday: Int) -> String { "reminder.day.\(isoWeekday)" }

    public static let privacyTitle = "privacy.title"
    public static let draftNotice = "privacy.draft_notice"
    public static let deleteAll = "privacy.delete"
    public static let confirmDelete = "privacy.confirm_delete"

    public static let subscriptionBack = "subscription.back"
    public static let subscriptionTitle = "subscription.title"
    public static let choosePlan = "subscription.choose"
    public static let planDone = "subscription.done"
    public static func plan(_ id: String) -> String { "subscription.plan.\(id)" }
}
