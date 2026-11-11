import Domain

/// Mock inbox: items come from `Mock/notifications_{tag}.json`; English defines the ids and
/// structure and a translation overrides text per item. Read state is kept in the local store.
public final class NotificationsRepositoryImpl: NotificationsRepository {
    private let source: any MockContentSource
    private let store: LittleStore

    public init(source: any MockContentSource, store: LittleStore) {
        self.source = source
        self.store = store
    }

    public func notifications(languageTag: String) -> AsyncStream<[NotificationItem]> {
        let items = entries(language: ContentLanguage.resolve(languageTag))
        return store.observe(.notificationRead) { actor in await actor.readNotificationIDs() }
            .map { readIDs in
                items.map { item in
                    var item = item
                    item.read = readIDs.contains(item.id)
                    return item
                }
            }
    }

    public func markRead(id: String) async {
        await store.write(.notificationRead) { actor in await actor.markNotificationsRead([id]) }
    }

    public func markAllRead() async {
        let ids = baseEntries().map(\.id)
        await store.write(.notificationRead) { actor in await actor.markNotificationsRead(ids) }
    }

    private func baseEntries() -> [NotificationEntry] {
        source.decode(NotificationsFile.self, from: MockFile.notifications(ContentLanguage.fallback))?.notifications ?? []
    }

    private func entries(language: String) -> [NotificationItem] {
        let local = language == ContentLanguage.fallback
            ? [:]
            : byID(source.decode(NotificationsFile.self, from: MockFile.notifications(language))?.notifications)
        return baseEntries().map { entry in
            let text = local[entry.id]
            return NotificationItem(
                id: entry.id,
                title: text?.title?.nonBlank ?? entry.title ?? "",
                body: text?.body?.nonBlank ?? entry.body ?? "",
                read: false,
                section: entry.section.flatMap(NotificationSection.init(mockName:)) ?? .earlier,
                kind: entry.kind.flatMap(NotificationKind.init(mockName:)) ?? .newStories,
            )
        }
    }
}

/// The mock files use Android enum names (`Today`, `StoryReady`); Swift raw values are lower camel case.
extension RawRepresentable<String> {
    init?(mockName: String) {
        guard let first = mockName.first else {
            return nil
        }
        self.init(rawValue: first.lowercased() + mockName.dropFirst())
    }
}
