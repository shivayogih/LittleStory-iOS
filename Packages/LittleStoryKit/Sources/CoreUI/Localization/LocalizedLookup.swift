import Common
import Foundation

/// Looks keys up in the `.lproj` of the chosen app language, so the in-app language switch works
/// without restarting (iOS would otherwise use the system language for the whole process).
enum LocalizedLookup {
    /// Returned by `Bundle` when a key is missing; never shown.
    private static let missing = "\u{0}missing"
    private static let lprojType = "lproj"

    static func languageTag(of locale: Locale) -> String {
        SupportedLanguages.language(forTag: locale.language.languageCode?.identifier).tag
    }

    static func string(_ key: LocalizedKey, arguments: [UIText.Argument], languageTag: String) -> String {
        let format = format(for: key, languageTag: languageTag)
        guard !arguments.isEmpty else {
            return format
        }
        let values: [any CVarArg] = arguments.map { argument in
            switch argument {
            case let .text(text): text
            case let .number(number): number
            case let .localized(nested): string(nested, arguments: [], languageTag: languageTag)
            }
        }
        return String(format: format, locale: Locale(identifier: languageTag), arguments: values)
    }

    private static func format(for key: LocalizedKey, languageTag: String) -> String {
        guard let bundle = Bundle(url: key.bundleURL) else {
            return key.key
        }
        for tag in [languageTag, SupportedLanguages.fallback.tag] {
            if let path = bundle.path(forResource: tag, ofType: lprojType), let localized = Bundle(path: path) {
                let value = localized.localizedString(forKey: key.key, value: missing, table: nil)
                if value != missing {
                    return value
                }
            }
        }
        // Without an .lproj (unexpected) let Foundation pick, which still prefers English source text.
        return bundle.localizedString(forKey: key.key, value: nil, table: nil)
    }
}
