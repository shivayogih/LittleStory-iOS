import SwiftUI

/// Every icon in the design: 24 × 24 line icons, 1.8 stroke, round caps (Android `ic_*`).
/// The vectors in `Resources/Icons.xcassets` come from the Android drawables through
/// `Tools/convert-icons.py`; back and chevron mirror in right-to-left languages.
public enum LSIcon: String, Sendable, CaseIterable {
    case back
    case bell
    case book
    case check
    case chevron
    case clock
    case close
    case compass
    case download
    case downloadFilled
    case edit
    case forward15
    case heart
    case heartFilled
    case home
    case moon
    case pause
    case play
    case plus
    case rewind15
    case search
    case settings
    case user
    case volume

    /// The template image; tint it with `foregroundStyle`.
    public var image: Image {
        Image(rawValue, bundle: .module)
    }
}

/// An icon at the design size. Pass a label for icons that carry meaning on their own; icons next
/// to text that already says the same thing are hidden from VoiceOver.
public struct LSIconView: View {
    private let icon: LSIcon
    private let label: Text?
    private let size: CGFloat

    public init(_ icon: LSIcon, label: Text? = nil, size: CGFloat = LSDimens.iconSize) {
        self.icon = icon
        self.label = label
        self.size = size
    }

    public var body: some View {
        if let label {
            sized.accessibilityLabel(label)
        } else {
            sized.accessibilityHidden(true)
        }
    }

    private var sized: some View {
        icon.image
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
    }
}
