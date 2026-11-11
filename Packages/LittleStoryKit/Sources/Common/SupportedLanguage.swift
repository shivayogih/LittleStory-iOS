/// A language the app can be shown in.
public struct SupportedLanguage: Sendable, Hashable, Identifiable {
    /// BCP 47 tag, also the suffix of `stories_{tag}.json`.
    public let tag: String
    /// Name in the language itself, shown in the picker; never translated.
    public let nativeName: String
    public let isEnabled: Bool

    public var id: String { tag }

    public init(tag: String, nativeName: String, isEnabled: Bool = true) {
        self.tag = tag
        self.nativeName = nativeName
        self.isEnabled = isEnabled
    }
}

/// The only list of supported languages. Adding one: an entry here, the tag in every
/// `Localizable.xcstrings`, `CFBundleLocalizations` in `project.yml`, and mock content files.
public enum SupportedLanguages {
    public static let english = SupportedLanguage(tag: "en", nativeName: "English")
    public static let kannada = SupportedLanguage(tag: "kn", nativeName: "ಕನ್ನಡ")

    public static let all: [SupportedLanguage] = [english, kannada]
    public static var enabled: [SupportedLanguage] { all.filter(\.isEnabled) }

    /// English is the default and the fallback for missing translations.
    public static let fallback = english

    /// Resolves a tag such as "kn-IN" or "kn_IN" to a supported language, or the fallback.
    public static func language(forTag tag: String?) -> SupportedLanguage {
        guard let tag else { return fallback }
        let base = tag.split(whereSeparator: { $0 == "-" || $0 == "_" }).first.map { $0.lowercased() }
        return enabled.first { $0.tag == base } ?? fallback
    }
}
