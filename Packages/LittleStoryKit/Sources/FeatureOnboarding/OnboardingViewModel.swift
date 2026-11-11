import CoreUI
import Observation

public struct OnboardingSlide: Sendable, Hashable {
    public let title: UIText
    public let body: UIText
    public let action: UIText
}

public struct OnboardingState: Sendable, Hashable {
    public let slides: [OnboardingSlide]
    public var page: Int

    public var current: OnboardingSlide { slides[page] }
    public var isLast: Bool { page == slides.count - 1 }
    public var pagerLabel: UIText { OnboardingStrings.pagerDescription(.number(page + 1), .number(slides.count)) }
}

public enum OnboardingEffect: Sendable, Equatable {
    case goToSetup
}

/// Three intro slides; Continue advances, the last button and Skip leave for Setup.
@MainActor
@Observable
public final class OnboardingViewModel {
    public private(set) var state: OnboardingState
    @ObservationIgnored public let effects: AsyncStream<OnboardingEffect>
    @ObservationIgnored private let effectSink: AsyncStream<OnboardingEffect>.Continuation

    public init() {
        let slides = zip(OnboardingStrings.titles, OnboardingStrings.bodies).enumerated().map { index, text in
            OnboardingSlide(
                title: UIText(text.0),
                body: UIText(text.1),
                action: UIText(index == OnboardingStrings.titles.count - 1 ? OnboardingStrings.getStarted : CoreUIStrings.actionContinue),
            )
        }
        state = OnboardingState(slides: slides, page: 0)
        let (stream, sink) = AsyncStream<OnboardingEffect>.makeStream()
        effects = stream
        effectSink = sink
    }

    public func onContinue() {
        if state.isLast {
            effectSink.yield(.goToSetup)
        } else {
            state.page += 1
        }
    }

    public func onSkip() {
        effectSink.yield(.goToSetup)
    }

    /// Swiping between slides (the pager also accepts gestures).
    public func onPageChanged(_ page: Int) {
        state.page = min(max(page, 0), state.slides.count - 1)
    }
}
