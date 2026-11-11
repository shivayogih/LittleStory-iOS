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
}

/// Spacing scale; features use these instead of numbers.
public enum LSSpacing {
    public static let xs: CGFloat = 4
    public static let sm: CGFloat = 8
    public static let md: CGFloat = 16
    public static let lg: CGFloat = 24
    public static let xl: CGFloat = 32
}
