import Common
import CoreUI
import Domain
import Foundation
import Observation

/// A child who can be the story hero.
public struct HeroOption: Sendable, Hashable, Identifiable {
    public let id: String
    public let name: String
    public let age: Int
    public let avatarTone: Int

    public var label: UIText { CreateStrings.heroNameAge(.text(name), .number(age)) }
}

/// A prompt starter: tapping it puts `fill` (named after the hero) in the prompt.
public struct PromptSuggestion: Sendable, Hashable, Identifiable {
    public let id: String
    public let label: UIText
    public let fill: UIText
}

public struct CreateState: Sendable, Hashable {
    public var prompt = ""
    public var heroes: [HeroOption] = []
    public var heroID: String?
    public var themeID = AppConfig.Create.defaultTheme
    public var moodID = AppConfig.Create.defaultMood
    public var durationMinutes = AppConfig.Create.defaultDurationMinutes
    public var languageTag = SupportedLanguages.fallback.tag
    public var moreOptionsExpanded = false
    public var showEmptyError = false
    public var submitting = false

    public var hero: HeroOption? { heroes.first { $0.id == heroID } }
    public var counter: UIText { CreateStrings.counter(.number(prompt.count), .number(AppConfig.Create.promptMaxCharacters)) }

    public var placeholder: UIText {
        hero.map { CreateStrings.promptPlaceholderNamed(.text($0.name)) } ?? UIText(CreateStrings.promptPlaceholder)
    }

    public var suggestions: [PromptSuggestion] {
        AppConfig.Create.suggestionIDs.map { id in
            let fill = CreateStrings.fill(id)
            return PromptSuggestion(
                id: id,
                label: UIText(CreateStrings.suggestion(id)),
                fill: hero.map { fill(.text($0.name)) } ?? fill(.localized(CreateStrings.heroFallback)),
            )
        }
    }
}

public enum CreateEffect: Sendable, Equatable {
    case startGeneration(requestID: String)
}

/// Create (SCR-07): the parent describes the day; nothing typed here leaves the device.
@MainActor
@Observable
public final class CreateViewModel {
    public private(set) var state = CreateState()
    @ObservationIgnored public let effects: AsyncStream<CreateEffect>
    @ObservationIgnored private let effectSink: AsyncStream<CreateEffect>.Continuation
    @ObservationIgnored private let profiles: any ProfilesRepository
    @ObservationIgnored private let preferences: any PreferencesRepository
    @ObservationIgnored private let generation: any GenerationRepository
    @ObservationIgnored private let makeRequestID: @Sendable () -> String

    public init(
        profiles: any ProfilesRepository,
        preferences: any PreferencesRepository,
        generation: any GenerationRepository,
        makeRequestID: @escaping @Sendable () -> String = { UUID().uuidString },
    ) {
        self.profiles = profiles
        self.preferences = preferences
        self.generation = generation
        self.makeRequestID = makeRequestID
        let (stream, sink) = AsyncStream<CreateEffect>.makeStream()
        effects = stream
        effectSink = sink
    }

    /// Runs while the screen is shown (`.task`): content language, then the children as heroes.
    public func start() async {
        let tag = await preferences.contentLanguageTag().first()
        state.languageTag = SupportedLanguages.language(forTag: tag).tag
        for await (all, active) in combineLatest(profiles.profiles(), profiles.activeProfile()) {
            onProfiles(all, active: active)
        }
    }

    private func onProfiles(_ all: [ChildProfile], active: ChildProfile?) {
        let heroes = all.map { HeroOption(id: $0.id, name: $0.firstName, age: $0.age, avatarTone: $0.avatar.index) }
        let kept = state.heroID.flatMap { id in heroes.contains { $0.id == id } ? id : nil }
        // The active child's usual length applies only until the parent picks a hero.
        if state.heroID == nil, let minutes = active?.defaultDurationMinutes, AppConfig.Create.durationOptionsMinutes.contains(minutes) {
            state.durationMinutes = minutes
        }
        state.heroes = heroes
        state.heroID = kept ?? active?.id ?? heroes.first?.id
    }

    public func onPromptChange(_ value: String) {
        state.prompt = String(value.prefix(AppConfig.Create.promptMaxCharacters))
        state.showEmptyError = false
    }

    public func onHeroSelected(_ id: String) {
        state.heroID = id
    }

    public func onThemeSelected(_ id: String) {
        state.themeID = id
    }

    public func onMoodSelected(_ id: String) {
        state.moodID = id
    }

    public func onDurationSelected(_ minutes: Int) {
        state.durationMinutes = minutes
    }

    public func onLanguageSelected(_ tag: String) {
        state.languageTag = tag
    }

    public func onToggleMoreOptions() {
        state.moreOptionsExpanded.toggle()
    }

    public func onCreate() async {
        guard !state.submitting else {
            return
        }
        if PromptValidator.validate(state.prompt) == .empty {
            state.showEmptyError = true
            return
        }
        state.submitting = true
        defer { state.submitting = false }
        let hero = state.hero
        let request = StoryCreationRequest(
            requestID: makeRequestID(),
            prompt: state.prompt.trimmingCharacters(in: .whitespacesAndNewlines),
            heroChildID: hero?.id ?? AppConfig.Profiles.guestID,
            heroName: hero?.name ?? "",
            heroAge: hero?.age ?? AppConfig.Setup.defaultAge,
            themeID: state.themeID,
            moodID: state.moodID,
            durationMinutes: state.durationMinutes,
            languageTag: state.languageTag,
        )
        await generation.submit(request)
        effectSink.yield(.startGeneration(requestID: request.requestID))
    }
}
