import SwiftUI

/// Animation timings from design-tokens.json `motion`. Programmatic timings (generation steps,
/// player ticks) are behaviour and live in `AppConfig`, not here.
public enum LSMotion {
    public static let twinkleOnboarding: Duration = .milliseconds(2400)
    public static let twinkleGenerating: Duration = .milliseconds(1700)
    public static let twinkleGeneratingDelays: [Duration] = [.zero, .milliseconds(400), .milliseconds(700)]
    public static let twinkleSpark: Duration = .milliseconds(1100)
    public static let press: Duration = .milliseconds(180)
    public static let pressScale: CGFloat = 0.98
    public static let toggle: Duration = .milliseconds(200)
    public static let iconState: Duration = .milliseconds(200)
    public static let chevron: Duration = .milliseconds(200)
    public static let readingProgress: Duration = .milliseconds(300)
    public static let readerFontSize: Duration = .milliseconds(200)
    public static let twinkleMinOpacity = 0.3
    public static let twinkleMinScale: CGFloat = 0.8
    public static let twinkleRotationDegrees = 12.0

    /// An ease-in-out animation of `duration`, or nil (no animation) when Reduce Motion is on.
    /// Use with `.animation(_:value:)` and read `\.accessibilityReduceMotion` in the view.
    public static func standard(_ duration: Duration, reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : .easeInOut(duration: duration.lsSeconds)
    }
}

public extension Duration {
    /// Seconds as a `TimeInterval`, for SwiftUI animation APIs.
    var lsSeconds: TimeInterval {
        let parts = components
        return TimeInterval(parts.seconds) + TimeInterval(parts.attoseconds) / Self.attosecondsPerSecond
    }

    private static let attosecondsPerSecond = 1e18
}
