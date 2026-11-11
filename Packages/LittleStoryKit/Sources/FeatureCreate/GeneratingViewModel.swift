import Common
import CoreUI
import Domain
import Observation

/// One step of the progress list.
public struct GenerationStep: Sendable, Hashable, Identifiable {
    public enum Status: Sendable, Hashable {
        case done
        case active
        case pending
    }

    public let stage: GenerationStage
    public let status: Status

    public var id: Int { stage.rawValue }
    public var number: Int { stage.rawValue + 1 }

    public var title: UIText {
        switch stage {
        case .imagining: UIText(CreateStrings.stageImagining)
        case .writing: UIText(CreateStrings.stageWriting)
        case .preparingNarration: UIText(CreateStrings.stageNarration)
        }
    }

    /// Spoken status, since the disc colour alone does not say it.
    public var statusLabel: UIText {
        switch status {
        case .done: UIText(CreateStrings.stageDone)
        case .active: UIText(CreateStrings.stageActive)
        case .pending: UIText(CreateStrings.stagePending)
        }
    }
}

public struct GeneratingState: Sendable, Hashable {
    public var heroName = ""
    public var percent = 0
    public var paused = false

    public var stage: GenerationStage { GenerationStage(percent: percent) }
    public var percentLabel: UIText { CreateStrings.generatingPercent(.number(percent)) }
    public var fraction: Double { Double(percent) / Double(Self.full) }

    public var eyebrow: UIText {
        heroName.isEmpty ? UIText(CreateStrings.generatingEyebrow) : CreateStrings.generatingEyebrowNamed(.text(heroName.uppercased()))
    }

    public var steps: [GenerationStep] {
        GenerationStage.allCases.map { stage in
            let status: GenerationStep.Status = stage.rawValue < self.stage.rawValue ? .done : stage == self.stage ? .active : .pending
            return GenerationStep(stage: stage, status: status)
        }
    }

    private static let full = 100
}

public enum GeneratingEffect: Sendable, Equatable {
    case ready(storyID: String)
}

/// Generating (SCR-08): runs the simulated generation. Closing pauses it; Try again restarts at
/// `AppConfig.Generation.restartPercent`. An unknown request (the app was closed) shows the paused
/// panel, whose "Back to your idea" returns to Create.
@MainActor
@Observable
public final class GeneratingViewModel {
    public private(set) var state = GeneratingState()
    @ObservationIgnored public let effects: AsyncStream<GeneratingEffect>
    @ObservationIgnored private let effectSink: AsyncStream<GeneratingEffect>.Continuation
    @ObservationIgnored private let requestID: String
    @ObservationIgnored private let generation: any GenerationRepository
    @ObservationIgnored private let clock: any Clock<Duration>
    @ObservationIgnored private var run: Task<Void, Never>?

    public init(requestID: String, generation: any GenerationRepository, clock: any Clock<Duration> = ContinuousClock()) {
        self.requestID = requestID
        self.generation = generation
        self.clock = clock
        let (stream, sink) = AsyncStream<GeneratingEffect>.makeStream()
        effects = stream
        effectSink = sink
    }

    /// Starts the generation when the screen appears (`.task`); returns when it ends or pauses.
    public func start() async {
        state.heroName = await generation.request(id: requestID)?.heroName ?? ""
        await generate(from: 0)
    }

    /// The close button: stops the run and shows the paused panel.
    public func onClose() {
        run?.cancel()
        run = nil
        state.paused = true
    }

    public func onTryAgain() async {
        await generate(from: AppConfig.Generation.restartPercent)
    }

    private func generate(from startPercent: Int) async {
        run?.cancel()
        state.paused = false
        state.percent = startPercent
        let updates = generation.generate(requestID: requestID, startPercent: startPercent)
        let task = Task { await self.follow(updates) }
        run = task
        // Leaving the screen cancels `.task`; the run is unstructured, so stop it too.
        await withTaskCancellationHandler {
            await task.value
        } onCancel: {
            task.cancel()
        }
    }

    private func follow(_ updates: AsyncStream<GenerationState>) async {
        for await update in updates {
            guard !Task.isCancelled else {
                return
            }
            switch update {
            case let .inProgress(_, _, percent):
                state.percent = percent
            case let .completed(_, storyID):
                // A short pause on 100 % so the last step is seen before the story opens.
                try? await clock.sleep(for: AppConfig.Generation.autoAdvanceDelay)
                guard !Task.isCancelled else {
                    return
                }
                effectSink.yield(.ready(storyID: storyID))
            case .paused, .failed:
                state.paused = true
            case .idle:
                break
            }
        }
    }
}
