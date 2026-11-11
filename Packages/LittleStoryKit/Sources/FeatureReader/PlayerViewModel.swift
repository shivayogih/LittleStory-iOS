import Common
import CoreUI
import Domain
import Foundation
import Observation

/// A sleep timer choice in the sheet.
public struct SleepOption: Sendable, Hashable, Identifiable {
    public let timer: SleepTimer
    public let id: String
    public let label: UIText

    static let all: [SleepOption] = AppConfig.Player.sleepTimerMinutes.map { minutes in
        SleepOption(timer: .minutes(minutes), id: "\(minutes)", label: ReaderStrings.sleepMinutes(.number(minutes)))
    } + [SleepOption(timer: .endOfStory, id: endOfStoryID, label: UIText(ReaderStrings.sleepEndOfStory))]

    private static let endOfStoryID = "end"
}

public struct PlayerState: Sendable, Hashable {
    public var loading = true
    public var notFound = false
    public var title = ""
    public var heroName: String?
    public var languageName = ""
    public var paletteID = ""
    public var motifID = ""
    public var durationMinutes = 1
    public var chapters = 1
    public var position = 0.0
    public var playing = false
    public var speed = AppConfig.Player.defaultSpeed
    public var volumePercent = AppConfig.Player.defaultVolumePercent
    public var sleepTimer = SleepTimer.off
    public var sleepSheetOpen = false
    public var favourite = false
    public var downloaded = false

    public var totalSeconds: Int { SimulatedPlayback.totalSeconds(durationMinutes: durationMinutes) }
    public var elapsedSeconds: Int { Int(position * Double(totalSeconds)) }
    public var chapter: Int { SimulatedPlayback.chapter(of: position, chapters: chapters) }
    public var elapsedLabel: UIText { Self.time(elapsedSeconds) }
    public var totalLabel: UIText { Self.time(totalSeconds) }
    public var sleepOptions: [SleepOption] { SleepOption.all }

    public var eyebrow: UIText {
        heroName.map { ReaderStrings.nowPlayingFor(.text($0.uppercased())) } ?? UIText(ReaderStrings.nowPlaying)
    }

    public var subtitle: UIText { ReaderStrings.languageNarration(.text(languageName)) }
    public var playLabel: UIText { UIText(playing ? ReaderStrings.playerPause : ReaderStrings.playerPlay) }
    public var speedValue: UIText { ReaderStrings.speedValue(.text(Self.speedText(speed))) }
    public var speedDescription: UIText { ReaderStrings.speedDescription(.text(Self.speedText(speed))) }
    public var rewindLabel: UIText { ReaderStrings.rewind(.number(AppConfig.Player.skipSeconds)) }
    public var forwardLabel: UIText { ReaderStrings.forward(.number(AppConfig.Player.skipSeconds)) }
    public var sleepTimerOn: Bool { sleepTimer != .off }

    public var favouriteLabel: UIText {
        favourite ? CoreUIStrings.storyFavouriteRemove(.text(title)) : CoreUIStrings.storyFavouriteAdd(.text(title))
    }

    /// "2:28": minutes, then seconds padded to two digits by the catalog format.
    static func time(_ seconds: Int) -> UIText {
        ReaderStrings.time(.text(String(seconds / secondsPerMinute)), .number(seconds % secondsPerMinute))
    }

    /// 1, 1.25, 0.75: the shortest form of the speed.
    static func speedText(_ speed: Double) -> String {
        speed.formatted(.number.precision(.fractionLength(0 ... maxSpeedDecimals)).locale(Locale(identifier: posixLocale)))
    }

    private static let secondsPerMinute = 60
    private static let maxSpeedDecimals = 2
    /// Speeds are numerals in both languages, as on Android.
    private static let posixLocale = "en_US_POSIX"
}

/// Player (SCR-11a/b): a labelled simulated narration. Nothing plays; the position advances on a
/// timer and is saved as listening progress so Home can offer to resume it.
@MainActor
@Observable
public final class PlayerViewModel {
    public private(set) var state = PlayerState()
    @ObservationIgnored public let storyID: String
    @ObservationIgnored private let profiles: any ProfilesRepository
    @ObservationIgnored private let preferences: any PreferencesRepository
    @ObservationIgnored private let stores: StoryStores
    @ObservationIgnored private let clock: any Clock<Duration>
    @ObservationIgnored private let now: @Sendable () -> Date
    @ObservationIgnored private var childID = AppConfig.Profiles.guestID
    @ObservationIgnored private var ticker: Task<Void, Never>?
    /// Simulated seconds left before the sleep timer stops playback; nil when it is not counting.
    @ObservationIgnored private var sleepRemaining: Double?

    public init(
        storyID: String,
        profiles: any ProfilesRepository,
        preferences: any PreferencesRepository,
        stores: StoryStores,
        clock: any Clock<Duration> = ContinuousClock(),
        now: @escaping @Sendable () -> Date = Date.init,
    ) {
        self.storyID = storyID
        self.profiles = profiles
        self.preferences = preferences
        self.stores = stores
        self.clock = clock
        self.now = now
    }

    /// Runs while the screen is shown; leaving the screen stops playback and saves the position.
    public func start() async {
        guard let context = await Browse.context(profiles: profiles, preferences: preferences).first() else {
            return
        }
        childID = context.childID
        let saved = await stores.progress.progress(childID: childID).first()?.first { $0.storyID == storyID }
        let speed = await preferences.reading().first()?.playbackSpeed ?? AppConfig.Player.defaultSpeed
        if let fraction = saved?.listenFraction, fraction < 1 {
            state.position = fraction
        }
        state.speed = AppConfig.Player.speedOptions.contains(speed) ? speed : AppConfig.Player.defaultSpeed
        let stores = stores
        let updates = combineLatest(
            Browse.story(id: storyID, languageTag: context.languageTag, catalog: stores.catalog, library: stores.library),
            combineLatest(stores.favourites.favouriteIDs(childID: childID), stores.downloads.downloads()),
        )
        for await (story, saved) in updates {
            apply(story: story, context: context, favouriteIDs: saved.0, downloads: saved.1)
        }
        ticker?.cancel()
        if state.playing {
            state.playing = false
            await saveProgress()
        }
    }

    private func apply(story: Story?, context: BrowseContext, favouriteIDs: Set<String>, downloads: [Download]) {
        state.loading = false
        guard let story else {
            state.notFound = true
            return
        }
        state.notFound = false
        state.title = story.title
        state.heroName = context.child?.firstName
        state.languageName = SupportedLanguages.language(forTag: story.resolvedLanguage).nativeName
        state.paletteID = story.art.paletteID
        state.motifID = story.art.motifID
        state.durationMinutes = story.durationMinutes
        state.chapters = max(story.pages.count, 1)
        state.favourite = favouriteIDs.contains(story.id)
        state.downloaded = downloads.contains { $0.storyID == story.id }
    }

    public func onPlayPause() async {
        if state.playing {
            await pause()
        } else {
            play()
        }
    }

    public func onSeek(_ fraction: Double) async {
        state.position = min(max(fraction, 0), 1)
        await saveProgress()
    }

    public func onRewind() {
        state.position = SimulatedPlayback.skip(state.position, durationMinutes: state.durationMinutes, direction: -1)
    }

    public func onForward() {
        state.position = SimulatedPlayback.skip(state.position, durationMinutes: state.durationMinutes, direction: 1)
    }

    /// Like most players: the first tap returns to the start of the chapter, the next goes back one.
    public func onPreviousChapter() {
        let start = SimulatedPlayback.chapterStart(state.chapter, chapters: state.chapters)
        let target = state.position - start > Self.chapterRestartSlack ? state.chapter : state.chapter - 1
        state.position = SimulatedPlayback.chapterStart(max(target, 0), chapters: state.chapters)
    }

    public func onNextChapter() {
        guard state.chapter + 1 < state.chapters else {
            return
        }
        state.position = SimulatedPlayback.chapterStart(state.chapter + 1, chapters: state.chapters)
    }

    public func onSpeed() async {
        let speed = SimulatedPlayback.nextSpeed(after: state.speed)
        state.speed = speed
        if var reading = await preferences.reading().first() {
            reading.playbackSpeed = speed
            await preferences.setReading(reading)
        }
    }

    public func onVolumeChange(_ percent: Int) {
        state.volumePercent = min(max(percent, 0), AppConfig.Player.volumeMaxPercent)
    }

    public func onSleepTimer() {
        state.sleepSheetOpen = true
    }

    public func onSleepSheetDismiss() {
        state.sleepSheetOpen = false
    }

    public func onSleepTimerSelected(_ timer: SleepTimer) {
        sleepRemaining = SimulatedPlayback.sleepAfterSeconds(timer).map(Double.init)
        state.sleepTimer = timer
        state.sleepSheetOpen = false
    }

    public func onFavourite() async {
        _ = await stores.favourites.toggle(storyID: storyID, childID: childID)
    }

    /// Downloads are simulated: this only records that the story is "available offline".
    public func onDownload() async {
        if state.downloaded {
            await stores.downloads.remove(storyID: storyID)
        } else {
            await stores.downloads.start(storyID: storyID)
        }
    }

    private func play() {
        if state.position >= 1 {
            state.position = 0
        }
        state.playing = true
        ticker?.cancel()
        ticker = Task { [weak self] in await self?.runTicks() }
    }

    private func pause() async {
        ticker?.cancel()
        ticker = nil
        state.playing = false
        await saveProgress()
    }

    private func runTicks() async {
        var ticks = 0
        while !Task.isCancelled, state.playing {
            do {
                try await clock.sleep(for: AppConfig.Player.simulatedTick)
            } catch {
                return
            }
            guard !Task.isCancelled, state.playing else {
                return
            }
            let stopped = tick()
            ticks += 1
            if stopped || ticks.isMultiple(of: AppConfig.Player.progressSaveEveryTicks) {
                await saveProgress()
            }
        }
    }

    /// One step of simulated time; returns true when playback stopped (end or sleep timer).
    private func tick() -> Bool {
        let position = SimulatedPlayback.tick(state.position, speed: state.speed)
        let remaining = sleepRemaining.map { $0 - SimulatedPlayback.secondsPerTick(
            durationMinutes: state.durationMinutes,
            speed: state.speed,
        ) }
        let sleepFired = remaining.map { $0 <= 0 } ?? false
        let ended = position >= 1
        sleepRemaining = sleepFired ? nil : remaining
        state.position = position
        if sleepFired || (ended && state.sleepTimer == .endOfStory) {
            state.sleepTimer = .off
        }
        if ended || sleepFired {
            state.playing = false
            return true
        }
        return false
    }

    private func saveProgress() async {
        let existing = await stores.progress.progress(childID: childID).first()?.first { $0.storyID == storyID }
        await stores.progress.update(ReadingProgress(
            childID: childID,
            storyID: storyID,
            page: existing?.page ?? 0,
            listenFraction: state.position,
            updatedAt: now(),
        ))
    }

    /// How far into a chapter "previous" still restarts it instead of going back one.
    private static let chapterRestartSlack = 0.01
}
