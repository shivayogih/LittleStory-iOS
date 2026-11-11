import Common

/// Pure rules of the simulated narration player. Nothing plays: position is a fraction of the
/// story's length that advances on a timer while "playing".
public enum SimulatedPlayback {
    private static let secondsPerMinute = 60

    public static func totalSeconds(durationMinutes: Int) -> Int {
        max(durationMinutes, 1) * secondsPerMinute
    }

    /// One timer tick: `AppConfig.Player.tickFraction` of the track, scaled by `speed`.
    public static func tick(_ position: Double, speed: Double) -> Double {
        clamp(position + AppConfig.Player.tickFraction * speed)
    }

    /// Skips by `AppConfig.Player.skipSeconds`; a negative `direction` rewinds.
    public static func skip(_ position: Double, durationMinutes: Int, direction: Int) -> Double {
        let step = Double(AppConfig.Player.skipSeconds) / Double(totalSeconds(durationMinutes: durationMinutes))
        return clamp(position + step * Double(min(max(direction, -1), 1)))
    }

    /// Chapters are the story's pages, evenly spread over the track.
    public static func chapter(of position: Double, chapters: Int) -> Int {
        let count = max(chapters, 1)
        return min(max(Int(position * Double(count)), 0), count - 1)
    }

    public static func chapterStart(_ chapter: Int, chapters: Int) -> Double {
        clamp(Double(chapter) / Double(max(chapters, 1)))
    }

    /// The next speed in `AppConfig.Player.speedOptions`, wrapping around.
    public static func nextSpeed(after current: Double) -> Double {
        let options = AppConfig.Player.speedOptions
        let index = options.firstIndex(of: current) ?? -1
        return options[(index + 1) % options.count]
    }

    /// Simulated seconds after which the sleep timer stops playback, counted from when it was set;
    /// nil when it never fires early (off, or end of story, which stops at the end anyway).
    public static func sleepAfterSeconds(_ timer: SleepTimer) -> Int? {
        switch timer {
        case let .minutes(value): value * secondsPerMinute
        case .off, .endOfStory: nil
        }
    }

    /// Simulated seconds that pass in one tick at `speed`.
    public static func secondsPerTick(durationMinutes: Int, speed: Double) -> Double {
        Double(totalSeconds(durationMinutes: durationMinutes)) * AppConfig.Player.tickFraction * speed
    }

    private static func clamp(_ value: Double) -> Double {
        min(max(value, 0), 1)
    }
}
