import CoreUI
import Domain
@testable import FeatureOnboarding
import Foundation
import Testing

@MainActor
struct OnboardingViewModelTests {
    @Test("Continue walks the three slides, then the last button goes to Setup")
    func continueThroughSlides() async {
        let viewModel = OnboardingViewModel()
        #expect(viewModel.state.slides.count == 3)
        #expect(viewModel.state.current.action == UIText(CoreUIStrings.actionContinue))
        viewModel.onContinue()
        viewModel.onContinue()
        #expect(viewModel.state.isLast)
        #expect(viewModel.state.current.action == UIText(OnboardingStrings.getStarted))
        viewModel.onContinue()
        #expect(await viewModel.effects.first() == .goToSetup)
    }

    @Test("Skip goes to Setup from any slide")
    func skip() async {
        let viewModel = OnboardingViewModel()
        viewModel.onSkip()
        #expect(viewModel.state.page == 0)
        #expect(await viewModel.effects.first() == .goToSetup)
    }

    @Test("Swiping clamps to the slides and updates the pager label")
    func pageChanged() {
        let viewModel = OnboardingViewModel()
        viewModel.onPageChanged(7)
        #expect(viewModel.state.page == 2)
        viewModel.onPageChanged(-1)
        #expect(viewModel.state.page == 0)
        #expect(viewModel.state.pagerLabel.resolved(for: Locale(identifier: "en")) == "Slide 1 of 3")
    }
}
