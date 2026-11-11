import CoreText
import SwiftUI
import UIKit

/// Which typography set to use. Kannada needs its own font, taller lines and no case transforms
/// (Android `kannada-typography.md` §3), so the set follows the app language, not the device.
public enum LSTypographyScript: Sendable, CaseIterable {
    case latin
    case kannada

    private static let kannadaLanguage = "kn"

    public init(locale: Locale) {
        self = locale.language.languageCode?.identifier == Self.kannadaLanguage ? .kannada : .latin
    }
}

/// Text styles from Android `design-system.md` §4, the same names as Android's `LittleStoryTypography`.
public enum LSTextStyle: Sendable, CaseIterable {
    case displayOnboarding
    case displaySetup
    case heroTitle
    case homeTitle
    case topBarTitle
    case brandName
    case bodyLarge
    /// Titles of cards, list rows and settings rows: bolder than body text so they lead the row.
    case itemTitle
    case body
    case readerBody
    case button
    case chip
    case eyebrow
    case heroKicker
    case navLabel
}

/// One style's design values at the default text size. Sizes and tracking are in points
/// (1 CSS px = 1 pt); `lineHeight` is a multiple of the size, nil for the font's own.
public struct LSTextSpec: Sendable, Equatable {
    public let family: LSFontFamily
    public let weight: LSFontWeight
    public let size: CGFloat
    public let lineHeight: CGFloat?
    public let tracking: CGFloat
    /// The Dynamic Type curve the size follows.
    public let relativeTo: Font.TextStyle
    public let uppercased: Bool

    init(
        _ family: LSFontFamily,
        _ weight: LSFontWeight,
        _ size: CGFloat,
        lineHeight: CGFloat? = nil,
        tracking: CGFloat = 0,
        relativeTo: Font.TextStyle,
        uppercased: Bool = false,
    ) {
        self.family = family
        self.weight = weight
        self.size = size
        self.lineHeight = lineHeight
        self.tracking = tracking
        self.relativeTo = relativeTo
        self.uppercased = uppercased
    }

    /// The style scaled for `dynamicTypeSize`, times `extraScale` (the Reader's own text size).
    public func resolved(for dynamicTypeSize: DynamicTypeSize, extraScale: CGFloat = 1) -> LSResolvedText {
        let traits = UITraitCollection(preferredContentSizeCategory: UIContentSizeCategory(dynamicTypeSize))
        let metrics = UIFontMetrics(forTextStyle: relativeTo.uiTextStyle)
        let scale = metrics.scaledValue(for: size, compatibleWith: traits) / size * extraScale
        let font = LSFonts.font(family, weight: weight, size: size * scale)
        let lineSpacing = lineHeight.map { max($0 * size * scale - font.lineHeight, 0) } ?? 0
        return LSResolvedText(font: font, lineSpacing: lineSpacing, tracking: tracking * scale, uppercased: uppercased)
    }
}

/// A style ready to apply: the scaled font plus the extra spacing SwiftUI adds around it.
public struct LSResolvedText: @unchecked Sendable {
    /// The scaled font. `UIFont` is immutable and thread-safe but not marked Sendable, hence `@unchecked`.
    public let font: UIFont
    public let lineSpacing: CGFloat
    public let tracking: CGFloat
    public let uppercased: Bool
}

public extension LSTextStyle {
    func spec(for script: LSTypographyScript) -> LSTextSpec {
        switch script {
        case .latin: latinSpec
        case .kannada: kannadaSpec
        }
    }

    /// Android LatinTypography. body and button sizes are not in design-tokens.json: proposed on Android too.
    private var latinSpec: LSTextSpec {
        switch self {
        case .displayOnboarding: LSTextSpec(.manrope, .extraBold, 29, lineHeight: 1.12, tracking: -0.8, relativeTo: .largeTitle)
        case .displaySetup: LSTextSpec(.manrope, .extraBold, 29, lineHeight: 1.18, tracking: -0.8, relativeTo: .largeTitle)
        case .heroTitle: LSTextSpec(.manrope, .extraBold, 25, lineHeight: 1.12, tracking: -0.7, relativeTo: .title)
        case .homeTitle: LSTextSpec(.manrope, .extraBold, 21, tracking: -0.5, relativeTo: .title2)
        case .topBarTitle: LSTextSpec(.manrope, .extraBold, 17, relativeTo: .headline)
        case .brandName: LSTextSpec(.manrope, .extraBold, 18, tracking: -0.5, relativeTo: .headline)
        case .bodyLarge: LSTextSpec(.dmSans, .regular, 15, lineHeight: 1.55, relativeTo: .body)
        case .itemTitle: LSTextSpec(.dmSans, .semibold, 15, lineHeight: 1.35, relativeTo: .body)
        case .body: LSTextSpec(.dmSans, .regular, 14, lineHeight: 1.5, relativeTo: .callout)
        case .readerBody: LSTextSpec(.manrope, .medium, 16, lineHeight: 1.95, relativeTo: .body)
        case .button: LSTextSpec(.dmSans, .bold, 15, relativeTo: .body)
        case .chip: LSTextSpec(.dmSans, .semibold, 12, relativeTo: .caption)
        case .eyebrow: LSTextSpec(.dmSans, .extraBold, 10, tracking: 1.6, relativeTo: .caption2, uppercased: true)
        case .heroKicker: LSTextSpec(.dmSans, .extraBold, 9, tracking: 1.4, relativeTo: .caption2, uppercased: true)
        case .navLabel: LSTextSpec(.dmSans, .semibold, 10, relativeTo: .caption2)
        }
    }

    /// Android KannadaTypography: no negative tracking, line height >= 1.4, small labels >= 11 pt, no case transform.
    private var kannadaSpec: LSTextSpec {
        switch self {
        case .displayOnboarding: LSTextSpec(.notoSansKannada, .bold, 29, lineHeight: 1.4, relativeTo: .largeTitle)
        case .displaySetup: LSTextSpec(.notoSansKannada, .bold, 29, lineHeight: 1.4, relativeTo: .largeTitle)
        case .heroTitle: LSTextSpec(.notoSansKannada, .bold, 25, lineHeight: 1.4, relativeTo: .title)
        case .homeTitle: LSTextSpec(.notoSansKannada, .bold, 21, lineHeight: 1.4, relativeTo: .title2)
        case .topBarTitle: LSTextSpec(.notoSansKannada, .bold, 17, lineHeight: 1.4, relativeTo: .headline)
        case .brandName: LSTextSpec(.notoSansKannada, .bold, 18, lineHeight: 1.4, relativeTo: .headline)
        case .bodyLarge: LSTextSpec(.notoSansKannada, .regular, 15, lineHeight: 1.7, relativeTo: .body)
        case .itemTitle: LSTextSpec(.notoSansKannada, .semibold, 15, lineHeight: 1.6, relativeTo: .body)
        case .body: LSTextSpec(.notoSansKannada, .regular, 14, lineHeight: 1.7, relativeTo: .callout)
        case .readerBody: LSTextSpec(.notoSansKannada, .medium, 16, lineHeight: 2.0, relativeTo: .body)
        case .button: LSTextSpec(.notoSansKannada, .bold, 15, lineHeight: 1.5, relativeTo: .body)
        case .chip: LSTextSpec(.notoSansKannada, .semibold, 12, lineHeight: 1.5, relativeTo: .caption)
        case .eyebrow: LSTextSpec(.notoSansKannada, .bold, 11, lineHeight: 1.5, relativeTo: .caption2)
        case .heroKicker: LSTextSpec(.notoSansKannada, .bold, 11, lineHeight: 1.5, relativeTo: .caption2)
        case .navLabel: LSTextSpec(.notoSansKannada, .semibold, 11, lineHeight: 1.5, relativeTo: .caption2)
        }
    }
}

/// Applies an `LSTextStyle` for the current language and text size.
struct LSTextStyleModifier: ViewModifier {
    let style: LSTextStyle
    let extraScale: CGFloat
    @Environment(\.locale) private var locale
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    func body(content: Content) -> some View {
        let text = style.spec(for: LSTypographyScript(locale: locale)).resolved(for: dynamicTypeSize, extraScale: extraScale)
        content
            .font(Font(text.font as CTFont))
            .tracking(text.tracking)
            .lineSpacing(text.lineSpacing)
            .textCase(text.uppercased ? .uppercase : nil)
    }
}

public extension View {
    /// Styles text with a design text style; scales with Dynamic Type and switches to the
    /// Kannada set when the app language is Kannada. `extraScale` is an in-app text size on top
    /// of Dynamic Type (the Reader's A− / A+).
    func lsTextStyle(_ style: LSTextStyle, extraScale: CGFloat = 1) -> some View {
        modifier(LSTextStyleModifier(style: style, extraScale: extraScale))
    }
}

extension Font.TextStyle {
    var uiTextStyle: UIFont.TextStyle {
        switch self {
        case .largeTitle: .largeTitle
        case .title: .title1
        case .title2: .title2
        case .title3: .title3
        case .headline: .headline
        case .subheadline: .subheadline
        case .callout: .callout
        case .footnote: .footnote
        case .caption: .caption1
        case .caption2: .caption2
        default: .body
        }
    }
}
