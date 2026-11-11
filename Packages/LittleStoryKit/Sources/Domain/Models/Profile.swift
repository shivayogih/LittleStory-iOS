import Common
import Foundation

/// Which of the drawn avatars a child uses (the design shows three plus an add tile).
public struct AvatarID: Sendable, Hashable, Codable {
    public let index: Int

    public init(_ index: Int) {
        self.index = index
    }
}

/// A child's profile. Data is minimal on purpose (decision D14): no surname, birthday or parent email.
public struct ChildProfile: Sendable, Hashable, Identifiable {
    public let id: String
    public var firstName: String
    public var age: Int
    public var avatar: AvatarID
    public var interestIDs: Set<String>
    public var languageTag: String
    public var defaultDurationMinutes: Int

    public init(
        id: String,
        firstName: String,
        age: Int,
        avatar: AvatarID,
        interestIDs: Set<String>,
        languageTag: String,
        defaultDurationMinutes: Int,
    ) {
        self.id = id
        self.firstName = firstName
        self.age = age
        self.avatar = avatar
        self.interestIDs = interestIDs
        self.languageTag = languageTag
        self.defaultDurationMinutes = defaultDurationMinutes
    }
}

/// Input from the Setup form before it becomes a `ChildProfile`.
public struct ChildProfileDraft: Sendable, Hashable {
    public var firstName: String
    public var age: Int
    public var avatar: AvatarID
    public var interestIDs: Set<String>
    public var languageTag: String
    public var defaultDurationMinutes: Int

    public init(
        firstName: String,
        age: Int,
        avatar: AvatarID,
        interestIDs: Set<String>,
        languageTag: String,
        defaultDurationMinutes: Int,
    ) {
        self.firstName = firstName
        self.age = age
        self.avatar = avatar
        self.interestIDs = interestIDs
        self.languageTag = languageTag
        self.defaultDurationMinutes = defaultDurationMinutes
    }
}

public enum ProfileError: Sendable, Hashable, CaseIterable {
    case nameEmpty
    case nameTooLong
    case ageOutOfRange
    case durationNotAllowed
}

/// Interests are optional in the design, so an empty set is valid.
public enum ProfileValidator {
    public static func validate(_ draft: ChildProfileDraft) -> Set<ProfileError> {
        var errors = Set<ProfileError>()
        let name = draft.firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        if name.isEmpty {
            errors.insert(.nameEmpty)
        }
        if name.count > AppConfig.Setup.nameMaxCharacters {
            errors.insert(.nameTooLong)
        }
        if !AppConfig.Setup.ageRange.contains(draft.age) {
            errors.insert(.ageOutOfRange)
        }
        if !AppConfig.Setup.durationOptionsMinutes.contains(draft.defaultDurationMinutes) {
            errors.insert(.durationNotAllowed)
        }
        return errors
    }
}
