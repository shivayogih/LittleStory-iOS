import Common
import CoreUI
import Domain
import Observation

public struct StoryDetailContent: Sendable, Hashable {
    public let id: String
    public let title: String
    public let categoryName: String
    public let ages: ClosedRange<Int>
    public let durationMinutes: Int
    /// Native name of the language the text is actually in (English when a translation is missing).
    public let languageName: String
    public let synopsis: String
    public let lesson: String
    public let paletteID: String
    public let motifID: String
    public let favourite: Bool
    public let downloaded: Bool

    public var meta: UIText {
        DiscoverStrings.detailMeta(.number(ages.lowerBound), .number(ages.upperBound), .number(durationMinutes), .text(languageName))
    }

    public var narration: UIText { DiscoverStrings.detailNarrationText(.text(languageName)) }
    public var favouriteLabel: UIText {
        favourite ? CoreUIStrings.storyFavouriteRemove(.text(title)) : CoreUIStrings.storyFavouriteAdd(.text(title))
    }

    public var downloadLabel: UIText {
        downloaded ? DiscoverStrings.detailDownloadRemove(.text(title)) : DiscoverStrings.detailDownloadAdd(.text(title))
    }
}

public enum StoryDetailState: Sendable, Hashable {
    case loading
    case notFound
    case loaded(StoryDetailContent)
}

/// Story detail (SCR-06): cover, metadata, lesson, narration note, Listen and Read.
@MainActor
@Observable
public final class StoryDetailViewModel {
    public private(set) var state = StoryDetailState.loading
    @ObservationIgnored private let storyID: String
    @ObservationIgnored private let profiles: any ProfilesRepository
    @ObservationIgnored private let preferences: any PreferencesRepository
    @ObservationIgnored private let stores: StoryStores
    @ObservationIgnored private var childID = AppConfig.Profiles.guestID

    public init(storyID: String, profiles: any ProfilesRepository, preferences: any PreferencesRepository, stores: StoryStores) {
        self.storyID = storyID
        self.profiles = profiles
        self.preferences = preferences
        self.stores = stores
    }

    public func start() async {
        let stores = stores
        let storyID = storyID
        let updates = Browse.context(profiles: profiles, preferences: preferences).flatMapLatest { context in
            combineLatest(
                combineLatest(
                    Browse.story(id: storyID, languageTag: context.languageTag, catalog: stores.catalog, library: stores.library),
                    stores.catalog.categories(languageTag: context.languageTag),
                ),
                combineLatest(stores.favourites.favouriteIDs(childID: context.childID), stores.downloads.downloads()),
            )
            .map { content, saved in
                DetailSnapshot(context: context, story: content.0, categories: content.1, favouriteIDs: saved.0, downloads: saved.1)
            }
        }
        for await snapshot in updates {
            childID = snapshot.context.childID
            state = Self.state(for: snapshot)
        }
    }

    public func onFavourite() async {
        _ = await stores.favourites.toggle(storyID: storyID, childID: childID)
    }

    /// Downloads are simulated: this only records that the story is "available offline".
    public func onDownload() async {
        let downloaded = await stores.downloads.downloads().first()?.contains { $0.storyID == storyID } ?? false
        if downloaded {
            await stores.downloads.remove(storyID: storyID)
        } else {
            await stores.downloads.start(storyID: storyID)
        }
    }

    static func state(for snapshot: DetailSnapshot) -> StoryDetailState {
        guard let story = snapshot.story else {
            return .notFound
        }
        return .loaded(StoryDetailContent(
            id: story.id,
            title: story.title,
            categoryName: snapshot.categories.first { $0.id == story.categoryID }?.name ?? "",
            ages: story.ages,
            durationMinutes: story.durationMinutes,
            languageName: SupportedLanguages.language(forTag: story.resolvedLanguage).nativeName,
            synopsis: story.synopsis,
            lesson: story.lesson,
            paletteID: story.art.paletteID,
            motifID: story.art.motifID,
            favourite: snapshot.favouriteIDs.contains(story.id),
            downloaded: snapshot.downloads.contains { $0.storyID == story.id },
        ))
    }
}

struct DetailSnapshot: Sendable {
    let context: BrowseContext
    let story: Story?
    let categories: [StoryCategory]
    let favouriteIDs: Set<String>
    let downloads: [Download]
}
