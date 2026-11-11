import Common
import Domain

/// Small builders for domain values, so tests state only what they care about.
public enum Fixtures {
    public static func story(
        id: String = "story_1",
        title: String = "The Little Elephant",
        categoryID: String = "animals",
        tags: [String] = [],
        pages: [String] = ["Page one.", "Page two."],
        language: String = "en",
        origin: StoryOrigin = .catalogue,
        durationMinutes: Int = 5,
        addedEpochDay: Int = 20000,
        synopsis: String = "A gentle story.",
    ) -> Story {
        Story(
            id: id,
            title: title,
            synopsis: synopsis,
            categoryID: categoryID,
            tags: tags,
            ages: 3 ... 6,
            durationMinutes: durationMinutes,
            lesson: "Kindness",
            addedEpochDay: addedEpochDay,
            art: StoryArtSpec(paletteID: "adventure", motifID: "cricket"),
            pages: pages.enumerated().map { StoryPage(index: $0.offset, text: $0.element) },
            resolvedLanguage: language,
            origin: origin,
        )
    }

    public static func category(id: String, name: String? = nil) -> StoryCategory {
        StoryCategory(id: id, name: name ?? id.capitalized, summary: "About \(id).", storyCount: 0)
    }

    public static func child(id: String = "child_1", firstName: String = "Asha", age: Int = 6) -> ChildProfile {
        ChildProfile(
            id: id,
            firstName: firstName,
            age: age,
            avatar: AvatarID(0),
            interestIDs: ["animals"],
            languageTag: "en",
            defaultDurationMinutes: AppConfig.Setup.defaultDurationMinutes,
        )
    }

    public static func draft(firstName: String = "Aarav") -> ChildProfileDraft {
        ChildProfileDraft(
            firstName: firstName,
            age: AppConfig.Setup.defaultAge,
            avatar: AvatarID(0),
            interestIDs: ["animals"],
            languageTag: "en",
            defaultDurationMinutes: AppConfig.Setup.defaultDurationMinutes,
        )
    }
}
