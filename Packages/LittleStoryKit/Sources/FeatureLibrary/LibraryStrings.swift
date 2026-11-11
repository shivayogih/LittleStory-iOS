import CoreUI
import Foundation

/// Typed keys for this target's `Localizable.xcstrings` (My Stories and Offline downloads).
enum LibraryStrings {
    private static func key(_ name: String) -> LocalizedKey {
        LocalizedKey(name, bundle: .module)
    }

    static let title = key("stories.title")
    static let openDownloads = key("stories.open_downloads")
    static let search = key("stories.search")
    static let searchClear = key("stories.search_clear")
    static let tabAll = key("stories.tab_all")
    static let tabCreated = key("stories.tab_created")
    static let tabDownloaded = key("stories.tab_downloaded")
    static let tabFavourites = key("stories.tab_favourites")
    static let recentlyPlayed = key("stories.recently_played")
    static let collection = key("stories.collection")
    static let remaining = key("stories.remaining")
    static let play = key("stories.play")
    static let rowMeta = key("stories.row_meta")
    static let emptyTitle = key("stories.empty_title")
    static let emptyText = key("stories.empty_text")
    static let emptyDownloadedTitle = key("stories.empty_downloaded_title")
    static let emptyDownloadedText = key("stories.empty_downloaded_text")
    static let emptyAction = key("stories.empty_action")

    static let downloadsTitle = key("downloads.title")
    static let downloadsUsed = key("downloads.used")
    static let downloadsQuota = key("downloads.quota")
    static let downloadsAvailable = key("downloads.available")
    static let downloadsSize = key("downloads.size")
    static let downloadsRemove = key("downloads.remove")
    static let downloadsEmptyTitle = key("downloads.empty_title")
    static let downloadsEmptyText = key("downloads.empty_text")
    static let downloadsEmptyAction = key("downloads.empty_action")
    static let downloadsTip = key("downloads.tip")
}

/// Accessibility identifiers for UI tests; never user-facing.
public enum LibraryID {
    public static let title = "stories.title"
    public static let downloads = "stories.downloads"
    public static let search = "stories.search"
    public static let clearSearch = "stories.clear_search"
    public static let recent = "stories.recent"
    public static let empty = "stories.empty"
    public static func tab(_ tab: LibraryTab) -> String { "stories.tab.\(tab.rawValue)" }

    public static let downloadsTitle = "downloads.title"
    public static let downloadsBack = "downloads.back"
    public static let storage = "downloads.storage"
    public static let downloadsEmpty = "downloads.empty"
    public static func download(_ id: String) -> String { "downloads.item.\(id)" }
    public static func remove(_ id: String) -> String { "downloads.remove.\(id)" }
}

/// Where the library screens send the child; the app maps these to routes.
public struct LibraryNavigation {
    public var downloads: () -> Void
    /// A catalogue story opens its detail page.
    public var story: (String) -> Void
    /// A story the child created opens on Story ready.
    public var createdStory: (String) -> Void
    public var play: (String) -> Void
    public var discover: () -> Void
    public var back: () -> Void

    public init(
        downloads: @escaping () -> Void,
        story: @escaping (String) -> Void,
        createdStory: @escaping (String) -> Void,
        play: @escaping (String) -> Void,
        discover: @escaping () -> Void,
        back: @escaping () -> Void,
    ) {
        self.downloads = downloads
        self.story = story
        self.createdStory = createdStory
        self.play = play
        self.discover = discover
        self.back = back
    }
}
