import Foundation
import SwiftData

// SwiftData schema, versioned from day one (LLD §4.2). No relationships, like Android Room: the
// guest key has no profile row, so deleting a child removes its rows explicitly.
// Composite keys are a joined string because SwiftData has no composite primary key.

enum LittleStorySchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            ChildProfileRecord.self,
            SavedStoryRecord.self,
            ReadingProgressRecord.self,
            DownloadRecord.self,
            GeneratedStoryRecord.self,
            NotificationReadRecord.self,
        ]
    }

    @Model
    final class ChildProfileRecord {
        @Attribute(.unique) var id: String
        var firstName: String
        var age: Int
        var avatarIndex: Int
        /// Sorted ids joined with `,`.
        var interestIDs: String
        var languageTag: String
        var defaultDurationMinutes: Int
        /// Insertion order; the profile list is sorted by it.
        var position: Int

        init(
            id: String,
            firstName: String,
            age: Int,
            avatarIndex: Int,
            interestIDs: String,
            languageTag: String,
            defaultDurationMinutes: Int,
            position: Int,
        ) {
            self.id = id
            self.firstName = firstName
            self.age = age
            self.avatarIndex = avatarIndex
            self.interestIDs = interestIDs
            self.languageTag = languageTag
            self.defaultDurationMinutes = defaultDurationMinutes
            self.position = position
        }
    }

    @Model
    final class SavedStoryRecord {
        /// `childID|storyID`.
        @Attribute(.unique) var key: String
        var childID: String
        var storyID: String
        var favourite: Bool
        var downloaded: Bool

        init(childID: String, storyID: String, favourite: Bool, downloaded: Bool) {
            key = StoreKey.child(childID, story: storyID)
            self.childID = childID
            self.storyID = storyID
            self.favourite = favourite
            self.downloaded = downloaded
        }
    }

    @Model
    final class ReadingProgressRecord {
        /// `childID|storyID`.
        @Attribute(.unique) var key: String
        var childID: String
        var storyID: String
        var page: Int
        var listenFraction: Double
        var updatedAt: Date

        init(childID: String, storyID: String, page: Int, listenFraction: Double, updatedAt: Date) {
            key = StoreKey.child(childID, story: storyID)
            self.childID = childID
            self.storyID = storyID
            self.page = page
            self.listenFraction = listenFraction
            self.updatedAt = updatedAt
        }
    }

    @Model
    final class DownloadRecord {
        @Attribute(.unique) var storyID: String
        var sizeBytes: Int64
        /// `DownloadStatus` raw value.
        var status: String
        /// Keeps the Downloads list in the order the parent added stories.
        var startedAt: Date

        init(storyID: String, sizeBytes: Int64, status: String, startedAt: Date) {
            self.storyID = storyID
            self.sizeBytes = sizeBytes
            self.status = status
            self.startedAt = startedAt
        }
    }

    @Model
    final class GeneratedStoryRecord {
        /// `generated_<requestID>`.
        @Attribute(.unique) var id: String
        var childID: String
        var title: String
        var synopsis: String
        var categoryID: String
        var durationMinutes: Int
        var lesson: String
        var paletteID: String
        var motifID: String
        /// Page texts as a JSON array of strings.
        var pagesJSON: Data
        var languageTag: String
        var ageMin: Int
        var ageMax: Int
        var createdAt: Date

        init(
            id: String,
            childID: String,
            title: String,
            synopsis: String,
            categoryID: String,
            durationMinutes: Int,
            lesson: String,
            paletteID: String,
            motifID: String,
            pagesJSON: Data,
            languageTag: String,
            ageMin: Int,
            ageMax: Int,
            createdAt: Date,
        ) {
            self.id = id
            self.childID = childID
            self.title = title
            self.synopsis = synopsis
            self.categoryID = categoryID
            self.durationMinutes = durationMinutes
            self.lesson = lesson
            self.paletteID = paletteID
            self.motifID = motifID
            self.pagesJSON = pagesJSON
            self.languageTag = languageTag
            self.ageMin = ageMin
            self.ageMax = ageMax
            self.createdAt = createdAt
        }
    }

    @Model
    final class NotificationReadRecord {
        @Attribute(.unique) var notificationID: String

        init(notificationID: String) {
            self.notificationID = notificationID
        }
    }
}

enum LittleStoryMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [LittleStorySchemaV1.self]
    }

    static var stages: [MigrationStage] {
        []
    }
}

typealias ChildProfileRecord = LittleStorySchemaV1.ChildProfileRecord
typealias SavedStoryRecord = LittleStorySchemaV1.SavedStoryRecord
typealias ReadingProgressRecord = LittleStorySchemaV1.ReadingProgressRecord
typealias DownloadRecord = LittleStorySchemaV1.DownloadRecord
typealias GeneratedStoryRecord = LittleStorySchemaV1.GeneratedStoryRecord
typealias NotificationReadRecord = LittleStorySchemaV1.NotificationReadRecord

enum StoreKey {
    private static let separator = "|"

    static func child(_ childID: String, story storyID: String) -> String {
        childID + separator + storyID
    }
}
