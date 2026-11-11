import Common
import CoreUI
import Domain
import Observation

public struct SetupState: Sendable, Hashable {
    public var name = ""
    public var nameError: UIText?
    public var avatar = 0
    public var age = AppConfig.Setup.defaultAge
    public var languageTag = SupportedLanguages.fallback.tag
    public var interestIDs: Set<String> = []
    public var durationMinutes = AppConfig.Setup.defaultDurationMinutes
    public var isEditing = false
    public var loading = false

    /// "Create {name}'s profile" once a name is typed, a generic label before, "Save" when editing.
    public var actionTitle: UIText {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if isEditing {
            return UIText(OnboardingStrings.ctaSave)
        }
        return trimmed.isEmpty ? UIText(OnboardingStrings.ctaCreate) : OnboardingStrings.ctaCreateNamed(.text(trimmed))
    }
}

public enum SetupEffect: Sendable, Equatable {
    /// The profile was saved or Setup was skipped; the app decides where to go next.
    case done
    /// The child chose another language: the app applies it at once.
    case applyLanguage(String)
}

/// The child's profile form, for first run and (later) for editing a child from Settings.
@MainActor
@Observable
public final class SetupViewModel {
    public private(set) var state: SetupState
    @ObservationIgnored public let effects: AsyncStream<SetupEffect>
    @ObservationIgnored private let effectSink: AsyncStream<SetupEffect>.Continuation
    @ObservationIgnored private let profiles: any ProfilesRepository
    @ObservationIgnored private let preferences: any PreferencesRepository
    @ObservationIgnored private let childID: String?

    /// - Parameters:
    ///   - uiLanguageTag: the language the app is shown in; a new profile starts with it.
    ///   - childID: the child to edit, or nil for a new profile.
    public init(
        profiles: any ProfilesRepository,
        preferences: any PreferencesRepository,
        uiLanguageTag: String,
        childID: String? = nil,
    ) {
        self.profiles = profiles
        self.preferences = preferences
        self.childID = childID
        var initial = SetupState()
        initial.languageTag = SupportedLanguages.language(forTag: uiLanguageTag).tag
        initial.isEditing = childID != nil
        initial.loading = childID != nil
        state = initial
        let (stream, sink) = AsyncStream<SetupEffect>.makeStream()
        effects = stream
        effectSink = sink
    }

    /// Loads the child being edited; a new profile has nothing to load.
    public func start() async {
        guard let childID else {
            return
        }
        let existing = await profiles.profiles().first()?.first { $0.id == childID }
        if let existing {
            state.name = existing.firstName
            state.avatar = existing.avatar.index
            state.age = existing.age
            state.languageTag = existing.languageTag
            state.interestIDs = existing.interestIDs
            state.durationMinutes = existing.defaultDurationMinutes
        }
        state.loading = false
    }

    public func onNameChange(_ value: String) {
        state.name = String(value.prefix(AppConfig.Setup.nameMaxCharacters))
        state.nameError = nil
    }

    public func onAvatarSelected(_ index: Int) {
        state.avatar = index
    }

    public func onAgeSelected(_ age: Int) {
        state.age = age
    }

    public func onLanguageSelected(_ tag: String) {
        state.languageTag = tag
        effectSink.yield(.applyLanguage(tag))
    }

    public func onInterestToggled(_ id: String) {
        if state.interestIDs.contains(id) {
            state.interestIDs.remove(id)
        } else {
            state.interestIDs.insert(id)
        }
    }

    public func onDurationSelected(_ minutes: Int) {
        state.durationMinutes = minutes
    }

    public func onSubmit() async {
        let draft = ChildProfileDraft(
            firstName: state.name,
            age: state.age,
            avatar: AvatarID(state.avatar),
            interestIDs: state.interestIDs,
            languageTag: state.languageTag,
            defaultDurationMinutes: state.durationMinutes,
        )
        let errors = ProfileValidator.validate(draft)
        if !errors.isEmpty {
            state.nameError = Self.nameError(errors)
            return
        }
        if let childID {
            if var existing = await profiles.profiles().first()?.first(where: { $0.id == childID }) {
                existing.firstName = draft.firstName.trimmingCharacters(in: .whitespacesAndNewlines)
                existing.age = draft.age
                existing.avatar = draft.avatar
                existing.interestIDs = draft.interestIDs
                existing.languageTag = draft.languageTag
                existing.defaultDurationMinutes = draft.defaultDurationMinutes
                await profiles.update(existing)
            }
        } else {
            _ = await profiles.create(draft)
        }
        await preferences.setContentLanguageTag(draft.languageTag)
        await preferences.setFirstRunCompleted(true)
        effectSink.yield(.done)
    }

    /// "Skip for now": no profile is saved but the first run counts as done.
    public func onSkip() async {
        await preferences.setFirstRunCompleted(true)
        effectSink.yield(.done)
    }

    private static func nameError(_ errors: Set<ProfileError>) -> UIText? {
        if errors.contains(.nameEmpty) {
            return UIText(OnboardingStrings.errorNameEmpty)
        }
        if errors.contains(.nameTooLong) {
            return OnboardingStrings.errorNameTooLong(.number(AppConfig.Setup.nameMaxCharacters))
        }
        return nil
    }
}
