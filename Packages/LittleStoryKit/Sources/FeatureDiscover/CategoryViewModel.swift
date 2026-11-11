import Common
import CoreUI
import Domain
import Observation

public struct SortOption: Sendable, Hashable, Identifiable {
    public let id: String
    public let label: UIText
}

public struct CategoryState: Sendable, Hashable {
    public var title = UIText.verbatim("")
    public var summary = UIText.verbatim("")
    public var storyCount = 0
    public var sortOptions: [SortOption] = CategorySorting.options
    public var selectedSort = AppConfig.Discover.defaultSortID
    public var stories: [StoryItem] = []
    /// True until the catalogue first arrives, so "No stories" never flashes while loading.
    public var loading = true

    public var countLabel: UIText { DiscoverStrings.categoryStoryCount(.number(storyCount)) }
}

/// Category (SCR-05): one collection, or the whole catalogue for `AppConfig.Discover.allID`, sorted.
@MainActor
@Observable
public final class CategoryViewModel {
    public private(set) var state = CategoryState()
    @ObservationIgnored private let categoryID: String
    @ObservationIgnored private let profiles: any ProfilesRepository
    @ObservationIgnored private let preferences: any PreferencesRepository
    @ObservationIgnored private let catalog: any CatalogRepository
    @ObservationIgnored private let favourites: any FavouritesRepository
    @ObservationIgnored private let downloads: any DownloadsRepository
    @ObservationIgnored private var snapshot: CategorySnapshot?

    public init(
        categoryID: String,
        profiles: any ProfilesRepository,
        preferences: any PreferencesRepository,
        catalog: any CatalogRepository,
        favourites: any FavouritesRepository,
        downloads: any DownloadsRepository,
    ) {
        self.categoryID = categoryID
        self.profiles = profiles
        self.preferences = preferences
        self.catalog = catalog
        self.favourites = favourites
        self.downloads = downloads
    }

    public func start() async {
        let catalog = catalog
        let favourites = favourites
        let downloads = downloads
        let updates = Browse.context(profiles: profiles, preferences: preferences).flatMapLatest { context in
            combineLatest(
                Browse.catalogue(catalog, languageTag: context.languageTag),
                combineLatest(favourites.favouriteIDs(childID: context.childID), downloads.downloads()),
            )
            .map { catalogue, saved in
                CategorySnapshot(
                    context: context,
                    catalogue: catalogue,
                    favouriteIDs: saved.0,
                    downloadedIDs: Set(saved.1.map(\.storyID)),
                )
            }
        }
        for await snapshot in updates {
            self.snapshot = snapshot
            state = Self.state(for: snapshot, categoryID: categoryID, sort: state.selectedSort)
        }
    }

    public func onSortSelected(_ id: String) {
        state.selectedSort = id
        if let snapshot {
            state = Self.state(for: snapshot, categoryID: categoryID, sort: id)
        }
    }

    public func onFavourite(storyID: String) async {
        guard let childID = snapshot?.context.childID else {
            return
        }
        _ = await favourites.toggle(storyID: storyID, childID: childID)
    }

    static func state(for snapshot: CategorySnapshot, categoryID: String, sort: String) -> CategoryState {
        let catalogue = snapshot.catalogue
        let isAll = categoryID == AppConfig.Discover.allID
        let category = catalogue.category(id: categoryID)
        let members = isAll ? catalogue.stories : catalogue.stories(in: categoryID)
        var state = CategoryState()
        state.title = isAll ? UIText(DiscoverStrings.categoryAllName) : .verbatim(category?.name ?? "")
        state.summary = isAll ? UIText(DiscoverStrings.categoryAllDescription) : .verbatim(category?.summary ?? "")
        state.storyCount = members.count
        state.selectedSort = sort
        state.stories = CategorySorting.sorted(members, by: sort).map {
            $0.item(categoryNames: catalogue.categoryNames, favouriteIDs: snapshot.favouriteIDs, downloadedIDs: snapshot.downloadedIDs)
        }
        state.loading = false
        return state
    }
}

/// Sort options and ordering for the Category screen.
enum CategorySorting {
    static let options = AppConfig.Discover.sortOptionIDs.map { id in
        SortOption(id: id, label: UIText(label(id)))
    }

    /// Recommended keeps catalogue order; the sorts are stable.
    static func sorted(_ stories: [Story], by sort: String) -> [Story] {
        switch sort {
        case shortest:
            stories.enumerated().sorted { ($0.element.durationMinutes, $0.offset) < ($1.element.durationMinutes, $1.offset) }.map(\.element)
        case newest:
            stories.enumerated().sorted { ($1.element.addedEpochDay, $0.offset) < ($0.element.addedEpochDay, $1.offset) }.map(\.element)
        default:
            stories
        }
    }

    private static let shortest = "shortest"
    private static let newest = "newest"

    private static func label(_ id: String) -> LocalizedKey {
        switch id {
        case shortest: DiscoverStrings.sortShortest
        case newest: DiscoverStrings.sortNewest
        default: DiscoverStrings.sortRecommended
        }
    }
}

struct CategorySnapshot: Sendable {
    let context: BrowseContext
    let catalogue: Catalogue
    let favouriteIDs: Set<String>
    let downloadedIDs: Set<String>
}
