import Common
import CoreUI
import Domain
import Foundation
import Observation

/// One saved story on the Offline downloads screen.
public struct DownloadItem: Sendable, Hashable, Identifiable {
    public let storyID: String
    public let title: String
    public let sizeBytes: Int64
    public let paletteID: String
    public let motifID: String

    public var id: String { storyID }

    /// "12 MB · Audio & story".
    public var sizeLabel: UIText { LibraryStrings.downloadsSize(.text(DownloadSizes.megabytes(sizeBytes))) }

    public var removeLabel: UIText { LibraryStrings.downloadsRemove(.text(title)) }
}

public struct DownloadsState: Sendable, Hashable {
    public var loading = true
    public var items: [DownloadItem] = []
    public var quotaBytes = AppConfig.Downloads.simulatedQuotaBytes

    public var usedBytes: Int64 { items.reduce(0) { $0 + $1.sizeBytes } }

    /// Share of the simulated quota in use; never drawn thinner than the design's minimum once something is saved.
    public var usedFraction: Double {
        guard !items.isEmpty, quotaBytes > 0 else {
            return 0
        }
        return min(max(Double(usedBytes) / Double(quotaBytes), AppConfig.Downloads.storageBarMinFraction), 1)
    }

    /// "24 MB used".
    public var usedLabel: UIText { LibraryStrings.downloadsUsed(.text(DownloadSizes.megabytes(usedBytes))) }

    /// "1 GB available for stories".
    public var quotaLabel: UIText { LibraryStrings.downloadsQuota(.text(DownloadSizes.gigabytes(quotaBytes))) }

    public var isEmpty: Bool { items.isEmpty && !loading }
}

extension DownloadsState {
    /// Rows whose story is in the catalogue or among the child's own stories; others are left out.
    init(stories: [Story], rows: [Download]) {
        let byID = Dictionary(stories.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        self.init()
        loading = false
        items = rows.compactMap { row in
            byID[row.storyID].map { story in
                DownloadItem(
                    storyID: story.id,
                    title: story.title,
                    sizeBytes: row.sizeBytes,
                    paletteID: story.art.paletteID,
                    motifID: story.art.motifID,
                )
            }
        }
    }
}

/// Offline downloads (SCR-17): simulated. Nothing is fetched; sizes are illustrative.
@MainActor
@Observable
public final class DownloadsViewModel {
    public private(set) var state = DownloadsState()
    @ObservationIgnored private let profiles: any ProfilesRepository
    @ObservationIgnored private let preferences: any PreferencesRepository
    @ObservationIgnored private let stores: StoryStores

    public init(profiles: any ProfilesRepository, preferences: any PreferencesRepository, stores: StoryStores) {
        self.profiles = profiles
        self.preferences = preferences
        self.stores = stores
    }

    public func start() async {
        let stores = stores
        let updates = Browse.context(profiles: profiles, preferences: preferences).flatMapLatest { context in
            combineLatest(
                combineLatest(
                    stores.catalog.stories(languageTag: context.languageTag),
                    stores.library.created(childID: context.childID),
                ),
                stores.downloads.downloads(),
            )
            .map { stories, rows in DownloadsState(stories: stories.1 + stories.0, rows: rows) }
        }
        for await state in updates {
            self.state = state
        }
    }

    public func onRemove(storyID: String) async {
        await stores.downloads.remove(storyID: storyID)
    }
}

/// Whole megabytes and up to one decimal of gigabytes, written with Western digits as on Android.
enum DownloadSizes {
    private static let bytesPerMegabyte: Int64 = 1_000_000
    private static let bytesPerGigabyte = 1_000_000_000.0
    private static let gigabyteDecimals = 1
    private static let posixLocale = "en_US_POSIX"

    static func megabytes(_ bytes: Int64) -> String {
        String(bytes / bytesPerMegabyte)
    }

    static func gigabytes(_ bytes: Int64) -> String {
        (Double(bytes) / bytesPerGigabyte)
            .formatted(.number.precision(.fractionLength(0 ... gigabyteDecimals)).locale(Locale(identifier: posixLocale)))
    }
}
