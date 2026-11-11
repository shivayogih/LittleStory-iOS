import Common
import Domain
import Testing
import TestSupport

struct SimulationTests {
    private static let complete = GenerationProgress.completePercent

    private func percents(_ states: [GenerationState]) -> [Int] {
        states.compactMap { state in
            guard case let .inProgress(_, _, percent) = state else {
                return nil
            }
            return percent
        }
    }

    private func collect(_ stream: AsyncStream<GenerationState>) async -> [GenerationState] {
        var states: [GenerationState] = []
        for await state in stream {
            states.append(state)
        }
        return states
    }

    @Test("Progress runs from 0 to 100 in fixed steps on the injected clock")
    func progressFromZero() async {
        let clock = ImmediateClock()
        let states = await collect(GenerationProgress(clock: clock).run(requestID: "r1"))
        let step = AppConfig.Generation.stepPercent
        #expect(percents(states) == Array(stride(from: 0, through: Self.complete, by: step)))
        let steps = Self.complete / step
        #expect(clock.elapsed == AppConfig.Generation.stepInterval * steps)
    }

    @Test("Each state names its request and the stage for its percent")
    func progressStages() async {
        let states = await collect(GenerationProgress(clock: ImmediateClock()).run(requestID: "r1"))
        for state in states {
            guard case let .inProgress(requestID, stage, percent) = state else {
                Issue.record("Unexpected state \(state)")
                continue
            }
            #expect(requestID == "r1")
            #expect(stage == GenerationStage(percent: percent))
        }
    }

    @Test("Try again resumes from the restart percent")
    func progressRestart() async {
        let start = AppConfig.Generation.restartPercent
        let values = await percents(collect(GenerationProgress(clock: ImmediateClock()).run(requestID: "r1", from: start)))
        #expect(values.first == start)
        #expect(values.last == Self.complete)
    }

    @Test("Out-of-range start values are clamped")
    func progressClamp() async {
        let values = await percents(collect(GenerationProgress(clock: ImmediateClock()).run(requestID: "r1", from: 250)))
        #expect(values == [Self.complete])
    }

    @Test("Stopping the consumer stops the simulation")
    func progressCancel() async {
        let first = await GenerationProgress(clock: ImmediateClock()).run(requestID: "r1").first()
        #expect(first == .inProgress(requestID: "r1", stage: .imagining, percent: 0))
    }

    @Test("Ticks advance by the configured fraction times speed and stop at the end")
    func ticks() {
        let fraction = AppConfig.Player.tickFraction
        #expect(SimulatedPlayback.tick(0, speed: 1) == fraction)
        #expect(SimulatedPlayback.tick(0, speed: 2) == fraction * 2)
        #expect(SimulatedPlayback.tick(1 - fraction / 2, speed: 1) == 1)
    }

    @Test("Skips move by the configured seconds and stay within the track")
    func skips() {
        let minutes = 5
        let step = Double(AppConfig.Player.skipSeconds) / Double(SimulatedPlayback.totalSeconds(durationMinutes: minutes))
        #expect(SimulatedPlayback.skip(0.5, durationMinutes: minutes, direction: 1) == 0.5 + step)
        #expect(SimulatedPlayback.skip(0.5, durationMinutes: minutes, direction: -1) == 0.5 - step)
        #expect(SimulatedPlayback.skip(0, durationMinutes: minutes, direction: -1) == 0)
        #expect(SimulatedPlayback.skip(1, durationMinutes: minutes, direction: 1) == 1)
    }

    @Test("Speed cycles through the options and wraps around")
    func speeds() {
        let options = AppConfig.Player.speedOptions
        for (index, speed) in options.enumerated() {
            #expect(SimulatedPlayback.nextSpeed(after: speed) == options[(index + 1) % options.count])
        }
        #expect(SimulatedPlayback.nextSpeed(after: 3) == options[0])
    }

    @Test("Chapters are the pages spread evenly over the track")
    func chapters() {
        #expect(SimulatedPlayback.chapter(of: 0, chapters: 4) == 0)
        #expect(SimulatedPlayback.chapter(of: 0.5, chapters: 4) == 2)
        #expect(SimulatedPlayback.chapter(of: 1, chapters: 4) == 3)
        #expect(SimulatedPlayback.chapter(of: 0.7, chapters: 0) == 0)
        #expect(SimulatedPlayback.chapterStart(2, chapters: 4) == 0.5)
    }

    @Test("Only a minutes sleep timer stops playback early")
    func sleepTimer() {
        let minutes = AppConfig.Player.sleepTimerMinutes[0]
        #expect(SimulatedPlayback.sleepAfterSeconds(.minutes(minutes)) == minutes * 60)
        #expect(SimulatedPlayback.sleepAfterSeconds(.off) == nil)
        #expect(SimulatedPlayback.sleepAfterSeconds(.endOfStory) == nil)
    }
}
