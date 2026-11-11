import Common
import Domain
import Foundation

/// Serialised by the store actor, so toggles from any screen settle on a consistent value.
public struct FavouritesRepositoryImpl: FavouritesRepository {
    private let store: LittleStore

    public init(store: LittleStore) {
        self.store = store
    }

    public func favouriteIDs(childID: String) -> AsyncStream<Set<String>> {
        store.observe(.savedStories) { actor in await actor.favouriteIDs(childID: childID) }
    }

    public func setFavourite(_ favourite: Bool, storyID: String, childID: String) async {
        await store.write(.savedStories) { actor in await actor.setFavourite(favourite, storyID: storyID, childID: childID) }
    }

    public func toggle(storyID: String, childID: String) async -> Bool {
        await store.write(.savedStories) { actor in await actor.toggleFavourite(storyID: storyID, childID: childID) }
    }
}

public struct ProgressRepositoryImpl: ProgressRepository {
    private let store: LittleStore

    public init(store: LittleStore) {
        self.store = store
    }

    public func progress(childID: String) -> AsyncStream<[ReadingProgress]> {
        store.observe(.progress) { actor in await actor.progress(childID: childID) }
    }

    public func update(_ progress: ReadingProgress) async {
        await store.write(.progress) { actor in await actor.upsert(progress) }
    }
}

/// Downloads are simulated: a row records the story and a fixed size, nothing is fetched.
public struct DownloadsRepositoryImpl: DownloadsRepository {
    private let store: LittleStore
    private let now: @Sendable () -> Date

    public init(store: LittleStore, now: @escaping @Sendable () -> Date = { Date() }) {
        self.store = store
        self.now = now
    }

    public func downloads() -> AsyncStream<[Download]> {
        store.observe(.downloads) { actor in await actor.downloads() }
    }

    public func start(storyID: String) async {
        let download = Download(storyID: storyID, sizeBytes: AppConfig.Downloads.simulatedStoryBytes, status: .completed)
        let startedAt = now()
        await store.write(.downloads) { actor in await actor.upsert(download, startedAt: startedAt) }
    }

    public func remove(storyID: String) async {
        await store.write(.downloads) { actor in await actor.removeDownload(storyID: storyID) }
    }
}

/// Stories made by the simulated generator, kept per child. `now` stamps the creation time.
public struct LibraryRepositoryImpl: LibraryRepository {
    private let store: LittleStore
    private let now: @Sendable () -> Date

    public init(store: LittleStore, now: @escaping @Sendable () -> Date = { Date() }) {
        self.store = store
        self.now = now
    }

    public func created(childID: String) -> AsyncStream<[Story]> {
        store.observe(.generatedStories) { actor in await actor.createdStories(childID: childID) }
    }

    public func story(id: String) -> AsyncStream<Story?> {
        store.observe(.generatedStories) { actor in await actor.createdStory(id: id) }
    }

    public func save(_ story: Story, childID: String) async {
        let createdAt = now()
        await store.write(.generatedStories) { actor in await actor.save(story, childID: childID, createdAt: createdAt) }
    }
}

/// Wipes everything this device keeps: the store and the preferences.
public struct LocalDataRepositoryImpl: LocalDataRepository {
    private let store: LittleStore
    private let preferences: PreferencesStore

    public init(store: LittleStore, preferences: PreferencesStore) {
        self.store = store
        self.preferences = preferences
    }

    public func deleteAll() async {
        await store.write(tables: Set(StoreTable.allCases)) { actor in await actor.deleteAll() }
        preferences.removeAll()
    }
}
