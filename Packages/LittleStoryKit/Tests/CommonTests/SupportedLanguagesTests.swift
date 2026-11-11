@testable import Common
import Testing

struct SupportedLanguagesTests {
    @Test("English is the fallback and comes first")
    func fallback() {
        #expect(SupportedLanguages.fallback == SupportedLanguages.english)
        #expect(SupportedLanguages.all.first == SupportedLanguages.english)
    }

    @Test("Region and script suffixes resolve to the base language", arguments: ["kn", "kn-IN", "kn_IN", "KN"])
    func resolvesKannada(tag: String) {
        #expect(SupportedLanguages.language(forTag: tag) == SupportedLanguages.kannada)
    }

    @Test("Unknown or missing tags fall back to English", arguments: [nil, "", "fr", "hi-IN"] as [String?])
    func fallsBack(tag: String?) {
        #expect(SupportedLanguages.language(forTag: tag) == SupportedLanguages.english)
    }

    @Test("Native names are shown in their own script")
    func nativeNames() {
        #expect(SupportedLanguages.kannada.nativeName == "ಕನ್ನಡ")
        #expect(Set(SupportedLanguages.enabled.map(\.tag)) == ["en", "kn"])
    }
}
