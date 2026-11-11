import Common
import CoreUI
import Domain
import Foundation
import Observation

public struct FilterChip: Sendable, Hashable, Identifiable {
    public let id: String
    public let label: UIText
}

public struct FeaturedItem: Sendable, Hashable {
    public let story: StoryItem
    public let synopsis: String
}

public struct DiscoverState: Sendable, Hashable {
    public var query = ""
    public var selectedFilter = AppConfig.Discover.allID
    public var filters: [FilterChip] = []
    /// Hidden while searching (design).
    public var featured: FeaturedItem?
    public var sectionTitle = UIText(DiscoverStrings.popular)
    public var results: [StoryItem] = []
    /// "View all" opens the Category screen for the active filter.
    public var showViewAll = false
    public var bedtime: [StoryItem] = []
    /// True until the catalogue first arrives.
    public var loading = true

    public var isSearching: Bool { !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    public var isFiltered: Bool { selectedFilter != AppConfig.Discover.allID }
    public var hasNoResults: Bool { results.isEmpty && (isSearching || isFiltered) && !loading }
}

/// Discover (SCR-04): search, featured story, filter chips, popular grid and bedtime row.
@MainActor
@Observable
public final class DiscoverViewModel {
    public private(set) var state = DiscoverState()
    @ObservationIgnored private let profiles: any ProfilesRepository
    @ObservationIgnored private let preferences: any PreferencesRepository
    @ObservationIgnored private let catalog: any CatalogRepository
    @ObservationIgnored private let favourites: any FavouritesRepository
    @ObservationIgnored private var snapshot: DiscoverSnapshot?

    public init(
        profiles: any ProfilesRepository,
        preferences: any PreferencesRepository,
        catalog: any CatalogRepository,
        favourites: any FavouritesRepository,
    ) {
        self.profiles = profiles
        self.preferences = preferences
        self.catalog = catalog
        self.favourites = favourites
    }

    public func start() async {
        let catalog = catalog
        let favourites = favourites
        let updates = Browse.context(profiles: profiles, preferences: preferences).flatMapLatest { context in
            combineLatest(Browse.catalogue(catalog, languageTag: context.languageTag), favourites.favouriteIDs(childID: context.childID))
                .map { catalogue, favouriteIDs in DiscoverSnapshot(context: context, catalogue: catalogue, favouriteIDs: favouriteIDs) }
        }
        for await snapshot in updates {
            self.snapshot = snapshot
            rebuild()
        }
    }

    public func onQueryChange(_ query: String) {
        state.query = query
        rebuild()
    }

    public func onFilterSelected(_ id: String) {
        state.selectedFilter = id
        rebuild()
    }

    /// "Clear search" resets the query and the chip to All.
    public func onClearSearch() {
        state.query = ""
        state.selectedFilter = AppConfig.Discover.allID
        rebuild()
    }

    public func onFavourite(storyID: String) async {
        guard let childID = snapshot?.context.childID else {
            return
        }
        _ = await favourites.toggle(storyID: storyID, childID: childID)
    }

    private func rebuild() {
        guard let snapshot else {
            return
        }
        state = Self.state(for: snapshot, query: state.query, filter: state.selectedFilter)
    }

    static func state(for snapshot: DiscoverSnapshot, query rawQuery: String, filter: String) -> DiscoverState {
        let catalogue = snapshot.catalogue
        let names = catalogue.categoryNames
        let locale = Locale(identifier: snapshot.context.languageTag)
        let query = rawQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        let matches = catalogue.stories.filter { story in
            (filter == AppConfig.Discover.allID || story.belongs(to: filter))
                && (query.isEmpty || story.matches(query, categoryName: names[story.categoryID] ?? "", locale: locale))
        }
        let unfiltered = filter == AppConfig.Discover.allID && query.isEmpty
        let results = unfiltered ? Array(matches.prefix(AppConfig.Discover.popularCount)) : matches
        let item = { (story: Story) in story.item(categoryNames: names, favouriteIDs: snapshot.favouriteIDs) }

        var state = DiscoverState()
        state.query = rawQuery
        state.selectedFilter = filter
        state.filters = AppConfig.Discover.filterIDs.compactMap { id in
            if id == AppConfig.Discover.allID {
                return FilterChip(id: id, label: UIText(DiscoverStrings.filterAll))
            }
            return names[id].map { FilterChip(id: id, label: .verbatim($0)) }
        }
        if query.isEmpty {
            let featured = catalogue.stories.first { $0.id == AppConfig.Discover.featuredStoryID } ?? catalogue.stories.first
            state.featured = featured.map { FeaturedItem(story: item($0), synopsis: $0.synopsis) }
            state.bedtime = catalogue.stories(in: AppConfig.Discover.bedtimeCategoryID).map(item)
        }
        if !query.isEmpty {
            state.sectionTitle = DiscoverStrings.results(.text(query))
        } else if !unfiltered {
            state.sectionTitle = .verbatim(names[filter] ?? "")
        }
        state.results = results.map(item)
        state.showViewAll = query.isEmpty && !results.isEmpty
        state.loading = false
        return state
    }
}

struct DiscoverSnapshot: Sendable {
    let context: BrowseContext
    let catalogue: Catalogue
    let favouriteIDs: Set<String>
}

extension Story {
    /// Free text, case- and diacritic-insensitive for the content locale, over title, synopsis and category.
    func matches(_ query: String, categoryName: String, locale: Locale) -> Bool {
        [title, synopsis, categoryName].contains { field in
            field.range(of: query, options: [.caseInsensitive, .diacriticInsensitive], locale: locale) != nil
        }
    }
}
