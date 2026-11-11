/// Contracts the data layer implements. Reads are streams that emit the current value at once and
/// again on every change; writes are async. Nothing here knows about storage, bundles or UI.

/// Read-only catalogue of bundled stories, resolved for a language with English fallback.
public protocol CatalogRepository: Sendable {
    func categories(languageTag: String) -> AsyncStream<[StoryCategory]>
    func stories(languageTag: String) -> AsyncStream<[Story]>
    func story(id: String, languageTag: String) -> AsyncStream<Story?>
}

public protocol ProfilesRepository: Sendable {
    func profiles() -> AsyncStream<[ChildProfile]>
    /// The child whose name and defaults the app shows; nil before Setup is completed.
    func activeProfile() -> AsyncStream<ChildProfile?>
    func create(_ draft: ChildProfileDraft) async -> ChildProfile
    func update(_ profile: ChildProfile) async
    func delete(profileID: String) async
    func setActive(profileID: String) async
}

public protocol FavouritesRepository: Sendable {
    func favouriteIDs(childID: String) -> AsyncStream<Set<String>>
    func setFavourite(_ favourite: Bool, storyID: String, childID: String) async
    /// Flips `storyID` for `childID` and returns the new state. Implementations serialise toggles
    /// so rapid taps from any screen settle on a consistent value.
    func toggle(storyID: String, childID: String) async -> Bool
}

public extension FavouritesRepository {
    func toggle(storyID: String, childID: String) async -> Bool {
        let favourite = await !(favouriteIDs(childID: childID).first() ?? []).contains(storyID)
        await setFavourite(favourite, storyID: storyID, childID: childID)
        return favourite
    }
}

/// Stories the child created, newest first.
public protocol LibraryRepository: Sendable {
    func created(childID: String) -> AsyncStream<[Story]>
    /// A created story by id, whichever child made it; nil when it does not exist.
    func story(id: String) -> AsyncStream<Story?>
    func save(_ story: Story, childID: String) async
}

/// Simulated story generation (no AI provider in the MVP). Create submits the request, the
/// Generating screen runs `generate` for its id; nothing leaves the device.
public protocol GenerationRepository: Sendable {
    func submit(_ request: StoryCreationRequest) async
    func request(id: String) async -> StoryCreationRequest?
    /// Progress from `startPercent` to 100, then the saved story; `failed` when the request is unknown.
    func generate(requestID: String, startPercent: Int) -> AsyncStream<GenerationState>
}

public protocol ProgressRepository: Sendable {
    /// Newest first; Home's "Resume" reads the first.
    func progress(childID: String) -> AsyncStream<[ReadingProgress]>
    func update(_ progress: ReadingProgress) async
}

public protocol DownloadsRepository: Sendable {
    func downloads() -> AsyncStream<[Download]>
    func start(storyID: String) async
    func remove(storyID: String) async
}

/// App-level choices that survive restarts. The UI language is not here: the app's `Localizer` owns it.
public protocol PreferencesRepository: Sendable {
    /// True once the first-run flow (onboarding, Setup) is finished or skipped.
    func firstRunCompleted() -> AsyncStream<Bool>
    func setFirstRunCompleted(_ completed: Bool) async
    /// BCP 47 tag chosen for story content.
    func contentLanguageTag() -> AsyncStream<String>
    func setContentLanguageTag(_ tag: String) async
    func reading() -> AsyncStream<ReadingPreferences>
    func setReading(_ preferences: ReadingPreferences) async
    func parentSettings() -> AsyncStream<ParentSettings>
    func setParentSettings(_ settings: ParentSettings) async
}

public protocol NotificationsRepository: Sendable {
    func notifications(languageTag: String) -> AsyncStream<[NotificationItem]>
    func markRead(id: String) async
    func markAllRead() async
}

public protocol SubscriptionRepository: Sendable {
    /// Illustrative plans only; behind `FeatureFlags.demoSubscription`.
    func plans() -> AsyncStream<[Plan]>
}

/// Everything the app keeps on this device; Privacy & parent controls can wipe it.
public protocol LocalDataRepository: Sendable {
    /// Deletes profiles, favourites, progress, downloads, created stories and preferences.
    func deleteAll() async
}

/// The per-story repositories that the library, reader and player read together, so their view
/// models take one dependency instead of five.
public struct StoryStores: Sendable {
    public let catalog: any CatalogRepository
    public let library: any LibraryRepository
    public let favourites: any FavouritesRepository
    public let downloads: any DownloadsRepository
    public let progress: any ProgressRepository

    public init(
        catalog: any CatalogRepository,
        library: any LibraryRepository,
        favourites: any FavouritesRepository,
        downloads: any DownloadsRepository,
        progress: any ProgressRepository,
    ) {
        self.catalog = catalog
        self.library = library
        self.favourites = favourites
        self.downloads = downloads
        self.progress = progress
    }
}
