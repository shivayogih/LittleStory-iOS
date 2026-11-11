// Shapes of the bundled mock JSON. Every field is optional: English defines ids and structure, a
// translation file carries only text, and a missing field never fails the whole file.

struct StoriesFile: Decodable {
    let stories: [StoryEntry]?
}

struct StoryEntry: Decodable, Identifiable {
    let id: String
    let title: String?
    let synopsis: String?
    let lesson: String?
    let pages: [String]?
    let categoryId: String?
    let tags: [String]?
    let ageMin: Int?
    let ageMax: Int?
    let durationMinutes: Int?
    let addedEpochDay: Int?
    let art: ArtEntry?
}

struct ArtEntry: Decodable {
    let paletteId: String?
    let motifId: String?
}

struct CategoriesFile: Decodable {
    let categories: [CategoryEntry]?
}

struct CategoryEntry: Decodable, Identifiable {
    let id: String
    let name: String?
    let description: String?
}

/// `generated_{tag}.json`: one story template; `{child}` is replaced with the hero's name.
struct GeneratedTemplate: Decodable {
    let defaultHero: String?
    let title: String?
    let synopsis: String?
    let lesson: String?
    let pages: [String]?
}

struct NotificationsFile: Decodable {
    let notifications: [NotificationEntry]?
}

struct NotificationEntry: Decodable, Identifiable {
    let id: String
    let title: String?
    let body: String?
    /// Android enum names such as `Today` or `StoryReady`.
    let section: String?
    let kind: String?
}

struct PlansFile: Decodable {
    let plans: [PlanEntry]?
}

struct PlanEntry: Decodable, Identifiable {
    let id: String
    let priceMinorUnits: Int64?
    let currencyCode: String?
    let billedYearly: Bool?
    let bestValue: Bool?
    let maxChildren: Int?
}
