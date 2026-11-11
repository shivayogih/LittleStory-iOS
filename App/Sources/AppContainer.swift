import AppFeatures
import DataLayer
import Foundation

/// Composition root (LLD §7.1): the only place that builds concrete repositories.
@MainActor
final class AppContainer {
    /// Launch argument UI tests pass: in-memory store and a fresh preferences suite on every launch.
    static let uiTestArgument = "-uiTest"
    private static let uiTestSuite = "littlestory.uitest"

    let dependencies: AppDependencies
    let defaults: UserDefaults

    init(arguments: [String] = ProcessInfo.processInfo.arguments) {
        let uiTest = arguments.contains(Self.uiTestArgument)
        let defaults = uiTest ? UserDefaults(suiteName: Self.uiTestSuite) ?? .standard : .standard
        if uiTest {
            defaults.removePersistentDomain(forName: Self.uiTestSuite)
        }
        let store: LittleStore
        do {
            store = try LittleStore(inMemory: uiTest)
        } catch {
            // The only crash point, at launch, by design: without its store the app cannot work.
            fatalError("LittleStore could not open: \(error)")
        }
        let repositories = LocalRepositories(store: store, preferences: PreferencesStore(defaults: defaults))
        self.defaults = defaults
        dependencies = AppDependencies(
            profiles: repositories.profiles,
            preferences: repositories.preferences,
            stores: repositories.storyStores,
            generation: repositories.generation,
            notifications: repositories.notifications,
            appVersion: Bundle.main.object(forInfoDictionaryKey: Self.versionKey) as? String ?? "",
            appBuild: Bundle.main.object(forInfoDictionaryKey: Self.buildKey) as? String ?? "",
            fixedParentalGate: uiTest,
        )
    }

    private static let versionKey = "CFBundleShortVersionString"
    private static let buildKey = "CFBundleVersion"
}
