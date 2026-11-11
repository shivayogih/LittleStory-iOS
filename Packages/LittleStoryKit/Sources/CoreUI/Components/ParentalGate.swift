import Common
import DesignSystem
import SwiftUI

/// Accessibility identifiers for UI tests; never user-facing.
public enum ParentalGateID {
    public static let gate = "parental_gate"
    public static let question = "parental_gate.question"
    public static let answer = "parental_gate.answer"
    public static let clear = "parental_gate.clear"
    public static let submit = "parental_gate.submit"
    public static let cancel = "parental_gate.cancel"
    public static func key(_ digit: Int) -> String { "parental_gate.key.\(digit)" }
}

public extension EnvironmentValues {
    /// Where gate questions come from; the app sets a fixed source only for UI tests.
    @Entry var parentalGateChallenges: any ParentalGateChallenges = RandomParentalGateChallenges()
}

/// Shows `content` only after a grown-up answers the gate; Cancel calls `onCancel` (usually Back).
/// Used for parent-only screens: child profiles, language, plan and privacy (App Store guideline 1.3).
public struct ParentGated<Content: View>: View {
    private let onCancel: () -> Void
    private let content: () -> Content
    @State private var passed = false

    public init(onCancel: @escaping () -> Void, @ViewBuilder content: @escaping () -> Content) {
        self.onCancel = onCancel
        self.content = content
    }

    public var body: some View {
        if passed {
            content()
        } else {
            ScrollView {
                ParentalGateCard(onPassed: { passed = true }, onCancel: onCancel)
                    .frame(maxWidth: LayoutTokens.readableMaxWidth)
                    .frame(maxWidth: .infinity)
                    .padding(LSSpacing.screenHorizontal)
            }
            .background(LSColor.background)
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}

/// The gate itself: a multiplication answered on an in-card keypad, the same in every language.
/// A wrong answer swaps in a new question.
public struct ParentalGateCard: View {
    private let onPassed: () -> Void
    private let onCancel: () -> Void
    @Environment(\.parentalGateChallenges) private var challenges
    @Environment(\.locale) private var locale
    @State private var challenge: ParentalGateChallenge?
    @State private var input = ""
    @State private var wrong = false

    public init(onPassed: @escaping () -> Void, onCancel: @escaping () -> Void) {
        self.onPassed = onPassed
        self.onCancel = onCancel
    }

    public var body: some View {
        let current = challenge ?? challenges.next()
        VStack(alignment: .leading, spacing: LSSpacing.md) {
            LText(CoreUIStrings.ParentalGate.title)
                .lsTextStyle(.topBarTitle)
                .foregroundStyle(LSColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
            LText(CoreUIStrings.ParentalGate.body)
                .lsTextStyle(.bodyLarge)
                .foregroundStyle(LSColor.textSecondary)
            LText(CoreUIStrings.ParentalGate.question(.text(String(current.first)), .text(String(current.second))))
                .lsTextStyle(.topBarTitle)
                .foregroundStyle(LSColor.textPrimary)
                .accessibilityIdentifier(ParentalGateID.question)
            answerBox
            keypad
            LSButton(CoreUIStrings.actionContinue.text(locale)) { submit(current) }
                .disabled(input.isEmpty)
                .keyboardShortcut(.defaultAction)
                .accessibilityIdentifier(ParentalGateID.submit)
            LSButton(CoreUIStrings.ParentalGate.cancel.text(locale), variant: .ghost, action: onCancel)
                .accessibilityIdentifier(ParentalGateID.cancel)
        }
        .padding(LSSpacing.xxl)
        .background(LSColor.surface, in: .rect(cornerRadius: LSRadius.large))
        .lsShadow(.soft)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(ParentalGateID.gate)
        .onAppear {
            if challenge == nil {
                challenge = current
            }
        }
    }

    private var answerBox: some View {
        VStack(alignment: .leading, spacing: LSSpacing.xs) {
            Text(input)
                .lsTextStyle(.topBarTitle)
                .foregroundStyle(LSColor.textPrimary)
                .frame(maxWidth: .infinity, minHeight: LSDimens.inputHeight, alignment: .leading)
                .padding(.horizontal, LSSpacing.lg)
                .overlay(
                    RoundedRectangle(cornerRadius: LSRadius.small)
                        .strokeBorder(wrong ? LSColor.error : LSColor.outline, lineWidth: LSDimens.borderWidth),
                )
                .accessibilityLabel(UIText(CoreUIStrings.ParentalGate.answer))
                .accessibilityValue(input)
                .accessibilityIdentifier(ParentalGateID.answer)
            if wrong {
                LText(CoreUIStrings.ParentalGate.wrong)
                    .lsTextStyle(.chip)
                    .foregroundStyle(LSColor.error)
            }
        }
    }

    private var keypad: some View {
        Grid(horizontalSpacing: LSSpacing.sm, verticalSpacing: LSSpacing.sm) {
            ForEach(GateKeypad.rows, id: \.self) { row in
                GridRow {
                    ForEach(row, id: \.self) { digit in
                        digitKey(digit)
                    }
                }
            }
            GridRow {
                LSButton(CoreUIStrings.ParentalGate.clear.text(locale), variant: .ghost) {
                    input = ""
                }
                .keyboardShortcut(.delete, modifiers: [])
                .accessibilityIdentifier(ParentalGateID.clear)
                digitKey(GateKeypad.lastRowDigit)
                Color.clear.gridCellUnsizedAxes([.horizontal, .vertical])
            }
        }
    }

    private func digitKey(_ digit: Int) -> some View {
        LSButton(Text(digit, format: .number), variant: .secondary) {
            if let current = challenge, input.count < String(current.answer).count + 1 {
                input += String(digit)
            }
            wrong = false
        }
        // Digits can also be typed on an iPad keyboard.
        .keyboardShortcut(KeyEquivalent(Character(String(digit))), modifiers: [])
        .accessibilityIdentifier(ParentalGateID.key(digit))
    }

    private func submit(_ current: ParentalGateChallenge) {
        if current.isAnswered(by: input) {
            onPassed()
        } else {
            wrong = true
            input = ""
            challenge = challenges.next()
        }
    }
}

/// Phone-style keypad: three rows of digits, then Clear, 0 and an empty slot.
private enum GateKeypad {
    static let rows = [[1, 2, 3], [4, 5, 6], [7, 8, 9]]
    static let lastRowDigit = 0
}
