import Common
import CoreUI
import Domain
@testable import FeatureDiscover
import Foundation
import Testing
import TestSupport

private let categories = ["bedtime", "animals", "adventure", "space"].map { Fixtures.category(id: $0) }
private let stories = [
    Fixtures.story(id: "s1", title: "Moon Lullaby", categoryID: "bedtime"),
    Fixtures.story(id: AppConfig.Discover.featuredStoryID, title: "The Little Elephant", categoryID: "animals"),
    Fixtures.story(id: "s3", title: "Tiger Trail", categoryID: "adventure", tags: ["animals"]),
    Fixtures.story(id: "s4", title: "Rocket Café", categoryID: "space"),
    Fixtures.story(id: "s5", title: "Starry Night", categoryID: "bedtime", synopsis: "Counting stars."),
]

private func snapshot(favouriteIDs: Set<String> = []) -> DiscoverSnapshot {
    DiscoverSnapshot(
        context: BrowseContext(child: nil, languageTag: "en"),
        catalogue: Catalogue(stories: stories, categories: categories),
        favouriteIDs: favouriteIDs,
    )
}

@MainActor
struct DiscoverViewModelTests {
    @Test("Browsing shows the featured story, a popular grid and the bedtime row")
    func browsing() {
        let state = DiscoverViewModel.state(for: snapshot(), query: "", filter: AppConfig.Discover.allID)
        #expect(state.featured?.story.id == AppConfig.Discover.featuredStoryID)
        #expect(state.results.count == AppConfig.Discover.popularCount)
        #expect(state.bedtime.map(\.id) == ["s1", "s5"])
        #expect(state.sectionTitle == UIText(DiscoverStrings.popular))
        #expect(state.showViewAll)
        #expect(!state.hasNoResults)
    }

    @Test("Filter chips list All plus the categories the catalogue has, in config order")
    func chips() {
        let state = DiscoverViewModel.state(for: snapshot(), query: "", filter: AppConfig.Discover.allID)
        #expect(state.filters.map(\.id) == ["all", "animals", "adventure", "space"])
        #expect(state.filters.first?.label == UIText(DiscoverStrings.filterAll))
    }

    @Test("A filter keeps stories whose category or tag matches")
    func filter() {
        let state = DiscoverViewModel.state(for: snapshot(), query: "", filter: "animals")
        #expect(state.results.map(\.id) == [AppConfig.Discover.featuredStoryID, "s3"])
        #expect(state.sectionTitle == .verbatim("Animals"))
    }

    @Test("Search ignores case and accents, covers the synopsis and hides featured and bedtime")
    func search() {
        let accent = DiscoverViewModel.state(for: snapshot(), query: "  rocket cafe ", filter: AppConfig.Discover.allID)
        #expect(accent.results.map(\.id) == ["s4"])
        #expect(accent.featured == nil)
        #expect(accent.bedtime.isEmpty)
        #expect(!accent.showViewAll)
        #expect(accent.sectionTitle.resolved(for: Locale(identifier: "en")) == "Results for “rocket cafe”")

        let synopsis = DiscoverViewModel.state(for: snapshot(), query: "STARS", filter: AppConfig.Discover.allID)
        #expect(synopsis.results.map(\.id) == ["s5"])
    }

    @Test("No match shows the empty state")
    func empty() {
        let state = DiscoverViewModel.state(for: snapshot(), query: "dragon", filter: "space")
        #expect(state.results.isEmpty)
        #expect(state.hasNoResults)
    }

    @Test("Clear search resets the query and the chip")
    func clear() async throws {
        let viewModel = DiscoverViewModel(
            profiles: FakeProfiles(),
            preferences: FakePreferences(),
            catalog: FakeCatalog(stories: stories, categories: categories),
            favourites: FakeFavourites(),
        )
        let task = Task { await viewModel.start() }
        defer { task.cancel() }
        try await waitUntil { !viewModel.state.loading }
        viewModel.onFilterSelected("space")
        viewModel.onQueryChange("dragon")
        #expect(viewModel.state.hasNoResults)
        viewModel.onClearSearch()
        #expect(viewModel.state.query.isEmpty)
        #expect(viewModel.state.selectedFilter == AppConfig.Discover.allID)
        #expect(viewModel.state.featured != nil)
    }
}

@MainActor
struct CategoryViewModelTests {
    private let sortable = [
        Fixtures.story(id: "a", categoryID: "animals", durationMinutes: 10, addedEpochDay: 100),
        Fixtures.story(id: "b", categoryID: "animals", durationMinutes: 5, addedEpochDay: 300),
        Fixtures.story(id: "c", categoryID: "space", tags: ["animals"], durationMinutes: 5, addedEpochDay: 200),
        Fixtures.story(id: "d", categoryID: "space", durationMinutes: 3, addedEpochDay: 400),
    ]

    private func state(_ categoryID: String, sort: String = AppConfig.Discover.defaultSortID) -> CategoryState {
        CategoryViewModel.state(
            for: CategorySnapshot(
                context: BrowseContext(child: nil, languageTag: "en"),
                catalogue: Catalogue(stories: sortable, categories: categories),
                favouriteIDs: [],
                downloadedIDs: ["b"],
            ),
            categoryID: categoryID,
            sort: sort,
        )
    }

    @Test("A category lists its stories and tagged ones, with name, summary and count")
    func members() {
        let animals = state("animals")
        #expect(animals.stories.map(\.id) == ["a", "b", "c"])
        #expect(animals.title == .verbatim("Animals"))
        #expect(animals.storyCount == 3)
        #expect(animals.stories.first { $0.id == "b" }?.downloaded == true)
    }

    @Test("All stories uses the catalogue-wide title")
    func all() {
        let all = state(AppConfig.Discover.allID)
        #expect(all.stories.count == sortable.count)
        #expect(all.title == UIText(DiscoverStrings.categoryAllName))
    }

    @Test("Shortest and newest sort stably; recommended keeps catalogue order")
    func sorting() {
        #expect(state("animals", sort: "shortest").stories.map(\.id) == ["b", "c", "a"])
        #expect(state("animals", sort: "newest").stories.map(\.id) == ["b", "c", "a"])
        #expect(state(AppConfig.Discover.allID, sort: "newest").stories.map(\.id) == ["d", "b", "c", "a"])
        #expect(state("animals", sort: "recommended").stories.map(\.id) == ["a", "b", "c"])
        #expect(CategorySorting.options.map(\.id) == AppConfig.Discover.sortOptionIDs)
    }

    @Test("The count label uses plural forms in English and Kannada")
    func countLabel() {
        var one = CategoryState()
        one.storyCount = 1
        var many = CategoryState()
        many.storyCount = 4
        #expect(one.countLabel.resolved(for: Locale(identifier: "en")) == "1 STORY")
        #expect(many.countLabel.resolved(for: Locale(identifier: "en")) == "4 STORIES")
        #expect(one.countLabel.resolved(for: Locale(identifier: "kn")) == "1 ಕಥೆ")
        #expect(many.countLabel.resolved(for: Locale(identifier: "kn")) == "4 ಕಥೆಗಳು")
    }
}

@MainActor
struct StoryDetailViewModelTests {
    private func makeViewModel(storyID: String) -> (StoryDetailViewModel, StoryStores) {
        let stores = StoryStores.fakes(catalog: FakeCatalog(stories: stories, categories: categories))
        let viewModel = StoryDetailViewModel(storyID: storyID, profiles: FakeProfiles(), preferences: FakePreferences(), stores: stores)
        return (viewModel, stores)
    }

    @Test("An unknown story shows not found")
    func notFound() async throws {
        let (viewModel, _) = makeViewModel(storyID: "missing")
        let task = Task { await viewModel.start() }
        defer { task.cancel() }
        try await waitUntil { viewModel.state != .loading }
        #expect(viewModel.state == .notFound)
    }

    @Test("Favourite and download toggle and relabel the buttons")
    func toggles() async throws {
        let (viewModel, stores) = makeViewModel(storyID: "s1")
        let task = Task { await viewModel.start() }
        defer { task.cancel() }
        try await waitUntil { viewModel.content != nil }
        #expect(viewModel.content?.categoryName == "Bedtime")
        #expect(viewModel.content?.languageName == "English")
        #expect(viewModel.content?.favouriteLabel.resolved(for: Locale(identifier: "en")) == "Add Moon Lullaby to favourites")

        await viewModel.onFavourite()
        await viewModel.onDownload()
        try await waitUntil { viewModel.content?.favourite == true && viewModel.content?.downloaded == true }
        #expect(viewModel.content?.downloadLabel == DiscoverStrings.detailDownloadRemove(.text("Moon Lullaby")))

        await viewModel.onDownload()
        try await waitUntil { viewModel.content?.downloaded == false }
        #expect(await stores.downloads.downloads().first()?.isEmpty == true)
    }
}

private extension StoryDetailViewModel {
    var content: StoryDetailContent? {
        if case let .loaded(content) = state {
            return content
        }
        return nil
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
