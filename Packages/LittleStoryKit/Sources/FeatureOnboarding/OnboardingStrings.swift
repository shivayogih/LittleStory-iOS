import CoreUI
import Foundation

/// Typed keys for this target's `Localizable.xcstrings`.
enum OnboardingStrings {
    private static func key(_ name: String) -> LocalizedKey {
        LocalizedKey(name, bundle: .module)
    }

    static let eyebrow = key("onboarding.eyebrow")
    static let titles = [key("onboarding.title_1"), key("onboarding.title_2"), key("onboarding.title_3")]
    static let bodies = [key("onboarding.body_1"), key("onboarding.body_2"), key("onboarding.body_3")]
    static let getStarted = key("onboarding.cta_get_started")
    static let pagerDescription = key("onboarding.pager_description")

    static let setupBadge = key("setup.badge")
    static let setupTitle = key("setup.title")
    static let setupSubtitle = key("setup.subtitle")
    static let labelName = key("setup.label_name")
    static let placeholderName = key("setup.placeholder_name")
    static let labelAvatar = key("setup.label_avatar")
    static let labelAge = key("setup.label_age")
    static let labelLanguage = key("setup.label_language")
    static let labelInterests = key("setup.label_interests")
    static let labelDuration = key("setup.label_duration")
    static let ctaCreate = key("setup.cta_create")
    static let ctaCreateNamed = key("setup.cta_create_named")
    static let ctaSave = key("setup.cta_save")
    static let skip = key("setup.skip")
    static let errorNameEmpty = key("setup.error_name_empty")
    static let errorNameTooLong = key("setup.error_name_too_long")
    static let ageYears = key("setup.age_years")
}

/// Accessibility identifiers for UI tests; never user-facing.
public enum OnboardingID {
    public static let title = "onboarding.title"
    public static let continueButton = "onboarding.continue"
    public static let skip = "onboarding.skip"
    public static let pager = "onboarding.pager"
    public static let setupName = "setup.name"
    public static let setupSubmit = "setup.submit"
    public static let setupSkip = "setup.skip"
    public static let setupLanguage = "setup.language"
    public static let setupAge = "setup.age"
    public static func avatar(_ index: Int) -> String { "setup.avatar.\(index)" }
    public static func interest(_ id: String) -> String { "setup.interest.\(id)" }
    public static func duration(_ minutes: Int) -> String { "setup.duration.\(minutes)" }
}
