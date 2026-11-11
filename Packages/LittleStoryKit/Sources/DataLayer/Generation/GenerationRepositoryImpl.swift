import Common
import Domain

/// Simulated generation (no AI provider): deterministic progress, then a localized template filled
/// with the hero's name and saved to the library. Pending requests live in memory only; nothing
/// the parent typed is stored or sent anywhere.
///
/// When a `writer` is given, it writes the story while progress runs up to
/// `AppConfig.Generation.writerWaitPercent`; an unavailable writer falls back to the template, and
/// a rejected or failed one ends in `.failed`, which the Generating screen shows as paused.
public final class GenerationRepositoryImpl: GenerationRepository {
    private let source: any MockContentSource
    private let library: any LibraryRepository
    private let progress: GenerationProgress
    private let mode: Mode
    private let pending = PendingRequests()

    public init(
        source: any MockContentSource,
        library: any LibraryRepository,
        clock: any Clock<Duration> = ContinuousClock(),
    ) {
        self.source = source
        self.library = library
        progress = GenerationProgress(clock: clock)
        mode = .simulated
    }

    /// Generation backed by a story writer, with the template as the fallback when it is unavailable.
    public init(
        source: any MockContentSource,
        library: any LibraryRepository,
        writer: any StoryWriter,
        clock: any Clock<Duration> = ContinuousClock(),
    ) {
        self.source = source
        self.library = library
        progress = GenerationProgress(clock: clock)
        mode = .writer(writer)
    }

    private enum Mode: Sendable {
        case simulated
        case writer(any StoryWriter)
    }

    /// One story per request, so retrying a request never creates a duplicate.
    public static func generatedStoryID(requestID: String) -> String {
        "generated_\(requestID)"
    }

    public func submit(_ request: StoryCreationRequest) async {
        await pending.add(request)
    }

    public func request(id: String) async -> StoryCreationRequest? {
        await pending.request(id: id)
    }

    public func generate(requestID: String, startPercent: Int) -> AsyncStream<GenerationState> {
        AsyncStream { continuation in
            let task = Task {
                await self.run(requestID: requestID, startPercent: startPercent, into: continuation)
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    private func run(requestID: String, startPercent: Int, into output: AsyncStream<GenerationState>.Continuation) async {
        guard let request = await pending.request(id: requestID) else {
            output.yield(.failed(requestID: requestID, error: .unknownRequest))
            return
        }
        let template = TemplateStory(source: source)
        let story: Story
        if case let .writer(writer) = mode {
            let storyID = Self.generatedStoryID(requestID: requestID)
            async let written = writer.write(request, storyID: storyID)
            for await state in progress.run(requestID: requestID, from: startPercent) {
                guard state.percent <= AppConfig.Generation.writerWaitPercent else {
                    break
                }
                output.yield(state)
            }
            let result = await written
            guard !Task.isCancelled else {
                return
            }
            switch result {
            case let .written(draft):
                story = template.story(for: request, draft: draft)
            case .unavailable:
                story = template.story(for: request)
            case .rejected:
                output.yield(.failed(requestID: requestID, error: .rejected))
                return
            case .failed:
                output.yield(.failed(requestID: requestID, error: .writerFailed))
                return
            }
        } else {
            for await state in progress.run(requestID: requestID, from: startPercent) {
                output.yield(state)
            }
            story = template.story(for: request)
        }
        // A cancelled run is the Generating screen's pause: nothing is saved until it completes.
        guard !Task.isCancelled else {
            return
        }
        await library.save(story, childID: request.heroChildID)
        output.yield(.completed(requestID: requestID, storyID: story.id))
    }
}

/// Requests waiting for the Generating screen; memory only, so nothing typed is kept on disk.
private actor PendingRequests {
    private var requests: [String: StoryCreationRequest] = [:]

    func add(_ request: StoryCreationRequest) {
        requests[request.requestID] = request
    }

    func request(id: String) -> StoryCreationRequest? {
        requests[id]
    }
}

extension GenerationState {
    var percent: Int {
        switch self {
        case let .inProgress(_, _, percent), let .paused(_, percent):
            percent
        case .completed:
            GenerationProgress.completePercent
        case .idle, .failed:
            0
        }
    }
}
