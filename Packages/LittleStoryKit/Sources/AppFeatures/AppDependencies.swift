import Common
import Domain

/// Everything the screens need, as Domain protocols. The app target builds it from the data layer;
/// tests and previews build it from fakes. Features never see this type, only what they ask for.
public struct AppDependencies: Sendable {
    public let profiles: any ProfilesRepository
    public let preferences: any PreferencesRepository
    public let stores: StoryStores
    public let generation: any GenerationRepository
    public let notifications: any NotificationsRepository
    public let subscription: any SubscriptionRepository
    public let localData: any LocalDataRepository
    public let appInfo: AppInfo
    /// Questions for the grown-ups-only gate; UI tests ask for the fixed one.
    public let parentalGate: any ParentalGateChallenges
    public let flags: FeatureFlags

    public init(
        profiles: any ProfilesRepository,
        preferences: any PreferencesRepository,
        stores: StoryStores,
        generation: any GenerationRepository,
        notifications: any NotificationsRepository,
        subscription: any SubscriptionRepository,
        localData: any LocalDataRepository,
        appVersion: String,
        appBuild: String,
        fixedParentalGate: Bool = false,
        flags: FeatureFlags = .mvp,
    ) {
        self.profiles = profiles
        self.preferences = preferences
        self.stores = stores
        self.generation = generation
        self.notifications = notifications
        self.subscription = subscription
        self.localData = localData
        appInfo = AppInfo(version: appVersion, build: appBuild)
        parentalGate = fixedParentalGate ? FixedParentalGate() : RandomParentalGateChallenges()
        self.flags = flags
    }
}

/// UI tests only (`-uiTest`): always asks 12 × 3, so a journey can answer 36 on the keypad.
struct FixedParentalGate: ParentalGateChallenges {
    static let challenge = ParentalGateChallenge(first: 12, second: 3)

    func next() -> ParentalGateChallenge { Self.challenge }
}
