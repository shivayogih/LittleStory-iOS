@testable import DataLayer
import Foundation
import Testing

/// Mock files held in memory, so tests can drop, blank or break a translation.
struct FakeContentSource: MockContentSource {
    var files: [String: String]

    func data(named fileName: String) -> Data? {
        files[fileName].map { Data($0.utf8) }
    }
}

enum TestStores {
    static func store() throws -> LittleStore {
        try LittleStore(inMemory: true)
    }

    static func preferences() throws -> PreferencesStore {
        try PreferencesStore(defaults: #require(UserDefaults(suiteName: UUID().uuidString)))
    }
}

extension AsyncStream {
    /// The values until (and including) the first one that matches.
    func values(until done: (Element) -> Bool) async -> [Element] {
        var values: [Element] = []
        for await value in self {
            values.append(value)
            if done(value) {
                break
            }
        }
        return values
    }
}
