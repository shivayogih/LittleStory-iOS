import Common
import Foundation
import Observation

/// Owns the app language (LLD §8). The choice is kept in `UserDefaults` under `ui_language_tag`;
/// with no choice the app follows the system's preferred languages. The root view sets
/// `\.locale` from `locale`, and every `LText` and text style follows it.
@MainActor
@Observable
public final class Localizer {
    static let storageKey = "ui_language_tag"

    public private(set) var language: SupportedLanguage
    @ObservationIgnored private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard, preferredLanguages: [String] = Locale.preferredLanguages) {
        self.defaults = defaults
        let saved = defaults.string(forKey: Self.storageKey)
        language = SupportedLanguages.language(forTag: saved ?? preferredLanguages.first)
    }

    public var locale: Locale {
        Locale(identifier: language.tag)
    }

    /// Switches the app language at once and remembers it.
    public func apply(tag: String) {
        let chosen = SupportedLanguages.language(forTag: tag)
        defaults.set(chosen.tag, forKey: Self.storageKey)
        language = chosen
    }

    /// Forgets the choice (Delete all data); the system language applies again.
    public func reset(preferredLanguages: [String] = Locale.preferredLanguages) {
        defaults.removeObject(forKey: Self.storageKey)
        language = SupportedLanguages.language(forTag: preferredLanguages.first)
    }
}
