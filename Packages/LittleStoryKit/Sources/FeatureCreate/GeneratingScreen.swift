import CoreUI
import DesignSystem
import SwiftUI

/// Where Generating sends the user.
public struct GeneratingNavigation {
    public let ready: (String) -> Void
    public let backToIdea: () -> Void

    public init(ready: @escaping (String) -> Void, backToIdea: @escaping () -> Void) {
        self.ready = ready
        self.backToIdea = backToIdea
    }
}

public struct GeneratingRoute: View {
    @State private var viewModel: GeneratingViewModel
    private let navigation: GeneratingNavigation

    public init(viewModel: @autoclosure @escaping () -> GeneratingViewModel, navigation: GeneratingNavigation) {
        _viewModel = State(wrappedValue: viewModel())
        self.navigation = navigation
    }

    public var body: some View {
        let viewModel = viewModel
        GeneratingScreen(
            state: viewModel.state,
            onClose: viewModel.onClose,
            onTryAgain: { Task { await viewModel.onTryAgain() } },
            onBackToIdea: navigation.backToIdea,
        )
        .task { await viewModel.start() }
        .task {
            for await effect in viewModel.effects {
                switch effect {
                case let .ready(storyID): navigation.ready(storyID)
                }
            }
        }
    }
}

/// SCR-08: a night screen with the magic book, progress and the three steps.
struct GeneratingScreen: View {
    let state: GeneratingState
    let onClose: () -> Void
    let onTryAgain: () -> Void
    let onBackToIdea: () -> Void
    @Environment(\.locale) private var locale

    var body: some View {
        ScrollView {
            VStack(spacing: LSSpacing.xl) {
                MagicBook()
                    .padding(.top, LSSpacing.xxxl)
                LText(state.eyebrow)
                    .lsTextStyle(.eyebrow)
                    .foregroundStyle(LSColor.highlight)
                LText(CreateStrings.generatingTitle)
                    .lsTextStyle(.displaySetup)
                    .foregroundStyle(LSColor.onNight)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier(CreateID.generatingTitle)
                LText(CreateStrings.generatingBody)
                    .lsTextStyle(.bodyLarge)
                    .foregroundStyle(LSColor.accent)
                    .multilineTextAlignment(.center)
                if state.paused {
                    paused
                } else {
                    progress
                    steps
                    LText(CreateStrings.generatingFootnote)
                        .lsTextStyle(.chip)
                        .foregroundStyle(LSColor.accent)
                }
                LText(CreateStrings.generatingSimulated)
                    .lsTextStyle(.chip)
                    .foregroundStyle(LSColor.accent)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, LSSpacing.xxl)
            .padding(.bottom, LSSpacing.screenBottom)
            .frame(maxWidth: LayoutTokens.readableMaxWidth)
            .frame(maxWidth: .infinity)
        }
        .background(LSColor.night.ignoresSafeArea())
        .overlay(alignment: .topTrailing) {
            if !state.paused {
                LSIconButton(.close, label: CreateStrings.generatingClose.text(locale), action: onClose)
                    .accessibilityIdentifier(CreateID.generatingClose)
                    .padding(.horizontal, LSSpacing.lg)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
    }

    private var progress: some View {
        VStack(spacing: LSSpacing.sm) {
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(LSColor.nightSurface)
                    Capsule()
                        .fill(LinearGradient(
                            colors: [LSColor.generationGradient.start, LSColor.generationGradient.end],
                            startPoint: .leading,
                            endPoint: .trailing,
                        ))
                        .frame(width: proxy.size.width * state.fraction)
                }
            }
            .frame(height: LSDimens.progressBarHeight)
            LText(state.percentLabel)
                .lsTextStyle(.button)
                .foregroundStyle(LSColor.onNight)
                .accessibilityIdentifier(CreateID.generatingPercent)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(UIText(CreateStrings.generatingTitle))
        .accessibilityValue(state.percentLabel.text(locale))
    }

    private var steps: some View {
        VStack(alignment: .leading, spacing: LSSpacing.lg) {
            ForEach(state.steps) { step in
                HStack(spacing: LSSpacing.md) {
                    StageDisc(step: step)
                    LText(step.title)
                        .lsTextStyle(step.status == .active ? .itemTitle : .bodyLarge)
                        .foregroundStyle(step.status == .pending ? LSColor.textSecondary : LSColor.onNight)
                    Spacer(minLength: LSSpacing.none)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(step.title)
                .accessibilityValue(step.statusLabel.text(locale))
            }
        }
    }

    private var paused: some View {
        VStack(spacing: LSSpacing.md) {
            LText(CreateStrings.pausedTitle)
                .lsTextStyle(.homeTitle)
                .foregroundStyle(LSColor.onNight)
            LText(CreateStrings.pausedBody)
                .lsTextStyle(.body)
                .foregroundStyle(LSColor.accent)
                .multilineTextAlignment(.center)
            LSButton(CreateStrings.tryAgain.text(locale), action: onTryAgain)
                .accessibilityIdentifier(CreateID.tryAgain)
            LSButton(CreateStrings.backToIdea.text(locale), variant: .secondary, action: onBackToIdea)
                .accessibilityIdentifier(CreateID.backToIdea)
        }
        .padding(LSSpacing.xl)
        .background(LSColor.nightSurface, in: .rect(cornerRadius: LSRadius.large))
    }
}

/// Numbered disc: a check when done, highlighted while active, outlined while pending.
private struct StageDisc: View {
    let step: GenerationStep

    var body: some View {
        ZStack {
            switch step.status {
            case .done:
                Circle().fill(LSColor.success)
                LSIconView(.check, size: LSDimens.iconSizeSmall).foregroundStyle(LSColor.onNight)
            case .active:
                Circle().fill(LSColor.accent)
                Text(step.number, format: .number).lsTextStyle(.chip).foregroundStyle(LSColor.primary)
            case .pending:
                Circle().strokeBorder(LSColor.textSecondary, lineWidth: LSDimens.borderWidth)
                Text(step.number, format: .number).lsTextStyle(.chip).foregroundStyle(LSColor.textSecondary)
            }
        }
        .frame(width: LSDimens.stageDiscSize, height: LSDimens.stageDiscSize)
        .accessibilityHidden(true)
    }
}

/// Two glowing pages, tilted apart, with a sparkle above.
private struct MagicBook: View {
    var body: some View {
        VStack(spacing: LSSpacing.md) {
            Sparkle()
                .fill(LSColor.highlight)
                .frame(width: LSDimens.sparkleSize * Book.sparkleScale, height: LSDimens.sparkleSize * Book.sparkleScale)
            HStack(spacing: LSSpacing.xs) {
                page.rotationEffect(.degrees(-Book.tilt))
                page.rotationEffect(.degrees(Book.tilt))
            }
            .frame(width: LSDimens.magicBookWidth, height: LSDimens.magicBookHeight)
            .shadow(color: LSColor.moon.opacity(Book.glowOpacity), radius: LSSpacing.xxl)
        }
        .accessibilityHidden(true)
    }

    private var page: some View {
        RoundedRectangle(cornerRadius: LSRadius.medium).fill(LSColor.moon)
    }

    private enum Book {
        static let tilt = 5.0
        static let glowOpacity = 0.5
        static let sparkleScale = 2.0
    }
}
