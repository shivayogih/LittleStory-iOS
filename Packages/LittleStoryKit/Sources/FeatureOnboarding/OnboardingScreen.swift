import CoreUI
import DesignSystem
import SwiftUI

/// Owns the view model and turns its effects into navigation.
public struct OnboardingRoute: View {
    @State private var viewModel = OnboardingViewModel()
    private let onFinished: () -> Void

    public init(onFinished: @escaping () -> Void) {
        self.onFinished = onFinished
    }

    public var body: some View {
        OnboardingScreen(
            state: viewModel.state,
            onContinue: viewModel.onContinue,
            onSkip: viewModel.onSkip,
            onPageChanged: viewModel.onPageChanged,
        )
        .task {
            for await effect in viewModel.effects {
                switch effect {
                case .goToSetup: onFinished()
                }
            }
        }
    }
}

/// Night scene on top, a cream sheet with the slide text, dots and button below (SCR-01).
/// On wide windows the scene and the sheet sit side by side.
struct OnboardingScreen: View {
    let state: OnboardingState
    let onContinue: () -> Void
    let onSkip: () -> Void
    let onPageChanged: (Int) -> Void
    @Environment(\.layoutClass) private var layoutClass
    @Environment(\.locale) private var locale

    var body: some View {
        Group {
            if layoutClass == .compact {
                VStack(spacing: LSSpacing.none) {
                    NightScene()
                    sheet
                        .background(
                            LSColor.background,
                            in: UnevenRoundedRectangle(topLeadingRadius: LSRadius.sheet, topTrailingRadius: LSRadius.sheet),
                        )
                }
            } else {
                HStack(spacing: LSSpacing.none) {
                    NightScene()
                    sheet
                        .frame(maxWidth: LayoutTokens.readableMaxWidth, maxHeight: .infinity)
                        .background(LSColor.background)
                }
            }
        }
        .background(LSColor.night)
        .overlay(alignment: .top) { topBar }
        .gesture(swipe)
    }

    private var topBar: some View {
        HStack {
            BrandMark(light: true)
            Spacer()
            Button(action: onSkip) {
                CoreUIStrings.actionSkip.text(locale)
                    .lsTextStyle(.button)
                    .foregroundStyle(LSColor.secondaryContainer)
                    .padding(.horizontal, LSSpacing.md)
                    .frame(minHeight: LSDimens.minTouchTarget)
            }
            .accessibilityIdentifier(OnboardingID.skip)
        }
        .padding(.horizontal, LSSpacing.screenHorizontal)
        .frame(minHeight: LSDimens.topBarHeight)
    }

    private var sheet: some View {
        VStack(spacing: LSSpacing.md) {
            LText(OnboardingStrings.eyebrow)
                .lsTextStyle(.eyebrow)
                .foregroundStyle(LSColor.primaryVariantLabel)
            LText(state.current.title)
                .lsTextStyle(.displayOnboarding)
                .foregroundStyle(LSColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier(OnboardingID.title)
            LText(state.current.body)
                .lsTextStyle(.bodyLarge)
                .foregroundStyle(LSColor.textSecondary)
            PagerDots(count: state.slides.count, selected: state.page, label: state.pagerLabel)
                .padding(.vertical, LSSpacing.sm)
            LSButton(state.current.action.text(locale), action: onContinue)
                .accessibilityIdentifier(OnboardingID.continueButton)
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, LSSpacing.screenHorizontal)
        .padding(.top, LSSpacing.xxl)
        .padding(.bottom, LSSpacing.screenBottom)
        .frame(maxWidth: LayoutTokens.readableMaxWidth)
        .frame(maxWidth: .infinity)
    }

    /// Horizontal swipes move between slides, like the Android pager.
    private var swipe: some Gesture {
        DragGesture(minimumDistance: LSSpacing.xxxl).onEnded { value in
            let swipedLeft = value.translation.width < 0
            let rightToLeft = locale.language.characterDirection == .rightToLeft
            onPageChanged(state.page + (swipedLeft != rightToLeft ? 1 : -1))
        }
    }
}

/// Dots for the pager; the active one widens. Read as "Slide n of m".
struct PagerDots: View {
    let count: Int
    let selected: Int
    let label: UIText

    var body: some View {
        HStack(spacing: LSSpacing.xs) {
            ForEach(0 ..< count, id: \.self) { index in
                Capsule()
                    .fill(index == selected ? LSColor.primary : LSColor.outline)
                    .frame(width: index == selected ? LSDimens.pagerDotActiveWidth : LSDimens.pagerDotSize, height: LSDimens.pagerDotSize)
            }
        }
        .accessibilityElement()
        .accessibilityLabel(label)
        .accessibilityIdentifier(OnboardingID.pager)
    }
}

#Preview("Onboarding") {
    AdaptiveRoot {
        OnboardingRoute {}
    }
}
