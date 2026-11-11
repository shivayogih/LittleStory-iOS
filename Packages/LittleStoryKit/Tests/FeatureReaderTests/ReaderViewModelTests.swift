import Common
import CoreUI
import Domain
@testable import FeatureReader
import Foundation
import Testing
import TestSupport

private let story = Fixtures.story(id: "s1", title: "Moon", pages: ["One.", "Two.", "Three."], durationMinutes: 30)
private let fixedDate = Date(timeIntervalSince1970: 1_000_000)

@MainActor
struct ReaderViewModelTests {
    private let preferences = FakePreferences()
    private let stores = StoryStores.fakes(catalog: FakeCatalog(stories: [story], categories: []))

    private func makeViewModel(storyID: String = "s1", page: Int = 0) -> ReaderViewModel {
        ReaderViewModel(
            storyID: storyID,
            page: page,
            profiles: FakeProfiles(),
            preferences: preferences,
            stores: stores,
            now: { fixedDate },
        )
    }

    private func content(_ viewModel: ReaderViewModel) -> ReaderContent? {
        if case let .loaded(content) = viewModel.state {
            return content
        }
        return nil
    }

    @Test("Pages turn within the story and the page is saved as progress")
    func paging() async throws {
        let viewModel = makeViewModel()
        let task = Task { await viewModel.start() }
        defer { task.cancel() }
        try await waitUntil { content(viewModel) != nil }
        #expect(content(viewModel)?.canGoBack == false)
        #expect(content(viewModel)?.pageLabel.resolved(for: Locale(identifier: "en")) == "1 of 3")
        await viewModel.onNext()
        await viewModel.onNext()
        await viewModel.onNext()
        #expect(content(viewModel)?.page == 2)
        #expect(content(viewModel)?.canGoForward == false)
        let saved = await stores.progress.progress(childID: AppConfig.Profiles.guestID).first()?.first
        #expect(saved?.page == 2)
        #expect(saved?.updatedAt == fixedDate)
        await viewModel.onPrevious()
        #expect(content(viewModel)?.text == "Two.")
    }

    @Test("Text size steps by a tenth and stops at the range ends")
    func textSize() async throws {
        let viewModel = makeViewModel()
        let task = Task { await viewModel.start() }
        defer { task.cancel() }
        try await waitUntil { content(viewModel) != nil }
        for _ in 0 ..< 10 {
            await viewModel.onTextLarger()
        }
        #expect(preferences.readingPreferences.current.textScale == AppConfig.Reader.textScaleRange.upperBound)
        try await waitUntil { content(viewModel)?.canGrow == false }
        await viewModel.onTextSmaller()
        #expect(abs(preferences.readingPreferences.current.textScale - 1.2) < 0.0001)
    }

    @Test("A wide window shows two pages, turns two at a time and keeps the child's page in view")
    func spread() async throws {
        let viewModel = makeViewModel(page: 1)
        let task = Task { await viewModel.start() }
        defer { task.cancel() }
        try await waitUntil { content(viewModel) != nil }
        viewModel.onSpreadChanged(true)
        #expect(content(viewModel)?.page == 0)
        #expect(content(viewModel)?.facingText == "Two.")
        #expect(content(viewModel)?.pageLabel.resolved(for: Locale(identifier: "en")) == "1–2 of 3")
        #expect(content(viewModel)?.progress == 2.0 / 3.0)
        #expect(content(viewModel)?.canGoBack == false)

        await viewModel.onNext()
        #expect(content(viewModel)?.page == 2)
        #expect(content(viewModel)?.facingText == nil)
        #expect(content(viewModel)?.pageLabel.resolved(for: Locale(identifier: "en")) == "3 of 3")
        #expect(content(viewModel)?.canGoForward == false)

        await viewModel.onPrevious()
        #expect(content(viewModel)?.page == 0)
        viewModel.onSpreadChanged(false)
        #expect(content(viewModel)?.facingText == nil)
        #expect(content(viewModel)?.text == "One.")
        await viewModel.onNext()
        #expect(content(viewModel)?.text == "Two.")
    }

    @Test("A start page past the end shows the last page; an unknown story shows not found")
    func bounds() async throws {
        let late = makeViewModel(page: 9)
        let lateTask = Task { await late.start() }
        defer { lateTask.cancel() }
        try await waitUntil { content(late) != nil }
        #expect(content(late)?.page == 2)

        let missing = makeViewModel(storyID: "nope")
        let missingTask = Task { await missing.start() }
        defer { missingTask.cancel() }
        try await waitUntil { missing.state != .loading }
        #expect(missing.state == .notFound)
    }
}

@MainActor
struct PlayerViewModelTests {
    private let stores = StoryStores.fakes(catalog: FakeCatalog(stories: [story], categories: []))
    private let preferences = FakePreferences()

    private func makeViewModel() -> PlayerViewModel {
        PlayerViewModel(
            storyID: "s1",
            profiles: FakeProfiles(),
            preferences: preferences,
            stores: stores,
            clock: ImmediateClock(),
            now: { fixedDate },
        )
    }

    private func started() async throws -> (PlayerViewModel, Task<Void, Never>) {
        let viewModel = makeViewModel()
        let task = Task { await viewModel.start() }
        try await waitUntil { !viewModel.state.loading }
        return (viewModel, task)
    }

    @Test("Loads the story as chapters and labels the time")
    func loads() async throws {
        let (viewModel, task) = try await started()
        defer { task.cancel() }
        #expect(viewModel.state.title == "Moon")
        #expect(viewModel.state.chapters == 3)
        #expect(viewModel.state.totalLabel.resolved(for: Locale(identifier: "en")) == "30:00")
        #expect(viewModel.state.speedValue.resolved(for: Locale(identifier: "en")) == "1×")
        #expect(viewModel.state.eyebrow.resolved(for: Locale(identifier: "en")) == "NOW PLAYING")
    }

    @Test("Playing runs to the end, stops and saves the listening progress")
    func playsToEnd() async throws {
        let (viewModel, task) = try await started()
        defer { task.cancel() }
        await viewModel.onPlayPause()
        try await waitUntil { !viewModel.state.playing }
        #expect(viewModel.state.position == 1)
        var saved: Double?
        for _ in 0 ..< 200 where saved != 1 {
            saved = await stores.progress.progress(childID: AppConfig.Profiles.guestID).first()?.first?.listenFraction
            try await Task.sleep(for: .milliseconds(10))
        }
        #expect(saved == 1)
    }

    @Test("A sleep timer stops playback early and switches itself off")
    func sleepTimer() async throws {
        let (viewModel, task) = try await started()
        defer { task.cancel() }
        viewModel.onSleepTimer()
        #expect(viewModel.state.sleepSheetOpen)
        viewModel.onSleepTimerSelected(.minutes(AppConfig.Player.sleepTimerMinutes[0]))
        #expect(!viewModel.state.sleepSheetOpen)
        #expect(viewModel.state.sleepTimerOn)
        await viewModel.onPlayPause()
        try await waitUntil { !viewModel.state.playing }
        #expect(viewModel.state.position < 1)
        #expect(viewModel.state.sleepTimer == .off)
    }

    @Test("Skips, chapters, speed and volume")
    func controls() async throws {
        let (viewModel, task) = try await started()
        defer { task.cancel() }
        viewModel.onForward()
        #expect(viewModel.state.position > 0)
        viewModel.onRewind()
        #expect(viewModel.state.position == 0)
        viewModel.onNextChapter()
        #expect(viewModel.state.chapter == 1)
        viewModel.onPreviousChapter()
        #expect(viewModel.state.chapter == 0)
        await viewModel.onSpeed()
        #expect(viewModel.state.speed == 1.25)
        #expect(preferences.readingPreferences.current.playbackSpeed == 1.25)
        viewModel.onVolumeChange(150)
        #expect(viewModel.state.volumePercent == AppConfig.Player.volumeMaxPercent)
        await viewModel.onSeek(0.5)
        #expect(viewModel.state.position == 0.5)
    }

    @Test("Favourite and download update the tiles")
    func toggles() async throws {
        let (viewModel, task) = try await started()
        defer { task.cancel() }
        await viewModel.onFavourite()
        await viewModel.onDownload()
        try await waitUntil { viewModel.state.favourite && viewModel.state.downloaded }
    }
}

/// Polls on the main actor until `condition` holds; fails after about two seconds.
@MainActor
func waitUntil(_ condition: () -> Bool) async throws {
    for _ in 0 ..< 200 {
        if condition() {
            return
        }
        try await Task.sleep(for: .milliseconds(10))
    }
    Issue.record("Condition not met in time")
}
