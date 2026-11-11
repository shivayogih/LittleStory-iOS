import Common
import Foundation

public struct StoryCreationRequest: Sendable, Hashable, Identifiable {
    public let requestID: String
    public let prompt: String
    public let heroChildID: String
    /// First name of the hero; empty when Setup was skipped (the story then uses a neutral hero).
    public let heroName: String
    public let heroAge: Int
    public let themeID: String
    public let moodID: String
    public let durationMinutes: Int
    public let languageTag: String

    public var id: String { requestID }

    public init(
        requestID: String,
        prompt: String,
        heroChildID: String,
        heroName: String = "",
        heroAge: Int = AppConfig.Setup.defaultAge,
        themeID: String,
        moodID: String,
        durationMinutes: Int,
        languageTag: String,
    ) {
        self.requestID = requestID
        self.prompt = prompt
        self.heroChildID = heroChildID
        self.heroName = heroName
        self.heroAge = heroAge
        self.themeID = themeID
        self.moodID = moodID
        self.durationMinutes = durationMinutes
        self.languageTag = languageTag
    }
}

public enum PromptError: Sendable, Hashable {
    case empty
    case tooLong
}

public enum PromptValidator {
    /// Nil when the prompt can be sent; the form also stops typing at the limit.
    public static func validate(_ prompt: String) -> PromptError? {
        if prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return .empty
        }
        if prompt.count > AppConfig.Create.promptMaxCharacters {
            return .tooLong
        }
        return nil
    }
}

public enum GenerationStage: Int, Sendable, Hashable, CaseIterable {
    case imagining
    case writing
    case preparingNarration

    /// The stage shown for `percent`, using `AppConfig.Generation.stageThresholdsPercent`.
    public init(percent: Int) {
        let passed = AppConfig.Generation.stageThresholdsPercent.count(where: { percent >= $0 })
        self = GenerationStage(rawValue: min(passed, GenerationStage.allCases.count - 1)) ?? .preparingNarration
    }
}

public enum GenerationError: Sendable, Hashable {
    /// The user closed the Generating screen; Try again resumes.
    case interrupted
    /// The request is not known (for example the app was closed); the screen offers "Back to your idea".
    case unknownRequest
    /// A real writer refused the idea or the story (safety rules); nothing is kept.
    case rejected
    /// A real writer failed or timed out.
    case writerFailed
}

/// Progress of one generation request; deterministic in the MVP.
public enum GenerationState: Sendable, Hashable {
    case idle
    case inProgress(requestID: String, stage: GenerationStage, percent: Int)
    case paused(requestID: String, percent: Int)
    case completed(requestID: String, storyID: String)
    case failed(requestID: String, error: GenerationError)
}
