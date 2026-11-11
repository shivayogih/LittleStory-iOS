import CoreText
import Foundation
import OSLog
import UIKit

/// The bundled typefaces (SIL Open Font License, texts in `Resources/Licenses`). All three are
/// variable fonts: one file per family, and the weight is set on the `wght` axis, as on Android.
public enum LSFontFamily: String, Sendable, CaseIterable {
    /// Body text, buttons, chips and labels.
    case dmSans = "dm_sans"
    /// Titles, the brand name, top bars and reader paragraphs.
    case manrope
    /// Every style when the app language is Kannada (Latin fonts have no Kannada glyphs).
    case notoSansKannada = "noto_sans_kannada"

    /// PostScript name of the file's default instance; variations are applied on top of it.
    public var postScriptName: String {
        switch self {
        case .dmSans: "DMSans-9ptRegular"
        case .manrope: "Manrope-ExtraLight"
        case .notoSansKannada: "NotoSansKannada-Regular"
        }
    }

    var fileURL: URL? {
        Bundle.module.url(forResource: rawValue, withExtension: "ttf")
    }
}

/// Weights as values of the OpenType `wght` axis.
public enum LSFontWeight: CGFloat, Sendable {
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

    /// Registers the bundled fonts for this process. Safe to call many times; the work runs once.
    public static func register() {
        _ = registration
    }

    /// Families that registered (or were already registered).
    public static var registeredFamilies: Set<LSFontFamily> {
        registration
    }

    private static let registration: Set<LSFontFamily> = {
        var registered = Set<LSFontFamily>()
        for family in LSFontFamily.allCases {
            guard let url = family.fileURL else {
                logger.error("Missing font file \(family.rawValue, privacy: .public)")
                continue
            }
            var error: Unmanaged<CFError>?
            let alreadyAvailable = UIFont(name: family.postScriptName, size: UIFont.systemFontSize) != nil
            if alreadyAvailable || CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error) {
                registered.insert(family)
            } else {
                let reason = error?.takeRetainedValue().localizedDescription ?? "unknown"
                logger.error("Could not register \(family.rawValue, privacy: .public): \(reason, privacy: .public)")
            }
        }
        return registered
    }()

    /// The family at `weight` and `size` points. Falls back to the system font if the file is missing.
    public static func font(_ family: LSFontFamily, weight: LSFontWeight, size: CGFloat) -> UIFont {
        register()
        let attributes: [UIFontDescriptor.AttributeName: Any] = [
            .name: family.postScriptName,
            UIFontDescriptor.AttributeName(rawValue: kCTFontVariationAttribute as String): [weightAxisTag: weight.rawValue],
        ]
        let font = UIFont(descriptor: UIFontDescriptor(fontAttributes: attributes), size: size)
        guard font.fontName.hasPrefix(family.postScriptName.prefix { $0 != "-" }) else {
            return UIFont.systemFont(ofSize: size, weight: weight.systemWeight)
        }
        return font
    }
}

extension LSFontWeight {
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
