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
