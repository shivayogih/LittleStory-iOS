import Common
import Domain

public struct PreferencesRepositoryImpl: PreferencesRepository {
    private let store: PreferencesStore

    public init(store: PreferencesStore) {
        self.store = store
    }

    public func firstRunCompleted() -> AsyncStream<Bool> {
        store.observe { $0.bool(.firstRunCompleted) ?? false }
    }

    public func setFirstRunCompleted(_ completed: Bool) async {
        store.set([.firstRunCompleted: completed])
    }

    public func contentLanguageTag() -> AsyncStream<String> {
        store.observe { $0.string(.contentLanguageTag) ?? SupportedLanguages.fallback.tag }
    }

    public func setContentLanguageTag(_ tag: String) async {
        store.set([.contentLanguageTag: tag])
    }

    public func reading() -> AsyncStream<ReadingPreferences> {
        store.observe { store in
            ReadingPreferences(
                textScale: store.double(.readerTextScale) ?? AppConfig.Reader.textScaleDefault,
                playbackSpeed: store.double(.playbackSpeed) ?? AppConfig.Player.defaultSpeed,
            )
        }
    }

    public func setReading(_ preferences: ReadingPreferences) async {
        store.set([.readerTextScale: preferences.textScale, .playbackSpeed: preferences.playbackSpeed])
    }

    public func parentSettings() -> AsyncStream<ParentSettings> {
        store.observe { store in
            // Days are stored as strings, like Android's string set.
            let days = store.strings(.reminderDays)?.compactMap(Int.init) ?? AppConfig.Reminder.defaultDaysOfWeek
            return ParentSettings(
                reminder: ReminderSettings(
                    enabled: store.bool(.reminderEnabled) ?? false,
                    hour: store.int(.reminderHour) ?? AppConfig.Reminder.defaultHour,
                    minute: store.int(.reminderMinute) ?? AppConfig.Reminder.defaultMinute,
                    days: Set(days),
                ),
                notificationsEnabled: store.bool(.notificationsEnabled) ?? true,
                wifiOnlyDownloads: store.bool(.wifiOnlyDownloads) ?? true,
            )
        }
    }

    public func setParentSettings(_ settings: ParentSettings) async {
        store.set([
            .reminderEnabled: settings.reminder.enabled,
            .reminderHour: settings.reminder.hour,
            .reminderMinute: settings.reminder.minute,
            .reminderDays: settings.reminder.days.sorted().map(String.init),
            .notificationsEnabled: settings.notificationsEnabled,
            .wifiOnlyDownloads: settings.wifiOnlyDownloads,
        ])
    }
}
