/// Small, dependency-free stream operators the domain and view models need. Each returned stream
/// cancels its upstream work when the consumer stops listening.
public extension AsyncStream where Element: Sendable {
    /// A stream that emits `values` in order and then finishes.
    static func of(_ values: Element...) -> AsyncStream<Element> {
        AsyncStream { continuation in
            for value in values {
                continuation.yield(value)
            }
            continuation.finish()
        }
    }

    /// Transforms every element.
    func map<T: Sendable>(_ transform: @escaping @Sendable (Element) -> T) -> AsyncStream<T> {
        let upstream = self
        return AsyncStream<T> { continuation in
            let task = Task {
                for await value in upstream {
                    continuation.yield(transform(value))
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    /// Drops an element that equals the one before it.
    func removeDuplicates() -> AsyncStream<Element> where Element: Equatable {
        let upstream = self
        return AsyncStream { continuation in
            let task = Task {
                var last: Element?
                for await value in upstream where value != last {
                    last = value
                    continuation.yield(value)
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    /// Re-runs `transform` for every element and forwards only the newest inner stream, like
    /// Kotlin's `flatMapLatest`. Finishes when this stream and the last inner stream have finished.
    func flatMapLatest<T: Sendable>(_ transform: @escaping @Sendable (Element) -> AsyncStream<T>) -> AsyncStream<T> {
        let upstream = self
        return AsyncStream<T> { continuation in
            let relay = LatestRelay(continuation)
            let task = Task {
                for await value in upstream {
                    await relay.switchTo(transform(value))
                }
                await relay.upstreamFinished()
            }
            continuation.onTermination = { _ in
                task.cancel()
                Task { await relay.cancel() }
            }
        }
    }

    /// The first element, or nil when the stream finishes empty.
    func first() async -> Element? {
        for await value in self {
            return value
        }
        return nil
    }
}

/// Emits a pair whenever either stream emits, once both have emitted at least once.
public func combineLatest<A: Sendable, B: Sendable>(_ first: AsyncStream<A>, _ second: AsyncStream<B>) -> AsyncStream<(A, B)> {
    AsyncStream { continuation in
        let state = CombineLatestState<A, B>(continuation)
        let firstTask = Task {
            for await value in first {
                await state.setFirst(value)
            }
            await state.sourceFinished()
        }
        let secondTask = Task {
            for await value in second {
                await state.setSecond(value)
            }
            await state.sourceFinished()
        }
        continuation.onTermination = { _ in
            firstTask.cancel()
            secondTask.cancel()
        }
    }
}

private actor CombineLatestState<A: Sendable, B: Sendable> {
    private let continuation: AsyncStream<(A, B)>.Continuation
    private var first: A?
    private var second: B?
    private var finishedSources = 0

    init(_ continuation: AsyncStream<(A, B)>.Continuation) {
        self.continuation = continuation
    }

    func setFirst(_ value: A) {
        first = value
        emit()
    }

    func setSecond(_ value: B) {
        second = value
        emit()
    }

    func sourceFinished() {
        finishedSources += 1
        if finishedSources == 2 {
            continuation.finish()
        }
    }

    private func emit() {
        if let first, let second {
            continuation.yield((first, second))
        }
    }
}

private actor LatestRelay<T: Sendable> {
    private let continuation: AsyncStream<T>.Continuation
    private var inner: Task<Void, Never>?
    private var generation = 0
    private var upstreamDone = false
    private var innerDone = true

    init(_ continuation: AsyncStream<T>.Continuation) {
        self.continuation = continuation
    }

    func switchTo(_ stream: AsyncStream<T>) {
        inner?.cancel()
        generation += 1
        let current = generation
        innerDone = false
        let continuation = continuation
        inner = Task {
            for await value in stream {
                guard !Task.isCancelled else { return }
                continuation.yield(value)
            }
            await self.innerFinished(current)
        }
    }

    func upstreamFinished() {
        upstreamDone = true
        finishIfDone()
    }

    func cancel() {
        inner?.cancel()
    }

    private func innerFinished(_ finishedGeneration: Int) {
        guard finishedGeneration == generation else { return }
        innerDone = true
        finishIfDone()
    }

    private func finishIfDone() {
        if upstreamDone, innerDone {
            continuation.finish()
        }
    }
}
