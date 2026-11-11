import Foundation

/// App choices in `UserDefaults` (LLD §4.5), with change streams. Keys match the Android DataStore keys.
/// The suite is injectable, so tests use a throwaway one.
public final class PreferencesStore: @unchecked Sendable {
    // UserDefaults is documented as thread-safe; the class only adds the change broadcaster.
    private let defaults: UserDefaults
    private let changes = ChangeBroadcaster()

    enum Key: String, CaseIterable {
        case firstRunCompleted = "first_run_completed"
        case contentLanguageTag = "content_language_tag"
        case activeProfileID = "active_profile_id"
        case readerTextScale = "reader_text_scale"
        case playbackSpeed = "playback_speed"
        case reminderEnabled = "reminder_enabled"
        case reminderHour = "reminder_hour"
        case reminderMinute = "reminder_minute"
        case reminderDays = "reminder_days"
        case notificationsEnabled = "notifications_enabled"
        case wifiOnlyDownloads = "wifi_only_downloads"
    }

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func bool(_ key: Key) -> Bool? {
        defaults.object(forKey: key.rawValue) as? Bool
    }

    func int(_ key: Key) -> Int? {
        defaults.object(forKey: key.rawValue) as? Int
    }

    func double(_ key: Key) -> Double? {
        defaults.object(forKey: key.rawValue) as? Double
    }

    func string(_ key: Key) -> String? {
        defaults.string(forKey: key.rawValue)
    }

    func strings(_ key: Key) -> [String]? {
        defaults.stringArray(forKey: key.rawValue)
    }

    /// Writes several keys, then notifies observers once. A nil value removes the key.
    func set(_ values: [Key: Any?]) {
        for (key, value) in values {
            if let value {
                defaults.set(value, forKey: key.rawValue)
            } else {
                defaults.removeObject(forKey: key.rawValue)
            }
        }
        changes.publish([.preferences])
    }

    func removeAll() {
        for key in Key.allCases {
            defaults.removeObject(forKey: key.rawValue)
        }
        changes.publish([.preferences])
    }

    /// Emits `read()` now and after every change, skipping repeats.
    func observe<Value: Sendable & Equatable>(_ read: @escaping @Sendable (PreferencesStore) -> Value) -> AsyncStream<Value> {
        changes.observe([.preferences]) { [self] in read(self) }
    }
}
