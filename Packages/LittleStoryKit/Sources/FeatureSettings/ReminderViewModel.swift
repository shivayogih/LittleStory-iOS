import Common
import CoreUI
import Domain
import Observation

public struct ReminderState: Sendable, Hashable {
    public var loading = true
    public var enabled = false
    public var hour = AppConfig.Reminder.defaultHour
    public var minute = AppConfig.Reminder.defaultMinute
    /// ISO weekdays, Monday = 1 … Sunday = 7.
    public var days = Set(AppConfig.Reminder.defaultDaysOfWeek)
    /// True right after saving; the screen shows "Reminder saved for …" until it is acknowledged.
    public var showSaved = false

    /// "Reminder saved for 8:30 PM"; `time` is written for the app language.
    public func savedMessage(time: String) -> UIText { SettingsStrings.Reminder.saved(.text(time)) }
}

/// Bedtime reminder (SCR-16): settings kept on the device. Nothing is scheduled in the MVP
/// (decision D13) and no notification permission is asked for.
@MainActor
@Observable
public final class ReminderViewModel {
    public private(set) var state = ReminderState()
    @ObservationIgnored private let preferences: any PreferencesRepository

    public init(preferences: any PreferencesRepository) {
        self.preferences = preferences
    }

    public func start() async {
        guard let reminder = await preferences.parentSettings().first()?.reminder else {
            state.loading = false
            return
        }
        state.enabled = reminder.enabled
        state.hour = reminder.hour
        state.minute = reminder.minute
        state.days = reminder.days
        state.loading = false
    }

    public func onEnabledChange(_ enabled: Bool) {
        state.enabled = enabled
    }

    public func onTimeSelected(hour: Int, minute: Int) {
        state.hour = hour
        state.minute = minute
    }

    public func onDayToggled(_ isoWeekday: Int) {
        if state.days.contains(isoWeekday) {
            state.days.remove(isoWeekday)
        } else {
            state.days.insert(isoWeekday)
        }
    }

    public func onSave() async {
        guard var settings = await preferences.parentSettings().first() else {
            return
        }
        settings.reminder = ReminderSettings(enabled: state.enabled, hour: state.hour, minute: state.minute, days: state.days)
        await preferences.setParentSettings(settings)
        state.showSaved = true
    }

    public func onSavedShown() {
        state.showSaved = false
    }
}
