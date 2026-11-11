import Common
import CoreUI
import DesignSystem
import SwiftUI

/// Where the Profile hub sends the parent; the app maps these to routes.
public struct ProfileNavigation {
    /// Edit the active child, or add the first one (nil); opens after the parental gate.
    public var editChild: (String?) -> Void
    public var children: () -> Void
    public var language: () -> Void
    public var reminder: () -> Void
    public var notifications: () -> Void
    public var downloads: () -> Void
    public var subscription: () -> Void
    public var privacy: () -> Void
    public var help: () -> Void

    public init(
        editChild: @escaping (String?) -> Void,
        children: @escaping () -> Void,
        language: @escaping () -> Void,
        reminder: @escaping () -> Void,
        notifications: @escaping () -> Void,
        downloads: @escaping () -> Void,
        subscription: @escaping () -> Void,
        privacy: @escaping () -> Void,
        help: @escaping () -> Void,
    ) {
        self.editChild = editChild
        self.children = children
        self.language = language
        self.reminder = reminder
        self.notifications = notifications
        self.downloads = downloads
        self.subscription = subscription
        self.privacy = privacy
        self.help = help
    }
}

public struct ProfileRoute: View {
    @State private var viewModel: ProfileViewModel
    private let navigation: ProfileNavigation

    public init(viewModel: @autoclosure @escaping () -> ProfileViewModel, navigation: ProfileNavigation) {
        _viewModel = State(wrappedValue: viewModel())
        self.navigation = navigation
    }

    public var body: some View {
        let viewModel = viewModel
        ProfileScreen(
            state: viewModel.state,
            navigation: navigation,
            toggles: ProfileToggles(
                reminder: { on in Task { await viewModel.onReminderToggled(on) } },
                notifications: { on in Task { await viewModel.onNotificationsToggled(on) } },
                wifiOnly: { on in Task { await viewModel.onWifiOnlyToggled(on) } },
            ),
        )
        .task { await viewModel.start() }
    }
}

struct ProfileToggles {
    let reminder: (Bool) -> Void
    let notifications: (Bool) -> Void
    let wifiOnly: (Bool) -> Void
}

/// SCR-13: the child card, then Children, Experience and LittleStory groups, and the footer.
struct ProfileScreen: View {
    let state: ProfileState
    let navigation: ProfileNavigation
    let toggles: ProfileToggles
    @Environment(\.locale) private var locale
    @State private var gateOpen = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: LSSpacing.xl) {
                LText(SettingsStrings.Profile.title)
                    .lsTextStyle(.topBarTitle)
                    .foregroundStyle(LSColor.textPrimary)
                    .frame(minHeight: LSDimens.topBarHeight)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier(SettingsID.profileTitle)
                ChildHeaderCard(state: state) { gateOpen = true }
                childrenGroup
                experienceGroup
                appGroup
                footer
            }
            .frame(maxWidth: LayoutTokens.readableMaxWidth)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, LSSpacing.screenHorizontal)
            .padding(.vertical, LSSpacing.screenTop)
        }
        .background(LSColor.background)
        // Editing or adding a child changes a child's details, so a grown-up confirms first.
        .sheet(isPresented: $gateOpen) {
            ScrollView {
                ParentalGateCard(
                    onPassed: {
                        gateOpen = false
                        navigation.editChild(state.activeChildID)
                    },
                    onCancel: { gateOpen = false },
                )
                .padding(LSSpacing.screenHorizontal)
            }
            .background(LSColor.background)
            .presentationDetents([.large])
            // A form sheet on iPad, sized for the keypad rather than the whole window.
            .presentationSizing(.form)
        }
    }

    private var childrenGroup: some View {
        SettingsGroup(title: UIText(SettingsStrings.Profile.groupChildren)) {
            SettingsRow(
                icon: .user,
                title: UIText(SettingsStrings.Profile.manageChildren),
                subtitle: state.childrenCount,
                identifier: SettingsID.children,
                onOpen: navigation.children,
            )
            SettingsDivider()
            SettingsRow(
                icon: .book,
                title: UIText(SettingsStrings.Profile.language),
                subtitle: state.languageSubtitle(appLanguageTag: locale.identifier),
                identifier: SettingsID.language,
                onOpen: navigation.language,
            )
        }
    }

    private var experienceGroup: some View {
        SettingsGroup(title: UIText(SettingsStrings.Profile.groupExperience)) {
            SettingsRow(
                icon: .moon,
                title: UIText(SettingsStrings.Profile.reminder),
                subtitle: state.reminderSubtitle(
                    time: ReminderTimeText.format(hour: state.reminderHour, minute: state.reminderMinute, locale: locale),
                ),
                identifier: SettingsID.reminder,
                onOpen: navigation.reminder,
                toggle: state.reminderEnabled,
                onToggle: toggles.reminder,
            )
            SettingsDivider()
            SettingsRow(
                icon: .bell,
                title: UIText(SettingsStrings.Profile.notifications),
                subtitle: UIText(SettingsStrings.Profile.notificationsSubtitle),
                identifier: SettingsID.notifications,
                onOpen: navigation.notifications,
                toggle: state.notificationsEnabled,
                onToggle: toggles.notifications,
            )
            SettingsDivider()
            SettingsRow(
                icon: .volume,
                title: UIText(SettingsStrings.Profile.audio),
                subtitle: state.audioSubtitle,
                identifier: SettingsID.audio,
            )
            SettingsDivider()
            SettingsRow(
                icon: .download,
                title: UIText(SettingsStrings.Profile.downloads),
                subtitle: state.downloadsSubtitle,
                identifier: SettingsID.downloads,
                onOpen: navigation.downloads,
                toggle: state.wifiOnlyDownloads,
                onToggle: toggles.wifiOnly,
            )
        }
    }

    private var appGroup: some View {
        SettingsGroup(title: UIText(SettingsStrings.Profile.groupApp)) {
            if state.subscriptionVisible {
                SettingsRow(
                    icon: .heart,
                    title: UIText(SettingsStrings.Profile.subscription),
                    subtitle: UIText(SettingsStrings.Profile.subscriptionSubtitle),
                    identifier: SettingsID.subscription,
                    onOpen: navigation.subscription,
                )
                SettingsDivider()
            }
            SettingsRow(
                icon: .settings,
                title: UIText(SettingsStrings.Profile.privacy),
                subtitle: UIText(SettingsStrings.Profile.privacySubtitle),
                identifier: SettingsID.privacy,
                onOpen: navigation.privacy,
            )
            SettingsDivider()
            SettingsRow(
                icon: .book,
                title: UIText(SettingsStrings.Profile.help),
                subtitle: UIText(SettingsStrings.Profile.helpSubtitle),
                identifier: SettingsID.help,
                onOpen: navigation.help,
            )
        }
    }

    private var footer: some View {
        VStack(spacing: LSSpacing.sm) {
            BrandMark()
            LText(SettingsStrings.Profile.footer)
                .lsTextStyle(.chip)
                .foregroundStyle(LSColor.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

/// Avatar, the child's name, "Private and parent-managed" and the edit or add link.
private struct ChildHeaderCard: View {
    let state: ProfileState
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: LSSpacing.lg) {
                Avatar(tone: state.avatarTone, size: LSDimens.avatarLargeSize)
                VStack(alignment: .leading, spacing: LSSpacing.xxs) {
                    LText(state.headerName)
                        .lsTextStyle(.homeTitle)
                        .foregroundStyle(LSColor.onPrimary)
                    LText(SettingsStrings.Profile.privateNote)
                        .lsTextStyle(.chip)
                        .foregroundStyle(LSColor.secondaryContainer)
                    LText(state.headerAction)
                        .lsTextStyle(.chip)
                        .foregroundStyle(LSColor.highlight)
                }
                .multilineTextAlignment(.leading)
                Spacer(minLength: LSSpacing.none)
            }
            .padding(LSSpacing.xl)
            .background(LSColor.primary, in: .rect(cornerRadius: LSRadius.large))
        }
        .buttonStyle(LSPressStyle())
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(SettingsID.childCard)
    }
}
