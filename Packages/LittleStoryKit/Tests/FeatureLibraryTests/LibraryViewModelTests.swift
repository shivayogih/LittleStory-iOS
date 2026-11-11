import Common
import CoreUI
import Domain
@testable import FeatureLibrary
import Foundation
import Testing
import TestSupport

private let english = Locale(identifier: "en")
private let moon = Fixtures.story(id: "moon", title: "Moon Boat", durationMinutes: 30)
private let elephant = Fixtures.story(id: "elephant", title: "The Little Elephant")
private let mine = Fixtures.story(id: "mine", title: "Asha and the Kite", origin: .generated)

@MainActor
struct MyStoriesViewModelTests {
    private let stores = StoryStores.fakes(catalog: FakeCatalog(stories: [moon, elephant], categories: [Fixtures.category(id: "animals")]))
    private let guest = AppConfig.Profiles.guestID

    private func makeViewModel(tab: LibraryTab = .all) -> MyStoriesViewModel {
        MyStoriesViewModel(tab: tab, profiles: FakeProfiles(), preferences: FakePreferences(), stores: stores)
    }

    private func ids(_ viewModel: MyStoriesViewModel) -> [String] {
        viewModel.state.stories.map(\.id)
    }

    @Test("All lists the child's own stories first, then the catalogue")
    func allTab() async throws {
        await stores.library.save(mine, childID: guest)
        let viewModel = makeViewModel()
        let task = Task { await viewModel.start() }
        defer { task.cancel() }
        try await waitUntil { !viewModel.state.loading }
        try await waitUntil { ids(viewModel).count == 3 }
        #expect(ids(viewModel) == ["mine", "moon", "elephant"])
        #expect(viewModel.state.createdIDs == ["mine"])
        #expect(viewModel.state.showsCollectionTitle)
        #expect(viewModel.state.stories.first?.libraryMeta.resolved(for: english) == "5 min · 3–6 years")
    }

    @Test("Tabs filter to created, downloaded and favourite stories")
    func tabs() async throws {
        await stores.library.save(mine, childID: guest)
        await stores.downloads.start(storyID: "moon")
        await stores.favourites.setFavourite(true, storyID: "elephant", childID: guest)
        let viewModel = makeViewModel(tab: .createdByMe)
        let task = Task { await viewModel.start() }
        defer { task.cancel() }
        try await waitUntil { ids(viewModel) == ["mine"] }
        viewModel.onTabSelected(.downloaded)
        #expect(ids(viewModel) == ["moon"])
        #expect(viewModel.state.stories.first?.downloaded == true)
        viewModel.onTabSelected(.favourites)
        #expect(ids(viewModel) == ["elephant"])
        #expect(!viewModel.state.showsCollectionTitle)
    }

    @Test("The Downloaded tab has its own empty message")
    func emptyDownloaded() async throws {
        let viewModel = makeViewModel(tab: .downloaded)
        let task = Task { await viewModel.start() }
        defer { task.cancel() }
        try await waitUntil { !viewModel.state.loading }
        #expect(viewModel.state.stories.isEmpty)
        #expect(viewModel.state.emptyTitle.resolved(for: english) == "Ready for offline adventures?")
        viewModel.onTabSelected(.favourites)
        #expect(viewModel.state.emptyTitle.resolved(for: english) == "No stories here yet")
    }

    @Test("Search matches titles without regard to case and hides Recently played")
    func search() async throws {
        await stores.progress.update(ReadingProgress(
            childID: guest,
            storyID: "moon",
            page: 0,
            listenFraction: 0.5,
            updatedAt: Date(timeIntervalSince1970: 1),
        ))
        let viewModel = makeViewModel()
        let task = Task { await viewModel.start() }
        defer { task.cancel() }
        try await waitUntil { viewModel.state.recentlyPlayed != nil }
        viewModel.onQueryChange("  ELEPHANT ")
        #expect(ids(viewModel) == ["elephant"])
        #expect(viewModel.state.recentlyPlayed == nil)
        viewModel.onClearSearch()
        #expect(ids(viewModel).count == 2)
        #expect(viewModel.state.recentlyPlayed != nil)
    }

    @Test("Recently played is the newest unfinished story, with the time left")
    func recentlyPlayed() async throws {
        await stores.library.save(mine, childID: guest)
        let rows = [
            ReadingProgress(childID: guest, storyID: "mine", page: 0, listenFraction: 1, updatedAt: Date(timeIntervalSince1970: 3)),
            ReadingProgress(childID: guest, storyID: "moon", page: 0, listenFraction: 0.5, updatedAt: Date(timeIntervalSince1970: 2)),
            ReadingProgress(childID: guest, storyID: "elephant", page: 0, listenFraction: 0.2, updatedAt: Date(timeIntervalSince1970: 1)),
        ]
        for row in rows {
            await stores.progress.update(row)
        }
        let viewModel = makeViewModel()
        let task = Task { await viewModel.start() }
        defer { task.cancel() }
        try await waitUntil { viewModel.state.recentlyPlayed != nil }
        let recent = try #require(viewModel.state.recentlyPlayed)
        #expect(recent.story.id == "moon")
        #expect(recent.remainingSeconds == 900)
        #expect(recent.remainingLabel.resolved(for: english) == "15:00 remaining")
        #expect(recent.playLabel.resolved(for: english) == "Play Moon Boat")
    }

    @Test("Favourite toggles for the active child")
    func favourite() async throws {
        let viewModel = makeViewModel()
        let task = Task { await viewModel.start() }
        defer { task.cancel() }
        try await waitUntil { !viewModel.state.loading }
        await viewModel.onFavourite(storyID: "moon")
        let favourites = await stores.favourites.favouriteIDs(childID: guest).first()
        #expect(favourites == ["moon"])
    }
}

@MainActor
struct DownloadsViewModelTests {
    private let stores = StoryStores.fakes(catalog: FakeCatalog(stories: [moon, elephant], categories: []))

    private func makeViewModel() -> DownloadsViewModel {
        DownloadsViewModel(profiles: FakeProfiles(), preferences: FakePreferences(), stores: stores)
    }

    @Test("Saved stories are listed with their sizes and the storage used")
    func listsDownloads() async throws {
        await stores.downloads.start(storyID: "moon")
        await stores.downloads.start(storyID: "elephant")
        await stores.downloads.start(storyID: "gone")
        let viewModel = makeViewModel()
        let task = Task { await viewModel.start() }
        defer { task.cancel() }
        try await waitUntil { viewModel.state.items.count == 2 }
        #expect(viewModel.state.items.map(\.storyID) == ["moon", "elephant"])
        #expect(viewModel.state.usedLabel.resolved(for: english) == "24 MB used")
        #expect(viewModel.state.quotaLabel.resolved(for: english) == "1 GB available for stories")
        #expect(viewModel.state.items.first?.sizeLabel.resolved(for: english) == "12 MB · Audio & story")
        #expect(viewModel.state.usedFraction == AppConfig.Downloads.storageBarMinFraction)
    }

    @Test("Removing a download updates the list; an empty list shows the empty state")
    func remove() async throws {
        await stores.downloads.start(storyID: "moon")
        let viewModel = makeViewModel()
        let task = Task { await viewModel.start() }
        defer { task.cancel() }
        try await waitUntil { viewModel.state.items.count == 1 }
        await viewModel.onRemove(storyID: "moon")
        try await waitUntil { viewModel.state.items.isEmpty }
        #expect(viewModel.state.isEmpty)
        #expect(viewModel.state.usedFraction == 0)
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
