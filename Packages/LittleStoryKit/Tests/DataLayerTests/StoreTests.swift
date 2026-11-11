import Common
@testable import DataLayer
import Domain
import Foundation
import Testing
import TestSupport

@Suite("Local store")
struct StoreTests {
    private let store: LittleStore
    private let preferences: PreferencesStore

    init() throws {
        store = try TestStores.store()
        preferences = try TestStores.preferences()
    }

    private func profiles(ids: [String] = ["p1", "p2"]) -> ProfilesRepositoryImpl {
        let queue = IDQueue(ids)
        return ProfilesRepositoryImpl(store: store, preferences: preferences, newID: { queue.next() })
    }

    @Test("The first created child becomes active; later ones keep the choice")
    func createSetsActive() async {
        let repository = profiles()
        #expect(await repository.activeProfile().first() == .some(nil))
        let first = await repository.create(Fixtures.draft(firstName: "  Aarav "))
        #expect(first.firstName == "Aarav")
        let second = await repository.create(Fixtures.draft(firstName: "Asha"))
        #expect(await repository.activeProfile().first()??.id == first.id)
        #expect(await repository.profiles().first()?.map(\.id) == [first.id, second.id])

        await repository.setActive(profileID: second.id)
        #expect(await repository.activeProfile().first()??.id == second.id)
    }

    @Test("Updating a profile keeps its place and round-trips every field")
    func update() async throws {
        let repository = profiles()
        let first = await repository.create(Fixtures.draft(firstName: "Aarav"))
        _ = await repository.create(Fixtures.draft(firstName: "Asha"))
        var changed = first
        changed.firstName = "Ravi"
        changed.age = 9
        changed.avatar = AvatarID(2)
        changed.interestIDs = ["space", "music"]
        changed.languageTag = "kn"
        await repository.update(changed)
        let all = try #require(await repository.profiles().first())
        #expect(all.first == changed)
    }

    @Test("Deleting a child removes their rows and falls back to the next profile")
    func deleteChild() async {
        let repository = profiles()
        let first = await repository.create(Fixtures.draft(firstName: "Aarav"))
        let second = await repository.create(Fixtures.draft(firstName: "Asha"))
        let favourites = FavouritesRepositoryImpl(store: store)
        let progress = ProgressRepositoryImpl(store: store)
        let library = LibraryRepositoryImpl(store: store)
        await favourites.setFavourite(true, storyID: "s1", childID: first.id)
        await favourites.setFavourite(true, storyID: "s1", childID: second.id)
        await progress.update(ReadingProgress(childID: first.id, storyID: "s1", page: 2, listenFraction: 0.5, updatedAt: Date()))
        await library.save(Fixtures.story(id: "generated_r1", origin: .generated), childID: first.id)

        await repository.delete(profileID: first.id)
        #expect(await repository.profiles().first()?.map(\.id) == [second.id])
        #expect(await repository.activeProfile().first()??.id == second.id)
        #expect(await favourites.favouriteIDs(childID: first.id).first() == [])
        #expect(await favourites.favouriteIDs(childID: second.id).first() == ["s1"])
        #expect(await progress.progress(childID: first.id).first() == [])
        #expect(await library.created(childID: first.id).first() == [])
    }

    @Test("Favourite toggles are serialised and an open stream sees each change")
    func favourites() async {
        let favourites = FavouritesRepositoryImpl(store: store)
        var iterator = favourites.favouriteIDs(childID: AppConfig.Profiles.guestID).makeAsyncIterator()
        #expect(await iterator.next() == [])
        #expect(await favourites.toggle(storyID: "s1", childID: AppConfig.Profiles.guestID))
        #expect(await iterator.next() == ["s1"])

        let toggles = 10
        await withTaskGroup { group in
            for _ in 0 ..< toggles {
                group.addTask { _ = await favourites.toggle(storyID: "s2", childID: AppConfig.Profiles.guestID) }
            }
        }
        // An even number of toggles leaves s2 where it started.
        #expect(await favourites.favouriteIDs(childID: AppConfig.Profiles.guestID).first() == ["s1"])
    }

    @Test("Progress is newest first, one record per child and story")
    func progress() async {
        let progress = ProgressRepositoryImpl(store: store)
        let start = Date(timeIntervalSince1970: 0)
        await progress.update(ReadingProgress(childID: "c", storyID: "a", page: 1, listenFraction: 0, updatedAt: start))
        await progress.update(ReadingProgress(
            childID: "c",
            storyID: "b",
            page: 1,
            listenFraction: 0,
            updatedAt: start.addingTimeInterval(1),
        ))
        await progress.update(ReadingProgress(
            childID: "c",
            storyID: "a",
            page: 3,
            listenFraction: 0.4,
            updatedAt: start.addingTimeInterval(2),
        ))
        let rows = await progress.progress(childID: "c").first() ?? []
        #expect(rows.map(\.storyID) == ["a", "b"])
        #expect(rows.first?.page == 3)
        #expect(rows.first?.listenFraction == 0.4)
    }

    @Test("Downloads are simulated with a fixed size and keep their order")
    func downloads() async {
        let clock = SteppingDates()
        let downloads = DownloadsRepositoryImpl(store: store, now: { clock.next() })
        await downloads.start(storyID: "b")
        await downloads.start(storyID: "a")
        await downloads.start(storyID: "b")
        let rows = await downloads.downloads().first() ?? []
        #expect(rows.map(\.storyID) == ["b", "a"])
        #expect(rows.allSatisfy { $0.status == .completed && $0.sizeBytes == AppConfig.Downloads.simulatedStoryBytes })
        await downloads.remove(storyID: "b")
        #expect(await downloads.downloads().first()?.map(\.storyID) == ["a"])
    }

    @Test("Created stories are newest first and saving again replaces the story")
    func library() async throws {
        let clock = SteppingDates()
        let library = LibraryRepositoryImpl(store: store, now: { clock.next() })
        let older = Fixtures.story(id: "generated_1", title: "Old", pages: ["A", "B"], origin: .generated)
        await library.save(older, childID: "c")
        await library.save(Fixtures.story(id: "generated_2", origin: .generated), childID: "c")
        await library.save(Fixtures.story(id: "generated_1", title: "Again", origin: .generated), childID: "c")
        #expect(await library.created(childID: "c").first()?.map(\.id) == ["generated_1", "generated_2"])
        let story = try #require(await library.story(id: "generated_1").first() ?? nil)
        #expect(story.title == "Again")
        #expect(story.origin == .generated)
        #expect(story.ages == older.ages)
        #expect(await library.story(id: "missing").first() == .some(nil))
    }

    @Test("Preferences have Android's defaults and round-trip")
    func preferencesRoundTrip() async throws {
        let repository = PreferencesRepositoryImpl(store: preferences)
        #expect(await repository.firstRunCompleted().first() == false)
        #expect(await repository.contentLanguageTag().first() == "en")
        let reading = try #require(await repository.reading().first())
        #expect(reading == ReadingPreferences(textScale: AppConfig.Reader.textScaleDefault, playbackSpeed: AppConfig.Player.defaultSpeed))
        let settings = try #require(await repository.parentSettings().first())
        #expect(settings.reminder.enabled == false)
        #expect(settings.reminder.days == Set(AppConfig.Reminder.defaultDaysOfWeek))
        #expect(settings.notificationsEnabled && settings.wifiOnlyDownloads)

        var iterator = repository.contentLanguageTag().makeAsyncIterator()
        #expect(await iterator.next() == "en")
        await repository.setContentLanguageTag("kn")
        #expect(await iterator.next() == "kn")

        await repository.setFirstRunCompleted(true)
        await repository.setReading(ReadingPreferences(textScale: 1.2, playbackSpeed: 1.5))
        let changed = ParentSettings(
            reminder: ReminderSettings(enabled: true, hour: 19, minute: 15, days: [1, 3, 5]),
            notificationsEnabled: false,
            wifiOnlyDownloads: false,
        )
        await repository.setParentSettings(changed)
        #expect(await repository.firstRunCompleted().first() == true)
        #expect(await repository.reading().first() == ReadingPreferences(textScale: 1.2, playbackSpeed: 1.5))
        #expect(await repository.parentSettings().first() == changed)
    }

    @Test("Deleting all local data empties every table and preference")
    func deleteAll() async {
        let repositories = LocalRepositories(store: store, preferences: preferences, clock: ImmediateClock())
        let child = await repositories.profiles.create(Fixtures.draft())
        await repositories.favourites.setFavourite(true, storyID: "s1", childID: child.id)
        await repositories.downloads.start(storyID: "s1")
        await repositories.notifications.markAllRead()
        await repositories.preferences.setFirstRunCompleted(true)

        await repositories.localData.deleteAll()
        #expect(await repositories.profiles.profiles().first() == [])
        #expect(await repositories.profiles.activeProfile().first() == .some(nil))
        #expect(await repositories.favourites.favouriteIDs(childID: child.id).first() == [])
        #expect(await repositories.downloads.downloads().first() == [])
        #expect(await repositories.notifications.notifications(languageTag: "en").first()?.contains { $0.read } == false)
        #expect(await repositories.preferences.firstRunCompleted().first() == false)
    }
}

/// Hands out fixed ids in order, then fresh UUIDs.
private final class IDQueue: @unchecked Sendable {
    private let lock = NSLock()
    private var ids: [String]

    init(_ ids: [String]) {
        self.ids = ids
    }

    func next() -> String {
        lock.withLock { ids.isEmpty ? UUID().uuidString : ids.removeFirst() }
    }
}

/// A date one second later on every call, so ordering by time is deterministic.
private final class SteppingDates: @unchecked Sendable {
    private let lock = NSLock()
    private var current = Date(timeIntervalSince1970: 0)

    func next() -> Date {
        lock.withLock {
            current = current.addingTimeInterval(1)
            return current
        }
    }
}
