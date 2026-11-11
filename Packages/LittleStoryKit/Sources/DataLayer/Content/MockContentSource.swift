import Common
import Foundation
import OSLog

/// Where the bundled mock JSON comes from. The app reads the package bundle; tests can pass fixtures.
public protocol MockContentSource: Sendable {
    /// The bytes of `Mock/<fileName>`, or nil when the file does not exist.
    func data(named fileName: String) -> Data?
}

/// Reads `Resources/Mock` from this package's bundle: the same files as Android's `assets/mock`.
public struct BundleMockContentSource: MockContentSource {
    private static let folder = "Mock"

    public init() {}

    public func data(named fileName: String) -> Data? {
        guard let url = Bundle.module.url(forResource: fileName, withExtension: nil, subdirectory: Self.folder) else {
            return nil
        }
        return try? Data(contentsOf: url)
    }
}

enum MockFile {
    static func stories(_ tag: String) -> String { "stories_\(tag).json" }
    static func categories(_ tag: String) -> String { "categories_\(tag).json" }
    static func generated(_ tag: String) -> String { "generated_\(tag).json" }
    static func notifications(_ tag: String) -> String { "notifications_\(tag).json" }
    static let plans = "plans.json"
}

extension MockContentSource {
    /// A file that is missing or malformed yields nil, so the caller falls back to English.
    func decode<T: Decodable>(_ type: T.Type, from fileName: String) -> T? {
        guard let data = data(named: fileName) else {
            return nil
        }
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            DataLog.content.error("Mock file \(fileName, privacy: .public) is malformed")
            return nil
        }
    }
}

enum DataLog {
    private static let subsystem = "LittleStoryKit"
    static let content = Logger(subsystem: subsystem, category: "Content")
    static let store = Logger(subsystem: subsystem, category: "Store")
}

/// The content language for a tag: a supported language's base tag, otherwise English.
enum ContentLanguage {
    static let fallback = SupportedLanguages.fallback.tag

    static func resolve(_ tag: String) -> String {
        SupportedLanguages.language(forTag: tag).tag
    }
}

extension String {
    /// Nil for a blank value, so a translation that left a field empty keeps English.
    var nonBlank: String? {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : self
    }
}
