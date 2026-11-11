import Common
import CoreUI
import DesignSystem
import Domain
import FeatureDiscover
import FeatureHome
import FeatureOnboarding
import Foundation
import SwiftUI

/// Accessibility identifiers for UI tests; never user-facing text.
public enum AppAccessibilityID {
    public static let launching = "app.launching"
    public static func tab(_ tab: AppTab) -> String { "app.tab.\(tab.rawValue)" }
}

/// Root of the app: first-run flow or the tab shell, in the app language from `Localizer`.
public struct AppRootView: View {
    private let dependencies: AppDependencies
    @State private var localizer: Localizer
    @State private var router = AppRouter()

    /// - Parameter defaults: where the chosen app language is kept (a throwaway suite in UI tests).
    public init(dependencies: AppDependencies, defaults: UserDefaults = .standard) {
        self.dependencies = dependencies
        _localizer = State(initialValue: Localizer(defaults: defaults))
    }

    public var body: some View {
        AdaptiveRoot {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(LSColor.background)
        }
        .environment(\.locale, localizer.locale)
        .tint(LSColor.primary)
        // One light theme with night surfaces (Android ADR-013) until a dark palette is designed.
        .preferredColorScheme(.light)
        .task {
            let completed = await dependencies.preferences.firstRunCompleted().first() ?? false
            router.showFirstRun(completed: completed)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch router.root {
        case .launching:
            Color.clear.accessibilityIdentifier(AppAccessibilityID.launching)
        case .onboarding:
            FirstRunFlow(dependencies: dependencies, localizer: localizer, router: router)
        case .main:
            MainTabs(dependencies: dependencies, router: router)
        }
    }
}

/// Onboarding, then Setup, in their own stack.
private struct FirstRunFlow: View {
    let dependencies: AppDependencies
    let localizer: Localizer
    @Bindable var router: AppRouter

    var body: some View {
        NavigationStack(path: $router.onboardingPath) {
            OnboardingRoute(onFinished: router.openSetup)
                .toolbar(.hidden, for: .navigationBar)
                .navigationDestination(for: AppRouter.OnboardingStep.self) { _ in
                    SetupRoute(
                        profiles: dependencies.profiles,
                        preferences: dependencies.preferences,
                        uiLanguageTag: localizer.language.tag,
                        onApplyLanguage: localizer.apply(tag:),
                        onDone: router.finishOnboarding,
                    )
                    .toolbar(.hidden, for: .navigationBar)
                }
        }
    }
}

/// Five tabs; on iPad (regular width) they become a sidebar.
private struct MainTabs: View {
    let dependencies: AppDependencies
    @Bindable var router: AppRouter

    var body: some View {
        TabView(selection: Binding(get: { router.selectedTab }, set: router.select)) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                Tab(value: tab) {
                    TabStack(tab: tab, dependencies: dependencies, router: router)
                } label: {
                    TabLabel(tab: tab)
                }
                .accessibilityIdentifier(AppAccessibilityID.tab(tab))
            }
        }
        .tabViewStyle(.sidebarAdaptable)
    }
}

private struct TabLabel: View {
    let tab: AppTab

    var body: some View {
        Label {
            LText(title)
        } icon: {
            icon.image
        }
    }

    private var title: LocalizedKey {
        switch tab {
        case .home: CoreUIStrings.Tab.home
        case .discover: CoreUIStrings.Tab.discover
        case .create: CoreUIStrings.Tab.create
        case .stories: CoreUIStrings.Tab.stories
        case .profile: CoreUIStrings.Tab.profile
        }
    }

    private var icon: LSIcon {
        switch tab {
        case .home: .home
        case .discover: .compass
        case .create: .plus
        case .stories: .book
        case .profile: .user
        }
    }
}

/// One tab's navigation stack and the screens it can push.
private struct TabStack: View {
    let tab: AppTab
    let dependencies: AppDependencies
    @Bindable var router: AppRouter

    var body: some View {
        NavigationStack(path: Binding(get: { router.paths[tab] ?? [] }, set: { router.paths[tab] = $0 })) {
            root
                .toolbar(.hidden, for: .navigationBar)
                .navigationDestination(for: AppRoute.self, destination: destination)
        }
    }

    @ViewBuilder
    private var root: some View {
        switch tab {
        case .home:
            HomeRoute(
                viewModel: HomeViewModel(
                    profiles: dependencies.profiles,
                    preferences: dependencies.preferences,
                    catalog: dependencies.stores.catalog,
                    favourites: dependencies.stores.favourites,
                    progress: dependencies.stores.progress,
                ),
                navigation: homeNavigation,
            )
        case .discover:
            DiscoverRoute(
                viewModel: DiscoverViewModel(
                    profiles: dependencies.profiles,
                    preferences: dependencies.preferences,
                    catalog: dependencies.stores.catalog,
                    favourites: dependencies.stores.favourites,
                ),
                navigation: discoverNavigation,
            )
        case .create, .stories, .profile:
            ComingSoonView()
        }
    }

    @ViewBuilder
    private func destination(_ route: AppRoute) -> some View {
        switch route {
        case let .category(id):
            CategoryRoute(
                viewModel: CategoryViewModel(
                    categoryID: id,
                    profiles: dependencies.profiles,
                    preferences: dependencies.preferences,
                    catalog: dependencies.stores.catalog,
                    favourites: dependencies.stores.favourites,
                    downloads: dependencies.stores.downloads,
                ),
                navigation: discoverNavigation,
            )
        case let .story(id):
            StoryDetailRoute(
                viewModel: StoryDetailViewModel(
                    storyID: id,
                    profiles: dependencies.profiles,
                    preferences: dependencies.preferences,
                    stores: dependencies.stores,
                ),
                navigation: discoverNavigation,
            )
        case .comingSoon:
            ComingSoonView()
        }
    }

    private var homeNavigation: HomeNavigation {
        let router = router
        return HomeNavigation(
            notifications: { router.push(.comingSoon(Pending.notifications)) },
            profiles: { router.select(.profile) },
            create: { router.select(.create) },
            resume: { router.push(.comingSoon(Pending.player($0))) },
            discover: { router.select(.discover) },
            category: { router.push(.category($0)) },
            story: { router.push(.story($0)) },
        )
    }

    private var discoverNavigation: DiscoverNavigation {
        let router = router
        return DiscoverNavigation(
            notifications: { router.push(.comingSoon(Pending.notifications)) },
            category: { router.push(.category($0)) },
            story: { router.push(.story($0)) },
            listen: { router.push(.comingSoon(Pending.player($0))) },
            read: { router.push(.comingSoon(Pending.reader($0))) },
            back: router.pop,
        )
    }
}

/// Names for screens later phases build (Reader and Player in I5, Notifications in I6).
private enum Pending {
    static let notifications = "notifications"
    static func player(_ id: String) -> String { "player.\(id)" }
    static func reader(_ id: String) -> String { "reader.\(id)" }
}
