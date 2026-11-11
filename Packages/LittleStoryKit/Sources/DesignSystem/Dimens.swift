import CoreGraphics

/// Spacing scale (4 pt base) and screen padding from design-tokens.json `layout.content-padding`.
/// Same values as Android's `LittleStorySpacing` (1 CSS px = 1 pt = 1 dp).
public enum LSSpacing {
    /// Stacks whose children touch, such as a hero image over its content.
    public static let none: CGFloat = 0
    public static let xxs: CGFloat = 2
    public static let xs: CGFloat = 4
    public static let sm: CGFloat = 8
    public static let md: CGFloat = 12
    public static let lg: CGFloat = 16
    public static let xl: CGFloat = 20
    public static let xxl: CGFloat = 24
    public static let xxxl: CGFloat = 32
    public static let screenTop: CGFloat = 6
    public static let screenHorizontal: CGFloat = 20
    /// Side padding on phones at or below `LayoutTokens.narrowPhoneMaxWidth`.
    public static let screenHorizontalNarrow: CGFloat = 16
    public static let screenBottom: CGFloat = 28
}

/// Component sizes from design-tokens.json `layout` and Android `LittleStoryDimens`.
public enum LSDimens {
    public static let buttonMinHeight: CGFloat = 52
    public static let iconButtonVisual: CGFloat = 42
    /// Apple's minimum hit target (HIG); Android uses 48 dp.
    public static let minTouchTarget: CGFloat = 44
    public static let iconSize: CGFloat = 24
    public static let iconSizeSmall: CGFloat = 18
    public static let topBarHeight: CGFloat = 68
    public static let bottomNavHeight: CGFloat = 76
    public static let inputHeight: CGFloat = 48
    public static let borderWidth: CGFloat = 1
    public static let selectedBorderWidth: CGFloat = 2
    public static let focusRingWidth: CGFloat = 3
    public static let toggleWidth: CGFloat = 43
    public static let toggleHeight: CGFloat = 25
    public static let toggleKnob: CGFloat = 19
    public static let toggleKnobInset: CGFloat = 3
    public static let segmentedInset: CGFloat = 4
    public static let readingProgressHeight: CGFloat = 3
    public static let progressBarHeight: CGFloat = 8
    public static let sheetHandleWidth: CGFloat = 40
    public static let sheetHandleHeight: CGFloat = 4
    public static let dialogIconSize: CGFloat = 56
    public static let emptyStateIconSize: CGFloat = 72
    /// Proposed: the design has no loading state; sized between an icon button and the empty-state disc.
    public static let loadingIndicatorSize: CGFloat = 40
    /// Proposed: the prototype dims behind sheets but the alpha is not in the tokens.
    public static let scrimOpacity = 0.5
    public static let storyCardWidth: CGFloat = 150
    public static let storyCardWideWidth: CGFloat = 220
    public static let listArtWidth: CGFloat = 78
    public static let listArtHeight: CGFloat = 90
    public static let avatarSize: CGFloat = 56
    public static let avatarLargeSize: CGFloat = 72
    /// Dark translucent hill on story covers (design `#18243047`: alpha 0x47).
    public static let storyHillOpacity = 0.28
    public static let navPillWidth: CGFloat = 56
    public static let navPillHeight: CGFloat = 32
    public static let createTileWidth: CGFloat = 48
    public static let createTileHeight: CGFloat = 40
    public static let createTileRing: CGFloat = 5
    /// The bottom bar is white at 96 % (`#FFFFFFF5`) over the content.
    public static let bottomNavOpacity = 0.96
    public static let pagerDotSize: CGFloat = 7
    public static let pagerDotActiveWidth: CGFloat = 24
    public static let categoryTileSize: CGFloat = 58
    public static let categoryTileItemWidth: CGFloat = 72
    public static let heroSceneWidth: CGFloat = 130
    public static let heroMinHeight: CGFloat = 240
    public static let cultureArtWidth: CGFloat = 96
    public static let cultureArtHeight: CGFloat = 84
    public static let homeAvatarSize: CGFloat = 42
    public static let detailCoverHeight: CGFloat = 355
    public static let detailSheetOverlap: CGFloat = 32
    public static let categoryHeroHeight: CGFloat = 220
    public static let categoryHeroArtWidth: CGFloat = 120
    public static let featuredArtWidth: CGFloat = 110
    // Create, Generating, Story Ready

    public static let createOrbSize: CGFloat = 58
    public static let sparkleSize: CGFloat = 16
    public static let promptMinHeight: CGFloat = 120
    public static let magicBookWidth: CGFloat = 200
    public static let magicBookHeight: CGFloat = 120
    public static let stageDiscSize: CGFloat = 32
    public static let readyCoverHeight: CGFloat = 300
    public static let peekRuleWidth: CGFloat = 3
    // Reader and Player

    public static let readerCoverHeight: CGFloat = 180
    public static let readerPlayButtonSize: CGFloat = 56
    public static let playerCoverWidth: CGFloat = 265
    public static let playerCoverHeight: CGFloat = 290
    public static let playerCoverCompactWidth: CGFloat = 220
    public static let playerCoverCompactHeight: CGFloat = 235
    public static let playerPlayButtonSize: CGFloat = 76
    // My Stories, Downloads, Settings

    public static let recentArtSize: CGFloat = 64
    public static let roundPlaySize: CGFloat = 44
    public static let settingsIconTile: CGFloat = 40
    public static let dayButtonSize: CGFloat = 40
    public static let unreadDotSize: CGFloat = 8
    public static let reminderMoonSize: CGFloat = 72
    public static let subscriptionMoonSize: CGFloat = 96
    /// Disabled controls are drawn at 45 % opacity.
    public static let disabledOpacity = 0.45
    /// The prototype draws icon buttons as white at about 76 % opacity.
    public static let iconButtonSurfaceOpacity = 0.76
}

/// Corner radii from design-tokens.json `radius`.
public enum LSRadius {
    public static let large: CGFloat = 24
    public static let medium: CGFloat = 18
    public static let small: CGFloat = 13
    public static let button: CGFloat = 16
    public static let hero: CGFloat = 26
    /// Top corners of bottom sheets.
    public static let sheet: CGFloat = 32
    public static let chip: CGFloat = 20
    public static let avatar: CGFloat = 15
    public static let avatarLarge: CGFloat = 19
}
