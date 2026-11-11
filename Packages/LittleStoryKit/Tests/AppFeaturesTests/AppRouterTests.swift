@testable import AppFeatures
import Testing

@MainActor
struct AppRouterTests {
    @Test("The first run decides between onboarding and the tabs")
    func firstRun() {
        let router = AppRouter()
        #expect(router.root == .launching)
        router.showFirstRun(completed: false)
        #expect(router.root == .onboarding)
        router.showFirstRun(completed: true)
        #expect(router.root == .main)
    }

    @Test("Finishing onboarding clears the setup step and opens Home")
    func finishOnboarding() {
        let router = AppRouter()
        router.showFirstRun(completed: false)
        router.openSetup()
        #expect(router.onboardingPath == [.setup])
        router.finishOnboarding()
        #expect(router.onboardingPath.isEmpty)
        #expect(router.root == .main)
        #expect(router.selectedTab == .home)
    }

    @Test("Each tab keeps its own stack and a double tap pushes once")
    func stacks() {
        let router = AppRouter()
        router.push(.category("animals"))
        router.push(.story("s1"))
        router.push(.story("s1"))
        #expect(router.paths[.home] == [.category("animals"), .story("s1")])
        router.select(.discover)
        router.push(.story("s2"))
        #expect(router.paths[.discover] == [.story("s2")])
        router.select(.home)
        #expect(router.paths[.home]?.count == 2)
        router.pop()
        #expect(router.paths[.home] == [.category("animals")])
    }

    @Test("Selecting the open tab again returns to its first screen")
    func reselect() {
        let router = AppRouter()
        router.push(.story("s1"))
        router.select(.home)
        #expect(router.paths[.home]?.isEmpty == true)
    }

    @Test("Resetting returns to onboarding with empty stacks")
    func reset() {
        let router = AppRouter()
        router.finishOnboarding()
        router.select(.discover)
        router.push(.story("s1"))
        router.resetToOnboarding()
        #expect(router.root == .onboarding)
        #expect(router.paths.isEmpty)
        #expect(router.selectedTab == .home)
    }
}

@MainActor
struct AppRouterCreateFlowTests {
    @Test("Story ready replaces Generating, so Back returns to the Create form")
    func replaceTop() {
        let router = AppRouter()
        router.select(.create)
        router.push(.generating(requestID: "r1"))
        router.replaceTop(with: .storyReady("made"))
        #expect(router.paths[.create] == [.storyReady("made")])
        router.pop()
        #expect(router.paths[.create]?.isEmpty == true)
    }
}
