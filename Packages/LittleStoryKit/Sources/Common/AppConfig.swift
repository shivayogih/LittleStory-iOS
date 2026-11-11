/// Every configurable limit, option and timing has exactly one home here.
/// Values match the Android app (`core/common/.../config/AppConfig.kt`) so both apps behave the same.
public enum AppConfig {
    public enum Profiles {
        /// Owner of favourites and progress when Setup was skipped and no child profile exists.
        public static let guestID = "guest"
    }

    public enum Home {
        /// Categories shown as tiles in "Explore stories", in order.
        public static let exploreCategoryIDs = ["bedtime", "animals", "adventure", "friendship", "indian_tales"]
        public static let madeForCount = 4
        public static let cultureCategoryID = "indian_tales"
    }

    public enum Create {
        public static let promptMaxCharacters = 500
        public static let durationOptionsMinutes = [5, 8, 10, 15]
        public static let defaultDurationMinutes = 8
        public static let themes = ["adventure", "bedtime", "animals", "friendship", "fantasy", "learning", "indian_folklore"]
        public static let defaultTheme = "adventure"
        public static let moods = ["calm", "funny", "magical", "adventurous"]
        public static let defaultMood = "magical"
        public static let suggestionIDs = ["suggestion_1", "suggestion_2", "suggestion_3", "suggestion_4", "suggestion_5"]
    }

    public enum Setup {
        public static let ageRange = 3 ... 12
        public static let defaultAge = 6
        /// Differs from Create's options, as on Android (open question C1).
        public static let durationOptionsMinutes = [5, 10, 15]
        public static let defaultDurationMinutes = 10
        public static let interestIDs = ["animals", "cricket", "adventure", "space", "nature", "music"]
        public static let defaultInterestIDs = Array(interestIDs.prefix(3))
        public static let avatarCount = 3
        public static let nameMaxCharacters = 30
    }

    public enum Generation {
        public static let stepPercent = 4
        public static let stepInterval: Duration = .milliseconds(120)
        public static let autoAdvanceDelay: Duration = .milliseconds(500)
        /// Below the first value the stage is "imagining", below the second "writing", then "preparing narration".
        public static let stageThresholdsPercent = [38, 76]
        public static let restartPercent = 8
        /// Age range printed on a generated story, around the hero's age.
        public static let heroAgesBelow = 1
        public static let heroAgesAbove = 3
        /// Create themes whose catalogue category has a different id.
        public static let themeCategoryIDs = ["indian_folklore": "indian_tales", "fantasy": "adventure"]
        public static let coverPaletteID = "adventure"
        public static let coverMotifID = "cricket"
        public static let peekPageIndex = 1
        /// With a real story writer, progress waits here until the writer answers.
        public static let writerWaitPercent = 92
        public static let writerTimeout: Duration = .seconds(90)
    }

    public enum Player {
        public static let skipSeconds = 15
        public static let speedOptions: [Double] = [0.75, 1.0, 1.25, 1.5]
        public static let defaultSpeed = 1.0
        public static let simulatedTick: Duration = .milliseconds(500)
        /// Fraction of the story advanced per simulated tick at 1× speed (0.25 %).
        public static let tickFraction = 0.0025
        public static let defaultVolumePercent = 75
        public static let volumeMaxPercent = 100
        public static let sleepTimerMinutes = [10, 15, 30]
        /// Listening progress is saved every this many ticks while playing, and on pause.
        public static let progressSaveEveryTicks = 10
    }

    public enum Reader {
        public static let textScaleRange = 0.9 ... 1.3
        public static let textScaleStep = 0.1
        public static let textScaleDefault = 1.0
    }

    public enum Downloads {
        /// Simulated storage quota: 1 GB.
        public static let simulatedQuotaBytes: Int64 = 1_000_000_000
        /// Size recorded for a simulated download until stories carry their own sizes.
        public static let simulatedStoryBytes: Int64 = 12_000_000
        /// The storage bar never looks empty once something is downloaded (design: minimum 3 %).
        public static let storageBarMinFraction = 0.03
    }

    public enum Reminder {
        public static let defaultHour = 20
        public static let defaultMinute = 30
        /// ISO weekdays, Monday = 1 … Sunday = 7.
        public static let defaultDaysOfWeek = Array(1 ... 7)
    }

    public enum Discover {
        public static let filterIDs = [
            "all", "animals", "adventure", "friendship", "kindness", "nature", "space",
            "science", "panchatantra", "indian_folk_tales", "festivals", "learning",
        ]
        public static let sortOptionIDs = ["recommended", "shortest", "newest"]
        /// Filter id meaning "no category filter"; also the Category route id for the whole catalogue.
        public static let allID = "all"
        public static let defaultSortID = "recommended"
        public static let featuredStoryID = "story_little_elephant"
        public static let popularCount = 4
        public static let bedtimeCategoryID = "bedtime"
    }

    public enum Subscription {
        public static let defaultPlanID = "yearly"
        public static let freePlanID = "free"
    }

    /// Parental gate (App Store Kids category, guideline 1.3): "first × second", e.g. 14 × 7.
    public enum ParentalGate {
        public static let firstFactorRange = 11 ... 19
        public static let secondFactorRange = 3 ... 9
        public static let maxAnswerDigits = 6
    }

    public enum UI {
        public static let toastDuration: Duration = .milliseconds(2500)
        /// A screen that loads faster than this never shows its loading spinner.
        public static let loadingIndicatorDelay: Duration = .milliseconds(300)
    }
}
