import SwiftUI

/// A two-stop gradient for story covers and progress bars.
public struct LSGradientPair: Sendable, Equatable {
    public let start: Color
    public let end: Color

    public var linear: LinearGradient {
        LinearGradient(colors: [start, end], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

/// Semantic colour roles (Android `LittleStoryColors`, design-system.md §3). Feature code reads
/// only these. One light theme with night surfaces for onboarding, Generating and the Player
/// (Android ADR-013); the app opts out of system dark mode until a dark palette is designed.
public enum LSColor {
    public static let primary = Palette.indigo
    public static let onPrimary = Palette.white
    public static let primaryVariantLabel = Palette.indigo2
    public static let accent = Palette.lavender
    public static let secondaryContainer = Palette.softLavender
    public static let onSecondaryContainer = Palette.indigo
    public static let background = Palette.cream
    public static let pageBackdrop = Palette.pageBackdrop
    public static let surface = Palette.white
    public static let surfaceMuted = Palette.surface
    public static let outline = Palette.line
    public static let night = Palette.night
    public static let nightSurface = Palette.nightSurface
    public static let onNight = Palette.white
    public static let highlight = Palette.yellow
    public static let warmAccent = Palette.peach
    public static let moon = Palette.moon
    public static let textPrimary = Palette.text
    public static let textSecondary = Palette.muted
    public static let textReader = Palette.readerBody
    /// The design's nav-inactive (#817B8D) fails WCAG AA contrast (Android accessibility-spec AX-01);
    /// muted text passes at 4.87:1 on cream, as on Android, until the owner decides.
    public static let navInactive = Palette.muted
    public static let success = Palette.success
    public static let successContainer = Palette.successBg
    public static let error = Palette.error
    public static let favourite = Palette.favourite
    public static let favouriteContainer = Palette.favouriteBg
    public static let cultureBanner = Palette.cultureBanner
    public static let lessonPanel = Palette.lessonPanel
    public static let readerBackground = Palette.readerBackground
    public static let successRibbon = Palette.successRibbon
    /// Shadow ink for the card and soft shadows.
    public static let shadowInk = Palette.shadowInk

    /// Lavender to yellow, used by the generation progress bar.
    public static let generationGradient = LSGradientPair(start: Palette.lavender, end: Palette.yellow)

    /// Story-cover gradients, keyed by the `paletteId` in the mock content (shared with Android).
    public enum StoryArt {
        public static let friendship = LSGradientPair(start: Palette.friendshipStart, end: Palette.friendshipEnd)
        public static let adventure = LSGradientPair(start: Palette.adventureStart, end: Palette.adventureEnd)
        public static let bedtime = LSGradientPair(start: Palette.bedtimeStart, end: Palette.bedtimeEnd)
        public static let indianTales = LSGradientPair(start: Palette.indianTalesStart, end: Palette.indianTalesEnd)
        public static let space = LSGradientPair(start: Palette.spaceStart, end: Palette.spaceEnd)
        public static let festivals = LSGradientPair(start: Palette.festivalsStart, end: Palette.festivalsEnd)

        /// Palette ids used by the content files, mapped to their gradients.
        public static let byPaletteID: [String: LSGradientPair] = [
            "friendship": friendship,
            "adventure": adventure,
            "bedtime": bedtime,
            "indian_tales": indianTales,
            "space": space,
            "festivals": festivals,
        ]

        /// Unknown ids use the Friendship gradient as a placeholder, as on Android.
        public static func gradient(paletteID: String) -> LSGradientPair {
            byPaletteID[paletteID] ?? friendship
        }
    }

    /// Colours for drawn characters and props.
    public enum Illustration {
        public static let skin = Palette.skin
        public static let skinLight = Palette.skinLight
        public static let hair = Palette.hair
        public static let childTop = Palette.childTop
        public static let elephant = Palette.elephant
        public static let elephantLight = Palette.elephantLight
        public static let elephantLeg = Palette.elephantLeg
        public static let cricketBat = Palette.cricketBat
        public static let shirtGold = Palette.shirtGold
        public static let terracotta = Palette.terracotta
        public static let heroHill = Palette.heroHill
        public static let heroShirt = Palette.heroShirt
    }

    /// Pastel backgrounds of the Home "Explore stories" icon tiles.
    public enum CategoryTile {
        public static let lavender = Palette.softLavender
        public static let peach = Palette.tilePeach
        public static let mint = Palette.tileMint
        public static let pink = Palette.tilePink
        public static let butter = Palette.tileButter
    }
}
