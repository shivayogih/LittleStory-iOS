@testable import DataLayer
import Domain
import Testing

@Suite("Notifications and plans")
struct SettingsContentTests {
    @Test("Notifications map Android enum names and resolve Kannada text")
    func notifications() async throws {
        let repository = try NotificationsRepositoryImpl(source: BundleMockContentSource(), store: TestStores.store())
        let english = try #require(await repository.notifications(languageTag: "en").first())
        #expect(english.map(\.section) == [.today, .today, .earlier])
        #expect(english.map(\.kind) == [.storyReady, .reminder, .newStories])
        #expect(english.allSatisfy { !$0.read })
        let kannada = try #require(await repository.notifications(languageTag: "kn").first())
        #expect(kannada.map(\.id) == english.map(\.id))
        #expect(zip(kannada, english).allSatisfy { $0.title != $1.title })
    }

    @Test("Marking read updates an open stream and survives a new subscription")
    func markRead() async throws {
        let repository = try NotificationsRepositoryImpl(source: BundleMockContentSource(), store: TestStores.store())
        var iterator = repository.notifications(languageTag: "en").makeAsyncIterator()
        let initial = try #require(await iterator.next())
        let first = try #require(initial.first)
        await repository.markRead(id: first.id)
        let updated = try #require(await iterator.next())
        #expect(updated.filter(\.read).map(\.id) == [first.id])
        await repository.markAllRead()
        let all = try #require(await repository.notifications(languageTag: "kn").first())
        #expect(all.allSatisfy { $0.read })
    }

    @Test("Unknown section and kind names use the defaults")
    func unknownNames() async throws {
        let source = FakeContentSource(files: [
            "notifications_en.json": #"{"notifications": [{"id": "n", "title": "T", "section": "Later", "kind": "Promo"}]}"#,
        ])
        let repository = try NotificationsRepositoryImpl(source: source, store: TestStores.store())
        let item = try #require(await repository.notifications(languageTag: "en").first()?.first)
        #expect(item.section == .earlier)
        #expect(item.kind == .newStories)
    }

    @Test("Plans come from plans.json")
    func plans() async throws {
        let plans = try #require(await SubscriptionRepositoryImpl(source: BundleMockContentSource()).plans().first())
        #expect(plans.map(\.id) == ["free", "monthly", "yearly", "family"])
        #expect(plans.filter(\.bestValue).map(\.id) == ["yearly"])
        #expect(plans.first { $0.id == "family" }?.maxChildren == 5)
        #expect(plans.allSatisfy { $0.currencyCode == "INR" })
    }
}
