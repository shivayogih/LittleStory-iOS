import Common

/// The simulated progress of one request: `AppConfig.Generation.stepPercent` every
/// `stepInterval`, from `startPercent` up to 100. Deterministic and driven by an injected clock,
/// so tests run it instantly. Cancelling the consumer stops it (the Generating screen's pause).
public struct GenerationProgress: Sendable {
    public static let completePercent = 100

    private let clock: any Clock<Duration>

    public init(clock: any Clock<Duration>) {
        self.clock = clock
    }

    public func run(requestID: String, from startPercent: Int = 0) -> AsyncStream<GenerationState> {
        let clock = clock
        return AsyncStream { continuation in
            let task = Task {
                var percent = min(max(startPercent, 0), Self.completePercent)
                continuation.yield(.inProgress(requestID: requestID, stage: GenerationStage(percent: percent), percent: percent))
                while percent < Self.completePercent {
                    do {
                        try await clock.sleep(for: AppConfig.Generation.stepInterval)
                    } catch {
                        break
                    }
                    percent = min(percent + AppConfig.Generation.stepPercent, Self.completePercent)
                    continuation.yield(.inProgress(requestID: requestID, stage: GenerationStage(percent: percent), percent: percent))
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}
