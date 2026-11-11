import CoreUI
import Foundation

enum DiscoverStrings {
    private static func key(_ name: String) -> LocalizedKey {
        LocalizedKey(name, bundle: .module)
    }

    static let title = key("discover.title")
    static let notifications = key("discover.notifications")
    static let searchPlaceholder = key("discover.search_placeholder")
    static let searchClear = key("discover.search_clear")
    static let featuredKicker = key("discover.featured_kicker")
    static let featuredAction = key("discover.featured_cta")
    static let filterAll = key("discover.filter_all")
    static let popular = key("discover.popular")
    static let results = key("discover.results")
    static let viewAll = key("discover.view_all")
    static let bedtime = key("discover.bedtime")
    static let emptyTitle = key("discover.empty_title")
    static let emptyText = key("discover.empty_text")
    static let emptyAction = key("discover.empty_action")

    static let categoryStoryCount = key("category.story_count")
    static let categoryAllName = key("category.all_name")
    static let categoryAllDescription = key("category.all_description")
    static let categoryHeading = key("category.heading")
    static let sortLabel = key("category.sort_label")
    static let sortRecommended = key("category.sort_recommended")
    static let sortShortest = key("category.sort_shortest")
    static let sortNewest = key("category.sort_newest")
    static let categoryEmptyTitle = key("category.empty_title")
    static let categoryEmptyText = key("category.empty_text")

    static let detailMeta = key("detail.meta")
    static let detailLessonTitle = key("detail.lesson_title")
    static let detailNarrationTitle = key("detail.narration_title")
    static let detailNarrationText = key("detail.narration_text")
    static let detailNarrationAvailable = key("detail.narration_available")
    static let detailListen = key("detail.listen")
    static let detailRead = key("detail.read")
    static let detailDownloadAdd = key("detail.download_add")
    static let detailDownloadRemove = key("detail.download_remove")
    static let detailNotFoundTitle = key("detail.not_found_title")
    static let detailNotFoundText = key("detail.not_found_text")
}

/// Accessibility identifiers for UI tests; never user-facing.
public enum DiscoverID {
    public static let title = "discover.title"
    public static let search = "discover.search"
    public static let clearSearch = "discover.clear_search"
    public static let featured = "discover.featured"
    public static let viewAll = "discover.view_all"
    public static let empty = "discover.empty"
    public static func filter(_ id: String) -> String { "discover.filter.\(id)" }
    public static let categoryTitle = "category.title"
    public static func sort(_ id: String) -> String { "category.sort.\(id)" }
    public static let detailTitle = "detail.title"
    public static let detailFavourite = "detail.favourite"
    public static let detailDownload = "detail.download"
    public static let detailListen = "detail.listen"
    public static let detailRead = "detail.read"
    public static let detailBack = "detail.back"
}

/// Where Discover's screens send the child; the app maps these to routes.
public struct DiscoverNavigation {
    public var notifications: () -> Void
    public var category: (String) -> Void
    public var story: (String) -> Void
    public var listen: (String) -> Void
    public var read: (String) -> Void
    public var back: () -> Void

    public init(
        notifications: @escaping () -> Void,
        category: @escaping (String) -> Void,
        story: @escaping (String) -> Void,
        listen: @escaping (String) -> Void,
        read: @escaping (String) -> Void,
        back: @escaping () -> Void,
    ) {
        self.notifications = notifications
        self.category = category
        self.story = story
        self.listen = listen
        self.read = read
        self.back = back
    }
}
