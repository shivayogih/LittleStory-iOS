import Common
import Domain

/// Serves the bundled mock catalogue. English is the base: it defines the story ids and every
/// structural field. A translation only overrides text, field by field, so a missing or broken
/// translation falls back to English instead of failing (LLD §4.1).
public final class CatalogRepositoryImpl: CatalogRepository {
    private let cache: CatalogueCache

    public init(source: any MockContentSource) {
        cache = CatalogueCache(source: source)
    }

    public func categories(languageTag: String) -> AsyncStream<[StoryCategory]> {
        catalogue(languageTag).map(\.categories)
    }

    public func stories(languageTag: String) -> AsyncStream<[Story]> {
        catalogue(languageTag).map(\.stories)
    }

    public func story(id: String, languageTag: String) -> AsyncStream<Story?> {
        catalogue(languageTag).map { catalogue in catalogue.stories.first { $0.id == id } }
    }

    /// Bundled content never changes while the app runs, so each stream emits once and finishes.
    private func catalogue(_ languageTag: String) -> AsyncStream<ResolvedCatalogue> {
        let cache = cache
        let language = ContentLanguage.resolve(languageTag)
        return AsyncStream { continuation in
            let task = Task {
                await continuation.yield(cache.catalogue(language: language))
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}

struct ResolvedCatalogue: Sendable {
    let stories: [Story]
    let categories: [StoryCategory]
}

/// One parse per language: a screen opens several catalogue streams at once on a cold start, and
/// the first parses while the others await the same task.
actor CatalogueCache {
    private let source: any MockContentSource
    private var loads: [String: Task<ResolvedCatalogue, Never>] = [:]

    init(source: any MockContentSource) {
        self.source = source
    }

    func catalogue(language: String) async -> ResolvedCatalogue {
        if let load = loads[language] {
            return await load.value
        }
        let source = source
        let load = Task { CatalogueResolver(source: source).resolve(language: language) }
        loads[language] = load
        return await load.value
    }
}

struct CatalogueResolver {
    let source: any MockContentSource

    func resolve(language: String) -> ResolvedCatalogue {
        let fallback = ContentLanguage.fallback
        let base = source.decode(StoriesFile.self, from: MockFile.stories(fallback))?.stories ?? []
        let translated = language == fallback ? [:] : byID(source.decode(StoriesFile.self, from: MockFile.stories(language))?.stories)
        let stories = base.map { resolveStory($0, local: translated[$0.id], language: language) }

        let baseCategories = source.decode(CategoriesFile.self, from: MockFile.categories(fallback))?.categories ?? []
        let translatedCategories = language == fallback
            ? [:]
            : byID(source.decode(CategoriesFile.self, from: MockFile.categories(language))?.categories)
        let categories = baseCategories.map { category in
            let local = translatedCategories[category.id]
            return StoryCategory(
                id: category.id,
                name: local?.name?.nonBlank ?? category.name ?? "",
                summary: local?.description?.nonBlank ?? category.description ?? "",
                storyCount: stories.count { $0.belongs(to: category.id) },
            )
        }
        return ResolvedCatalogue(stories: stories, categories: categories)
    }

    private func resolveStory(_ base: StoryEntry, local: StoryEntry?, language: String) -> Story {
        let translatedTitle = local?.title?.nonBlank
        let localPages = local?.pages ?? []
        let pages = localPages.isEmpty ? base.pages ?? [] : localPages
        let ageMin = base.ageMin ?? AppConfig.Setup.ageRange.lowerBound
        return Story(
            id: base.id,
            title: translatedTitle ?? base.title ?? "",
            synopsis: local?.synopsis?.nonBlank ?? base.synopsis ?? "",
            categoryID: base.categoryId ?? "",
            tags: base.tags ?? [],
            ages: ageMin ... max(ageMin, base.ageMax ?? AppConfig.Setup.ageRange.upperBound),
            durationMinutes: base.durationMinutes ?? 0,
            lesson: local?.lesson?.nonBlank ?? base.lesson ?? "",
            addedEpochDay: base.addedEpochDay ?? 0,
            art: StoryArtSpec(paletteID: base.art?.paletteId ?? "", motifID: base.art?.motifId ?? ""),
            pages: pages.enumerated().map { StoryPage(index: $0.offset, text: $0.element) },
            resolvedLanguage: translatedTitle == nil ? ContentLanguage.fallback : language,
        )
    }
}

/// Last entry wins for a duplicated id, like Kotlin's `associateBy`.
func byID<Entry: Identifiable>(_ entries: [Entry]?) -> [Entry.ID: Entry] {
    Dictionary((entries ?? []).map { ($0.id, $0) }, uniquingKeysWith: { _, last in last })
}
