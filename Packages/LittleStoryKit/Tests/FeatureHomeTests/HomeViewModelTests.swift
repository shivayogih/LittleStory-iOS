import Common
import CoreUI
import Domain
@testable import FeatureHome
import Foundation
import Testing
import TestSupport

@MainActor
struct HomeViewModelTests {
    private let categories = ["bedtime", "animals", "adventure", "friendship", "indian_tales", "space"].map { Fixtures.category(id: $0) }
    private let stories = [
        Fixtures.story(id: "s1", title: "Moon", categoryID: "bedtime"),
        Fixtures.story(id: "s2", title: "Rocket", categoryID: "space"),
        Fixtures.story(id: "s3", title: "Tiger", categoryID: "adventure", tags: ["animals"]),
        Fixtures.story(id: "s4", title: "Friends", categoryID: "friendship"),
        Fixtures.story(id: "s5", title: "Elephant", categoryID: "animals"),
    ]

    private func snapshot(
        child: ChildProfile? = nil,
        favouriteIDs: Set<String> = [],
        progress: [ReadingProgress] = [],
    ) -> HomeSnapshot {
        HomeSnapshot(
            context: BrowseContext(child: child, languageTag: "en"),
            catalogue: Catalogue(stories: stories, categories: categories),
            favouriteIDs: favouriteIDs,
            progress: progress,
        )
    }

    @Test("Without a profile the titles are generic and there is nothing to continue")
    func guest() {
        let state = HomeViewModel.state(for: snapshot())
        #expect(state.title == UIText(HomeStrings.titleGeneric))
        #expect(state.madeForTitle == UIText(HomeStrings.madeForGeneric))
        #expect(state.avatarTone == nil)
        #expect(state.continueListening == nil)
        #expect(!state.loading)
    }

    @Test("The child's name, avatar and interests shape the screen")
    func personalised() {
        let child = Fixtures.child(firstName: "Asha")
        let state = HomeViewModel.state(for: snapshot(child: child))
        #expect(state.title == HomeStrings.titleForChild(.text("Asha")))
        #expect(state.title.resolved(for: Locale(identifier: "en")) == "Stories for Asha")
        #expect(state.avatarTone == child.avatar.index)
        // The fixture child likes animals: the tagged story and the animals story lead, catalogue order kept.
        #expect(state.madeFor.map(\.id) == ["s3", "s5", "s1", "s2"])
        #expect(state.madeFor.count == AppConfig.Home.madeForCount)
    }

    @Test("Explore shows the configured categories in order, skipping missing ones")
    func categoriesInOrder() {
        let state = HomeViewModel.state(for: snapshot())
        #expect(state.categories.map(\.id) == AppConfig.Home.exploreCategoryIDs)
    }

    @Test("Continue listening is the latest story that is started but not finished")
    func continueListening() {
        let now = Date(timeIntervalSince1970: 1_000_000)
        let progress = [
            ReadingProgress(childID: "guest", storyID: "s1", page: 0, listenFraction: 0.4, updatedAt: now),
            ReadingProgress(childID: "guest", storyID: "s2", page: 0, listenFraction: 1, updatedAt: now.addingTimeInterval(60)),
            ReadingProgress(childID: "guest", storyID: "s4", page: 0, listenFraction: 0.25, updatedAt: now.addingTimeInterval(30)),
        ]
        let state = HomeViewModel.state(for: snapshot(favouriteIDs: ["s4"], progress: progress))
        #expect(state.continueListening?.story.id == "s4")
        #expect(state.continueListening?.percent == 25)
        #expect(state.continueListening?.story.favourite == true)
        #expect(state.continueListening?.eyebrow.resolved(for: Locale(identifier: "en")) == "5 MIN · 25% COMPLETE")
    }

    @Test("start() follows the stores, and favouriting updates the screen")
    func liveUpdates() async throws {
        let catalog = FakeCatalog(stories: stories, categories: categories)
        let favourites = FakeFavourites()
        let viewModel = HomeViewModel(
            profiles: FakeProfiles(),
            preferences: FakePreferences(),
            catalog: catalog,
            favourites: favourites,
            progress: FakeProgress(),
        )
        let task = Task { await viewModel.start() }
        defer { task.cancel() }
        try await waitUntil { !viewModel.state.loading }
        await viewModel.onFavourite(storyID: "s1")
        try await waitUntil { viewModel.state.madeFor.first { $0.id == "s1" }?.favourite == true }
        #expect(favourites.byChild.current[AppConfig.Profiles.guestID] == ["s1"])
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
