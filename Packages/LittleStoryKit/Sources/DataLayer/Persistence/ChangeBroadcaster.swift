import Domain
import Foundation

/// The stored tables; a write publishes its table so only the streams that read it query again.
public enum StoreTable: Sendable, Hashable, CaseIterable {
    case profiles
    case savedStories
    case progress
    case downloads
    case generatedStories
    case notificationRead
    case preferences
}

/// Fans change events out to every subscriber (LLD §4.3). SwiftData only observes through `@Query`
/// inside views, so the data layer keeps its own observation.
final class ChangeBroadcaster: @unchecked Sendable {
    private let lock = NSLock()
    private var subscribers: [UUID: AsyncStream<StoreTable>.Continuation] = [:]

    /// Registers at once, so a change published after this call returns is never missed.
    func subscribe() -> AsyncStream<StoreTable> {
        let (stream, continuation) = AsyncStream<StoreTable>.makeStream(bufferingPolicy: .unbounded)
        let id = UUID()
        lock.withLock { subscribers[id] = continuation }
        continuation.onTermination = { [weak self] _ in
            self?.remove(id)
        }
        return stream
    }

    func publish(_ tables: Set<StoreTable>) {
        lock.withLock {
            for subscriber in subscribers.values {
                for table in tables {
                    subscriber.yield(table)
                }
            }
        }
    }

    private func remove(_ id: UUID) {
        _ = lock.withLock { subscribers.removeValue(forKey: id) }
    }
}

extension ChangeBroadcaster {
    /// Emits `fetch()` now and again after every change to one of `tables`, skipping repeats.
    func observe<Value: Sendable & Equatable>(
        _ tables: Set<StoreTable>,
        fetch: @escaping @Sendable () async -> Value,
    ) -> AsyncStream<Value> {
        let changes = subscribe()
        return AsyncStream { continuation in
            let task = Task {
                await continuation.yield(fetch())
                for await table in changes where tables.contains(table) {
                    await continuation.yield(fetch())
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
        .removeDuplicates()
    }
}
