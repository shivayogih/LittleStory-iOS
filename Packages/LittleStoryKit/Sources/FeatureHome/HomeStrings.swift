import CoreUI
import Foundation

enum HomeStrings {
    private static func key(_ name: String) -> LocalizedKey {
        LocalizedKey(name, bundle: .module)
    }

    static let greeting = key("home.greeting")
    static let titleForChild = key("home.title_for_child")
    static let titleGeneric = key("home.title_generic")
    static let notifications = key("home.notifications")
    static let profiles = key("home.profiles")
    static let heroKicker = key("home.hero_kicker")
    static let heroTitle = key("home.hero_title")
    static let heroBody = key("home.hero_body")
    static let heroAction = key("home.hero_cta")
    static let continueTitle = key("home.continue_title")
    static let continueEyebrow = key("home.continue_eyebrow")
    static let continueResume = key("home.continue_resume")
    static let exploreTitle = key("home.explore_title")
    static let seeAll = key("home.see_all")
    static let madeForChild = key("home.made_for_child")
    static let madeForGeneric = key("home.made_for_generic")
    static let cultureKicker = key("home.culture_kicker")
    static let cultureTitle = key("home.culture_title")
    static let cultureBody = key("home.culture_body")
    static let cultureLink = key("home.culture_link")
}

/// Accessibility identifiers for UI tests; never user-facing.
public enum HomeID {
    public static let title = "home.title"
    public static let bell = "home.bell"
    public static let avatar = "home.avatar"
    public static let create = "home.create"
    public static let continueCard = "home.continue"
    public static let seeAllExplore = "home.see_all_explore"
    public static let seeAllMadeFor = "home.see_all_made_for"
    public static let culture = "home.culture"
    public static func category(_ id: String) -> String { "home.category.\(id)" }
}
