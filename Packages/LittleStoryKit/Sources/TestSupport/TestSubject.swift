import Foundation

/// A value that tests can change and that every subscriber sees, like a store emitting on change.
/// Each `stream()` emits the current value at once, then every later `send`.
public final class TestSubject<Value: Sendable>: @unchecked Sendable {
    private let lock = NSLock()
    private var value: Value
    private var continuations: [UUID: AsyncStream<Value>.Continuation] = [:]

    public init(_ value: Value) {
        self.value = value
    }

    public var current: Value {
        lock.withLock { value }
    }

    public func send(_ newValue: Value) {
        lock.withLock {
            value = newValue
            for subscriber in continuations.values {
                subscriber.yield(newValue)
            }
        }
    }

    public func stream() -> AsyncStream<Value> {
        AsyncStream { continuation in
            let id = UUID()
            continuation.onTermination = { [weak self] _ in
                self?.remove(id)
            }
            // Registering and yielding the current value under one lock keeps a concurrent
            // `send` from arriving before the initial value.
            lock.withLock {
                continuations[id] = continuation
                continuation.yield(value)
            }
        }
    }

    private func remove(_ id: UUID) {
        _ = lock.withLock { continuations.removeValue(forKey: id) }
    }
}
