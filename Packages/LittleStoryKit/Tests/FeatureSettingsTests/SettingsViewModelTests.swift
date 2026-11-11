import Common
import CoreUI
import Domain
@testable import FeatureSettings
import Foundation
import Testing
import TestSupport

private let english = Locale(identifier: "en")
private let asha = Fixtures.child(id: "asha", firstName: "Asha", age: 6)
private let ravi = ChildProfile(
    id: "ravi",
    firstName: "Ravi",
    age: 1,
    avatar: AvatarID(2),
    interestIDs: ["space", "animals"],
    languageTag: "kn",
    defaultDurationMinutes: AppConfig.Setup.defaultDurationMinutes,
)

@MainActor
struct ProfileViewModelTests {
    private let preferences = FakePreferences()

    private func start(_ viewModel: ProfileViewModel) -> Task<Void, Never> {
        Task { await viewModel.start() }
    }

    @Test("The header names the active child and counts every profile")
    func header() async throws {
        let viewModel = ProfileViewModel(profiles: FakeProfiles([asha, ravi], activeID: "asha"), preferences: preferences, flags: .mvp)
        let task = start(viewModel)
        defer { task.cancel() }
        try await waitUntil { viewModel.state.childCount == 2 }
        #expect(viewModel.state.headerName.resolved(for: english) == "Asha")
        #expect(viewModel.state.headerAction.resolved(for: english) == "Edit child profile")
        #expect(viewModel.state.childrenCount.resolved(for: english) == "2 child profiles")
    }

    @Test("Without a profile the header invites adding one")
    func noProfile() async throws {
        let viewModel = ProfileViewModel(profiles: FakeProfiles(), preferences: preferences, flags: .mvp)
        let task = start(viewModel)
        defer { task.cancel() }
        try await waitUntil { viewModel.state.audioSubtitle.resolved(for: english).contains("1×") }
        #expect(viewModel.state.headerName.resolved(for: english) == "Your family")
        #expect(viewModel.state.headerAction.resolved(for: english) == "Add a child profile")
        #expect(viewModel.state.childrenCount.resolved(for: english) == "0 child profiles")
    }

    @Test("The language row shows one name, or both when app and stories differ")
    func languageSubtitle() async throws {
        preferences.language.send("kn")
        let viewModel = ProfileViewModel(profiles: FakeProfiles(), preferences: preferences, flags: .mvp)
        let task = start(viewModel)
        defer { task.cancel() }
        try await waitUntil { viewModel.state.contentLanguageTag == "kn" }
        #expect(viewModel.state.languageSubtitle(appLanguageTag: "kn").resolved(for: english) == "ಕನ್ನಡ")
        #expect(viewModel.state.languageSubtitle(appLanguageTag: "en").resolved(for: english) == "English · Stories: ಕನ್ನಡ")
    }

    @Test("Toggles save at once, and the reminder subtitle follows them")
    func toggles() async throws {
        let viewModel = ProfileViewModel(profiles: FakeProfiles(), preferences: preferences, flags: .mvp)
        let task = start(viewModel)
        defer { task.cancel() }
        try await waitUntil { viewModel.state.wifiOnlyDownloads }
        #expect(viewModel.state.reminderSubtitle(time: "8:30 PM").resolved(for: english) == "Off")
        await viewModel.onReminderToggled(true)
        await viewModel.onWifiOnlyToggled(false)
        await viewModel.onNotificationsToggled(false)
        try await waitUntil { viewModel.state.reminderEnabled && !viewModel.state.wifiOnlyDownloads }
        #expect(preferences.parent.current.reminder.enabled)
        #expect(!preferences.parent.current.notificationsEnabled)
        #expect(viewModel.state.reminderSubtitle(time: "8:30 PM").resolved(for: english) == "Every day at 8:30 PM")
        #expect(viewModel.state.downloadsSubtitle.resolved(for: english) == "Any network")
    }

    @Test("The subscription row follows its feature flag")
    func subscriptionFlag() {
        let hidden = ProfileViewModel(profiles: FakeProfiles(), preferences: preferences, flags: FeatureFlags(demoSubscription: false))
        #expect(!hidden.state.subscriptionVisible)
    }

    @Test("Reminder times are written for the app language")
    func reminderTime() {
        #expect(ReminderTimeText.format(hour: 20, minute: 30, locale: Locale(identifier: "en_GB")) == "20:30")
    }
}

@MainActor
struct NotificationsViewModelTests {
    private let inbox = FakeNotifications([
        NotificationItem(id: "n1", title: "Your story is ready", body: "Open it now.", read: false, section: .today, kind: .storyReady),
        NotificationItem(id: "n2", title: "New stories", body: "Five new tales.", read: true, section: .earlier, kind: .newStories),
    ])

    @Test("Items are grouped Today then Earlier; opening one marks it read")
    func groupsAndRead() async throws {
        let viewModel = NotificationsViewModel(preferences: FakePreferences(), notifications: inbox)
        let task = Task { await viewModel.start() }
        defer { task.cancel() }
        try await waitUntil { !viewModel.state.loading }
        #expect(viewModel.state.groups.map(\.section) == [.today, .earlier])
        #expect(viewModel.state.groups.first?.title.resolved(for: english) == "TODAY")
        #expect(viewModel.state.hasUnread)
        await viewModel.onOpen(id: "n1")
        try await waitUntil { !viewModel.state.hasUnread }
    }

    @Test("Mark all read clears every unread dot; an empty inbox shows the empty state")
    func markAllAndEmpty() async throws {
        let viewModel = NotificationsViewModel(preferences: FakePreferences(), notifications: inbox)
        let task = Task { await viewModel.start() }
        defer { task.cancel() }
        try await waitUntil { viewModel.state.hasUnread }
        await viewModel.onMarkAllRead()
        try await waitUntil { !viewModel.state.hasUnread }
        inbox.items.send([])
        try await waitUntil { viewModel.state.isEmpty }
    }
}

@MainActor
struct LanguageViewModelTests {
    @Test("Choosing a story language saves it; unknown tags fall back to English")
    func storyLanguage() async throws {
        let preferences = FakePreferences()
        let viewModel = LanguageViewModel(preferences: preferences)
        let task = Task { await viewModel.start() }
        defer { task.cancel() }
        await viewModel.onStoryLanguageSelected("kn-IN")
        try await waitUntil { viewModel.state.storyLanguageTag == "kn" }
        await viewModel.onStoryLanguageSelected("fr")
        try await waitUntil { viewModel.state.storyLanguageTag == "en" }
        #expect(preferences.language.current == "en")
    }
}

@MainActor
struct ChildProfilesViewModelTests {
    @Test("Cards show age, language and interests in Setup order, and mark the active child")
    func cards() async throws {
        let viewModel = ChildProfilesViewModel(profiles: FakeProfiles([asha, ravi], activeID: "asha"))
        let task = Task { await viewModel.start() }
        defer { task.cancel() }
        try await waitUntil { viewModel.state.children.count == 2 }
        let cards = viewModel.state.children
        #expect(cards.map(\.active) == [true, false])
        #expect(cards[1].interestIDs == ["animals", "space"])
        #expect(cards[1].ageLanguage.resolved(for: english) == "1 year · ಕನ್ನಡ")
        #expect(cards[0].ageLanguage.resolved(for: english) == "6 years · English")
        #expect(cards[0].editLabel.resolved(for: english) == "Edit Asha’s profile")
    }

    @Test("Switch makes another child active")
    func switchChild() async throws {
        let profiles = FakeProfiles([asha, ravi], activeID: "asha")
        let viewModel = ChildProfilesViewModel(profiles: profiles)
        let task = Task { await viewModel.start() }
        defer { task.cancel() }
        try await waitUntil { viewModel.state.children.count == 2 }
        await viewModel.onSwitch(childID: "ravi")
        try await waitUntil { viewModel.state.children.last?.active == true }
    }
}

/// Polls on the main actor until `condition` holds; fails after about two seconds.
@MainActor
func waitUntil(_ condition: () -> Bool) async throws {
    for _ in 0 ..< 200 {
        if condition() {
            return
        }
        try await Task.sleep(for: .milliseconds(10))
    }
    Issue.record("Condition not met in time")
}

@MainActor
struct ReminderViewModelTests {
    @Test("Loads the saved reminder, edits stay local until Save")
    func editAndSave() async {
        let preferences = FakePreferences()
        let viewModel = ReminderViewModel(preferences: preferences)
        await viewModel.start()
        #expect(!viewModel.state.loading)
        #expect(viewModel.state.days.count == 7)
        viewModel.onEnabledChange(true)
        viewModel.onTimeSelected(hour: 19, minute: 45)
        viewModel.onDayToggled(7)
        #expect(!preferences.parent.current.reminder.enabled)
        await viewModel.onSave()
        let saved = preferences.parent.current.reminder
        #expect(saved.enabled && saved.hour == 19 && saved.minute == 45)
        #expect(!saved.days.contains(7))
        #expect(viewModel.state.showSaved)
        #expect(viewModel.state.savedMessage(time: "7:45 PM").resolved(for: english) == "Reminder saved for 7:45 PM")
        viewModel.onSavedShown()
        #expect(!viewModel.state.showSaved)
        viewModel.onDayToggled(7)
        #expect(viewModel.state.days.contains(7))
    }

    @Test("Weekdays follow the locale's first day and use its names")
    func weekdays() {
        #expect(WeekDays.ordered(for: Locale(identifier: "en_US")).first == 7)
        #expect(WeekDays.ordered(for: Locale(identifier: "en_GB")).first == 1)
        #expect(WeekDays.fullName(1, locale: Locale(identifier: "en_US")) == "Monday")
        #expect(WeekDays.ordered(for: Locale(identifier: "en_GB")).count == 7)
    }
}

@MainActor
struct PrivacyViewModelTests {
    @Test("Delete asks first; confirming wipes the data once and reports it")
    func delete() async {
        let localData = FakeLocalData()
        let viewModel = PrivacyViewModel(localData: localData, flags: .mvp)
        #expect(viewModel.state.showDraftNotice)
        viewModel.onDeleteTapped()
        #expect(viewModel.state.confirmOpen)
        viewModel.onConfirmDismissed()
        #expect(!viewModel.state.confirmOpen)
        #expect(localData.deletions.current == 0)
        viewModel.onDeleteTapped()
        await viewModel.onConfirmDelete()
        #expect(localData.deletions.current == 1)
        #expect(!viewModel.state.deleting)
        var effects = viewModel.effects.makeAsyncIterator()
        #expect(await effects.next() == .deleted)
    }

    @Test("The draft notice follows its feature flag")
    func draftFlag() {
        let viewModel = PrivacyViewModel(localData: FakeLocalData(), flags: FeatureFlags(draftLegalText: false))
        #expect(!viewModel.state.showDraftNotice)
    }
}

@MainActor
struct SubscriptionViewModelTests {
    private let plans = [
        Plan(id: "free", priceMinorUnits: 0, currencyCode: "INR", billedYearly: false),
        Plan(id: "monthly", priceMinorUnits: 24900, currencyCode: "INR", billedYearly: false),
        Plan(id: "yearly", priceMinorUnits: 179_900, currencyCode: "INR", billedYearly: true, bestValue: true),
        Plan(id: "family", priceMinorUnits: 249_900, currencyCode: "INR", billedYearly: true, maxChildren: 5),
    ]

    @Test("Yearly is chosen by default; Choose shows the prototype dialog for the selected plan")
    func chooseAPlan() async throws {
        let viewModel = SubscriptionViewModel(subscription: FakeSubscription(plans))
        let task = Task { await viewModel.start() }
        defer { task.cancel() }
        try await waitUntil { viewModel.state.plans.count == 4 }
        #expect(viewModel.state.chooseLabel.resolved(for: english) == "Choose Premium Yearly plan")
        viewModel.onSelect("family")
        viewModel.onChoose()
        #expect(viewModel.state.confirmedText?.resolved(for: english).contains("Premium Family") == true)
        viewModel.onDialogDismissed()
        #expect(viewModel.state.confirmedID == nil)
    }

    @Test("Periods and prices describe each plan")
    func labels() {
        #expect(plans[0].period.resolved(for: english) == "Try the magic")
        #expect(plans[1].period.resolved(for: english) == "per month")
        #expect(plans[2].period.resolved(for: english) == "per year · best value")
        #expect(plans[3].period.resolved(for: english) == "per year · up to 5 children")
        #expect(plans[1].price(locale: Locale(identifier: "en_IN")).contains("249"))
        #expect(!plans[1].price(locale: Locale(identifier: "en_IN")).contains("24,900"))
    }
}
