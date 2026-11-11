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
    ) -> Story {
        Story(
            id: id,
            title: title,
            synopsis: "A gentle story.",
            categoryID: categoryID,
            tags: tags,
            ages: 3 ... 6,
            durationMinutes: 5,
            lesson: "Kindness",
            addedEpochDay: 20000,
            art: StoryArtSpec(paletteID: "adventure", motifID: "cricket"),
            pages: pages.enumerated().map { StoryPage(index: $0.offset, text: $0.element) },
            resolvedLanguage: language,
            origin: origin,
        )
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
