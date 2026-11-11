import Common
@testable import DataLayer
import Domain
import Testing

@Suite("Catalogue")
struct CatalogTests {
    private let bundled = CatalogRepositoryImpl(source: BundleMockContentSource())

    @Test("English catalogue loads every bundled story and counts stories per category")
    func englishCatalogue() async throws {
        let stories = try #require(await bundled.stories(languageTag: "en").first())
        let categories = try #require(await bundled.categories(languageTag: "en").first())
        #expect(!stories.isEmpty)
        #expect(stories.allSatisfy { $0.resolvedLanguage == "en" && !$0.pages.isEmpty })
        for category in categories {
            #expect(category.storyCount == stories.count { $0.belongs(to: category.id) })
        }
        #expect(stories.contains { $0.id == AppConfig.Discover.featuredStoryID })
    }

    @Test("Kannada catalogue keeps English structure; an untranslated story stays in English")
    func kannadaCatalogue() async throws {
        let english = try #require(await bundled.stories(languageTag: "en").first())
        let kannada = try #require(await bundled.stories(languageTag: "kn-IN").first())
        #expect(kannada.map(\.id) == english.map(\.id))
        for (en, kn) in zip(english, kannada) {
            #expect(kn.categoryID == en.categoryID)
            #expect(kn.ages == en.ages)
            #expect(kn.art == en.art)
            if kn.resolvedLanguage == "kn" {
                #expect(kn.title != en.title)
            } else {
                #expect(kn.title == en.title)
                #expect(kn.pages == en.pages)
            }
        }
        // The shared mock files have no Kannada text for this story yet (same as Android).
        #expect(kannada.first { $0.id == Self.untranslatedStoryID }?.resolvedLanguage == "en")
        #expect(kannada.count { $0.resolvedLanguage == "kn" } == english.count - 1)
        let categories = try #require(await bundled.categories(languageTag: "kn").first())
        let englishCategories = try #require(await bundled.categories(languageTag: "en").first())
        #expect(zip(categories, englishCategories).allSatisfy { $0.name != $1.name })
    }

    private static let untranslatedStoryID = "story_lanterns_jaipur"

    @Test("An unsupported language shows English")
    func unsupportedLanguage() async throws {
        let story = try #require(await bundled.story(id: AppConfig.Discover.featuredStoryID, languageTag: "fr").first() ?? nil)
        #expect(story.resolvedLanguage == "en")
    }

    @Test("A missing story id yields nil")
    func missingStory() async {
        let story = await bundled.story(id: "nope", languageTag: "en").first()
        #expect(story == .some(nil))
    }

    @Test("Blank or missing translated fields fall back to English field by field")
    func fieldFallback() async throws {
        let source = FakeContentSource(files: [
            "stories_en.json": """
            {"stories": [
              {"id": "a", "title": "Alpha", "synopsis": "Syn", "lesson": "Les", "pages": ["One", "Two"],
               "categoryId": "animals", "ageMin": 3, "ageMax": 6, "durationMinutes": 5, "addedEpochDay": 1,
               "art": {"paletteId": "p", "motifId": "m"}},
              {"id": "b", "title": "Beta", "pages": ["Only"]}
            ]}
            """,
            "stories_kn.json": """
            {"stories": [{"id": "a", "title": "ಅಲ್ಫಾ", "synopsis": " ", "pages": []}, {"id": "b", "title": ""}]}
            """,
        ])
        let stories = try #require(await CatalogRepositoryImpl(source: source).stories(languageTag: "kn").first())
        #expect(stories.count == 2)
        #expect(stories[0].title == "ಅಲ್ಫಾ")
        #expect(stories[0].synopsis == "Syn")
        #expect(stories[0].lesson == "Les")
        #expect(stories[0].pages.map(\.text) == ["One", "Two"])
        #expect(stories[0].resolvedLanguage == "kn")
        #expect(stories[1].title == "Beta")
        #expect(stories[1].resolvedLanguage == "en")
    }

    @Test("A malformed translation file falls back to English instead of failing")
    func malformedTranslation() async throws {
        let source = FakeContentSource(files: [
            "stories_en.json": #"{"stories": [{"id": "a", "title": "Alpha"}]}"#,
            "stories_kn.json": "{ not json",
            "categories_en.json": #"{"categories": [{"id": "animals", "name": "Animals", "description": "D"}]}"#,
        ])
        let repository = CatalogRepositoryImpl(source: source)
        let stories = try #require(await repository.stories(languageTag: "kn").first())
        #expect(stories.map(\.title) == ["Alpha"])
        let categories = try #require(await repository.categories(languageTag: "kn").first())
        #expect(categories.map(\.name) == ["Animals"])
    }

    @Test("Concurrent first reads share one parse")
    func concurrentReads() async {
        let repository = CatalogRepositoryImpl(source: BundleMockContentSource())
        async let first = repository.stories(languageTag: "kn").first()
        async let second = repository.categories(languageTag: "kn").first()
        let (stories, categories) = await (first, second)
        #expect(stories?.isEmpty == false)
        #expect(categories?.isEmpty == false)
    }
}
