import Common
import CoreUI
import Domain
import Observation

/// One child on the Child Profiles screen.
public struct ChildCard: Sendable, Hashable, Identifiable {
    public let id: String
    public let name: String
    public let age: Int
    public let avatarTone: Int
    public let languageName: String
    public let interestIDs: [String]
    public let active: Bool

    /// "6 years · English".
    public var ageLanguage: UIText { SettingsStrings.Children.ageLanguage(.number(age), .text(languageName)) }

    public var editLabel: UIText { SettingsStrings.Children.edit(.text(name)) }
}

public struct ChildProfilesState: Sendable, Hashable {
    public var loading = true
    public var children: [ChildCard] = []
}

/// Child Profiles (SCR-14): list the children, switch the active one, open the edit form.
@MainActor
@Observable
public final class ChildProfilesViewModel {
    public private(set) var state = ChildProfilesState()
    @ObservationIgnored private let profiles: any ProfilesRepository

    public init(profiles: any ProfilesRepository) {
        self.profiles = profiles
    }

    public func start() async {
        for await (all, active) in combineLatest(profiles.profiles(), profiles.activeProfile()) {
            state = ChildProfilesState(
                loading: false,
                children: all.map { child in
                    ChildCard(
                        id: child.id,
                        name: child.firstName,
                        age: child.age,
                        avatarTone: child.avatar.index,
                        languageName: SupportedLanguages.language(forTag: child.languageTag).nativeName,
                        interestIDs: AppConfig.Setup.interestIDs.filter(child.interestIDs.contains),
                        active: child.id == active?.id,
                    )
                },
            )
        }
    }

    public func onSwitch(childID: String) async {
        await profiles.setActive(profileID: childID)
    }
}
