import Domain

/// What a story card or row needs, resolved from the catalogue. `categoryName` and `title` are
/// already in the content language; labels around them come from string catalogs.
public struct StoryItem: Sendable, Hashable, Identifiable {
    public let id: String
    public let title: String
    public let categoryName: String
    public let durationMinutes: Int
    public let ages: ClosedRange<Int>
    public let paletteID: String
    public let motifID: String
    public let favourite: Bool
    public let downloaded: Bool

    public init(
        id: String,
        title: String,
        categoryName: String,
        durationMinutes: Int,
        ages: ClosedRange<Int>,
        paletteID: String,
        motifID: String,
        favourite: Bool,
        downloaded: Bool = false,
    ) {
        self.id = id
        self.title = title
        self.categoryName = categoryName
        self.durationMinutes = durationMinutes
        self.ages = ages
        self.paletteID = paletteID
        self.motifID = motifID
        self.favourite = favourite
        self.downloaded = downloaded
    }
}

public extension Story {
    func item(categoryNames: [String: String], favouriteIDs: Set<String>, downloadedIDs: Set<String> = []) -> StoryItem {
        StoryItem(
            id: id,
            title: title,
            categoryName: categoryNames[categoryID] ?? "",
            durationMinutes: durationMinutes,
            ages: ages,
            paletteID: art.paletteID,
            motifID: art.motifID,
            favourite: favouriteIDs.contains(id),
            downloaded: downloadedIDs.contains(id),
        )
    }
}

public extension StoryItem {
    /// "Friendship · 6 min" under a card.
    var cardMeta: UIText {
        CoreUIStrings.storyCardMeta(.text(categoryName), .number(durationMinutes))
    }

    /// "Ages 4–7 · 6 min" on a list row.
    var listMeta: UIText {
        CoreUIStrings.storyListMeta(.number(ages.lowerBound), .number(ages.upperBound), .number(durationMinutes))
    }

    /// Spoken label of the favourite button, naming the story.
    var favouriteLabel: UIText {
        favourite ? CoreUIStrings.storyFavouriteRemove(.text(title)) : CoreUIStrings.storyFavouriteAdd(.text(title))
    }
}
