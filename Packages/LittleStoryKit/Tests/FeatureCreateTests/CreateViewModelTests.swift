import Common
import CoreUI
import Domain
@testable import FeatureCreate
import Foundation
import Testing
import TestSupport

@MainActor
struct CreateViewModelTests {
    private let english = Locale(identifier: "en")
    private let library = FakeLibrary()

    private func makeViewModel(profiles: FakeProfiles = FakeProfiles(), languageTag: String = "en") -> (CreateViewModel, FakeGeneration) {
        let generation = FakeGeneration(library: library, outcome: .completes(Fixtures.story(id: "made")))
        let viewModel = CreateViewModel(
            profiles: profiles,
            preferences: FakePreferences(languageTag: languageTag),
            generation: generation,
            makeRequestID: { "request_1" },
        )
        return (viewModel, generation)
    }

    @Test("Starts with the content language and the active child as hero with their usual length")
    func defaults() async throws {
        var child = Fixtures.child(id: "c1", firstName: "Asha", age: 6)
        child.defaultDurationMinutes = 5
        let (viewModel, _) = makeViewModel(
            profiles: FakeProfiles([child, Fixtures.child(id: "c2", firstName: "Ravi")], activeID: "c1"),
            languageTag: "kn",
        )
        let task = Task { await viewModel.start() }
        defer { task.cancel() }
        try await waitUntil { viewModel.state.hero != nil }
        #expect(viewModel.state.languageTag == "kn")
        #expect(viewModel.state.heroID == "c1")
        #expect(viewModel.state.durationMinutes == 5)
        #expect(viewModel.state.hero?.label.resolved(for: english) == "Asha, 6 years")
        #expect(viewModel.state.placeholder.resolved(for: english).hasPrefix("Asha"))
        viewModel.onHeroSelected("c2")
        #expect(viewModel.state.hero?.name == "Ravi")
    }

    @Test("Suggestions are named after the hero, or after 'My little one' without one")
    func suggestions() {
        let (viewModel, _) = makeViewModel()
        let fills = viewModel.state.suggestions.map { $0.fill.resolved(for: english) }
        #expect(viewModel.state.suggestions.map(\.id) == AppConfig.Create.suggestionIDs)
        #expect(fills.first == "My little one helped a friend at school and played cricket in the evening.")
        #expect(fills.filter(\.isEmpty).isEmpty)
    }

    @Test("The prompt stops at the limit and the counter follows it")
    func promptLimit() {
        let (viewModel, _) = makeViewModel()
        viewModel.onPromptChange(String(repeating: "a", count: AppConfig.Create.promptMaxCharacters + 10))
        #expect(viewModel.state.prompt.count == AppConfig.Create.promptMaxCharacters)
        #expect(viewModel.state.counter.resolved(for: english) == "500/500")
    }

    @Test("An empty prompt shows the error and sends nothing; typing clears it")
    func emptyPrompt() async {
        let (viewModel, generation) = makeViewModel()
        viewModel.onPromptChange("   ")
        await viewModel.onCreate()
        #expect(viewModel.state.showEmptyError)
        #expect(generation.submitted.isEmpty)
        viewModel.onPromptChange("We flew a kite")
        #expect(!viewModel.state.showEmptyError)
    }

    @Test("Create sends the trimmed request with the chosen options and opens Generating")
    func create() async {
        let (viewModel, generation) = makeViewModel()
        viewModel.onPromptChange("  We flew a kite  ")
        viewModel.onThemeSelected("bedtime")
        viewModel.onToggleMoreOptions()
        #expect(viewModel.state.moreOptionsExpanded)
        viewModel.onMoodSelected("calm")
        viewModel.onDurationSelected(15)
        viewModel.onLanguageSelected("kn")
        await viewModel.onCreate()
        let request = generation.submitted.first
        #expect(request?.prompt == "We flew a kite")
        #expect(request?.heroChildID == AppConfig.Profiles.guestID)
        #expect(request?.themeID == "bedtime")
        #expect(request?.moodID == "calm")
        #expect(request?.durationMinutes == 15)
        #expect(request?.languageTag == "kn")
        #expect(await viewModel.effects.first() == .startGeneration(requestID: "request_1"))
    }
}

@MainActor
struct GeneratingViewModelTests {
    private let library = FakeLibrary()

    private func submitted(_ outcome: FakeGeneration.Outcome) async -> FakeGeneration {
        let generation = FakeGeneration(library: library, outcome: outcome)
        await generation.submit(StoryCreationRequest(
            requestID: "r1",
            prompt: "Kite",
            heroChildID: "c1",
            heroName: "Asha",
            themeID: AppConfig.Create.defaultTheme,
            moodID: AppConfig.Create.defaultMood,
            durationMinutes: AppConfig.Create.defaultDurationMinutes,
            languageTag: "en",
        ))
        return generation
    }

    @Test("A finished run saves the story and opens it")
    func completes() async {
        let generation = await submitted(.completes(Fixtures.story(id: "made")))
        let viewModel = GeneratingViewModel(requestID: "r1", generation: generation, clock: ImmediateClock())
        await viewModel.start()
        #expect(viewModel.state.heroName == "Asha")
        #expect(viewModel.state.percent == 90)
        #expect(viewModel.state.stage == .preparingNarration)
        #expect(await viewModel.effects.first() == .ready(storyID: "made"))
        #expect(library.stories.current["c1"]?.first?.id == "made")
    }

    @Test("Steps show done, active and pending around the current stage")
    func steps() {
        var state = GeneratingState()
        state.percent = 50
        #expect(state.steps.map(\.status) == [.done, .active, .pending])
        #expect(state.eyebrow == UIText(CreateStrings.generatingEyebrow))
        state.heroName = "Asha"
        #expect(state.eyebrow.resolved(for: Locale(identifier: "en")) == "A STORY FOR ASHA")
        #expect(state.percentLabel.resolved(for: Locale(identifier: "en")) == "50%")
    }

    @Test("An unknown request shows the paused panel")
    func unknownRequest() async {
        let generation = FakeGeneration(library: library, outcome: .completes(Fixtures.story()))
        let viewModel = GeneratingViewModel(requestID: "missing", generation: generation, clock: ImmediateClock())
        await viewModel.start()
        #expect(viewModel.state.paused)
    }

    @Test("Close pauses; Try again restarts from the restart percent")
    func closeAndRetry() async {
        let generation = await submitted(.fails(.writerFailed))
        let viewModel = GeneratingViewModel(requestID: "r1", generation: generation, clock: ImmediateClock())
        await viewModel.start()
        #expect(viewModel.state.paused)
        generation.outcome = .completes(Fixtures.story(id: "made"))
        await viewModel.onTryAgain()
        #expect(!viewModel.state.paused)
        #expect(await viewModel.effects.first() == .ready(storyID: "made"))
        viewModel.onClose()
        #expect(viewModel.state.paused)
    }
}

@MainActor
struct StoryReadyViewModelTests {
    @Test("Shows the created story with a peek from the second page and the hero's name")
    func loaded() async throws {
        let stores = StoryStores.fakes(catalog: FakeCatalog(stories: [], categories: []))
        let story = Fixtures.story(id: "made", title: "Asha and the Kite", pages: ["One.", "Two.", "Three."], origin: .generated)
        await stores.library.save(story, childID: "c1")
        let profiles = FakeProfiles([Fixtures.child(id: "c1", firstName: "Asha")], activeID: "c1")
        let viewModel = StoryReadyViewModel(storyID: "made", profiles: profiles, preferences: FakePreferences(), stores: stores)
        let task = Task { await viewModel.start() }
        defer { task.cancel() }
        try await waitUntil { viewModel.state != .loading }
        guard case let .loaded(content) = viewModel.state else {
            Issue.record("Expected a loaded story")
            return
        }
        #expect(content.peek == "Two.")
        #expect(content.madeFor?.resolved(for: Locale(identifier: "en")) == "Made for Asha")
        #expect(content.meta.resolved(for: Locale(identifier: "en")) == "English · 5 min · Ages 3–6")

        await viewModel.onFavourite()
        await viewModel.onDownload()
        try await waitUntil {
            if case let .loaded(updated) = viewModel.state {
                return updated.favourite && updated.downloaded
            }
            return false
        }
    }

    @Test("A missing story shows not found")
    func notFound() async throws {
        let stores = StoryStores.fakes(catalog: FakeCatalog(stories: [], categories: []))
        let viewModel = StoryReadyViewModel(storyID: "missing", profiles: FakeProfiles(), preferences: FakePreferences(), stores: stores)
        let task = Task { await viewModel.start() }
        defer { task.cancel() }
        try await waitUntil { viewModel.state != .loading }
        #expect(viewModel.state == .notFound)
    }
}

/// Polls on the main actor until `condition` holds; fails after about two seconds.
@MainActor
func waitUntil(_ condition: () -> Bool) async throws {
    for _ in 0 ..< 200 {
        if condition() {
            return
        }
        try await Task.sleep(for: .milliseconds(10))
    }
    Issue.record("Condition not met in time")
}
