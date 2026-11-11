import Common
import Domain
import Testing
import TestSupport

private struct FakeProfiles: ProfilesRepository {
    let active: TestSubject<ChildProfile?>

    func profiles() -> AsyncStream<[ChildProfile]> {
        active.stream().map { child in child.map { [$0] } ?? [] }
    }

    func activeProfile() -> AsyncStream<ChildProfile?> {
        active.stream()
    }

    func create(_ draft: ChildProfileDraft) async -> ChildProfile {
        Fixtures.child(firstName: draft.firstName)
    }

    func update(_: ChildProfile) async {}

    func delete(profileID _: String) async {}

    func setActive(profileID _: String) async {}
}

private struct FakePreferences: PreferencesRepository {
    let language: TestSubject<String>

    func firstRunCompleted() -> AsyncStream<Bool> {
        .of(true)
    }

    func setFirstRunCompleted(_: Bool) async {}

    func contentLanguageTag() -> AsyncStream<String> {
        language.stream()
    }

    func setContentLanguageTag(_ tag: String) async {
        language.send(tag)
    }

    func reading() -> AsyncStream<ReadingPreferences> {
        AsyncStream { $0.finish() }
    }

    func setReading(_: ReadingPreferences) async {}

    func parentSettings() -> AsyncStream<ParentSettings> {
        AsyncStream { $0.finish() }
    }

    func setParentSettings(_: ParentSettings) async {}
}

struct StreamOperatorTests {
    private func collect<T>(_ stream: AsyncStream<T>) async -> [T] {
        var values: [T] = []
        for await value in stream {
            values.append(value)
        }
        return values
    }

    @Test("map and removeDuplicates transform and drop repeats")
    func mapAndDedupe() async {
        let values = await collect(AsyncStream.of(1, 1, 2, 2, 2, 3, 1).map { $0 * 10 }.removeDuplicates())
        #expect(values == [10, 20, 30, 10])
    }

    @Test("first returns the first element, or nil for an empty stream")
    func first() async {
        #expect(await AsyncStream.of(7, 8).first() == 7)
        #expect(await AsyncStream<Int>.of().first() == nil)
    }

    @Test("combineLatest waits for both sources and finishes after both")
    func combine() async {
        let pairs = await collect(combineLatest(AsyncStream.of(1), AsyncStream.of("a")).map { "\($0)\($1)" })
        #expect(pairs == ["1a"])
    }

    @Test("combineLatest emits again when either source changes")
    func combineChanges() async {
        let numbers = TestSubject(1)
        let letters = TestSubject("a")
        var iterator = combineLatest(numbers.stream(), letters.stream()).map { "\($0)\($1)" }.makeAsyncIterator()
        #expect(await iterator.next() == "1a")
        numbers.send(2)
        #expect(await iterator.next() == "2a")
        letters.send("b")
        #expect(await iterator.next() == "2b")
    }

    @Test("flatMapLatest forwards the newest inner stream")
    func flatMapLatest() async {
        let outer = TestSubject(1)
        var iterator = outer.stream().flatMapLatest { value in AsyncStream.of(value * 10, value * 10 + 1) }.makeAsyncIterator()
        #expect(await iterator.next() == 10)
        #expect(await iterator.next() == 11)
        outer.send(2)
        #expect(await iterator.next() == 20)
        #expect(await iterator.next() == 21)
    }

    @Test("flatMapLatest finishes once the outer and last inner streams finish")
    func flatMapLatestFinishes() async {
        let values = await collect(AsyncStream.of(1).flatMapLatest { AsyncStream.of($0, $0 + 1) })
        #expect(values == [1, 2])
    }

    @Test("Browse context starts as guest, skips repeats and follows language changes")
    func browseContext() async {
        let active = TestSubject<ChildProfile?>(nil)
        let language = TestSubject("en")
        let preferences = FakePreferences(language: language)
        var iterator = Browse.context(profiles: FakeProfiles(active: active), preferences: preferences).makeAsyncIterator()

        let initial = await iterator.next()
        #expect(initial == BrowseContext(child: nil, languageTag: "en"))
        #expect(initial?.childID == AppConfig.Profiles.guestID)

        await preferences.setContentLanguageTag("en")
        await preferences.setContentLanguageTag("kn")
        #expect(await iterator.next() == BrowseContext(child: nil, languageTag: "kn"))

        let child = Fixtures.child()
        active.send(child)
        #expect(await iterator.next() == BrowseContext(child: child, languageTag: "kn"))
    }
}
