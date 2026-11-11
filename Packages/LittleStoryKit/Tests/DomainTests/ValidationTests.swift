import Common
import Domain
import Testing
import TestSupport

struct ValidationTests {
    @Test("A complete draft has no errors")
    func validDraft() {
        #expect(ProfileValidator.validate(Fixtures.draft()).isEmpty)
    }

    @Test("A blank or whitespace name is refused", arguments: ["", "   ", "\n"])
    func blankName(name: String) {
        #expect(ProfileValidator.validate(Fixtures.draft(firstName: name)) == [.nameEmpty])
    }

    @Test("Names are limited, counting Kannada characters as the user sees them")
    func nameLength() {
        let limit = AppConfig.Setup.nameMaxCharacters
        #expect(ProfileValidator.validate(Fixtures.draft(firstName: String(repeating: "ಅ", count: limit))).isEmpty)
        #expect(ProfileValidator.validate(Fixtures.draft(firstName: String(repeating: "a", count: limit + 1))) == [.nameTooLong])
    }

    @Test("Age and duration must be offered values")
    func ageAndDuration() {
        var draft = Fixtures.draft()
        draft.age = AppConfig.Setup.ageRange.upperBound + 1
        draft.defaultDurationMinutes = 7
        #expect(ProfileValidator.validate(draft) == [.ageOutOfRange, .durationNotAllowed])
    }

    @Test("Interests are optional")
    func noInterests() {
        var draft = Fixtures.draft()
        draft.interestIDs = []
        #expect(ProfileValidator.validate(draft).isEmpty)
    }

    @Test("Prompts must have text and stay within the limit")
    func prompts() {
        let limit = AppConfig.Create.promptMaxCharacters
        #expect(PromptValidator.validate("A dragon who loves dosa") == nil)
        #expect(PromptValidator.validate("  ") == .empty)
        #expect(PromptValidator.validate(String(repeating: "x", count: limit)) == nil)
        #expect(PromptValidator.validate(String(repeating: "x", count: limit + 1)) == .tooLong)
    }

    @Test("Generation stages change at the configured thresholds")
    func stages() {
        let thresholds = AppConfig.Generation.stageThresholdsPercent
        #expect(GenerationStage(percent: 0) == .imagining)
        #expect(GenerationStage(percent: thresholds[0] - 1) == .imagining)
        #expect(GenerationStage(percent: thresholds[0]) == .writing)
        #expect(GenerationStage(percent: thresholds[1] - 1) == .writing)
        #expect(GenerationStage(percent: thresholds[1]) == .preparingNarration)
        #expect(GenerationStage(percent: 100) == .preparingNarration)
    }

    @Test("Browsing without a profile uses the guest id")
    func guestContext() {
        #expect(BrowseContext(child: nil, languageTag: "en").childID == AppConfig.Profiles.guestID)
        #expect(BrowseContext(child: Fixtures.child(id: "child_9"), languageTag: "kn").childID == "child_9")
    }

    @Test("Stories belong to their category and their tags")
    func belongs() {
        let story = Fixtures.story(categoryID: "animals", tags: ["bedtime"])
        #expect(story.belongs(to: "animals"))
        #expect(story.belongs(to: "bedtime"))
        #expect(!story.belongs(to: "space"))
    }
}
