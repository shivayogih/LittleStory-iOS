import CoreUI
import Foundation

/// Typed keys for this target's `Localizable.xcstrings` (Reader and Player).
enum ReaderStrings {
    private static func key(_ name: String) -> LocalizedKey {
        LocalizedKey(name, bundle: .module)
    }

    static let title = key("reader.title")
    static let pageOf = key("reader.page_of")
    static let pagesOf = key("reader.pages_of")
    static let textSmallerLabel = key("reader.text_smaller_label")
    static let textLargerLabel = key("reader.text_larger_label")
    static let textSmaller = key("reader.text_smaller")
    static let textLarger = key("reader.text_larger")
    static let previous = key("reader.previous")
    static let next = key("reader.next")
    static let play = key("reader.play")
    static let notFoundTitle = key("reader.not_found_title")
    static let notFoundText = key("reader.not_found_text")

    static let storyText = key("player.story_text")
    static let nowPlayingFor = key("player.now_playing_for")
    static let nowPlaying = key("player.now_playing")
    static let languageNarration = key("player.language_narration")
    static let seek = key("player.seek")
    static let time = key("player.time")
    static let playerPlay = key("player.play")
    static let playerPause = key("player.pause")
    static let previousChapter = key("player.previous_chapter")
    static let nextChapter = key("player.next_chapter")
    static let rewind = key("player.rewind")
    static let forward = key("player.forward")
    static let sleepTimer = key("player.sleep_timer")
    static let download = key("player.download")
    static let downloaded = key("player.downloaded")
    static let favourite = key("player.favourite")
    static let loved = key("player.loved")
    static let speed = key("player.speed")
    static let speedValue = key("player.speed_value")
    static let speedDescription = key("player.speed_description")
    static let stateOn = key("player.state_on")
    static let stateOff = key("player.state_off")
    static let volume = key("player.volume")
    static let sleepTitle = key("player.sleep_title")
    static let sleepBody = key("player.sleep_body")
    static let sleepMinutes = key("player.sleep_minutes")
    static let sleepEndOfStory = key("player.sleep_end_of_story")
    static let sleepCancel = key("player.sleep_cancel")
}

/// Accessibility identifiers for UI tests; never user-facing.
public enum ReaderID {
    public static let title = "reader.title"
    public static let back = "reader.back"
    public static let favourite = "reader.favourite"
    public static let pageLabel = "reader.page"
    public static let text = "reader.text"
    public static let facingText = "reader.facing_text"
    public static let smaller = "reader.smaller"
    public static let larger = "reader.larger"
    public static let previous = "reader.previous"
    public static let next = "reader.next"
    public static let play = "reader.play"

    public static let playerTitle = "player.title"
    public static let playerBack = "player.back"
    public static let storyText = "player.story_text"
    public static let playPause = "player.play_pause"
    public static let seek = "player.seek"
    public static let elapsed = "player.elapsed"
    public static let rewind = "player.rewind"
    public static let forward = "player.forward"
    public static let previousChapter = "player.previous_chapter"
    public static let nextChapter = "player.next_chapter"
    public static let sleepTimer = "player.sleep_timer"
    public static let playerDownload = "player.download"
    public static let playerFavourite = "player.favourite"
    public static let speed = "player.speed"
    public static let volume = "player.volume"
    public static func sleepOption(_ id: String) -> String { "player.sleep.\(id)" }
}
