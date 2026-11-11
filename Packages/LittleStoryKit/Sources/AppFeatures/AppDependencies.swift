import Common
import Domain

/// Everything the screens need, as Domain protocols. The app target builds it from the data layer;
/// tests and previews build it from fakes. Features never see this type, only what they ask for.
public struct AppDependencies: Sendable {
    public let profiles: any ProfilesRepository
    public let preferences: any PreferencesRepository
    public let stores: StoryStores
    public let generation: any GenerationRepository
    public let flags: FeatureFlags

    public init(
        profiles: any ProfilesRepository,
        preferences: any PreferencesRepository,
        stores: StoryStores,
        generation: any GenerationRepository,
        flags: FeatureFlags = .mvp,
    ) {
        self.profiles = profiles
        self.preferences = preferences
        self.stores = stores
        self.generation = generation
        self.flags = flags
    }
}
