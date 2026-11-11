import Common
import CoreUI
import Domain
import Foundation
import Observation

/// Tabs of My Stories, in display order.
public enum LibraryTab: String, Sendable, Hashable, CaseIterable {
    case all
    case createdByMe = "created"
    case downloaded
    case favourites

    var label: UIText {
        switch self {
        case .all: UIText(LibraryStrings.tabAll)
        case .createdByMe: UIText(LibraryStrings.tabCreated)
        case .downloaded: UIText(LibraryStrings.tabDownloaded)
        case .favourites: UIText(LibraryStrings.tabFavourites)
        }
    }
}

/// The story to pick up again, with the simulated time left.
public struct RecentlyPlayed: Sendable, Hashable {
    public let story: StoryItem
    /// Listening position from 0 to 1.
    public let progress: Double
    public let remainingSeconds: Int

    /// "12:05 remaining".
    public var remainingLabel: UIText {
        LibraryStrings.remaining(
            .text(String(remainingSeconds / Self.secondsPerMinute)),
            .number(remainingSeconds % Self.secondsPerMinute),
        )
    }

    public var playLabel: UIText { LibraryStrings.play(.text(story.title)) }

    private static let secondsPerMinute = 60
}

public struct MyStoriesState: Sendable, Hashable {
    public var loading = true
    public var query = ""
    public var tab = LibraryTab.all
    public var recentlyPlayed: RecentlyPlayed?
    public var stories: [StoryItem] = []
    /// Stories this child created; they open on Story ready rather than the catalogue detail.
    public var createdIDs: Set<String> = []

    /// The Downloaded tab has its own empty message.
    public var emptyTitle: UIText {
        UIText(tab == .downloaded ? LibraryStrings.emptyDownloadedTitle : LibraryStrings.emptyTitle)
    }

    public var emptyText: UIText {
        UIText(tab == .downloaded ? LibraryStrings.emptyDownloadedText : LibraryStrings.emptyText)
    }

    /// "Your collection" heads the list only on the All tab.
    public var showsCollectionTitle: Bool { tab == .all }
}

/// My Stories (SCR-12): the child's library across the catalogue and the stories they created.
@MainActor
@Observable
public final class MyStoriesViewModel {
    public private(set) var state: MyStoriesState
    @ObservationIgnored private let profiles: any ProfilesRepository
    @ObservationIgnored private let preferences: any PreferencesRepository
    @ObservationIgnored private let stores: StoryStores
    @ObservationIgnored private var snapshot: LibrarySnapshot?

    public init(
        tab: LibraryTab = .all,
        profiles: any ProfilesRepository,
        preferences: any PreferencesRepository,
        stores: StoryStores,
    ) {
        var initial = MyStoriesState()
        initial.tab = tab
        state = initial
        self.profiles = profiles
        self.preferences = preferences
        self.stores = stores
    }

    public func start() async {
        let stores = stores
        let updates = Browse.context(profiles: profiles, preferences: preferences).flatMapLatest { context in
            combineLatest(
                combineLatest(
                    Browse.catalogue(stores.catalog, languageTag: context.languageTag),
                    stores.library.created(childID: context.childID),
                ),
                combineLatest(
                    combineLatest(stores.favourites.favouriteIDs(childID: context.childID), stores.downloads.downloads()),
                    stores.progress.progress(childID: context.childID),
                ),
            )
            .map { content, saved in
                LibrarySnapshot(
                    context: context,
                    catalogue: content.0,
                    created: content.1,
                    favouriteIDs: saved.0.0,
                    downloadedIDs: Set(saved.0.1.map(\.storyID)),
                    progress: saved.1,
                )
            }
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

    public func onClearSearch() {
        onQueryChange("")
    }

    public func onTabSelected(_ tab: LibraryTab) {
        state.tab = tab
        rebuild()
    }

    public func onFavourite(storyID: String) async {
        guard let childID = snapshot?.context.childID else {
            return
        }
        _ = await stores.favourites.toggle(storyID: storyID, childID: childID)
    }

    private func rebuild() {
        guard let snapshot else {
            return
        }
        state = Self.state(for: snapshot, query: state.query, tab: state.tab)
    }

    static func state(for snapshot: LibrarySnapshot, query rawQuery: String, tab: LibraryTab) -> MyStoriesState {
        let all = snapshot.created + snapshot.catalogue.stories
        let names = snapshot.catalogue.categoryNames
        let item = { (story: Story) in
            story.item(categoryNames: names, favouriteIDs: snapshot.favouriteIDs, downloadedIDs: snapshot.downloadedIDs)
        }
        let inTab: [Story] = switch tab {
        case .all: all
        case .createdByMe: snapshot.created
        case .downloaded: all.filter { snapshot.downloadedIDs.contains($0.id) }
        case .favourites: all.filter { snapshot.favouriteIDs.contains($0.id) }
        }
        let query = rawQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        let locale = Locale(identifier: snapshot.context.languageTag)
        let matching = query.isEmpty ? inTab : inTab.filter { story in
            story.title.range(of: query, options: [.caseInsensitive, .diacriticInsensitive], locale: locale) != nil
        }

        var state = MyStoriesState()
        state.loading = false
        state.query = rawQuery
        state.tab = tab
        state.stories = matching.map(item)
        state.createdIDs = Set(snapshot.created.map(\.id))
        if tab == .all, query.isEmpty {
            state.recentlyPlayed = recentlyPlayed(in: all, progress: snapshot.progress, item: item)
        }
        return state
    }

    /// The newest story that was started but not finished.
    private static func recentlyPlayed(
        in stories: [Story],
        progress: [ReadingProgress],
        item: (Story) -> StoryItem,
    ) -> RecentlyPlayed? {
        let unfinished = progress
            .filter { $0.listenFraction > 0 && $0.listenFraction < 1 }
            .sorted { $0.updatedAt > $1.updatedAt }
        for row in unfinished {
            if let story = stories.first(where: { $0.id == row.storyID }) {
                let total = SimulatedPlayback.totalSeconds(durationMinutes: story.durationMinutes)
                return RecentlyPlayed(
                    story: item(story),
                    progress: row.listenFraction,
                    remainingSeconds: Int(Double(total) * (1 - row.listenFraction)),
                )
            }
        }
        return nil
    }
}

extension StoryItem {
    /// "6 min · 3–6 years" on a My Stories row.
    var libraryMeta: UIText {
        LibraryStrings.rowMeta(.number(durationMinutes), .number(ages.lowerBound), .number(ages.upperBound))
    }

    var playLabel: UIText { LibraryStrings.play(.text(title)) }
}

struct LibrarySnapshot: Sendable {
    let context: BrowseContext
    let catalogue: Catalogue
    let created: [Story]
    let favouriteIDs: Set<String>
    let downloadedIDs: Set<String>
    let progress: [ReadingProgress]
}
