@testable import CoreUI
import Domain
import Foundation
import Testing
import TestSupport

struct UITextTests {
    private let english = Locale(identifier: "en")
    private let kannada = Locale(identifier: "kn")

    @Test("A key resolves in the chosen language, whatever the device language")
    func perLanguage() {
        let text = UIText(CoreUIStrings.actionContinue)
        #expect(text.resolved(for: english) == "Continue")
        #expect(text.resolved(for: kannada) != text.resolved(for: english))
        #expect(!text.resolved(for: kannada).isEmpty)
    }

    @Test("Positional arguments fill in for both languages")
    func arguments() {
        let text = CoreUIStrings.storyCardMeta(.text("Friendship"), .number(6))
        #expect(text.resolved(for: english) == "Friendship · 6 min")
        #expect(text.resolved(for: kannada) == "Friendship · 6 ನಿಮಿಷ")
    }

    @Test("An unsupported language falls back to English, never the raw key")
    func fallback() {
        let text = UIText(CoreUIStrings.actionContinue)
        #expect(text.resolved(for: Locale(identifier: "fr")) == "Continue")
    }

    @Test("Verbatim content is shown as it is")
    func verbatim() {
        #expect(UIText.verbatim("ಆನೆ").resolved(for: english) == "ಆನೆ")
    }

    @Test("Story items carry favourite and download flags from the sets")
    func storyItem() {
        let story = Fixtures.story(id: "a", categoryID: "animals")
        let item = story.item(categoryNames: ["animals": "Animals"], favouriteIDs: ["a"], downloadedIDs: [])
        #expect(item.categoryName == "Animals")
        #expect(item.favourite)
        #expect(!item.downloaded)
        #expect(item.favouriteLabel == CoreUIStrings.storyFavouriteRemove(.text(story.title)))
    }
}

@MainActor
struct LocalizerTests {
    private func defaults() -> UserDefaults {
        let name = "littlestory.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name) ?? .standard
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    @Test("Starts from the device language when it is supported, else English")
    func initialLanguage() {
        #expect(Localizer(defaults: defaults(), preferredLanguages: ["kn-IN"]).language.tag == "kn")
        #expect(Localizer(defaults: defaults(), preferredLanguages: ["fr-FR"]).language.tag == "en")
    }

    @Test("A chosen language is kept for the next launch, and reset clears it")
    func override() {
        let store = defaults()
        let localizer = Localizer(defaults: store, preferredLanguages: ["en"])
        localizer.apply(tag: "kn")
        #expect(localizer.locale.language.languageCode?.identifier == "kn")
        #expect(Localizer(defaults: store, preferredLanguages: ["en"]).language.tag == "kn")
        localizer.reset()
        #expect(Localizer(defaults: store, preferredLanguages: ["en"]).language.tag == "en")
    }
}
