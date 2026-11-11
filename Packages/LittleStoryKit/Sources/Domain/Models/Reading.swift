import Foundation

/// Saved flags per child and story.
public struct SavedStory: Sendable, Hashable {
    public let childID: String
    public let storyID: String
    public var favourite: Bool
    public var downloaded: Bool

    public init(childID: String, storyID: String, favourite: Bool, downloaded: Bool) {
        self.childID = childID
        self.storyID = storyID
        self.favourite = favourite
        self.downloaded = downloaded
    }
}

/// How far a child got in a story; Reader and Player share one record per child and story.
public struct ReadingProgress: Sendable, Hashable {
    public let childID: String
    public let storyID: String
    public var page: Int
    /// Listening position from 0 to 1.
    public var listenFraction: Double
    public var updatedAt: Date

    public init(childID: String, storyID: String, page: Int, listenFraction: Double, updatedAt: Date) {
        self.childID = childID
        self.storyID = storyID
        self.page = page
        self.listenFraction = listenFraction
        self.updatedAt = updatedAt
    }
}

/// Sleep timer choices; `endOfStory` stops when the story ends.
public enum SleepTimer: Sendable, Hashable {
    case off
    case minutes(Int)
    case endOfStory
}

public struct PlaybackState: Sendable, Hashable {
    public let storyID: String
    public var playing: Bool
    public var positionFraction: Double
    public var speed: Double
    public var volumePercent: Int
    public var sleepTimer: SleepTimer

    public init(
        storyID: String,
        playing: Bool,
        positionFraction: Double,
        speed: Double,
        volumePercent: Int,
        sleepTimer: SleepTimer,
    ) {
        self.storyID = storyID
        self.playing = playing
        self.positionFraction = positionFraction
        self.speed = speed
        self.volumePercent = volumePercent
        self.sleepTimer = sleepTimer
    }
}

public enum DownloadStatus: String, Sendable, Hashable, Codable {
    case queued
    case downloading
    case completed
}

public struct Download: Sendable, Hashable, Identifiable {
    public let storyID: String
    public let sizeBytes: Int64
    public let status: DownloadStatus

    public var id: String { storyID }

    public init(storyID: String, sizeBytes: Int64, status: DownloadStatus) {
        self.storyID = storyID
        self.sizeBytes = sizeBytes
        self.status = status
    }
}

public struct ReadingPreferences: Sendable, Hashable {
    public var textScale: Double
    public var playbackSpeed: Double

    public init(textScale: Double, playbackSpeed: Double) {
        self.textScale = textScale
        self.playbackSpeed = playbackSpeed
    }
}

/// Bedtime reminder settings. UI only in the MVP (decision D13): nothing is scheduled.
public struct ReminderSettings: Sendable, Hashable {
    public var enabled: Bool
    public var hour: Int
    public var minute: Int
    /// ISO weekdays, Monday = 1 … Sunday = 7.
    public var days: Set<Int>

    public init(enabled: Bool, hour: Int, minute: Int, days: Set<Int>) {
        self.enabled = enabled
        self.hour = hour
        self.minute = minute
        self.days = days
    }
}

public struct ParentSettings: Sendable, Hashable {
    public var reminder: ReminderSettings
    public var notificationsEnabled: Bool
    public var wifiOnlyDownloads: Bool

    public init(reminder: ReminderSettings, notificationsEnabled: Bool, wifiOnlyDownloads: Bool) {
        self.reminder = reminder
        self.notificationsEnabled = notificationsEnabled
        self.wifiOnlyDownloads = wifiOnlyDownloads
    }
}

public enum NotificationSection: String, Sendable, Hashable, Codable {
    case today
    case earlier
}

/// What a notification is about; decides its icon tile and where tapping it goes.
public enum NotificationKind: String, Sendable, Hashable, Codable {
    case storyReady
    case reminder
    case newStories
}

/// A mock inbox item; `title` and `body` are content already resolved for the language.
public struct NotificationItem: Sendable, Hashable, Identifiable {
    public let id: String
    public let title: String
    public let body: String
    public var read: Bool
    public let section: NotificationSection
    public let kind: NotificationKind

    public init(
        id: String,
        title: String,
        body: String,
        read: Bool,
        section: NotificationSection = .earlier,
        kind: NotificationKind = .newStories,
    ) {
        self.id = id
        self.title = title
        self.body = body
        self.read = read
        self.section = section
        self.kind = kind
    }
}

/// An illustrative subscription plan; prices are minor units with an ISO currency code.
public struct Plan: Sendable, Hashable, Identifiable {
    public let id: String
    public let priceMinorUnits: Int64
    public let currencyCode: String
    public let billedYearly: Bool
    public let bestValue: Bool
    public let maxChildren: Int

    public init(
        id: String,
        priceMinorUnits: Int64,
        currencyCode: String,
        billedYearly: Bool,
        bestValue: Bool = false,
        maxChildren: Int = 1,
    ) {
        self.id = id
        self.priceMinorUnits = priceMinorUnits
        self.currencyCode = currencyCode
        self.billedYearly = billedYearly
        self.bestValue = bestValue
        self.maxChildren = maxChildren
    }
}
