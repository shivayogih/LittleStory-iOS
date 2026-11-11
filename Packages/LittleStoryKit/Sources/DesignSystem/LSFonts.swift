import CoreText
import Foundation
import OSLog
import UIKit

/// The bundled typefaces (SIL Open Font License, texts in `Resources/Licenses`). DM Sans and
/// Manrope are variable fonts with the weight set on the `wght` axis, as on Android; Noto Sans
/// Kannada ships one static file per weight.
public enum LSFontFamily: String, Sendable, CaseIterable {
    /// Body text, buttons, chips and labels.
    case dmSans = "dm_sans"
    /// Titles, the brand name, top bars and reader paragraphs.
    case manrope
    /// Every style when the app language is Kannada (Latin fonts have no Kannada glyphs).
    case notoSansKannada = "noto_sans_kannada"

    /// PostScript name of the default (regular) font of the family.
    public var postScriptName: String {
        switch self {
        case .dmSans: "DMSans-9ptRegular"
        case .manrope: "Manrope-ExtraLight"
        case .notoSansKannada: "NotoSansKannada-Regular"
        }
    }

    /// PostScript name of the static file for `weight`, for families shipped as one file per weight.
    /// CoreText applies neither a `wght` variation nor the named instances of the variable Noto Sans
    /// Kannada, and iOS has its own copy with fewer weights, so the app ships static files
    /// (`Tools/instance-noto-kannada.py`).
    public func instanceName(_ weight: LSFontWeight) -> String? {
        switch self {
        case .dmSans, .manrope: nil
        case .notoSansKannada: "NotoSansKannada-\(weight.instanceSuffix)"
        }
    }

    /// The bundled file holding `weight`.
    func fileName(_ weight: LSFontWeight) -> String {
        switch self {
        case .dmSans, .manrope: rawValue
        case .notoSansKannada: "\(rawValue)_\(weight.instanceSuffix.lowercased())"
        }
    }
}

/// Weights as values of the OpenType `wght` axis.
public enum LSFontWeight: CGFloat, Sendable, CaseIterable {
    case regular = 400
    case medium = 500
    case semibold = 600
    case bold = 700
    case extraBold = 800
}

public enum LSFonts {
    /// The OpenType tag 'wght' as a number, the key CoreText uses for the weight axis.
    private static let weightAxisTag = 0x7767_6874
    private static let logger = Logger(subsystem: "LittleStoryKit", category: "Fonts")

    /// Fonts are made from the bundled files' descriptors, not looked up by name, so a system font
    /// with the same PostScript name (iOS ships its own Noto Sans Kannada) can never replace them.
    /// `nonisolated(unsafe)`: the table is written once by the lazy initializer, and CoreText font
    /// descriptors are immutable and thread-safe, though not marked Sendable.
    private nonisolated(unsafe) static let descriptors: [String: CTFontDescriptor] = {
        var table: [String: CTFontDescriptor] = [:]
        let names = Set(LSFontFamily.allCases.flatMap { family in LSFontWeight.allCases.map(family.fileName) })
        for name in names {
            guard let url = Bundle.module.url(forResource: name, withExtension: "ttf"),
                  let found = CTFontManagerCreateFontDescriptorsFromURL(url as CFURL) as? [CTFontDescriptor],
                  let descriptor = found.first
            else {
                logger.error("Missing or unreadable font file \(name, privacy: .public)")
                continue
            }
            table[name] = descriptor
        }
        return table
    }()

    /// Families whose files are all present and readable.
    public static var availableFamilies: Set<LSFontFamily> {
        Set(LSFontFamily.allCases.filter { family in
            LSFontWeight.allCases.allSatisfy { descriptors[family.fileName($0)] != nil }
        })
    }

    /// The family at `weight` and `size` points. Falls back to the system font if a file is missing.
    public static func font(_ family: LSFontFamily, weight: LSFontWeight, size: CGFloat) -> UIFont {
        guard let descriptor = descriptors[family.fileName(weight)] else {
            return UIFont.systemFont(ofSize: size, weight: weight.systemWeight)
        }
        let base = CTFontCreateWithFontDescriptor(descriptor, size, nil)
        guard family.instanceName(weight) == nil else {
            return base as UIFont
        }
        // Variable file: copy the default instance with the weight axis set.
        let varied = CTFontDescriptorCreateCopyWithVariation(
            CTFontCopyFontDescriptor(base),
            NSNumber(value: weightAxisTag) as CFNumber,
            weight.rawValue,
        )
        return CTFontCreateCopyWithAttributes(base, size, nil, varied) as UIFont
    }
}

extension LSFontWeight {
    /// The OpenType instance name for this weight.
    var instanceSuffix: String {
        switch self {
        case .regular: "Regular"
        case .medium: "Medium"
        case .semibold: "SemiBold"
        case .bold: "Bold"
        case .extraBold: "ExtraBold"
        }
    }

    var systemWeight: UIFont.Weight {
        switch self {
        case .regular: .regular
        case .medium: .medium
        case .semibold: .semibold
        case .bold: .bold
        case .extraBold: .heavy
        }
    }
}
