import Common
import Testing

struct AppConfigTests {
    @Test("Defaults are among the offered options")
    func defaultsAreOffered() {
        #expect(AppConfig.Create.durationOptionsMinutes.contains(AppConfig.Create.defaultDurationMinutes))
        #expect(AppConfig.Create.themes.contains(AppConfig.Create.defaultTheme))
        #expect(AppConfig.Create.moods.contains(AppConfig.Create.defaultMood))
        #expect(AppConfig.Setup.durationOptionsMinutes.contains(AppConfig.Setup.defaultDurationMinutes))
        #expect(AppConfig.Setup.ageRange.contains(AppConfig.Setup.defaultAge))
        #expect(AppConfig.Player.speedOptions.contains(AppConfig.Player.defaultSpeed))
        #expect(AppConfig.Reader.textScaleRange.contains(AppConfig.Reader.textScaleDefault))
        #expect(AppConfig.Discover.sortOptionIDs.contains(AppConfig.Discover.defaultSortID))
    }

    @Test("Generation stages are ordered and below 100 %")
    func stageThresholds() {
        let thresholds = AppConfig.Generation.stageThresholdsPercent
        #expect(thresholds == thresholds.sorted())
        #expect(thresholds.allSatisfy { $0 > 0 && $0 < 100 })
        #expect(AppConfig.Generation.restartPercent < thresholds[0])
    }
}
