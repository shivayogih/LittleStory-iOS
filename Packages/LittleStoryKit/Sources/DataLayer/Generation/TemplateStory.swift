import Common
import Domain

/// Builds a created story from `Mock/generated_{tag}.json`, filling `{child}` with the hero's name.
struct TemplateStory {
    private static let childToken = "{child}"

    let source: any MockContentSource

    func story(for request: StoryCreationRequest) -> Story {
        let language = ContentLanguage.resolve(request.languageTag)
        let fallback = ContentLanguage.fallback
        let base = source.decode(GeneratedTemplate.self, from: MockFile.generated(fallback))
        let local = language == fallback ? nil : source.decode(GeneratedTemplate.self, from: MockFile.generated(language))
        let translated = local?.title?.nonBlank != nil
        let chosen = translated ? local : base
        let trimmedName = request.heroName.trimmingCharacters(in: .whitespacesAndNewlines)
        let hero = trimmedName.isEmpty ? chosen?.defaultHero ?? "" : trimmedName
        func fill(_ text: String?) -> String {
            (text ?? "").replacingOccurrences(of: Self.childToken, with: hero)
        }
        return Story(
            id: GenerationRepositoryImpl.generatedStoryID(requestID: request.requestID),
            title: fill(chosen?.title),
            synopsis: fill(chosen?.synopsis),
            categoryID: AppConfig.Generation.themeCategoryIDs[request.themeID] ?? request.themeID,
            ages: Self.ages(around: request.heroAge),
            durationMinutes: request.durationMinutes,
            lesson: fill(chosen?.lesson),
            addedEpochDay: 0,
            art: StoryArtSpec(paletteID: AppConfig.Generation.coverPaletteID, motifID: AppConfig.Generation.coverMotifID),
            pages: (chosen?.pages ?? []).enumerated().map { StoryPage(index: $0.offset, text: fill($0.element)) },
            resolvedLanguage: translated ? language : fallback,
            origin: .generated,
        )
    }

    /// A story a writer produced, with the structure and cover of the simulated one.
    func story(for request: StoryCreationRequest, draft: StoryDraft) -> Story {
        let base = story(for: request)
        return Story(
            id: base.id,
            title: draft.title,
            synopsis: draft.synopsis,
            categoryID: base.categoryID,
            ages: base.ages,
            durationMinutes: base.durationMinutes,
            lesson: draft.lesson,
            addedEpochDay: base.addedEpochDay,
            art: StoryArtSpec(
                paletteID: draft.paletteID ?? AppConfig.Generation.coverPaletteID,
                motifID: AppConfig.Generation.coverMotifID,
            ),
            pages: draft.pages.enumerated().map { StoryPage(index: $0.offset, text: $0.element) },
            resolvedLanguage: draft.languageTag,
            origin: .generated,
        )
    }

    /// The age range printed on a created story, around the hero's age and inside the Setup range.
    static func ages(around age: Int) -> ClosedRange<Int> {
        let range = AppConfig.Setup.ageRange
        let lower = (age - AppConfig.Generation.heroAgesBelow).clamped(to: range)
        let upper = (age + AppConfig.Generation.heroAgesAbove).clamped(to: range)
        return lower ... max(lower, upper)
    }
}

private extension Int {
    func clamped(to range: ClosedRange<Int>) -> Int {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}
