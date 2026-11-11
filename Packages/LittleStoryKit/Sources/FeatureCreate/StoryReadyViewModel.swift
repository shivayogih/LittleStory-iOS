import Common
import CoreUI
import Domain
import Observation

public struct StoryReadyContent: Sendable, Hashable {
    public let id: String
    public let title: String
    public let heroName: String?
    public let languageName: String
    public let durationMinutes: Int
    public let ages: ClosedRange<Int>
    public let synopsis: String
    public let peek: String
    public let paletteID: String
    public let motifID: String
    public let favourite: Bool
    public let downloaded: Bool

    public var meta: UIText {
        CreateStrings.readyMeta(.text(languageName), .number(durationMinutes), .number(ages.lowerBound), .number(ages.upperBound))
    }

    public var madeFor: UIText? { heroName.map { CreateStrings.readyMadeFor(.text($0)) } }

    public var favouriteLabel: UIText {
        favourite ? CoreUIStrings.storyFavouriteRemove(.text(title)) : CoreUIStrings.storyFavouriteAdd(.text(title))
    }

    public var downloadLabel: UIText {
        downloaded ? CreateStrings.readyDownloadRemove(.text(title)) : CreateStrings.readyDownloadAdd(.text(title))
    }
}

public enum StoryReadyState: Sendable, Hashable {
    case loading
    case notFound
    case loaded(StoryReadyContent)
}

/// Story ready (SCR-09): the generated story, already saved to My Stories.
@MainActor
@Observable
public final class StoryReadyViewModel {
    public private(set) var state = StoryReadyState.loading
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
                stores.library.story(id: storyID),
                combineLatest(stores.favourites.favouriteIDs(childID: context.childID), stores.downloads.downloads()),
            )
            .map { story, saved in
                ReadySnapshot(context: context, story: story, favouriteIDs: saved.0, downloadedIDs: Set(saved.1.map(\.storyID)))
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

    static func state(for snapshot: ReadySnapshot) -> StoryReadyState {
        guard let story = snapshot.story else {
            return .notFound
        }
        let peekIndex = AppConfig.Generation.peekPageIndex
        let peek = story.pages.indices.contains(peekIndex) ? story.pages[peekIndex].text : story.pages.first?.text ?? ""
        return .loaded(StoryReadyContent(
            id: story.id,
            title: story.title,
            heroName: snapshot.context.child?.firstName,
            languageName: SupportedLanguages.language(forTag: story.resolvedLanguage).nativeName,
            durationMinutes: story.durationMinutes,
            ages: story.ages,
            synopsis: story.synopsis,
            peek: peek,
            paletteID: story.art.paletteID,
            motifID: story.art.motifID,
            favourite: snapshot.favouriteIDs.contains(story.id),
            downloaded: snapshot.downloadedIDs.contains(story.id),
        ))
    }
}

struct ReadySnapshot: Sendable {
    let context: BrowseContext
    let story: Story?
    let favouriteIDs: Set<String>
    let downloadedIDs: Set<String>
}
