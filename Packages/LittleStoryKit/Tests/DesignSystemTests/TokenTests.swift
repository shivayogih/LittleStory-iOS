import CoreText
@testable import DesignSystem
import SwiftUI
import Testing
import UIKit

struct TokenTests {
    @Test("Every bundled font registers and its weight axis is applied")
    func fontsRegister() {
        LSFonts.register()
        #expect(LSFonts.registeredFamilies == Set(LSFontFamily.allCases))
        for family in LSFontFamily.allCases {
            let regular = LSFonts.font(family, weight: .regular, size: 20)
            let extraBold = LSFonts.font(family, weight: .extraBold, size: 20)
            #expect(regular.fontName.hasPrefix(family.postScriptName.prefix { $0 != "-" }), "\(family)")
            // Noto Sans Kannada has no Latin glyphs, so measure Kannada text with it.
            let sample = family == .notoSansKannada ? "ಕಥೆ ಹೇಳುವ ಸಮಯ" : "LittleStory"
            let regularWidth = (sample as NSString).size(withAttributes: [.font: regular]).width
            let boldWidth = (sample as NSString).size(withAttributes: [.font: extraBold]).width
            // A heavier instance of the same text is wider, so the weight axis was applied.
            #expect(boldWidth > regularWidth, "\(family)")
        }
    }

    @Test("Kannada glyphs come from Noto Sans Kannada")
    func kannadaGlyphs() {
        let font = LSFonts.font(.notoSansKannada, weight: .regular, size: 16)
        let characters = Array("ಕನ್ನಡ".utf16)
        var glyphs = [CGGlyph](repeating: 0, count: characters.count)
        #expect(CTFontGetGlyphsForCharacters(font as CTFont, characters, &glyphs, characters.count))
    }

    @Test("Every text style has a Latin and a Kannada spec", arguments: LSTextStyle.allCases)
    func specs(style: LSTextStyle) {
        let latin = style.spec(for: .latin)
        let kannada = style.spec(for: .kannada)
        #expect(latin.family != .notoSansKannada)
        #expect(kannada.family == .notoSansKannada)
        // Kannada rules: no negative tracking, tall lines, no case transform, small labels >= 11 pt.
        #expect(kannada.tracking >= 0)
        #expect((kannada.lineHeight ?? 0) >= 1.4)
        #expect(!kannada.uppercased)
        #expect(kannada.size >= 11)
    }

    @Test("Text scales up with Dynamic Type and keeps the design size at the default")
    func dynamicType() {
        let spec = LSTextStyle.bodyLarge.spec(for: .latin)
        let standard = spec.resolved(for: .large)
        let huge = spec.resolved(for: .accessibility3)
        #expect(abs(standard.font.pointSize - spec.size) < 0.01)
        #expect(huge.font.pointSize > standard.font.pointSize)
        #expect(huge.lineSpacing >= standard.lineSpacing)
    }

    @Test("The language picks the typography set")
    func scriptFromLocale() {
        #expect(LSTypographyScript(locale: Locale(identifier: "kn")) == .kannada)
        #expect(LSTypographyScript(locale: Locale(identifier: "kn-IN")) == .kannada)
        #expect(LSTypographyScript(locale: Locale(identifier: "en")) == .latin)
    }

    @Test("Every icon has a vector image in the bundle", arguments: LSIcon.allCases)
    func icons(icon: LSIcon) {
        #expect(UIImage(named: icon.rawValue, in: .module, with: nil) != nil)
    }

    @Test("Content palette ids map to their gradients; unknown ids fall back to Friendship")
    func storyArt() {
        #expect(LSColor.StoryArt.gradient(paletteID: "indian_tales") == LSColor.StoryArt.indianTales)
        #expect(LSColor.StoryArt.gradient(paletteID: "unknown") == LSColor.StoryArt.friendship)
        #expect(LSColor.StoryArt.byPaletteID.count == 6)
    }

    @Test("Reduce Motion turns animations off")
    func reducedMotion() {
        #expect(LSMotion.standard(LSMotion.press, reduceMotion: true) == nil)
        #expect(LSMotion.standard(LSMotion.press, reduceMotion: false) != nil)
        #expect(LSMotion.press.lsSeconds == 0.18)
    }

    @Test("Hex literals decode to the right sRGB channels")
    func hex() {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        #expect(UIColor(Color(lsHex: 0x35256F)).getRed(&red, green: &green, blue: &blue, alpha: &alpha))
        #expect(abs(red - 0x35 / 255.0) < 0.001)
        #expect(abs(green - 0x25 / 255.0) < 0.001)
        #expect(abs(blue - 0x6F / 255.0) < 0.001)
        #expect(alpha == 1)
    }
}
