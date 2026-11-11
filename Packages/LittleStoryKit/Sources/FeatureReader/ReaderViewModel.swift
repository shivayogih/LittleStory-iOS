import Common
import CoreUI
import Domain
import Foundation
import Observation

public struct ReaderContent: Sendable, Hashable {
    public let id: String
    public let title: String
    public let pages: [String]
    public let page: Int
    public let textScale: Double
    public let paletteID: String
    public let motifID: String
    public let favourite: Bool
    /// Two pages side by side on a wide window (HLD §6A.4); `page` is then the leading one.
    public var spread = false

    public var pageCount: Int { pages.count }
    public var text: String { pages[page] }
    /// The trailing page of a spread, or nil on a single page or the last odd page.
    public var facingText: String? { spread && page + 1 < pages.count ? pages[page + 1] : nil }
    /// The last page on screen.
    public var lastVisiblePage: Int { facingText == nil ? page : page + 1 }
    public var canGoBack: Bool { page > 0 }
    public var canGoForward: Bool { lastVisiblePage < pages.count - 1 }
    public var canShrink: Bool { textScale > AppConfig.Reader.textScaleRange.lowerBound + Self.epsilon }
    public var canGrow: Bool { textScale < AppConfig.Reader.textScaleRange.upperBound - Self.epsilon }
    public var pageLabel: UIText {
        facingText == nil ? ReaderStrings.pageOf(.number(page + 1), .number(pages.count)) : ReaderStrings.pagesOf(
            .number(page + 1),
            .number(page + 2),
            .number(pages.count),
        )
    }

    /// Share of the story read, for the thin progress line under the top bar.
    public var progress: Double { Double(lastVisiblePage + 1) / Double(max(pages.count, 1)) }

    public var favouriteLabel: UIText {
        favourite ? CoreUIStrings.storyFavouriteRemove(.text(title)) : CoreUIStrings.storyFavouriteAdd(.text(title))
    }

    /// Text scales are stored as doubles; comparisons allow for rounding.
    private static let epsilon = 0.001
}

public enum ReaderState: Sendable, Hashable {
    case loading
    case notFound
    case loaded(ReaderContent)
}

/// Reader (SCR-10): page by page; the page and the text size are remembered.
@MainActor
@Observable
public final class ReaderViewModel {
    public private(set) var state = ReaderState.loading
    @ObservationIgnored private let storyID: String
    @ObservationIgnored private let profiles: any ProfilesRepository
    @ObservationIgnored private let preferences: any PreferencesRepository
    @ObservationIgnored private let stores: StoryStores
    @ObservationIgnored private let now: @Sendable () -> Date
    @ObservationIgnored private var page: Int
    @ObservationIgnored private var spread = false
    @ObservationIgnored private var snapshot: ReaderSnapshot?

    public init(
        storyID: String,
        page: Int = 0,
        profiles: any ProfilesRepository,
        preferences: any PreferencesRepository,
        stores: StoryStores,
        now: @escaping @Sendable () -> Date = Date.init,
    ) {
        self.storyID = storyID
        self.page = max(page, 0)
        self.profiles = profiles
        self.preferences = preferences
        self.stores = stores
        self.now = now
    }

    public func start() async {
        let stores = stores
        let storyID = storyID
        let preferences = preferences
        let updates = Browse.context(profiles: profiles, preferences: preferences).flatMapLatest { context in
            combineLatest(
                Browse.story(id: storyID, languageTag: context.languageTag, catalog: stores.catalog, library: stores.library),
                combineLatest(preferences.reading(), stores.favourites.favouriteIDs(childID: context.childID)),
            )
            .map { story, saved in ReaderSnapshot(context: context, story: story, reading: saved.0, favouriteIDs: saved.1) }
        }
        for await snapshot in updates {
            self.snapshot = snapshot
            rebuild()
        }
    }

    public func onNext() async {
        await go(to: page + step)
    }

    public func onPrevious() async {
        await go(to: page - step)
    }

    /// The window became wide enough for a two-page spread, or narrow again. A spread starts on
    /// an odd page (1–2, 3–4), so the page the child was on stays in view.
    public func onSpreadChanged(_ enabled: Bool) {
        guard enabled != spread else {
            return
        }
        spread = enabled
        rebuild()
    }

    private var step: Int { spread ? Self.spreadPages : 1 }

    public func onTextSmaller() async {
        await changeScale(by: -AppConfig.Reader.textScaleStep)
    }

    public func onTextLarger() async {
        await changeScale(by: AppConfig.Reader.textScaleStep)
    }

    public func onFavourite() async {
        guard let childID = snapshot?.context.childID else {
            return
        }
        _ = await stores.favourites.toggle(storyID: storyID, childID: childID)
    }

    private func rebuild() {
        guard let snapshot else {
            return
        }
        state = Self.state(for: snapshot, page: page, spread: spread)
    }

    private func go(to target: Int) async {
        guard case let .loaded(content) = state, let childID = snapshot?.context.childID else {
            return
        }
        let next = Self.leadingPage(min(max(target, 0), content.pageCount - 1), spread: spread)
        guard next != page else {
            return
        }
        page = next
        rebuild()
        let existing = await stores.progress.progress(childID: childID).first()?.first { $0.storyID == storyID }
        await stores.progress.update(ReadingProgress(
            childID: childID,
            storyID: storyID,
            page: next,
            listenFraction: existing?.listenFraction ?? 0,
            updatedAt: now(),
        ))
    }

    private func changeScale(by delta: Double) async {
        guard var reading = await preferences.reading().first() else {
            return
        }
        let range = AppConfig.Reader.textScaleRange
        let rounded = ((reading.textScale + delta) * Self.scalePrecision).rounded() / Self.scalePrecision
        reading.textScale = min(max(rounded, range.lowerBound), range.upperBound)
        await preferences.setReading(reading)
    }

    static func state(for snapshot: ReaderSnapshot, page: Int, spread: Bool = false) -> ReaderState {
        guard let story = snapshot.story, !story.pages.isEmpty else {
            return .notFound
        }
        let current = min(max(page, 0), story.pages.count - 1)
        return .loaded(ReaderContent(
            id: story.id,
            title: story.title,
            pages: story.pages.map(\.text),
            page: leadingPage(current, spread: spread),
            textScale: snapshot.reading.textScale,
            paletteID: story.art.paletteID,
            motifID: story.art.motifID,
            favourite: snapshot.favouriteIDs.contains(story.id),
            spread: spread,
        ))
    }

    /// The first page of the spread that holds `page`; the page itself when there is no spread.
    static func leadingPage(_ page: Int, spread: Bool) -> Int {
        spread ? page - page % spreadPages : page
    }

    private static let spreadPages = 2

    /// Steps are compared in tenths so repeated taps do not drift.
    private static let scalePrecision = 10.0
}

struct ReaderSnapshot: Sendable {
    let context: BrowseContext
    let story: Story?
    let reading: ReadingPreferences
    let favouriteIDs: Set<String>
}
