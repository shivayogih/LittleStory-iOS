import Foundation

/// Where a story came from: bundled mock content or the simulated generator.
public enum StoryOrigin: String, Sendable, Hashable, Codable {
    case catalogue
    case generated
}

/// Cover art chosen by stable ids; the UI maps them to tokens. Unknown ids use a placeholder.
public struct StoryArtSpec: Sendable, Hashable, Codable {
    public let paletteID: String
    public let motifID: String

    public init(paletteID: String, motifID: String) {
        self.paletteID = paletteID
        self.motifID = motifID
    }
}

public struct StoryPage: Sendable, Hashable, Codable, Identifiable {
    public let index: Int
    public let text: String

    public var id: Int { index }

    public init(index: Int, text: String) {
        self.index = index
        self.text = text
    }
}

/// A story already resolved for one language. A missing translation falls back to English per field;
/// `resolvedLanguage` records the language the text is actually in.
public struct Story: Sendable, Hashable, Identifiable {
    public let id: String
    public let title: String
    public let synopsis: String
    public let categoryID: String
    /// Extra theme ids (for example `animals`) so a story can appear under several filters.
    public let tags: [String]
    public let ages: ClosedRange<Int>
    public let durationMinutes: Int
    public let lesson: String
    /// Days since 1970-01-01 when the story joined the catalogue; drives the "Newest" sort.
    public let addedEpochDay: Int
    public let art: StoryArtSpec
    public let pages: [StoryPage]
    public let resolvedLanguage: String
    public let origin: StoryOrigin

    public init(
        id: String,
        title: String,
        synopsis: String,
        categoryID: String,
        tags: [String] = [],
        ages: ClosedRange<Int>,
        durationMinutes: Int,
        lesson: String,
        addedEpochDay: Int,
        art: StoryArtSpec,
        pages: [StoryPage],
        resolvedLanguage: String,
        origin: StoryOrigin = .catalogue,
    ) {
        self.id = id
        self.title = title
        self.synopsis = synopsis
        self.categoryID = categoryID
        self.tags = tags
        self.ages = ages
        self.durationMinutes = durationMinutes
        self.lesson = lesson
        self.addedEpochDay = addedEpochDay
        self.art = art
        self.pages = pages
        self.resolvedLanguage = resolvedLanguage
        self.origin = origin
    }

    /// True when `categoryOrTagID` is this story's category or one of its tags.
    public func belongs(to categoryOrTagID: String) -> Bool {
        categoryID == categoryOrTagID || tags.contains(categoryOrTagID)
    }
}

/// A browsable collection. `name` and `summary` are content resolved for the language;
/// `storyCount` is computed from the catalogue.
public struct StoryCategory: Sendable, Hashable, Identifiable {
    public let id: String
    public let name: String
    public let summary: String
    public let storyCount: Int

    public init(id: String, name: String, summary: String, storyCount: Int) {
        self.id = id
        self.name = name
        self.summary = summary
        self.storyCount = storyCount
    }
}
