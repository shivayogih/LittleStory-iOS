import Common
import CoreUI
import DesignSystem
import Domain
import SwiftUI

/// Where a notification leads; the app maps these to routes.
public struct NotificationsNavigation {
    public var back: () -> Void
    public var storyReady: () -> Void
    public var reminder: () -> Void
    public var newStories: () -> Void

    public init(
        back: @escaping () -> Void,
        storyReady: @escaping () -> Void,
        reminder: @escaping () -> Void,
        newStories: @escaping () -> Void,
    ) {
        self.back = back
        self.storyReady = storyReady
        self.reminder = reminder
        self.newStories = newStories
    }
}

public struct NotificationsRoute: View {
    @State private var viewModel: NotificationsViewModel
    private let navigation: NotificationsNavigation

    public init(viewModel: @autoclosure @escaping () -> NotificationsViewModel, navigation: NotificationsNavigation) {
        _viewModel = State(wrappedValue: viewModel())
        self.navigation = navigation
    }

    public var body: some View {
        let viewModel = viewModel
        NotificationsScreen(
            state: viewModel.state,
            navigation: navigation,
            onOpen: { id in Task { await viewModel.onOpen(id: id) } },
            onMarkAll: { Task { await viewModel.onMarkAllRead() } },
        )
        .task { await viewModel.start() }
    }
}

/// SCR-18: "Mark all read", then Today and Earlier; a tap marks the item read and opens its screen.
struct NotificationsScreen: View {
    let state: NotificationsState
    let navigation: NotificationsNavigation
    let onOpen: (String) -> Void
    let onMarkAll: () -> Void
    @Environment(\.locale) private var locale

    var body: some View {
        SettingsPage(
            title: UIText(SettingsStrings.Notifications.title),
            titleID: SettingsID.notificationsTitle,
            onBack: navigation.back,
        ) {
            if state.hasUnread {
                Button(action: onMarkAll) {
                    LText(SettingsStrings.Notifications.markAll)
                        .lsTextStyle(.button)
                        .foregroundStyle(LSColor.primary)
                        .frame(minHeight: LSDimens.minTouchTarget)
                }
                .buttonStyle(LSPressStyle())
                .accessibilityIdentifier(SettingsID.markAll)
            }
        } content: {
            if state.loading {
                LoadingIndicator()
            } else if state.isEmpty {
                EmptyState(
                    icon: .bell,
                    title: UIText(SettingsStrings.Notifications.emptyTitle),
                    message: UIText(SettingsStrings.Notifications.emptyText),
                )
                .frame(maxWidth: .infinity)
                .accessibilityIdentifier(SettingsID.notificationsEmpty)
            } else {
                ForEach(state.groups) { group in
                    VStack(alignment: .leading, spacing: LSSpacing.md) {
                        LText(group.title)
                            .lsTextStyle(.eyebrow)
                            .foregroundStyle(LSColor.textSecondary)
                            .accessibilityAddTraits(.isHeader)
                        ForEach(group.items) { item in
                            NotificationRow(item: item) { open(item) }
                        }
                    }
                }
            }
        }
    }

    private func open(_ item: NotificationItem) {
        onOpen(item.id)
        switch item.kind {
        case .storyReady: navigation.storyReady()
        case .reminder: navigation.reminder()
        case .newStories: navigation.newStories()
        }
    }
}

private struct NotificationRow: View {
    let item: NotificationItem
    let onTap: () -> Void
    @Environment(\.locale) private var locale

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: LSSpacing.md) {
                LSIconView(icon, size: LSDimens.iconSizeSmall)
                    .foregroundStyle(LSColor.primary)
                    .frame(width: LSDimens.settingsIconTile, height: LSDimens.settingsIconTile)
                    .background(tile, in: .rect(cornerRadius: LSRadius.small))
                VStack(alignment: .leading, spacing: LSSpacing.xxs) {
                    Text(item.title)
                        .lsTextStyle(.itemTitle)
                        .foregroundStyle(LSColor.textPrimary)
                    Text(item.body)
                        .lsTextStyle(.chip)
                        .foregroundStyle(LSColor.textSecondary)
                }
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                if !item.read {
                    Circle()
                        .fill(LSColor.accent)
                        .frame(width: LSDimens.unreadDotSize, height: LSDimens.unreadDotSize)
                }
            }
            .padding(LSSpacing.lg)
            .background(LSColor.surface, in: .rect(cornerRadius: LSRadius.large))
        }
        .buttonStyle(LSPressStyle())
        .accessibilityElement(children: .combine)
        .accessibilityValue(item.read ? Text(verbatim: "") : SettingsStrings.Notifications.unread.text(locale))
        .accessibilityIdentifier(SettingsID.notification(item.id))
    }

    private var icon: LSIcon {
        switch item.kind {
        case .storyReady: .book
        case .reminder: .moon
        case .newStories: .compass
        }
    }

    private var tile: Color {
        switch item.kind {
        case .storyReady: LSColor.secondaryContainer
        case .reminder: LSColor.CategoryTile.peach
        case .newStories: LSColor.CategoryTile.butter
        }
    }
}
