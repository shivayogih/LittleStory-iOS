import Foundation

/// Typed keys for CoreUI's `Localizable.xcstrings`. Views use these instead of string literals.
public enum CoreUIStrings {
    public static var appName: LocalizedStringResource { resource("app.name") }
    public static var launchTagline: LocalizedStringResource { resource("launch.tagline") }

    /// Same key resolved for a specific language, used by tests and the in-app language override.
    static func resource(_ key: String.LocalizationValue, locale: Locale = .current) -> LocalizedStringResource {
        LocalizedStringResource(key, locale: locale, bundle: .atURL(Bundle.module.bundleURL))
    }
}
