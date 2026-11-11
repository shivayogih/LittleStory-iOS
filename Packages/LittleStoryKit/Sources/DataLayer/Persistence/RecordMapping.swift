import Common
import Domain
import Foundation

// Record ↔ Domain mapping. Only the store actor calls these, so model objects stay inside it.

private enum Interests {
    static let separator: Character = ","

    static func encode(_ ids: Set<String>) -> String {
        ids.sorted().joined(separator: String(separator))
    }

    static func decode(_ text: String) -> Set<String> {
        Set(text.split(separator: separator).map(String.init))
    }
}

extension ChildProfileRecord {
    var domain: ChildProfile {
        ChildProfile(
            id: id,
            firstName: firstName,
            age: age,
            avatar: AvatarID(avatarIndex),
            interestIDs: Interests.decode(interestIDs),
            languageTag: languageTag,
            defaultDurationMinutes: defaultDurationMinutes,
        )
    }

    func apply(_ profile: ChildProfile) {
        firstName = profile.firstName
        age = profile.age
        avatarIndex = profile.avatar.index
        interestIDs = Interests.encode(profile.interestIDs)
        languageTag = profile.languageTag
        defaultDurationMinutes = profile.defaultDurationMinutes
    }
}

extension ReadingProgressRecord {
    var domain: ReadingProgress {
        ReadingProgress(childID: childID, storyID: storyID, page: page, listenFraction: listenFraction, updatedAt: updatedAt)
    }
}

extension DownloadRecord {
    /// An unknown status (a newer app's value) reads as completed: the row exists, so the story is kept.
    var domain: Download {
        Download(storyID: storyID, sizeBytes: sizeBytes, status: DownloadStatus(rawValue: status) ?? .completed)
    }
}

extension GeneratedStoryRecord {
    /// One day in seconds, to turn the creation date into the catalogue's epoch-day field.
    private static let secondsPerDay: TimeInterval = 86400

    convenience init(_ story: Story, childID: String, createdAt: Date) {
        self.init(
            id: story.id,
            childID: childID,
            title: story.title,
            synopsis: story.synopsis,
            categoryID: story.categoryID,
            durationMinutes: story.durationMinutes,
            lesson: story.lesson,
            paletteID: story.art.paletteID,
            motifID: story.art.motifID,
            pagesJSON: (try? JSONEncoder().encode(story.pages.map(\.text))) ?? Data(),
            languageTag: story.resolvedLanguage,
            ageMin: story.ages.lowerBound,
            ageMax: story.ages.upperBound,
            createdAt: createdAt,
        )
    }

    var domain: Story {
        let texts = (try? JSONDecoder().decode([String].self, from: pagesJSON)) ?? []
        let ages = AppConfig.Setup.ageRange
        let lower = ageMin > 0 ? ageMin : ages.lowerBound
        let upper = max(lower, ageMax > 0 ? ageMax : ages.upperBound)
        return Story(
            id: id,
            title: title,
            synopsis: synopsis,
            categoryID: categoryID,
            ages: lower ... upper,
            durationMinutes: durationMinutes,
            lesson: lesson,
            addedEpochDay: Int(createdAt.timeIntervalSince1970 / Self.secondsPerDay),
            art: StoryArtSpec(paletteID: paletteID, motifID: motifID),
            pages: texts.enumerated().map { StoryPage(index: $0.offset, text: $0.element) },
            resolvedLanguage: languageTag,
            origin: .generated,
        )
    }
}
