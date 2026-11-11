import Observation

/// The bottom tabs (sidebar on iPad), in design order.
public enum AppTab: String, Sendable, Hashable, CaseIterable {
    case home
    case discover
    case create
    case stories
    case profile
}

/// Screens pushed inside a tab.
public enum AppRoute: Sendable, Hashable {
    case category(String)
    case story(String)
    case generating(requestID: String)
    case storyReady(String)
    case reader(storyID: String, page: Int)
    case player(String)
    case downloads
    case notifications
    case childProfiles
    /// The profile form for a child, or a new child when nil.
    case editChild(String?)
    case language
    case help
    case reminder
    case privacy
    case subscription
}

/// Which part of the app is shown and each tab's stack (LLD §6).
@MainActor
@Observable
public final class AppRouter {
    public enum Root: Sendable, Equatable {
        /// Reading whether the first run is done.
        case launching
        case onboarding
        case main
    }

    public enum OnboardingStep: Sendable, Hashable {
        case setup
    }

    public var root: Root = .launching
    public var onboardingPath: [OnboardingStep] = []
    public private(set) var selectedTab: AppTab = .home
    public var paths: [AppTab: [AppRoute]] = [:]

    public init() {}

    public func showFirstRun(completed: Bool) {
        root = completed ? .main : .onboarding
    }

    public func openSetup() {
        onboardingPath = [.setup]
    }

    public func finishOnboarding() {
        onboardingPath = []
        selectedTab = .home
        paths = [:]
        root = .main
    }

    public func resetToOnboarding() {
        paths = [:]
        selectedTab = .home
        onboardingPath = []
        root = .onboarding
    }

    /// Selecting the active tab again returns it to its first screen.
    public func select(_ tab: AppTab) {
        if tab == selectedTab {
            popToRoot()
        } else {
            selectedTab = tab
        }
    }

    /// Pushes on the current tab; a route equal to the top is ignored, so double taps open it once.
    public func push(_ route: AppRoute) {
        var path = paths[selectedTab] ?? []
        guard path.last != route else {
            return
        }
        path.append(route)
        paths[selectedTab] = path
    }

    /// Swaps the top screen, so Back skips it (Generating gives way to Story ready).
    public func replaceTop(with route: AppRoute) {
        var path = paths[selectedTab] ?? []
        if !path.isEmpty {
            path.removeLast()
        }
        path.append(route)
        paths[selectedTab] = path
    }

    public func pop() {
        guard var path = paths[selectedTab], !path.isEmpty else {
            return
        }
        path.removeLast()
        paths[selectedTab] = path
    }

    public func popToRoot() {
        paths[selectedTab] = []
    }
}
