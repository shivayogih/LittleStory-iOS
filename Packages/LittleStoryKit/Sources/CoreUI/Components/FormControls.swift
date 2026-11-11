import DesignSystem
import SwiftUI

/// A pill chip. Multi-select chips show a check when selected (Setup interests); single-select
/// chips fill with the primary colour (Discover filters).
public struct LSChip: View {
    private let title: UIText
    private let selected: Bool
    private let multiSelect: Bool
    private let action: () -> Void

    public init(_ title: UIText, selected: Bool, multiSelect: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.selected = selected
        self.multiSelect = multiSelect
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: LSSpacing.xs) {
                if multiSelect, selected {
                    LSIconView(.check, size: LSDimens.iconSizeSmall)
                }
                LText(title).lsTextStyle(.chip)
            }
            .foregroundStyle(foreground)
            .padding(.horizontal, LSSpacing.lg)
            .frame(minHeight: LSDimens.minTouchTarget)
            .background(background, in: .capsule)
            .overlay(Capsule().strokeBorder(border, lineWidth: LSDimens.borderWidth))
            .contentShape(.capsule)
        }
        .buttonStyle(LSPressStyle())
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private var foreground: Color {
        selected && !multiSelect ? LSColor.onPrimary : LSColor.textPrimary
    }

    private var background: Color {
        switch (selected, multiSelect) {
        case (true, false): LSColor.primary
        case (true, true): LSColor.secondaryContainer
        default: LSColor.surface
        }
    }

    private var border: Color {
        switch (selected, multiSelect) {
        case (true, false): LSColor.primary
        case (true, true): LSColor.accent
        default: LSColor.outline
        }
    }
}

/// Equal segments on a muted track; the selected one is a raised white pill.
public struct LSSegmentedControl<Option: Hashable>: View {
    private let options: [Option]
    private let selected: Option
    private let label: (Option) -> UIText
    private let identifier: (Option) -> String
    private let onSelect: (Option) -> Void

    public init(
        options: [Option],
        selected: Option,
        label: @escaping (Option) -> UIText,
        identifier: @escaping (Option) -> String,
        onSelect: @escaping (Option) -> Void,
    ) {
        self.options = options
        self.selected = selected
        self.label = label
        self.identifier = identifier
        self.onSelect = onSelect
    }

    public var body: some View {
        HStack(spacing: LSSpacing.xs) {
            ForEach(options, id: \.self) { option in
                let isSelected = option == selected
                Button {
                    onSelect(option)
                } label: {
                    LText(label(option))
                        .lsTextStyle(.chip)
                        .foregroundStyle(LSColor.textPrimary)
                        .frame(maxWidth: .infinity, minHeight: LSDimens.minTouchTarget)
                        .background(isSelected ? LSColor.surface : .clear, in: .rect(cornerRadius: LSRadius.small))
                        .lsShadow(isSelected ? .soft : .flat)
                        .contentShape(.rect)
                }
                .buttonStyle(LSPressStyle())
                .accessibilityAddTraits(isSelected ? .isSelected : [])
                .accessibilityIdentifier(identifier(option))
            }
        }
        .padding(LSDimens.segmentedInset)
        .background(LSColor.surfaceMuted, in: .rect(cornerRadius: LSRadius.button))
    }
}

/// Text field with a label above and an error line below.
public struct LSTextField: View {
    private let label: UIText
    private let placeholder: UIText
    private let error: UIText?
    private let identifier: String
    @Binding private var text: String
    @Environment(\.locale) private var locale
    @FocusState private var focused: Bool

    public init(_ label: UIText, text: Binding<String>, placeholder: UIText, error: UIText?, identifier: String) {
        self.label = label
        _text = text
        self.placeholder = placeholder
        self.error = error
        self.identifier = identifier
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: LSSpacing.xs) {
            FieldLabel(label)
            TextField(text: $text, prompt: placeholder.text(locale).foregroundStyle(LSColor.textSecondary)) {
                LText(label)
            }
            .focused($focused)
            .textInputAutocapitalization(.words)
            .autocorrectionDisabled()
            .lsTextStyle(.itemTitle)
            .foregroundStyle(LSColor.textPrimary)
            .padding(.horizontal, LSSpacing.lg)
            .frame(minHeight: LSDimens.inputHeight)
            .background(LSColor.surface, in: .rect(cornerRadius: LSRadius.button))
            .overlay(
                RoundedRectangle(cornerRadius: LSRadius.button)
                    .strokeBorder(borderColor, lineWidth: focused ? LSDimens.selectedBorderWidth : LSDimens.borderWidth),
            )
            .accessibilityIdentifier(identifier)
            if let error {
                LText(error)
                    .lsTextStyle(.chip)
                    .foregroundStyle(LSColor.error)
            }
        }
    }

    private var borderColor: Color {
        if error != nil {
            return LSColor.error
        }
        return focused ? LSColor.primary : LSColor.outline
    }
}

/// Small muted label above a form control.
public struct FieldLabel: View {
    private let text: UIText

    public init(_ text: UIText) {
        self.text = text
    }

    public var body: some View {
        LText(text)
            .lsTextStyle(.chip)
            .foregroundStyle(LSColor.textSecondary)
    }
}

/// A menu that looks like a form field: label above, current value and a chevron.
public struct LSSelect<Option: Hashable>: View {
    private let label: UIText
    private let options: [Option]
    private let selected: Option
    private let title: (Option) -> UIText
    private let identifier: String
    private let onSelect: (Option) -> Void

    public init(
        _ label: UIText,
        options: [Option],
        selected: Option,
        title: @escaping (Option) -> UIText,
        identifier: String,
        onSelect: @escaping (Option) -> Void,
    ) {
        self.label = label
        self.options = options
        self.selected = selected
        self.title = title
        self.identifier = identifier
        self.onSelect = onSelect
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: LSSpacing.xs) {
            FieldLabel(label)
            Menu {
                ForEach(options, id: \.self) { option in
                    Button {
                        onSelect(option)
                    } label: {
                        LText(title(option))
                    }
                }
            } label: {
                HStack {
                    LText(title(selected))
                        .lsTextStyle(.itemTitle)
                        .foregroundStyle(LSColor.textPrimary)
                    Spacer(minLength: LSSpacing.sm)
                    LSIconView(.chevron, size: LSDimens.iconSizeSmall)
                        .rotationEffect(.degrees(SelectChevron.downwards))
                        .foregroundStyle(LSColor.textSecondary)
                }
                .padding(.horizontal, LSSpacing.lg)
                .frame(minHeight: LSDimens.inputHeight)
                .background(LSColor.surface, in: .rect(cornerRadius: LSRadius.button))
                .overlay(RoundedRectangle(cornerRadius: LSRadius.button).strokeBorder(LSColor.outline, lineWidth: LSDimens.borderWidth))
            }
            .accessibilityIdentifier(identifier)
        }
    }
}

/// The chevron icon points to the trailing side; a menu shows it pointing down.
/// Outside `LSSelect` because generic types cannot hold static stored properties.
private enum SelectChevron {
    static let downwards = 90.0
}
