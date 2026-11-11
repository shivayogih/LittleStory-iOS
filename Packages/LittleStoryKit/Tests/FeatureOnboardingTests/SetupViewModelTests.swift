import Common
import CoreUI
import Domain
@testable import FeatureOnboarding
import Foundation
import Testing
import TestSupport

@MainActor
struct SetupViewModelTests {
    private let profiles = FakeProfiles()
    private let preferences = FakePreferences()

    private func makeViewModel(uiLanguageTag: String = "en", childID: String? = nil) -> SetupViewModel {
        SetupViewModel(profiles: profiles, preferences: preferences, uiLanguageTag: uiLanguageTag, childID: childID)
    }

    @Test("A new profile starts in the app language with the default age and duration")
    func defaults() {
        let state = makeViewModel(uiLanguageTag: "kn").state
        #expect(state.languageTag == "kn")
        #expect(state.age == AppConfig.Setup.defaultAge)
        #expect(state.durationMinutes == AppConfig.Setup.defaultDurationMinutes)
        #expect(!state.isEditing)
        #expect(state.actionTitle == UIText(OnboardingStrings.ctaCreate))
    }

    @Test("The button names the child once a name is typed")
    func namedAction() {
        let viewModel = makeViewModel()
        viewModel.onNameChange("  Asha ")
        #expect(viewModel.state.actionTitle == OnboardingStrings.ctaCreateNamed(.text("Asha")))
        #expect(viewModel.state.actionTitle.resolved(for: Locale(identifier: "en")) == "Create Asha’s profile")
    }

    @Test("Names are cut at the maximum length")
    func nameLimit() {
        let viewModel = makeViewModel()
        viewModel.onNameChange(String(repeating: "a", count: AppConfig.Setup.nameMaxCharacters + 5))
        #expect(viewModel.state.name.count == AppConfig.Setup.nameMaxCharacters)
    }

    @Test("An empty name shows an error and saves nothing")
    func emptyName() async {
        let viewModel = makeViewModel()
        viewModel.onNameChange("   ")
        await viewModel.onSubmit()
        #expect(viewModel.state.nameError == UIText(OnboardingStrings.errorNameEmpty))
        #expect(profiles.all.current.isEmpty)
        #expect(!preferences.firstRun.current)
    }

    @Test("Submitting saves the profile, the content language and the finished first run")
    func submit() async {
        let viewModel = makeViewModel()
        viewModel.onNameChange("Asha")
        viewModel.onAvatarSelected(2)
        viewModel.onAgeSelected(8)
        viewModel.onInterestToggled("space")
        viewModel.onInterestToggled("music")
        viewModel.onInterestToggled("music")
        viewModel.onDurationSelected(15)
        viewModel.onLanguageSelected("kn")
        await viewModel.onSubmit()

        let saved = profiles.all.current
        #expect(saved.count == 1)
        #expect(saved.first?.firstName == "Asha")
        #expect(saved.first?.avatar == AvatarID(2))
        #expect(saved.first?.age == 8)
        #expect(saved.first?.interestIDs == ["space"])
        #expect(saved.first?.defaultDurationMinutes == 15)
        #expect(saved.first?.languageTag == "kn")
        #expect(preferences.language.current == "kn")
        #expect(preferences.firstRun.current)

        var effects: [SetupEffect] = []
        for await effect in viewModel.effects {
            effects.append(effect)
            if effect == .done {
                break
            }
        }
        #expect(effects == [.applyLanguage("kn"), .done])
    }

    @Test("Skip finishes the first run without a profile")
    func skip() async {
        let viewModel = makeViewModel()
        await viewModel.onSkip()
        #expect(profiles.all.current.isEmpty)
        #expect(preferences.firstRun.current)
        #expect(await viewModel.effects.first() == .done)
    }

    @Test("Editing loads the child and saves changes in place")
    func edit() async {
        profiles.all.send([Fixtures.child(id: "c1", firstName: "Asha", age: 6)])
        let viewModel = makeViewModel(childID: "c1")
        #expect(viewModel.state.loading)
        await viewModel.start()
        #expect(!viewModel.state.loading)
        #expect(viewModel.state.name == "Asha")
        #expect(viewModel.state.actionTitle == UIText(OnboardingStrings.ctaSave))
        viewModel.onNameChange("Asha Rao")
        await viewModel.onSubmit()
        #expect(profiles.all.current.map(\.firstName) == ["Asha Rao"])
        #expect(profiles.all.current.first?.id == "c1")
    }
}
