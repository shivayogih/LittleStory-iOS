import DesignSystem
import SwiftUI

/// Rounded search box with a leading magnifier and a clear button once something is typed.
public struct SearchField: View {
    private let query: String
    private let placeholder: UIText
    private let clearLabel: UIText
    private let identifier: String
    private let clearIdentifier: String
    private let onChange: (String) -> Void
    private let onClear: () -> Void
    @Environment(\.locale) private var locale

    public init(
        query: String,
        placeholder: UIText,
        clearLabel: UIText,
        identifier: String,
        clearIdentifier: String,
        onChange: @escaping (String) -> Void,
        onClear: @escaping () -> Void,
    ) {
        self.query = query
        self.placeholder = placeholder
        self.clearLabel = clearLabel
        self.identifier = identifier
        self.clearIdentifier = clearIdentifier
        self.onChange = onChange
        self.onClear = onClear
    }

    public var body: some View {
        HStack(spacing: LSSpacing.sm) {
            LSIconView(.search, size: LSDimens.iconSizeSmall)
                .foregroundStyle(LSColor.textSecondary)
            TextField(
                text: Binding(get: { query }, set: onChange),
                prompt: placeholder.text(locale).foregroundStyle(LSColor.textSecondary),
            ) {
                LText(placeholder)
            }
            .submitLabel(.search)
            .autocorrectionDisabled()
            .lsTextStyle(.body)
            .foregroundStyle(LSColor.textPrimary)
            .accessibilityIdentifier(identifier)
            if !query.isEmpty {
                Button(action: onClear) {
                    LSIconView(.close, label: clearLabel.text(locale), size: LSDimens.iconSizeSmall)
                        .foregroundStyle(LSColor.textSecondary)
                        .frame(minWidth: LSDimens.minTouchTarget, minHeight: LSDimens.minTouchTarget)
                }
                .accessibilityIdentifier(clearIdentifier)
            }
        }
        .padding(.horizontal, LSSpacing.lg)
        .frame(minHeight: LSDimens.inputHeight)
        .background(LSColor.surface, in: .rect(cornerRadius: LSRadius.button))
        .overlay(RoundedRectangle(cornerRadius: LSRadius.button).strokeBorder(LSColor.outline, lineWidth: LSDimens.borderWidth))
    }
}
