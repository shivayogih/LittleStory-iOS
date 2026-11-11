import CoreGraphics

/// Layout tokens for iPhone and iPad (HLD §6A). Widths are in points.
public enum LayoutTokens {
    /// From this width a window uses the medium layout (iPad portrait, half split).
    public static let mediumMinWidth: CGFloat = 600
    /// From this width a window uses the expanded layout (iPad landscape, full screen).
    public static let expandedMinWidth: CGFloat = 900
    /// Longest comfortable line for story text and forms.
    public static let readableMaxWidth: CGFloat = 680
    /// Smallest width of a story card in adaptive grids.
    public static let cardMinWidth: CGFloat = 160
    /// Phone layouts at or below this width use the compact side padding (design-tokens.json breakpoints).
    public static let narrowPhoneMaxWidth: CGFloat = 360
    /// Phones at least this tall use the roomier vertical layout of the design.
    public static let tallPhoneMinHeight: CGFloat = 900
}
