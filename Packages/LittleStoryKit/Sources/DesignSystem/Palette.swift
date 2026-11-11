import SwiftUI

/// Raw palette from `docs/design/design-tokens.json`, the same values as Android's `Palette`.
/// This is the only file that may contain colour literals (`Tools/check-tokens.py`); everything
/// else uses the semantic roles in `LSColor`.
enum Palette {
    // brand

    static let indigo = Color(lsHex: 0x35256F)
    static let indigo2 = Color(lsHex: 0x4B388B)
    static let lavender = Color(lsHex: 0xA995F5)
    static let softLavender = Color(lsHex: 0xEAE3FF)

    // night

    static let night = Color(lsHex: 0x17152F)
    static let nightSurface = Color(lsHex: 0x242044)

    // surface

    static let cream = Color(lsHex: 0xFFF9F0)
    static let white = Color(lsHex: 0xFFFFFF)
    static let surface = Color(lsHex: 0xF8F5FB)
    static let line = Color(lsHex: 0xE9E4EC)
    static let pageBackdrop = Color(lsHex: 0xE8E5ED)

    /// Colour of the card and soft shadows (#231846).
    static let shadowInk = Color(lsHex: 0x231846)

    // accent

    static let yellow = Color(lsHex: 0xFFD977)
    static let peach = Color(lsHex: 0xFFC9AD)
    static let moon = Color(lsHex: 0xFFF1BD)

    // text

    static let text = Color(lsHex: 0x25213A)
    static let muted = Color(lsHex: 0x716B80)
    static let readerBody = Color(lsHex: 0x393348)
    static let navInactive = Color(lsHex: 0x817B8D)

    // semantic

    static let success = Color(lsHex: 0x287A54)
    static let successBg = Color(lsHex: 0xEAF5EE)
    static let error = Color(lsHex: 0xB42318)
    static let favourite = Color(lsHex: 0x9D3158)
    static let favouriteBg = Color(lsHex: 0xFFEDF2)

    // Used in screen specs but missing from design-tokens.json (Android docs/design/figma-audit.md A6).

    static let cultureBanner = Color(lsHex: 0xF5DFC0)
    static let lessonPanel = Color(lsHex: 0xFFF4E8)
    static let readerBackground = Color(lsHex: 0xFFFAF2)
    static let successRibbon = Color(lsHex: 0xE9F6EE)

    // storyArt gradients (start, end)

    static let friendshipStart = Color(lsHex: 0xF6B995)
    static let friendshipEnd = Color(lsHex: 0x694B91)
    static let adventureStart = Color(lsHex: 0x6252A6)
    static let adventureEnd = Color(lsHex: 0xF2A978)
    static let bedtimeStart = Color(lsHex: 0x32306D)
    static let bedtimeEnd = Color(lsHex: 0x9F91E9)
    static let indianTalesStart = Color(lsHex: 0x47796B)
    static let indianTalesEnd = Color(lsHex: 0xEFBB69)
    static let spaceStart = Color(lsHex: 0x25285D)
    static let spaceEnd = Color(lsHex: 0xDB82A6)
    static let festivalsStart = Color(lsHex: 0xB15B54)
    static let festivalsEnd = Color(lsHex: 0xF5C568)

    // illustration

    static let skin = Color(lsHex: 0xD9986C)
    static let skinLight = Color(lsHex: 0xE8C3A5)
    static let hair = Color(lsHex: 0x332422)
    static let childTop = Color(lsHex: 0x6652A1)
    static let elephant = Color(lsHex: 0x8C82A8)
    static let elephantLight = Color(lsHex: 0x9E95B8)
    static let elephantLeg = Color(lsHex: 0x81779D)
    static let cricketBat = Color(lsHex: 0xD9B885)
    static let shirtGold = Color(lsHex: 0xE2AA55)

    // Sampled from the Home screenshot (05-home.jpg); not in design-tokens.json (figma-audit A6).

    static let terracotta = Color(lsHex: 0xC96F52)
    static let heroHill = Color(lsHex: 0x45348A)
    static let heroShirt = Color(lsHex: 0xC77070)
    static let tilePeach = Color(lsHex: 0xFBE3D3)
    static let tileMint = Color(lsHex: 0xD9EFE3)
    static let tilePink = Color(lsHex: 0xFFE3EC)
    static let tileButter = Color(lsHex: 0xFCEBBE)
}

extension Color {
    private static let channelMax = 255.0
    private static let redShift: UInt32 = 16
    private static let greenShift: UInt32 = 8
    private static let channelMask: UInt32 = 0xFF

    /// An sRGB colour from a 0xRRGGBB literal, as written in the design tokens.
    init(lsHex hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> Self.redShift) & Self.channelMask) / Self.channelMax,
            green: Double((hex >> Self.greenShift) & Self.channelMask) / Self.channelMax,
            blue: Double(hex & Self.channelMask) / Self.channelMax,
        )
    }
}
