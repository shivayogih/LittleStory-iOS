/// On/off switches for simulated or optional features (no remote config in the MVP).
/// A plain value so the composition root and tests can override it.
public struct FeatureFlags: Sendable, Equatable {
    public var demoSubscription: Bool
    public var simulatedNarration: Bool
    public var simulatedDownloads: Bool
    public var bedtimeReminder: Bool
    public var notificationsInbox: Bool
    /// Labels privacy and family-safety text as a draft awaiting legal review.
    public var draftLegalText: Bool

    public init(
        demoSubscription: Bool = true,
        simulatedNarration: Bool = true,
        simulatedDownloads: Bool = true,
        bedtimeReminder: Bool = true,
        notificationsInbox: Bool = true,
        draftLegalText: Bool = true
    ) {
        self.demoSubscription = demoSubscription
        self.simulatedNarration = simulatedNarration
        self.simulatedDownloads = simulatedDownloads
        self.bedtimeReminder = bedtimeReminder
        self.notificationsInbox = notificationsInbox
        self.draftLegalText = draftLegalText
    }

    public static let mvp = FeatureFlags()
}
