@testable import CoreUI
import Foundation
import Testing

struct CoreUIStringsTests {
    @Test("Tagline resolves in English and Kannada from the package bundle")
    func taglineLocalized() {
        let english = String(localized: CoreUIStrings.resource("launch.tagline", locale: Locale(identifier: "en")))
        let kannada = String(localized: CoreUIStrings.resource("launch.tagline", locale: Locale(identifier: "kn")))
        #expect(english == "Every Day Has a Story")
        #expect(kannada == "ಪ್ರತಿ ದಿನವೂ ಒಂದು ಕಥೆ")
    }

    @Test("A language without translations falls back to English, never the raw key")
    func fallback() {
        let french = String(localized: CoreUIStrings.resource("launch.tagline", locale: Locale(identifier: "fr")))
        #expect(french == "Every Day Has a Story")
    }
}
