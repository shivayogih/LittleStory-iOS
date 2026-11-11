/// Writes the text of a story. The MVP uses a template writer in the data layer (simulated AI);
/// a future on-device or server writer implements the same contract. Implementations must keep
/// the child's name away from any provider and must never log the prompt.
public protocol StoryWriter: Sendable {
    func write(_ request: StoryCreationRequest, storyID: String) async -> StoryWriterResult
}

/// Text of a written story in `languageTag`; pages are plain paragraphs with the hero's name filled in.
public struct StoryDraft: Sendable, Hashable {
    public let title: String
    public let synopsis: String
    public let lesson: String
    public let pages: [String]
    public let languageTag: String
    public let paletteID: String?

    public init(title: String, synopsis: String, lesson: String, pages: [String], languageTag: String, paletteID: String? = nil) {
        self.title = title
        self.synopsis = synopsis
        self.lesson = lesson
        self.pages = pages
        self.languageTag = languageTag
        self.paletteID = paletteID
    }
}

public enum StoryWriterResult: Sendable, Hashable {
    case written(StoryDraft)
    /// The idea or the story failed the safety rules; nothing is kept.
    case rejected
    /// The writer is not configured on this build or device; the simulation runs instead.
    case unavailable
    case failed
}
