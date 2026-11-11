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

    /// PostScript name of the file's default instance; variations are applied on top of it.
    public var postScriptName: String {
        switch self {
        case .dmSans: "DMSans-9ptRegular"
        case .manrope: "Manrope-ExtraLight"
        case .notoSansKannada: "NotoSansKannada-Regular"
        }
    }

    /// PostScript name of the instance at `weight`, for families that ship or name their instances.
    /// CoreText applies neither a `wght` variation nor the named instances of the variable Noto Sans
    /// Kannada, so it ships as static files (`Tools/instance-noto-kannada.py`).
    public func instanceName(_ weight: LSFontWeight) -> String? {
        switch self {
        case .dmSans: nil
        case .manrope: "Manrope-\(weight.instanceSuffix)"
        case .notoSansKannada: "NotoSansKannada-\(weight.instanceSuffix)"
        }
    }

    var fileURLs: [URL] {
        switch self {
        case .dmSans, .manrope:
            [Bundle.module.url(forResource: rawValue, withExtension: "ttf")].compactMap(\.self)
        case .notoSansKannada:
            LSFontWeight.allCases.compactMap {
                Bundle.module.url(forResource: "\(rawValue)_\($0.instanceSuffix.lowercased())", withExtension: "ttf")
            }
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
            let urls = family.fileURLs
            guard !urls.isEmpty else {
                logger.error("Missing font files for \(family.rawValue, privacy: .public)")
                continue
            }
            let alreadyAvailable = UIFont(name: family.postScriptName, size: UIFont.systemFontSize) != nil
            if alreadyAvailable || urls.allSatisfy({ register($0) }) {
                registered.insert(family)
            }
        }
        return registered
    }()

    private static func register(_ url: URL) -> Bool {
        var error: Unmanaged<CFError>?
        guard CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error) else {
            let reason = error?.takeRetainedValue().localizedDescription ?? "unknown"
            logger.error("Could not register \(url.lastPathComponent, privacy: .public): \(reason, privacy: .public)")
            return false
        }
        return true
    }

    /// The family at `weight` and `size` points. Falls back to the system font if the file is missing.
    public static func font(_ family: LSFontFamily, weight: LSFontWeight, size: CGFloat) -> UIFont {
        register()
        if let name = family.instanceName(weight) {
            let instance = CTFontCreateWithName(name as CFString, size, nil)
            if (CTFontCopyPostScriptName(instance) as String) == name {
                return instance as UIFont
            }
        }
        // A name-plus-variation descriptor is ignored for some variable fonts, so build the default
        // instance first and then copy it with the weight axis set.
        let base = CTFontCreateWithName(family.postScriptName as CFString, size, nil)
        guard (CTFontCopyPostScriptName(base) as String) == family.postScriptName else {
            return UIFont.systemFont(ofSize: size, weight: weight.systemWeight)
        }
        let descriptor = CTFontDescriptorCreateCopyWithVariation(
            CTFontCopyFontDescriptor(base),
            NSNumber(value: weightAxisTag) as CFNumber,
            weight.rawValue,
        )
        return CTFontCreateCopyWithAttributes(base, size, nil, descriptor) as UIFont
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
