import Common
import CoreUI
import DesignSystem
import Domain
import SwiftUI

public struct SubscriptionRoute: View {
    @State private var viewModel: SubscriptionViewModel
    private let onBack: () -> Void
    private let onDone: () -> Void

    public init(viewModel: @autoclosure @escaping () -> SubscriptionViewModel, onBack: @escaping () -> Void, onDone: @escaping () -> Void) {
        _viewModel = State(wrappedValue: viewModel())
        self.onBack = onBack
        self.onDone = onDone
    }

    public var body: some View {
        let viewModel = viewModel
        SubscriptionScreen(
            state: viewModel.state,
            onBack: onBack,
            onSelect: viewModel.onSelect,
            onChoose: viewModel.onChoose,
            onDone: {
                viewModel.onDialogDismissed()
                onDone()
            },
        )
        .task { await viewModel.start() }
    }
}

/// SCR-15: night header, benefits in two columns, plan cards and the "illustrative only" note;
/// "Choose … plan" is pinned below and only shows a prototype dialog.
struct SubscriptionScreen: View {
    let state: SubscriptionState
    let onBack: () -> Void
    let onSelect: (String) -> Void
    let onChoose: () -> Void
    let onDone: () -> Void
    @Environment(\.locale) private var locale

    var body: some View {
        VStack(spacing: LSSpacing.none) {
            ScrollView {
                VStack(alignment: .leading, spacing: LSSpacing.none) {
                    header
                    VStack(alignment: .leading, spacing: LSSpacing.lg) {
                        benefits
                        ForEach(state.plans) { plan in
                            PlanCard(plan: plan, selected: plan.id == state.selectedID) { onSelect(plan.id) }
                        }
                        LText(SettingsStrings.Subscription.note)
                            .lsTextStyle(.chip)
                            .foregroundStyle(LSColor.textSecondary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                    }
                    .frame(maxWidth: LayoutTokens.readableMaxWidth)
                    .frame(maxWidth: .infinity)
                    .padding(LSSpacing.screenHorizontal)
                }
            }
            StickyActionBar(state.chooseLabel, enabled: state.selected != nil, identifier: SettingsID.choosePlan, action: onChoose)
        }
        .background(LSColor.background)
        .toolbar(.hidden, for: .navigationBar)
        .alert(
            SettingsStrings.Subscription.dialogTitle.text(locale),
            isPresented: Binding(get: { state.confirmedID != nil }, set: { open in
                if !open {
                    onDone()
                }
            }),
        ) {
            Button(action: onDone) {
                SettingsStrings.Subscription.dialogDone.text(locale)
            }
            .accessibilityIdentifier(SettingsID.planDone)
        } message: {
            if let text = state.confirmedText {
                text.text(locale)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: LSSpacing.sm) {
            LSIconButton(.back, label: CoreUIStrings.actionBack.text(locale), action: onBack)
                .accessibilityIdentifier(SettingsID.subscriptionBack)
            Circle()
                .fill(LSColor.moon)
                .frame(width: LSDimens.subscriptionMoonSize, height: LSDimens.subscriptionMoonSize)
                .frame(maxWidth: .infinity)
                .accessibilityHidden(true)
            LText(SettingsStrings.Subscription.kicker)
                .lsTextStyle(.heroKicker)
                .foregroundStyle(LSColor.highlight)
            LText(SettingsStrings.Subscription.title)
                .lsTextStyle(.heroTitle)
                .foregroundStyle(LSColor.onNight)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier(SettingsID.subscriptionTitle)
            LText(SettingsStrings.Subscription.body)
                .lsTextStyle(.body)
                .foregroundStyle(LSColor.secondaryContainer)
        }
        .padding(LSSpacing.screenHorizontal)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LSColor.nightSurface)
    }

    private var benefits: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), alignment: .topLeading), count: SubscriptionLayout.benefitColumns),
            alignment: .leading,
            spacing: LSSpacing.sm,
        ) {
            ForEach(SettingsStrings.Subscription.benefits, id: \.self) { benefit in
                HStack(alignment: .top, spacing: LSSpacing.xs) {
                    LSIconView(.check, size: LSDimens.iconSizeSmall)
                        .foregroundStyle(LSColor.success)
                    LText(benefit)
                        .lsTextStyle(.chip)
                        .foregroundStyle(LSColor.textPrimary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .combine)
            }
        }
    }
}

/// SCR-15 lays the benefits out in two columns.
private enum SubscriptionLayout {
    static let benefitColumns = 2
}

private struct PlanCard: View {
    let plan: Plan
    let selected: Bool
    let onSelect: () -> Void
    @Environment(\.locale) private var locale

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: LSSpacing.md) {
                VStack(alignment: .leading, spacing: LSSpacing.xxs) {
                    HStack(spacing: LSSpacing.sm) {
                        LText(plan.name)
                            .lsTextStyle(.itemTitle)
                            .foregroundStyle(LSColor.textPrimary)
                        if plan.bestValue {
                            LText(SettingsStrings.Subscription.bestValue)
                                .lsTextStyle(.eyebrow)
                                .foregroundStyle(LSColor.textPrimary)
                                .padding(.horizontal, LSSpacing.sm)
                                .padding(.vertical, LSSpacing.xxs)
                                .background(LSColor.highlight, in: .capsule)
                        }
                    }
                    LText(plan.period)
                        .lsTextStyle(.chip)
                        .foregroundStyle(LSColor.textSecondary)
                }
                .multilineTextAlignment(.leading)
                Spacer(minLength: LSSpacing.sm)
                Text(plan.price(locale: locale))
                    .lsTextStyle(.topBarTitle)
                    .foregroundStyle(LSColor.primary)
            }
            .padding(LSSpacing.lg)
            .background(selected ? LSColor.secondaryContainer : LSColor.surface, in: .rect(cornerRadius: LSRadius.large))
            .overlay(
                RoundedRectangle(cornerRadius: LSRadius.large)
                    .strokeBorder(
                        selected ? LSColor.accent : LSColor.outline,
                        lineWidth: selected ? LSDimens.selectedBorderWidth : LSDimens.borderWidth,
                    ),
            )
        }
        .buttonStyle(LSPressStyle())
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityIdentifier(SettingsID.plan(plan.id))
    }
}
