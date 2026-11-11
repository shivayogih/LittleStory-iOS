import Common
import CoreUI
import Domain
import Foundation
import Observation

public struct ProfileState: Sendable, Hashable {
    public var activeChildID: String?
    public var activeChildName: String?
    public var avatarTone = 0
    public var childCount = 0
    public var contentLanguageTag = SupportedLanguages.fallback.tag
    public var reminderEnabled = false
    public var reminderHour = AppConfig.Reminder.defaultHour
    public var reminderMinute = AppConfig.Reminder.defaultMinute
    public var reminderEveryDay = true
    public var notificationsEnabled = true
    public var wifiOnlyDownloads = true
    public var playbackSpeed = AppConfig.Player.defaultSpeed
    public var subscriptionVisible = true

    /// The child's name on the header card, or "Your family" before a profile exists.
    public var headerName: UIText {
        activeChildName.map(UIText.verbatim) ?? UIText(SettingsStrings.Profile.family)
    }

    public var headerAction: UIText {
        UIText(activeChildID == nil ? SettingsStrings.Profile.addChild : SettingsStrings.Profile.editChild)
    }

    public var childrenCount: UIText { SettingsStrings.Profile.childrenCount(.number(childCount)) }

    /// One name when the app and stories share a language, otherwise both.
    public func languageSubtitle(appLanguageTag: String) -> UIText {
        let app = SupportedLanguages.language(forTag: appLanguageTag)
        let story = SupportedLanguages.language(forTag: contentLanguageTag)
        return app == story ? .verbatim(app.nativeName) : SettingsStrings.Profile.languageSplit(
            .text(app.nativeName),
            .text(story.nativeName),
        )
    }

    /// "Every day at 8:30 PM"; `time` is the reminder time written for the app language.
    public func reminderSubtitle(time: String) -> UIText {
        guard reminderEnabled else {
            return UIText(SettingsStrings.Profile.reminderOff)
        }
        return reminderEveryDay ? SettingsStrings.Profile.reminderEveryDay(.text(time)) : SettingsStrings.Profile
            .reminderSomeDays(.text(time))
    }

    public var audioSubtitle: UIText { SettingsStrings.Profile.audioSubtitle(.text(SpeedText.format(playbackSpeed))) }

    public var downloadsSubtitle: UIText {
        UIText(wifiOnlyDownloads ? SettingsStrings.Profile.downloadsWifi : SettingsStrings.Profile.downloadsAny)
    }
}

/// Profile hub (SCR-13): toggles save straight away; rows open their screens.
@MainActor
@Observable
public final class ProfileViewModel {
    public private(set) var state: ProfileState
    @ObservationIgnored private let profiles: any ProfilesRepository
    @ObservationIgnored private let preferences: any PreferencesRepository

    public init(profiles: any ProfilesRepository, preferences: any PreferencesRepository, flags: FeatureFlags) {
        self.profiles = profiles
        self.preferences = preferences
        var initial = ProfileState()
        initial.subscriptionVisible = flags.demoSubscription
        state = initial
    }

    public func start() async {
        let preferences = preferences
        let updates = combineLatest(
            combineLatest(profiles.profiles(), profiles.activeProfile()),
            combineLatest(
                preferences.contentLanguageTag(),
                combineLatest(preferences.parentSettings(), preferences.reading()),
            ),
        )
        for await (children, settings) in updates {
            var next = state
            next.childCount = children.0.count
            next.activeChildID = children.1?.id
            next.activeChildName = children.1?.firstName
            next.avatarTone = children.1?.avatar.index ?? 0
            next.contentLanguageTag = settings.0
            let parent = settings.1.0
            next.reminderEnabled = parent.reminder.enabled
            next.reminderHour = parent.reminder.hour
            next.reminderMinute = parent.reminder.minute
            next.reminderEveryDay = parent.reminder.days.count == Self.daysInWeek
            next.notificationsEnabled = parent.notificationsEnabled
            next.wifiOnlyDownloads = parent.wifiOnlyDownloads
            next.playbackSpeed = settings.1.1.playbackSpeed
            state = next
        }
    }

    public func onReminderToggled(_ enabled: Bool) async {
        await updateSettings { $0.reminder.enabled = enabled }
    }

    public func onNotificationsToggled(_ enabled: Bool) async {
        await updateSettings { $0.notificationsEnabled = enabled }
    }

    public func onWifiOnlyToggled(_ enabled: Bool) async {
        await updateSettings { $0.wifiOnlyDownloads = enabled }
    }

    private func updateSettings(_ change: (inout ParentSettings) -> Void) async {
        guard var settings = await preferences.parentSettings().first() else {
            return
        }
        change(&settings)
        await preferences.setParentSettings(settings)
    }

    private static let daysInWeek = 7
}

/// Playback speed as "1" or "1.25", with Western digits as on the Player.
enum SpeedText {
    private static let maxDecimals = 2
    private static let posixLocale = "en_US_POSIX"

    static func format(_ speed: Double) -> String {
        speed.formatted(.number.precision(.fractionLength(0 ... maxDecimals)).locale(Locale(identifier: posixLocale)))
    }
}

/// A reminder time written for a locale ("8:30 PM", "20:30").
enum ReminderTimeText {
    static func format(hour: Int, minute: Int, locale: Locale) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = locale
        let date = calendar.date(from: DateComponents(hour: hour, minute: minute)) ?? .now
        return date.formatted(Date.FormatStyle(date: .omitted, time: .shortened, locale: locale, calendar: calendar))
    }
}
