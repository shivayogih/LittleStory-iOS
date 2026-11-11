/// Where the voice is: the page being read and how far into that page's text, from 0 to 1.
public struct NarrationProgress: Sendable, Hashable {
    public let page: Int
    public let pageFraction: Double

    public init(page: Int, pageFraction: Double = 0) {
        self.page = page
        self.pageFraction = pageFraction
    }
}

/// Reads a story aloud. The MVP has none and the player stays a labelled simulation; a later
/// on-device voice (AVSpeechSynthesizer) or server audio implements this.
public protocol Narrator: Sendable {
    /// Speaks `pages` from `fromPage`; emits progress as each page starts and as the voice moves
    /// through its text, and finishes after the last page. Cancelling the consumer stops the voice.
    func narrate(pages: [String], fromPage: Int, languageTag: String, speed: Double) -> AsyncStream<NarrationProgress>
}
