import Common
import Domain
import Foundation

// Small in-memory repositories for view model tests. Each read emits the current value and every
// later change, like the real store.

public final class FakeProfiles: ProfilesRepository, @unchecked Sendable {
    public let all: TestSubject<[ChildProfile]>
    public let activeID: TestSubject<String?>
    private let lock = NSLock()
    private var nextID = 0

    public init(_ profiles: [ChildProfile] = [], activeID: String? = nil) {
        all = TestSubject(profiles)
        self.activeID = TestSubject(activeID)
    }

    public func profiles() -> AsyncStream<[ChildProfile]> {
        all.stream()
    }

    public func activeProfile() -> AsyncStream<ChildProfile?> {
        combineLatest(all.stream(), activeID.stream()).map { profiles, id in
            profiles.first { $0.id == id } ?? profiles.first
        }
    }

    public func create(_ draft: ChildProfileDraft) async -> ChildProfile {
        let id = lock.withLock {
            nextID += 1
            return "child_\(nextID)"
        }
        let profile = ChildProfile(
            id: id,
            firstName: draft.firstName.trimmingCharacters(in: .whitespacesAndNewlines),
            age: draft.age,
            avatar: draft.avatar,
            interestIDs: draft.interestIDs,
            languageTag: draft.languageTag,
            defaultDurationMinutes: draft.defaultDurationMinutes,
        )
        all.send(all.current + [profile])
        return profile
    }

    public func update(_ profile: ChildProfile) async {
        all.send(all.current.map { $0.id == profile.id ? profile : $0 })
    }

    public func delete(profileID: String) async {
        all.send(all.current.filter { $0.id != profileID })
    }

    public func setActive(profileID: String) async {
        activeID.send(profileID)
    }
}

public final class FakePreferences: PreferencesRepository, @unchecked Sendable {
    public let firstRun: TestSubject<Bool>
    public let language: TestSubject<String>
    public let readingPreferences = TestSubject(ReadingPreferences(
        textScale: AppConfig.Reader.textScaleDefault,
        playbackSpeed: AppConfig.Player.defaultSpeed,
    ))
    public let parent = TestSubject(ParentSettings(
        reminder: ReminderSettings(
            enabled: false,
            hour: AppConfig.Reminder.defaultHour,
            minute: AppConfig.Reminder.defaultMinute,
            days: Set(AppConfig.Reminder.defaultDaysOfWeek),
        ),
        notificationsEnabled: true,
        wifiOnlyDownloads: true,
    ))

    public init(firstRunCompleted: Bool = false, languageTag: String = SupportedLanguages.fallback.tag) {
        firstRun = TestSubject(firstRunCompleted)
        language = TestSubject(languageTag)
    }

    public func firstRunCompleted() -> AsyncStream<Bool> { firstRun.stream() }
    public func setFirstRunCompleted(_ completed: Bool) async { firstRun.send(completed) }
    public func contentLanguageTag() -> AsyncStream<String> { language.stream() }
    public func setContentLanguageTag(_ tag: String) async { language.send(tag) }
    public func reading() -> AsyncStream<ReadingPreferences> { readingPreferences.stream() }
    public func setReading(_ preferences: ReadingPreferences) async { readingPreferences.send(preferences) }
    public func parentSettings() -> AsyncStream<ParentSettings> { parent.stream() }
    public func setParentSettings(_ settings: ParentSettings) async { parent.send(settings) }
}

/// A fixed catalogue per language tag; unknown tags get the English one.
public struct FakeCatalog: CatalogRepository {
    private let content: [String: Catalogue]

    public init(_ content: [String: Catalogue]) {
        self.content = content
    }

    public init(stories: [Story], categories: [StoryCategory]) {
        content = [SupportedLanguages.fallback.tag: Catalogue(stories: stories, categories: categories)]
    }

    private func catalogue(_ tag: String) -> Catalogue {
        content[tag] ?? content[SupportedLanguages.fallback.tag] ?? Catalogue(stories: [], categories: [])
    }

    public func categories(languageTag: String) -> AsyncStream<[StoryCategory]> { .of(catalogue(languageTag).categories) }
    public func stories(languageTag: String) -> AsyncStream<[Story]> { .of(catalogue(languageTag).stories) }
    public func story(id: String, languageTag: String) -> AsyncStream<Story?> { .of(catalogue(languageTag).stories.first { $0.id == id }) }
}

public final class FakeFavourites: FavouritesRepository, @unchecked Sendable {
    public let byChild = TestSubject<[String: Set<String>]>([:])

    public init() {}

    public func favouriteIDs(childID: String) -> AsyncStream<Set<String>> {
        byChild.stream().map { $0[childID] ?? [] }.removeDuplicates()
    }

    public func setFavourite(_ favourite: Bool, storyID: String, childID: String) async {
        var all = byChild.current
        var ids = all[childID] ?? []
        if favourite {
            ids.insert(storyID)
        } else {
            ids.remove(storyID)
        }
        all[childID] = ids
        byChild.send(all)
    }
}

public final class FakeProgress: ProgressRepository, @unchecked Sendable {
    public let rows = TestSubject<[ReadingProgress]>([])

    public init(_ rows: [ReadingProgress] = []) {
        self.rows.send(rows)
    }

    public func progress(childID: String) -> AsyncStream<[ReadingProgress]> {
        rows.stream().map { $0.filter { $0.childID == childID }.sorted { $0.updatedAt > $1.updatedAt } }
    }

    public func update(_ progress: ReadingProgress) async {
        rows.send(rows.current.filter { !($0.childID == progress.childID && $0.storyID == progress.storyID) } + [progress])
    }
}

public final class FakeDownloads: DownloadsRepository, @unchecked Sendable {
    public let rows = TestSubject<[Download]>([])

    public init() {}

    public func downloads() -> AsyncStream<[Download]> { rows.stream() }

    public func start(storyID: String) async {
        rows.send(rows.current + [Download(storyID: storyID, sizeBytes: AppConfig.Downloads.simulatedStoryBytes, status: .completed)])
    }

    public func remove(storyID: String) async {
        rows.send(rows.current.filter { $0.storyID != storyID })
    }
}

public final class FakeLibrary: LibraryRepository, @unchecked Sendable {
    public let stories = TestSubject<[String: [Story]]>([:])

    public init() {}

    public func created(childID: String) -> AsyncStream<[Story]> { stories.stream().map { $0[childID] ?? [] } }
    public func story(id: String) -> AsyncStream<Story?> { stories.stream().map { $0.values.joined().first { $0.id == id } } }

    public func save(_ story: Story, childID: String) async {
        var all = stories.current
        all[childID, default: []].insert(story, at: 0)
        stories.send(all)
    }
}

public extension StoryStores {
    static func fakes(catalog: any CatalogRepository) -> StoryStores {
        StoryStores(
            catalog: catalog,
            library: FakeLibrary(),
            favourites: FakeFavourites(),
            downloads: FakeDownloads(),
            progress: FakeProgress(),
        )
    }
}

/// Records requests and plays back a scripted run: progress steps, then the story id (saved to
/// `library` first, like the real generator), or a failure.
public final class FakeGeneration: GenerationRepository, @unchecked Sendable {
    public enum Outcome: Sendable {
        case completes(Story)
        case fails(GenerationError)
    }

    private let lock = NSLock()
    private var requests: [String: StoryCreationRequest] = [:]
    private let library: any LibraryRepository
    public var outcome: Outcome
    public var steps: [Int]

    public init(library: any LibraryRepository, outcome: Outcome, steps: [Int] = [20, 50, 90]) {
        self.library = library
        self.outcome = outcome
        self.steps = steps
    }

    public var submitted: [StoryCreationRequest] { lock.withLock { Array(requests.values) } }

    public func submit(_ request: StoryCreationRequest) async {
        lock.withLock { requests[request.requestID] = request }
    }

    public func request(id: String) async -> StoryCreationRequest? {
        lock.withLock { requests[id] }
    }

    public func generate(requestID: String, startPercent: Int) -> AsyncStream<GenerationState> {
        let request = lock.withLock { requests[requestID] }
        let remaining = steps.filter { $0 > startPercent }
        let result = outcome
        let store = library
        return AsyncStream { continuation in
            let task = Task {
                guard let request else {
                    continuation.yield(.failed(requestID: requestID, error: .unknownRequest))
                    continuation.finish()
                    return
                }
                for percent in remaining {
                    continuation.yield(.inProgress(requestID: requestID, stage: GenerationStage(percent: percent), percent: percent))
                }
                switch result {
                case let .completes(story):
                    await store.save(story, childID: request.heroChildID)
                    continuation.yield(.completed(requestID: requestID, storyID: story.id))
                case let .fails(error):
                    continuation.yield(.failed(requestID: requestID, error: error))
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}

/// Inbox items per language; reading state is shared across languages, like the real store.
public final class FakeNotifications: NotificationsRepository, @unchecked Sendable {
    public let items: TestSubject<[NotificationItem]>
    public let readIDs = TestSubject<Set<String>>([])

    public init(_ items: [NotificationItem] = []) {
        self.items = TestSubject(items)
    }

    public func notifications(languageTag _: String) -> AsyncStream<[NotificationItem]> {
        combineLatest(items.stream(), readIDs.stream()).map { all, read in
            all.map { item in
                var copy = item
                copy.read = item.read || read.contains(item.id)
                return copy
            }
        }
    }

    public func markRead(id: String) async {
        readIDs.send(readIDs.current.union([id]))
    }

    public func markAllRead() async {
        readIDs.send(Set(items.current.map(\.id)))
    }
}
