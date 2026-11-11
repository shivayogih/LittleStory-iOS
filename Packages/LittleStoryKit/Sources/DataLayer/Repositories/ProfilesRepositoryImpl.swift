import Domain
import Foundation

public struct ProfilesRepositoryImpl: ProfilesRepository {
    private let store: LittleStore
    private let preferences: PreferencesStore
    private let newID: @Sendable () -> String

    public init(store: LittleStore, preferences: PreferencesStore, newID: @escaping @Sendable () -> String = { UUID().uuidString }) {
        self.store = store
        self.preferences = preferences
        self.newID = newID
    }

    public func profiles() -> AsyncStream<[ChildProfile]> {
        store.observe(.profiles) { actor in await actor.profiles() }
    }

    /// The chosen child, or the first profile when none is chosen or the chosen one was deleted.
    public func activeProfile() -> AsyncStream<ChildProfile?> {
        combineLatest(profiles(), preferences.observe { $0.string(.activeProfileID) })
            .map { profiles, activeID in profiles.first { $0.id == activeID } ?? profiles.first }
            .removeDuplicates()
    }

    public func create(_ draft: ChildProfileDraft) async -> ChildProfile {
        let profile = ChildProfile(
            id: newID(),
            firstName: draft.firstName.trimmingCharacters(in: .whitespacesAndNewlines),
            age: draft.age,
            avatar: draft.avatar,
            interestIDs: draft.interestIDs,
            languageTag: draft.languageTag,
            defaultDurationMinutes: draft.defaultDurationMinutes,
        )
        await store.write(.profiles) { actor in await actor.upsert(profile) }
        if preferences.string(.activeProfileID) == nil {
            preferences.set([.activeProfileID: profile.id])
        }
        return profile
    }

    public func update(_ profile: ChildProfile) async {
        await store.write(.profiles) { actor in await actor.upsert(profile) }
    }

    /// Removes the child with their favourites, progress and created stories.
    public func delete(profileID: String) async {
        await store.write(.profiles, .savedStories, .progress, .generatedStories) { actor in
            await actor.deleteChild(id: profileID)
        }
        if preferences.string(.activeProfileID) == profileID {
            preferences.set([.activeProfileID: nil])
        }
    }

    public func setActive(profileID: String) async {
        preferences.set([.activeProfileID: profileID])
    }
}
