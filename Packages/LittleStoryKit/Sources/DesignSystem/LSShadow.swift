import SwiftUI

/// A CSS box-shadow from design-tokens.json `shadow`: y offset, blur and colour with alpha.
public struct LSShadow: Sendable, Equatable {
    public let offsetY: CGFloat
    public let blur: CGFloat
    public let color: Color

    // Alphas from the CSS #RRGGBBAA values.

    private static let cardOpacity = 0x1C / 255.0
    private static let softOpacity = 0x14 / 255.0
    private static let primaryOpacity = 0x33 / 255.0
    private static let shellOpacity = 0x24 / 255.0
    private static let createNavOpacity = 0x40 / 255.0

    public static let card = LSShadow(offsetY: 12, blur: 30, color: Palette.shadowInk.opacity(cardOpacity))
    public static let soft = LSShadow(offsetY: 5, blur: 18, color: Palette.shadowInk.opacity(softOpacity))
    public static let primaryButton = LSShadow(offsetY: 8, blur: 18, color: Palette.indigo.opacity(primaryOpacity))
    public static let hero = LSShadow(offsetY: 16, blur: 30, color: Palette.indigo.opacity(primaryOpacity))
    public static let appShell = LSShadow(offsetY: 0, blur: 50, color: Palette.night.opacity(shellOpacity))
    /// No shadow, for variants that draw flat.
    public static let flat = LSShadow(offsetY: 0, blur: 0, color: .clear)
    public static let createNav = LSShadow(offsetY: 5, blur: 15, color: Palette.indigo.opacity(createNavOpacity))

    /// SwiftUI's shadow radius is about half of a CSS blur radius.
    static let blurToRadius: CGFloat = 0.5
}

public extension View {
    /// Draws a design shadow token.
    func lsShadow(_ token: LSShadow) -> some View {
        shadow(color: token.color, radius: token.blur * LSShadow.blurToRadius, x: 0, y: token.offsetY)
    }
}
