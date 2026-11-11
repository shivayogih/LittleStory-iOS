import Foundation

/// A clock whose `sleep` returns at once but still moves `now` forward, so tests can run timed
/// simulations instantly and still check how much virtual time passed.
public final class ImmediateClock: Clock, @unchecked Sendable {
    public struct Instant: InstantProtocol {
        public let offset: Duration

        public init(offset: Duration = .zero) {
            self.offset = offset
        }

        public func advanced(by duration: Duration) -> Instant {
            Instant(offset: offset + duration)
        }

        public func duration(to other: Instant) -> Duration {
            other.offset - offset
        }

        public static func < (lhs: Instant, rhs: Instant) -> Bool {
            lhs.offset < rhs.offset
        }
    }

    private let lock = NSLock()
    private var current = Instant()

    public init() {}

    public var now: Instant {
        lock.withLock { current }
    }

    public var minimumResolution: Duration { .zero }

    /// Virtual time passed since the clock was made.
    public var elapsed: Duration {
        now.offset
    }

    public func sleep(until deadline: Instant, tolerance _: Duration?) async throws {
        try Task.checkCancellation()
        lock.withLock {
            if current < deadline {
                current = deadline
            }
        }
        await Task.yield()
    }
}
