import Domain
import Foundation

/// Every repository the app uses, built over one store, one preferences suite and the bundled
/// mock content. The app's `AppContainer` builds this once; tests build it in memory.
public struct LocalRepositories: Sendable {
    public let catalog: any CatalogRepository
    public let profiles: any ProfilesRepository
    public let favourites: any FavouritesRepository
    public let library: any LibraryRepository
    public let generation: any GenerationRepository
    public let progress: any ProgressRepository
    public let downloads: any DownloadsRepository
    public let preferences: any PreferencesRepository
    public let notifications: any NotificationsRepository
    public let subscription: any SubscriptionRepository
    public let localData: any LocalDataRepository

    public var storyStores: StoryStores {
        StoryStores(catalog: catalog, library: library, favourites: favourites, downloads: downloads, progress: progress)
    }

    public init(
        store: LittleStore,
        preferences preferencesStore: PreferencesStore,
        source: any MockContentSource = BundleMockContentSource(),
        clock: any Clock<Duration> = ContinuousClock(),
    ) {
        let library = LibraryRepositoryImpl(store: store)
        catalog = CatalogRepositoryImpl(source: source)
        profiles = ProfilesRepositoryImpl(store: store, preferences: preferencesStore)
        favourites = FavouritesRepositoryImpl(store: store)
        self.library = library
        generation = GenerationRepositoryImpl(source: source, library: library, clock: clock)
        progress = ProgressRepositoryImpl(store: store)
        downloads = DownloadsRepositoryImpl(store: store)
        preferences = PreferencesRepositoryImpl(store: preferencesStore)
        notifications = NotificationsRepositoryImpl(source: source, store: store)
        subscription = SubscriptionRepositoryImpl(source: source)
        localData = LocalDataRepositoryImpl(store: store, preferences: preferencesStore)
    }
}
