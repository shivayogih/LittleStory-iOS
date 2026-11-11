import SwiftUI

/// `Text` for a `UIText`, resolved in the app language from the environment's locale.
public struct LText: View {
    private let text: UIText
    @Environment(\.locale) private var locale

    public init(_ text: UIText) {
        self.text = text
    }

    public init(_ key: LocalizedKey) {
        text = UIText(key)
    }

    public var body: Text {
        Text(text.resolved(for: locale))
    }
}

/// Accessibility label from a `UIText`, in the app language.
private struct LocalizedAccessibilityLabel: ViewModifier {
    let text: UIText
    @Environment(\.locale) private var locale

    func body(content: Content) -> some View {
        content.accessibilityLabel(Text(text.resolved(for: locale)))
    }
}

public extension View {
    func accessibilityLabel(_ text: UIText) -> some View {
        modifier(LocalizedAccessibilityLabel(text: text))
    }
}

public extension UIText {
    /// For APIs that take a `Text` (buttons, icon buttons): pass the view's `\.locale`.
    func text(_ locale: Locale) -> Text {
        Text(resolved(for: locale))
    }
}

public extension LocalizedKey {
    /// For APIs that take a `Text` (buttons, icon buttons): pass the view's `\.locale`.
    func text(_ locale: Locale) -> Text {
        UIText(self).text(locale)
    }
}
