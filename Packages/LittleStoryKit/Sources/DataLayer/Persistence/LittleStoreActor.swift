import Common
import Domain
import Foundation
import SwiftData

/// Every SwiftData read and write, serialised off the main thread. `@Model` objects never leave
/// this actor: each call takes and returns Domain values, because model objects are not `Sendable`.
@ModelActor
actor LittleStoreActor {
    // MARK: Profiles

    func profiles() -> [ChildProfile] {
        fetch(FetchDescriptor<ChildProfileRecord>(sortBy: [SortDescriptor(\.position)])).map(\.domain)
    }

    /// Inserts a new profile at the end of the list or updates an existing one in place.
    func upsert(_ profile: ChildProfile) {
        if let record = profileRecord(id: profile.id) {
            record.apply(profile)
        } else {
            let last = fetch(FetchDescriptor<ChildProfileRecord>(sortBy: [SortDescriptor(\.position, order: .reverse)])).first
            let record = ChildProfileRecord(
                id: profile.id,
                firstName: "",
                age: profile.age,
                avatarIndex: profile.avatar.index,
                interestIDs: "",
                languageTag: profile.languageTag,
                defaultDurationMinutes: profile.defaultDurationMinutes,
                position: (last?.position ?? 0) + 1,
            )
            record.apply(profile)
            modelContext.insert(record)
        }
        save()
    }

    /// Removes the child and everything kept for them, in one save.
    func deleteChild(id: String) {
        let childID = id
        delete(ChildProfileRecord.self, where: #Predicate { $0.id == childID })
        delete(SavedStoryRecord.self, where: #Predicate { $0.childID == childID })
        delete(ReadingProgressRecord.self, where: #Predicate { $0.childID == childID })
        delete(GeneratedStoryRecord.self, where: #Predicate { $0.childID == childID })
        save()
    }

    // MARK: Favourites

    func favouriteIDs(childID: String) -> Set<String> {
        let descriptor = FetchDescriptor<SavedStoryRecord>(predicate: #Predicate { $0.childID == childID && $0.favourite == true })
        return Set(fetch(descriptor).map(\.storyID))
    }

    func setFavourite(_ favourite: Bool, storyID: String, childID: String) {
        if let record = savedRecord(childID: childID, storyID: storyID) {
            record.favourite = favourite
        } else {
            modelContext.insert(SavedStoryRecord(childID: childID, storyID: storyID, favourite: favourite, downloaded: false))
        }
        save()
    }

    /// Read-modify-write in one actor call, so rapid taps from any screen settle on a consistent value.
    func toggleFavourite(storyID: String, childID: String) -> Bool {
        let favourite = savedRecord(childID: childID, storyID: storyID)?.favourite != true
        setFavourite(favourite, storyID: storyID, childID: childID)
        return favourite
    }

    // MARK: Progress

    func progress(childID: String) -> [ReadingProgress] {
        let descriptor = FetchDescriptor<ReadingProgressRecord>(
            predicate: #Predicate { $0.childID == childID },
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)],
        )
        return fetch(descriptor).map(\.domain)
    }

    func upsert(_ progress: ReadingProgress) {
        let key = StoreKey.child(progress.childID, story: progress.storyID)
        if let record = fetch(FetchDescriptor<ReadingProgressRecord>(predicate: #Predicate { $0.key == key })).first {
            record.page = progress.page
            record.listenFraction = progress.listenFraction
            record.updatedAt = progress.updatedAt
        } else {
            modelContext.insert(ReadingProgressRecord(
                childID: progress.childID,
                storyID: progress.storyID,
                page: progress.page,
                listenFraction: progress.listenFraction,
                updatedAt: progress.updatedAt,
            ))
        }
        save()
    }

    // MARK: Downloads

    func downloads() -> [Download] {
        fetch(FetchDescriptor<DownloadRecord>(sortBy: [SortDescriptor(\.startedAt)])).map(\.domain)
    }

    func upsert(_ download: Download, startedAt: Date) {
        let storyID = download.storyID
        if let record = fetch(FetchDescriptor<DownloadRecord>(predicate: #Predicate { $0.storyID == storyID })).first {
            record.sizeBytes = download.sizeBytes
            record.status = download.status.rawValue
        } else {
            modelContext.insert(DownloadRecord(
                storyID: storyID,
                sizeBytes: download.sizeBytes,
                status: download.status.rawValue,
                startedAt: startedAt,
            ))
        }
        save()
    }

    func removeDownload(storyID: String) {
        delete(DownloadRecord.self, where: #Predicate { $0.storyID == storyID })
        save()
    }

    // MARK: Created stories

    func createdStories(childID: String) -> [Story] {
        let descriptor = FetchDescriptor<GeneratedStoryRecord>(
            predicate: #Predicate { $0.childID == childID },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)],
        )
        return fetch(descriptor).map(\.domain)
    }

    func createdStory(id: String) -> Story? {
        fetch(FetchDescriptor<GeneratedStoryRecord>(predicate: #Predicate { $0.id == id })).first?.domain
    }

    /// Saving the same story id again replaces it, so retrying a request never duplicates it.
    func save(_ story: Story, childID: String, createdAt: Date) {
        let storyID = story.id
        delete(GeneratedStoryRecord.self, where: #Predicate { $0.id == storyID })
        modelContext.insert(GeneratedStoryRecord(story, childID: childID, createdAt: createdAt))
        save()
    }

    // MARK: Notifications

    func readNotificationIDs() -> Set<String> {
        Set(fetch(FetchDescriptor<NotificationReadRecord>()).map(\.notificationID))
    }

    func markNotificationsRead(_ ids: [String]) {
        let known = readNotificationIDs()
        for id in Set(ids).subtracting(known) {
            modelContext.insert(NotificationReadRecord(notificationID: id))
        }
        save()
    }

    // MARK: Everything

    func deleteAll() {
        for model in LittleStorySchemaV1.models {
            deleteAll(of: model)
        }
        save()
    }

    // MARK: Helpers

    private func profileRecord(id: String) -> ChildProfileRecord? {
        fetch(FetchDescriptor<ChildProfileRecord>(predicate: #Predicate { $0.id == id })).first
    }

    private func savedRecord(childID: String, storyID: String) -> SavedStoryRecord? {
        let key = StoreKey.child(childID, story: storyID)
        return fetch(FetchDescriptor<SavedStoryRecord>(predicate: #Predicate { $0.key == key })).first
    }

    private func fetch<Model: PersistentModel>(_ descriptor: FetchDescriptor<Model>) -> [Model] {
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            DataLog.store.error("Fetch failed: \(error.localizedDescription, privacy: .public)")
            return []
        }
    }

    private func delete<Model: PersistentModel>(_ model: Model.Type, where predicate: Predicate<Model>) {
        do {
            try modelContext.delete(model: model, where: predicate)
        } catch {
            DataLog.store.error("Delete failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func deleteAll(of model: any PersistentModel.Type) {
        do {
            try modelContext.delete(model: model)
        } catch {
            DataLog.store.error("Delete failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func save() {
        do {
            try modelContext.save()
        } catch {
            DataLog.store.error("Save failed: \(error.localizedDescription, privacy: .public)")
        }
    }
}
