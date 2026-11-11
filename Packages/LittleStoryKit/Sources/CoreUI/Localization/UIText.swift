import Foundation

/// A key in one target's `Localizable.xcstrings`. Features declare theirs in a `…Strings` enum, so
/// no string literal for user-facing text appears in a view.
public struct LocalizedKey: Sendable, Hashable {
    public let key: String
    let bundleURL: URL

    public init(_ key: String, bundle: Bundle) {
        self.key = key
        bundleURL = bundle.bundleURL
    }

    /// The text with positional arguments, e.g. `HomeStrings.titleForChild(.text(name))`.
    public func callAsFunction(_ arguments: UIText.Argument...) -> UIText {
        UIText(source: .key(self, arguments))
    }
}

/// Text a view model hands to a view, like Android's `UiText`: a catalog key with positional
/// arguments, or content already resolved for the language (a story title).
public struct UIText: Sendable, Hashable {
    public enum Argument: Sendable, Hashable {
        case text(String)
        case number(Int)
        /// Another catalog key, resolved in the same language (e.g. "My little one" as a name).
        case localized(LocalizedKey)
    }

    enum Source: Sendable, Hashable {
        case key(LocalizedKey, [Argument])
        case verbatim(String)
    }

    let source: Source

    init(source: Source) {
        self.source = source
    }

    public init(_ key: LocalizedKey) {
        source = .key(key, [])
    }

    /// Content that is already in the right language, such as a story title or category name.
    public static func verbatim(_ text: String) -> UIText {
        UIText(source: .verbatim(text))
    }

    /// The text in `locale`'s language; English when a translation is missing, never the raw key.
    public func resolved(for locale: Locale) -> String {
        switch source {
        case let .verbatim(text):
            text
        case let .key(key, arguments):
            LocalizedLookup.string(key, arguments: arguments, languageTag: LocalizedLookup.languageTag(of: locale))
        }
    }
}
