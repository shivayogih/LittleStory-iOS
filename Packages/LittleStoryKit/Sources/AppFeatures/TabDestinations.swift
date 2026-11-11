import CoreUI
import FeatureCreate
import FeatureDiscover
import FeatureHome
import FeatureLibrary
import FeatureOnboarding
import FeatureReader
import FeatureSettings
import SwiftUI

/// Profile's destinations and every feature's navigation callbacks, kept apart from `TabStack`'s
/// body so each file stays readable.
extension TabStack {
    /// Profile's screens; parent-only ones open behind the grown-ups gate, and Cancel goes back.
    @ViewBuilder
    func settingsDestination(_ route: AppRoute) -> some View {
        switch route {
        case .notifications:
            NotificationsRoute(
                viewModel: NotificationsViewModel(preferences: dependencies.preferences, notifications: dependencies.notifications),
                navigation: NotificationsNavigation(
                    back: router.pop,
                    storyReady: { router.select(.stories) },
                    reminder: { router.push(.comingSoon(Pending.reminder)) },
                    newStories: { router.select(.discover) },
                ),
            )
        case .childProfiles:
            ParentGated(onCancel: router.pop) {
                ChildProfilesRoute(
                    viewModel: ChildProfilesViewModel(profiles: dependencies.profiles),
                    navigation: ChildProfilesNavigation(
                        back: router.pop,
                        edit: { router.push(.editChild($0)) },
                        add: { router.push(.editChild(nil)) },
                    ),
                )
            }
        case let .editChild(childID):
            SetupRoute(
                profiles: dependencies.profiles,
                preferences: dependencies.preferences,
                uiLanguageTag: localizer.language.tag,
                childID: childID,
                onApplyLanguage: localizer.apply(tag:),
                onDone: router.pop,
            )
        case .language:
            ParentGated(onCancel: router.pop) {
                LanguageRoute(
                    viewModel: LanguageViewModel(preferences: dependencies.preferences),
                    appLanguageTag: localizer.language.tag,
                    onApplyAppLanguage: localizer.apply(tag:),
                    onBack: router.pop,
                )
            }
        case .help:
            HelpRoute(appInfo: dependencies.appInfo, onBack: router.pop)
        default:
            EmptyView()
        }
    }

    var readerNavigation: ReaderNavigation {
        let router = router
        return ReaderNavigation(
            back: router.pop,
            listen: { router.push(.player($0)) },
            read: { router.push(.reader(storyID: $0, page: 0)) },
        )
    }

    var libraryNavigation: LibraryNavigation {
        let router = router
        return LibraryNavigation(
            downloads: { router.push(.downloads) },
            story: { router.push(.story($0)) },
            createdStory: { router.push(.storyReady($0)) },
            play: { router.push(.player($0)) },
            discover: { router.select(.discover) },
            back: router.pop,
        )
    }

    var profileNavigation: ProfileNavigation {
        let router = router
        return ProfileNavigation(
            editChild: { router.push(.editChild($0)) },
            children: { router.push(.childProfiles) },
            language: { router.push(.language) },
            reminder: { router.push(.comingSoon(Pending.reminder)) },
            notifications: { router.push(.notifications) },
            downloads: { router.push(.downloads) },
            subscription: { router.push(.comingSoon(Pending.subscription)) },
            privacy: { router.push(.comingSoon(Pending.privacy)) },
            help: { router.push(.help) },
        )
    }

    var homeNavigation: HomeNavigation {
        let router = router
        return HomeNavigation(
            notifications: { router.push(.notifications) },
            profiles: { router.select(.profile) },
            create: { router.select(.create) },
            resume: { router.push(.player($0)) },
            discover: { router.select(.discover) },
            category: { router.push(.category($0)) },
            story: { router.push(.story($0)) },
        )
    }

    var discoverNavigation: DiscoverNavigation {
        let router = router
        return DiscoverNavigation(
            notifications: { router.push(.notifications) },
            category: { router.push(.category($0)) },
            story: { router.push(.story($0)) },
            listen: { router.push(.player($0)) },
            read: { router.push(.reader(storyID: $0, page: 0)) },
            back: router.pop,
        )
    }
}

/// Names for screens a later phase builds (I6c).
enum Pending {
    static let reminder = "reminder"
    static let subscription = "subscription"
    static let privacy = "privacy"
}
