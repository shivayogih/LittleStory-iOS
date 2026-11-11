import Common
import Domain
import Observation

public struct PrivacyState: Sendable, Hashable {
    public var confirmOpen = false
    public var deleting = false
    /// The policy text is a draft until legal review (`FeatureFlags.draftLegalText`).
    public var showDraftNotice = true
}

public enum PrivacyEffect: Sendable, Equatable {
    /// Everything is gone; the app forgets its language and restarts the first-run flow.
    case deleted
}

/// Privacy & parent controls (SCR-21): what stays on the device, family safety, the draft policy,
/// and Delete all data.
@MainActor
@Observable
public final class PrivacyViewModel {
    public private(set) var state: PrivacyState
    @ObservationIgnored public let effects: AsyncStream<PrivacyEffect>
    @ObservationIgnored private let effectSink: AsyncStream<PrivacyEffect>.Continuation
    @ObservationIgnored private let localData: any LocalDataRepository

    public init(localData: any LocalDataRepository, flags: FeatureFlags) {
        self.localData = localData
        var initial = PrivacyState()
        initial.showDraftNotice = flags.draftLegalText
        state = initial
        let (stream, sink) = AsyncStream<PrivacyEffect>.makeStream()
        effects = stream
        effectSink = sink
    }

    public func onDeleteTapped() {
        state.confirmOpen = true
    }

    public func onConfirmDismissed() {
        state.confirmOpen = false
    }

    public func onConfirmDelete() async {
        guard !state.deleting else {
            return
        }
        state.confirmOpen = false
        state.deleting = true
        await localData.deleteAll()
        state.deleting = false
        effectSink.yield(.deleted)
    }
}
