import Common
import CoreUI
import Domain
import Foundation
import Observation

/// Notifications in one section ("Today" or "Earlier").
public struct NotificationGroup: Sendable, Hashable, Identifiable {
    public let section: NotificationSection
    public let items: [NotificationItem]

    public var id: NotificationSection { section }

    public var title: UIText {
        UIText(section == .today ? SettingsStrings.Notifications.today : SettingsStrings.Notifications.earlier)
    }
}

public struct NotificationsState: Sendable, Hashable {
    public var loading = true
    public var items: [NotificationItem] = []

    public var hasUnread: Bool { items.contains { !$0.read } }

    /// Today first, then Earlier; empty sections are left out.
    public var groups: [NotificationGroup] {
        [NotificationSection.today, .earlier].compactMap { section in
            let inSection = items.filter { $0.section == section }
            return inSection.isEmpty ? nil : NotificationGroup(section: section, items: inSection)
        }
    }

    public var isEmpty: Bool { items.isEmpty && !loading }
}

/// Notifications inbox (SCR-18): the mock inbox, in the content language. Nothing is pushed.
@MainActor
@Observable
public final class NotificationsViewModel {
    public private(set) var state = NotificationsState()
    @ObservationIgnored private let preferences: any PreferencesRepository
    @ObservationIgnored private let notifications: any NotificationsRepository

    public init(preferences: any PreferencesRepository, notifications: any NotificationsRepository) {
        self.preferences = preferences
        self.notifications = notifications
    }

    public func start() async {
        let notifications = notifications
        let updates = preferences.contentLanguageTag().flatMapLatest { tag in notifications.notifications(languageTag: tag) }
        for await items in updates {
            state = NotificationsState(loading: false, items: items)
        }
    }

    public func onOpen(id: String) async {
        await notifications.markRead(id: id)
    }

    public func onMarkAllRead() async {
        await notifications.markAllRead()
    }
}
