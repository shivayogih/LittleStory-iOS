import Common
import CoreUI
import DesignSystem
import SwiftUI

public struct ReminderRoute: View {
    @State private var viewModel: ReminderViewModel
    private let onBack: () -> Void

    public init(viewModel: @autoclosure @escaping () -> ReminderViewModel, onBack: @escaping () -> Void) {
        _viewModel = State(wrappedValue: viewModel())
        self.onBack = onBack
    }

    public var body: some View {
        let viewModel = viewModel
        ReminderScreen(
            state: viewModel.state,
            actions: ReminderActions(
                back: onBack,
                enabled: viewModel.onEnabledChange,
                time: viewModel.onTimeSelected,
                day: viewModel.onDayToggled,
                save: { Task { await viewModel.onSave() } },
                savedShown: viewModel.onSavedShown,
            ),
        )
        .task { await viewModel.start() }
    }
}

struct ReminderActions {
    let back: () -> Void
    let enabled: (Bool) -> Void
    let time: (_ hour: Int, _ minute: Int) -> Void
    let day: (Int) -> Void
    let save: () -> Void
    let savedShown: () -> Void
}

/// SCR-16: the night panel, the switch, time, weekdays and the quiet note; Save is pinned below.
struct ReminderScreen: View {
    let state: ReminderState
    let actions: ReminderActions
    @Environment(\.locale) private var locale

    var body: some View {
        VStack(spacing: LSSpacing.none) {
            SettingsPage(title: UIText(SettingsStrings.Reminder.title), titleID: SettingsID.reminderTitle, onBack: actions.back) {
                NightPanel()
                settingsCard
            }
            StickyActionBar(
                UIText(SettingsStrings.Reminder.save),
                enabled: !state.loading,
                identifier: SettingsID.reminderSave,
                action: actions.save,
            )
        }
        .background(LSColor.background)
        .overlay(alignment: .bottom) {
            if state.showSaved {
                LText(state.savedMessage(time: ReminderTimeText.format(hour: state.hour, minute: state.minute, locale: locale)))
                    .lsTextStyle(.chip)
                    .foregroundStyle(LSColor.onNight)
                    .padding(.horizontal, LSSpacing.lg)
                    .padding(.vertical, LSSpacing.md)
                    .background(LSColor.nightSurface, in: .capsule)
                    .padding(.bottom, LSDimens.bottomNavHeight)
                    .accessibilityIdentifier(SettingsID.reminderSaved)
                    .task {
                        AccessibilityNotification.Announcement(
                            state.savedMessage(time: ReminderTimeText.format(hour: state.hour, minute: state.minute, locale: locale))
                                .resolved(for: locale),
                        ).post()
                        try? await Task.sleep(for: AppConfig.UI.toastDuration)
                        actions.savedShown()
                    }
            }
        }
    }

    private var settingsCard: some View {
        VStack(alignment: .leading, spacing: LSSpacing.lg) {
            HStack(spacing: LSSpacing.md) {
                VStack(alignment: .leading, spacing: LSSpacing.xxs) {
                    LText(SettingsStrings.Reminder.toggle)
                        .lsTextStyle(.itemTitle)
                        .foregroundStyle(LSColor.textPrimary)
                    LText(SettingsStrings.Reminder.toggleHint)
                        .lsTextStyle(.chip)
                        .foregroundStyle(LSColor.textSecondary)
                }
                Spacer(minLength: LSSpacing.sm)
                Toggle(isOn: Binding(get: { state.enabled }, set: actions.enabled)) {
                    LText(SettingsStrings.Reminder.toggle)
                }
                .labelsHidden()
                .tint(LSColor.primary)
                .accessibilityIdentifier(SettingsID.reminderToggle)
            }
            SettingsDivider()
            DatePicker(selection: timeBinding, displayedComponents: .hourAndMinute) {
                LText(SettingsStrings.Reminder.time)
                    .lsTextStyle(.itemTitle)
                    .foregroundStyle(LSColor.textPrimary)
            }
            .environment(\.locale, locale)
            .accessibilityIdentifier(SettingsID.reminderTime)
            SettingsDivider()
            LText(SettingsStrings.Reminder.repeatOn)
                .lsTextStyle(.itemTitle)
                .foregroundStyle(LSColor.textPrimary)
            DayPicker(days: state.days, onToggle: actions.day)
            HStack(spacing: LSSpacing.md) {
                LSIconView(.moon, size: LSDimens.iconSizeSmall)
                    .foregroundStyle(LSColor.success)
                VStack(alignment: .leading, spacing: LSSpacing.xxs) {
                    LText(SettingsStrings.Reminder.quietTitle)
                        .lsTextStyle(.itemTitle)
                        .foregroundStyle(LSColor.textPrimary)
                    LText(SettingsStrings.Reminder.quietBody)
                        .lsTextStyle(.chip)
                        .foregroundStyle(LSColor.textSecondary)
                }
            }
            .accessibilityElement(children: .combine)
        }
        .padding(LSSpacing.lg)
        .background(LSColor.surface, in: .rect(cornerRadius: LSRadius.large))
    }

    /// The picker works on a date; only its hour and minute are read and written.
    private var timeBinding: Binding<Date> {
        let calendar = Calendar(identifier: .gregorian)
        return Binding(
            get: { calendar.date(from: DateComponents(hour: state.hour, minute: state.minute)) ?? .now },
            set: { date in
                let parts = calendar.dateComponents([.hour, .minute], from: date)
                actions.time(parts.hour ?? state.hour, parts.minute ?? state.minute)
            },
        )
    }
}

/// Moon and "A gentle nudge for storytime" on a night surface.
private struct NightPanel: View {
    var body: some View {
        VStack(alignment: .leading, spacing: LSSpacing.sm) {
            Circle()
                .fill(LSColor.moon)
                .frame(width: LSDimens.reminderMoonSize, height: LSDimens.reminderMoonSize)
                .accessibilityHidden(true)
            LText(SettingsStrings.Reminder.panelTitle)
                .lsTextStyle(.homeTitle)
                .foregroundStyle(LSColor.onNight)
            LText(SettingsStrings.Reminder.panelBody)
                .lsTextStyle(.body)
                .foregroundStyle(LSColor.secondaryContainer)
        }
        .padding(LSSpacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LSColor.nightSurface, in: .rect(cornerRadius: LSRadius.large))
        .accessibilityElement(children: .combine)
    }
}

/// Seven round buttons in the locale's week order, labelled with its very short weekday names.
private struct DayPicker: View {
    let days: Set<Int>
    let onToggle: (Int) -> Void
    @Environment(\.locale) private var locale

    var body: some View {
        HStack(spacing: LSSpacing.xs) {
            ForEach(WeekDays.ordered(for: locale), id: \.self) { isoDay in
                let selected = days.contains(isoDay)
                Button { onToggle(isoDay) } label: {
                    Text(WeekDays.shortName(isoDay, locale: locale))
                        .lsTextStyle(.chip)
                        .foregroundStyle(selected ? LSColor.onPrimary : LSColor.textPrimary)
                        .frame(width: LSDimens.dayButtonSize, height: LSDimens.dayButtonSize)
                        .background(selected ? LSColor.primary : LSColor.surfaceMuted, in: .circle)
                        .frame(maxWidth: .infinity, minHeight: LSDimens.minTouchTarget)
                }
                .buttonStyle(LSPressStyle())
                .accessibilityLabel(Text(WeekDays.fullName(isoDay, locale: locale)))
                .accessibilityAddTraits(selected ? .isSelected : [])
                .accessibilityIdentifier(SettingsID.day(isoDay))
            }
        }
    }
}

/// ISO weekdays (Monday = 1) mapped to the calendar's names and first day of the week.
enum WeekDays {
    private static let daysInWeek = 7

    static func ordered(for locale: Locale) -> [Int] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = locale
        // Calendar weekdays run Sunday = 1 … Saturday = 7; ISO puts Sunday last.
        let firstISO = iso(fromCalendarWeekday: calendar.firstWeekday)
        return (0 ..< daysInWeek).map { (firstISO - 1 + $0) % daysInWeek + 1 }
    }

    static func shortName(_ isoDay: Int, locale: Locale) -> String {
        symbols(locale).veryShort[calendarIndex(isoDay)]
    }

    static func fullName(_ isoDay: Int, locale: Locale) -> String {
        symbols(locale).full[calendarIndex(isoDay)]
    }

    private static func symbols(_ locale: Locale) -> (veryShort: [String], full: [String]) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = locale
        return (calendar.veryShortStandaloneWeekdaySymbols, calendar.standaloneWeekdaySymbols)
    }

    /// Index into the calendar's symbol arrays, which start on Sunday.
    private static func calendarIndex(_ isoDay: Int) -> Int {
        isoDay % daysInWeek
    }

    private static func iso(fromCalendarWeekday weekday: Int) -> Int {
        weekday == 1 ? daysInWeek : weekday - 1
    }
}
