import Common

/// Who is browsing and in which content language. `childID` falls back to the guest id when Setup
/// was skipped, so favourites and progress still work without a profile.
public struct BrowseContext: Sendable, Hashable {
    public let child: ChildProfile?
    public let languageTag: String

    public init(child: ChildProfile?, languageTag: String) {
        self.child = child
        self.languageTag = languageTag
    }

    public var childID: String { child?.id ?? AppConfig.Profiles.guestID }
}

/// The whole catalogue in one language.
public struct Catalogue: Sendable, Hashable {
    public let stories: [Story]
    public let categories: [StoryCategory]

    public init(stories: [Story], categories: [StoryCategory]) {
        self.stories = stories
        self.categories = categories
    }

    public var categoryNames: [String: String] {
        Dictionary(categories.map { ($0.id, $0.name) }, uniquingKeysWith: { first, _ in first })
    }

    public func category(id: String) -> StoryCategory? {
        categories.first { $0.id == id }
    }

    public func stories(in categoryID: String) -> [Story] {
        stories.filter { $0.belongs(to: categoryID) }
    }
}

/// Shared read helpers; small functions instead of use-case classes that would only forward a call.
public enum Browse {
    /// Active child plus content language, emitted again only when either really changes.
    public static func context(
        profiles: any ProfilesRepository,
        preferences: any PreferencesRepository,
    ) -> AsyncStream<BrowseContext> {
        combineLatest(profiles.activeProfile(), preferences.contentLanguageTag())
            .map { child, tag in BrowseContext(child: child, languageTag: tag) }
            .removeDuplicates()
    }

    public static func catalogue(_ catalog: any CatalogRepository, languageTag: String) -> AsyncStream<Catalogue> {
        combineLatest(catalog.stories(languageTag: languageTag), catalog.categories(languageTag: languageTag))
            .map { stories, categories in Catalogue(stories: stories, categories: categories) }
    }

    /// A story from the catalogue or, failing that, one the family created (Reader, Player, Story Ready).
    public static func story(
        id: String,
        languageTag: String,
        catalog: any CatalogRepository,
        library: any LibraryRepository,
    ) -> AsyncStream<Story?> {
        combineLatest(catalog.story(id: id, languageTag: languageTag), library.story(id: id))
            .map { bundled, created in bundled ?? created }
    }
}
