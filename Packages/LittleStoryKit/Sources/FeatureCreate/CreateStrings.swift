import CoreUI
import Foundation

/// Typed keys for this target's `Localizable.xcstrings` (Create, Generating, Story ready).
enum CreateStrings {
    private static func key(_ name: String) -> LocalizedKey {
        LocalizedKey(name, bundle: .module)
    }

    static let title = key("create.title")
    static let parentGuided = key("create.parent_guided")
    static let introTitle = key("create.intro_title")
    static let introBody = key("create.intro_body")
    static let promptLabel = key("create.prompt_label")
    static let promptPlaceholderNamed = key("create.prompt_placeholder_named")
    static let promptPlaceholder = key("create.prompt_placeholder")
    static let counter = key("create.counter")
    static let errorEmpty = key("create.error_empty")
    static let heroFallback = key("create.hero_fallback")
    static let heroEyebrow = key("create.hero_eyebrow")
    static let heroNameAge = key("create.hero_name_age")
    static let heroChange = key("create.hero_change")
    static let themeTitle = key("create.theme_title")
    static let moreOptions = key("create.more_options")
    static let moreOptionsExpanded = key("create.more_options_expanded")
    static let moreOptionsCollapsed = key("create.more_options_collapsed")
    static let moodTitle = key("create.mood_title")
    static let durationTitle = key("create.duration_title")
    static let durationMinutes = key("create.duration_minutes")
    static let languageTitle = key("create.language_title")
    static let safetyNote = key("create.safety_note")
    static let submit = key("create.submit")

    static func suggestion(_ id: String) -> LocalizedKey { key("create.suggestion_\(id)") }
    static func fill(_ id: String) -> LocalizedKey { key("create.fill_\(id)") }
    static func theme(_ id: String) -> LocalizedKey { key("create.theme_\(id)") }
    static func mood(_ id: String) -> LocalizedKey { key("create.mood_\(id)") }

    static let generatingClose = key("generating.close")
    static let generatingEyebrowNamed = key("generating.eyebrow_named")
    static let generatingEyebrow = key("generating.eyebrow")
    static let generatingTitle = key("generating.title")
    static let generatingBody = key("generating.body")
    static let generatingPercent = key("generating.percent")
    static let stageImagining = key("generating.stage_imagining")
    static let stageWriting = key("generating.stage_writing")
    static let stageNarration = key("generating.stage_narration")
    static let stageDone = key("generating.stage_done")
    static let stageActive = key("generating.stage_active")
    static let stagePending = key("generating.stage_pending")
    static let generatingFootnote = key("generating.footnote")
    static let generatingSimulated = key("generating.simulated")
    static let pausedTitle = key("generating.paused_title")
    static let pausedBody = key("generating.paused_body")
    static let tryAgain = key("generating.try_again")
    static let backToIdea = key("generating.back_to_idea")

    static let readyRibbon = key("ready.ribbon")
    static let readyMadeFor = key("ready.made_for")
    static let readyEyebrow = key("ready.eyebrow")
    static let readyMeta = key("ready.meta")
    static let readyPeekTitle = key("ready.peek_title")
    static let readyListen = key("ready.listen")
    static let readyRead = key("ready.read")
    static let readySavedTitle = key("ready.saved_title")
    static let readySavedBody = key("ready.saved_body")
    static let readyDownloadAdd = key("ready.download_add")
    static let readyDownloadRemove = key("ready.download_remove")
    static let readyNotFoundTitle = key("ready.not_found_title")
    static let readyNotFoundText = key("ready.not_found_text")
}

/// Accessibility identifiers for UI tests; never user-facing.
public enum CreateID {
    public static let title = "create.title"
    public static let prompt = "create.prompt"
    public static let counter = "create.counter"
    public static let error = "create.error"
    public static let hero = "create.hero"
    public static let moreOptions = "create.more_options"
    public static let language = "create.language"
    public static let submit = "create.submit"
    public static func suggestion(_ id: String) -> String { "create.suggestion.\(id)" }
    public static func theme(_ id: String) -> String { "create.theme.\(id)" }
    public static func mood(_ id: String) -> String { "create.mood.\(id)" }
    public static func duration(_ minutes: Int) -> String { "create.duration.\(minutes)" }

    public static let generatingTitle = "generating.title"
    public static let generatingClose = "generating.close"
    public static let generatingPercent = "generating.percent"
    public static let tryAgain = "generating.try_again"
    public static let backToIdea = "generating.back_to_idea"

    public static let readyTitle = "ready.title"
    public static let readyBack = "ready.back"
    public static let readyFavourite = "ready.favourite"
    public static let readyDownload = "ready.download"
    public static let readyListen = "ready.listen"
    public static let readyRead = "ready.read"
    public static let readySaved = "ready.saved"
}
