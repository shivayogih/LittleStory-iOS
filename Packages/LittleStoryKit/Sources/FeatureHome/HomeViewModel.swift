import Common
import CoreUI
import Domain
import Observation

/// The story the child can pick up again; `percent` is whole percent listened.
public struct ContinueItem: Sendable, Hashable {
    public let story: StoryItem
    public let percent: Int

    public var eyebrow: UIText {
        HomeStrings.continueEyebrow(.number(story.durationMinutes), .number(percent))
    }
}

public struct CategoryTileItem: Sendable, Hashable, Identifiable {
    public let id: String
    public let name: String
}

public struct HomeState: Sendable, Hashable {
    public var title = UIText(HomeStrings.titleGeneric)
    public var madeForTitle = UIText(HomeStrings.madeForGeneric)
    /// Avatar look of the active child; nil when Setup was skipped.
    public var avatarTone: Int?
    public var continueListening: ContinueItem?
    public var categories: [CategoryTileItem] = []
    public var madeFor: [StoryItem] = []
    /// True until the catalogue and the child's progress first arrive.
    public var loading = true
}

/// Home (SCR-03): greeting, create hero, continue listening, categories and picks for the child.
@MainActor
@Observable
public final class HomeViewModel {
    public private(set) var state = HomeState()
    @ObservationIgnored private let profiles: any ProfilesRepository
    @ObservationIgnored private let preferences: any PreferencesRepository
    @ObservationIgnored private let catalog: any CatalogRepository
    @ObservationIgnored private let favourites: any FavouritesRepository
    @ObservationIgnored private let progress: any ProgressRepository
    @ObservationIgnored private var childID = AppConfig.Profiles.guestID

    public init(
        profiles: any ProfilesRepository,
        preferences: any PreferencesRepository,
        catalog: any CatalogRepository,
        favourites: any FavouritesRepository,
        progress: any ProgressRepository,
    ) {
        self.profiles = profiles
        self.preferences = preferences
        self.catalog = catalog
        self.favourites = favourites
        self.progress = progress
    }

    /// Runs while the screen is shown (`.task`).
    public func start() async {
        let catalog = catalog
        let favourites = favourites
        let progress = progress
        let updates = Browse.context(profiles: profiles, preferences: preferences).flatMapLatest { context in
            combineLatest(
                Browse.catalogue(catalog, languageTag: context.languageTag),
                combineLatest(favourites.favouriteIDs(childID: context.childID), progress.progress(childID: context.childID)),
            )
            .map { catalogue, saved in HomeSnapshot(context: context, catalogue: catalogue, favouriteIDs: saved.0, progress: saved.1) }
        }
        for await snapshot in updates {
            childID = snapshot.context.childID
            state = Self.state(for: snapshot)
        }
    }

    public func onFavourite(storyID: String) async {
        _ = await favourites.toggle(storyID: storyID, childID: childID)
    }

    static func state(for snapshot: HomeSnapshot) -> HomeState {
        let catalogue = snapshot.catalogue
        let names = catalogue.categoryNames
        let child = snapshot.context.child
        let resumable = snapshot.progress
            .filter { $0.listenFraction > 0 && $0.listenFraction < 1 }
            .sorted { $0.updatedAt > $1.updatedAt }
            .lazy
            .compactMap { row in catalogue.stories.first { $0.id == row.storyID }.map { ($0, row) } }
            .first
        let interests = child?.interestIDs ?? []
        // Stories matching the child's interests first; the sort is stable, so catalogue order stays.
        let ranked = catalogue.stories.enumerated().sorted { lhs, rhs in
            let lhsMatch = interests.contains { lhs.element.belongs(to: $0) }
            let rhsMatch = interests.contains { rhs.element.belongs(to: $0) }
            return lhsMatch == rhsMatch ? lhs.offset < rhs.offset : lhsMatch
        }.map(\.element)
        var state = HomeState()
        if let child {
            state.title = HomeStrings.titleForChild(.text(child.firstName))
            state.madeForTitle = HomeStrings.madeForChild(.text(child.firstName))
            state.avatarTone = child.avatar.index
        }
        state.continueListening = resumable.map { story, row in
            ContinueItem(
                story: story.item(categoryNames: names, favouriteIDs: snapshot.favouriteIDs),
                percent: Int(row.listenFraction * Double(Self.percent)),
            )
        }
        state.categories = AppConfig.Home.exploreCategoryIDs.compactMap { id in
            catalogue.category(id: id).map { CategoryTileItem(id: $0.id, name: $0.name) }
        }
        state.madeFor = ranked.prefix(AppConfig.Home.madeForCount).map {
            $0.item(categoryNames: names, favouriteIDs: snapshot.favouriteIDs)
        }
        state.loading = false
        return state
    }

    private static let percent = 100
}

struct HomeSnapshot: Sendable {
    let context: BrowseContext
    let catalogue: Catalogue
    let favouriteIDs: Set<String>
    let progress: [ReadingProgress]
}
