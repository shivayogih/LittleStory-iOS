import Common
@testable import DataLayer
import Domain
import Foundation
import Testing
import TestSupport

private struct FakeWriter: StoryWriter {
    let result: StoryWriterResult

    func write(_: StoryCreationRequest, storyID _: String) async -> StoryWriterResult {
        result
    }
}

@Suite("Simulated generation")
struct GenerationTests {
    private func request(name: String = "Asha", age: Int = 6, theme: String = "indian_folklore", language: String = "en")
        -> StoryCreationRequest
    {
        StoryCreationRequest(
            requestID: "r1",
            prompt: "A cricket bat that glows",
            heroChildID: "child_1",
            heroName: name,
            heroAge: age,
            themeID: theme,
            moodID: AppConfig.Create.defaultMood,
            durationMinutes: AppConfig.Create.defaultDurationMinutes,
            languageTag: language,
        )
    }

    private func isDone(_ state: GenerationState) -> Bool {
        switch state {
        case .completed, .failed:
            true
        case .idle, .inProgress, .paused:
            false
        }
    }

    @Test("An unknown request fails at once")
    func unknownRequest() async throws {
        let library = try LibraryRepositoryImpl(store: TestStores.store())
        let repository = GenerationRepositoryImpl(source: BundleMockContentSource(), library: library, clock: ImmediateClock())
        let states = await repository.generate(requestID: "missing", startPercent: 0).values(until: isDone)
        #expect(states == [.failed(requestID: "missing", error: .unknownRequest)])
    }

    @Test("Progress runs to 100, then the filled template is saved for the hero")
    func simulatedStory() async throws {
        let library = try LibraryRepositoryImpl(store: TestStores.store())
        let repository = GenerationRepositoryImpl(source: BundleMockContentSource(), library: library, clock: ImmediateClock())
        await repository.submit(request())
        #expect(await repository.request(id: "r1") == request())

        let states = await repository.generate(requestID: "r1", startPercent: 0).values(until: isDone)
        let storyID = GenerationRepositoryImpl.generatedStoryID(requestID: "r1")
        #expect(states.last == .completed(requestID: "r1", storyID: storyID))
        #expect(states.dropLast().last?.percent == GenerationProgress.completePercent)

        let story = try #require(await library.story(id: storyID).first() ?? nil)
        #expect(story.title.contains("Asha"))
        #expect(story.pages.allSatisfy { !$0.text.contains("{child}") })
        #expect(story.origin == .generated)
        #expect(story.categoryID == "indian_tales")
        #expect(story.ages == 5 ... 9)
        #expect(story.resolvedLanguage == "en")
        #expect(await library.created(childID: "child_1").first()?.map(\.id) == [storyID])
    }

    @Test("Kannada uses the Kannada template; a skipped name uses its default hero")
    func kannadaDefaultHero() async throws {
        let library = try LibraryRepositoryImpl(store: TestStores.store())
        let repository = GenerationRepositoryImpl(source: BundleMockContentSource(), library: library, clock: ImmediateClock())
        await repository.submit(request(name: "  ", theme: "space", language: "kn"))
        _ = await repository.generate(requestID: "r1", startPercent: AppConfig.Generation.restartPercent).values(until: isDone)
        let story = try #require(await library.story(id: GenerationRepositoryImpl.generatedStoryID(requestID: "r1")).first() ?? nil)
        #expect(story.resolvedLanguage == "kn")
        #expect(story.title.contains("ಪುಟ್ಟ ತಾರೆ"))
        #expect(story.categoryID == "space")
    }

    @Test("The printed age range stays inside the Setup range")
    func ageRange() {
        #expect(TemplateStory.ages(around: 3) == 3 ... 6)
        #expect(TemplateStory.ages(around: 12) == 11 ... 12)
    }

    @Test("A writer's story is saved; progress waits at the writer percent")
    func writtenStory() async throws {
        let draft = StoryDraft(title: "Written", synopsis: "S", lesson: "L", pages: ["P1", "P2"], languageTag: "en", paletteID: "bedtime")
        let library = try LibraryRepositoryImpl(store: TestStores.store())
        let repository = GenerationRepositoryImpl(
            source: BundleMockContentSource(),
            library: library,
            writer: FakeWriter(result: .written(draft)),
            clock: ImmediateClock(),
        )
        await repository.submit(request())
        let states = await repository.generate(requestID: "r1", startPercent: 0).values(until: isDone)
        #expect(states.dropLast().allSatisfy { $0.percent <= AppConfig.Generation.writerWaitPercent })
        let story = try #require(await library.story(id: GenerationRepositoryImpl.generatedStoryID(requestID: "r1")).first() ?? nil)
        #expect(story.title == "Written")
        #expect(story.pages.map(\.text) == ["P1", "P2"])
        #expect(story.art.paletteID == "bedtime")
    }

    @Test("A rejected or failed writer saves nothing; an unavailable one falls back to the template")
    func writerOutcomes() async throws {
        let outcomes: [(StoryWriterResult, GenerationState)] = [
            (.rejected, .failed(requestID: "r1", error: .rejected)),
            (.failed, .failed(requestID: "r1", error: .writerFailed)),
            (.unavailable, .completed(requestID: "r1", storyID: GenerationRepositoryImpl.generatedStoryID(requestID: "r1"))),
        ]
        for (result, expected) in outcomes {
            let library = try LibraryRepositoryImpl(store: TestStores.store())
            let repository = GenerationRepositoryImpl(
                source: BundleMockContentSource(),
                library: library,
                writer: FakeWriter(result: result),
                clock: ImmediateClock(),
            )
            await repository.submit(request())
            let states = await repository.generate(requestID: "r1", startPercent: 0).values(until: isDone)
            #expect(states.last == expected)
            let saved = await library.created(childID: "child_1").first() ?? []
            #expect(saved.count == (result == .unavailable ? 1 : 0))
        }
    }
}
