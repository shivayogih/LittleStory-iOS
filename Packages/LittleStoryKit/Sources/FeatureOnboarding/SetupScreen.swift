import Common
import CoreUI
import DesignSystem
import Domain
import SwiftUI

/// Owns the Setup view model and turns its effects into navigation and the language switch.
public struct SetupRoute: View {
    @State private var viewModel: SetupViewModel
    private let onApplyLanguage: (String) -> Void
    private let onDone: () -> Void

    public init(
        profiles: any ProfilesRepository,
        preferences: any PreferencesRepository,
        uiLanguageTag: String,
        childID: String? = nil,
        onApplyLanguage: @escaping (String) -> Void,
        onDone: @escaping () -> Void,
    ) {
        _viewModel = State(
            initialValue: SetupViewModel(profiles: profiles, preferences: preferences, uiLanguageTag: uiLanguageTag, childID: childID),
        )
        self.onApplyLanguage = onApplyLanguage
        self.onDone = onDone
    }

    public var body: some View {
        SetupScreen(state: viewModel.state, actions: actions)
            .task { await viewModel.start() }
            .task {
                for await effect in viewModel.effects {
                    switch effect {
                    case .done: onDone()
                    case let .applyLanguage(tag): onApplyLanguage(tag)
                    }
                }
            }
    }

    private var actions: SetupActions {
        let viewModel = viewModel
        return SetupActions(
            name: viewModel.onNameChange,
            avatar: viewModel.onAvatarSelected,
            age: viewModel.onAgeSelected,
            language: viewModel.onLanguageSelected,
            interest: viewModel.onInterestToggled,
            duration: viewModel.onDurationSelected,
            submit: { Task { await viewModel.onSubmit() } },
            skip: { Task { await viewModel.onSkip() } },
        )
    }
}

struct SetupActions {
    let name: (String) -> Void
    let avatar: (Int) -> Void
    let age: (Int) -> Void
    let language: (String) -> Void
    let interest: (String) -> Void
    let duration: (Int) -> Void
    let submit: () -> Void
    let skip: () -> Void
}

/// SCR-02: the child's name, avatar, age, language, interests and story length.
struct SetupScreen: View {
    let state: SetupState
    let actions: SetupActions
    @Environment(\.locale) private var locale

    var body: some View {
        VStack(spacing: LSSpacing.none) {
            topBar
            ScrollView {
                VStack(alignment: .leading, spacing: LSSpacing.lg) {
                    NotesBanner(UIText(OnboardingStrings.setupBadge), icon: .heart)
                    LText(OnboardingStrings.setupTitle)
                        .lsTextStyle(.displaySetup)
                        .foregroundStyle(LSColor.textPrimary)
                        .accessibilityAddTraits(.isHeader)
                    LText(OnboardingStrings.setupSubtitle)
                        .lsTextStyle(.bodyLarge)
                        .foregroundStyle(LSColor.textSecondary)
                    form
                }
                .padding(.horizontal, LSSpacing.screenHorizontal)
                .padding(.vertical, LSSpacing.screenTop)
                .frame(maxWidth: LayoutTokens.readableMaxWidth)
                .frame(maxWidth: .infinity)
            }
            .scrollDismissesKeyboard(.interactively)
            StickyActionBar(state.actionTitle, enabled: !state.loading, identifier: OnboardingID.setupSubmit, action: actions.submit)
        }
        .background(LSColor.background)
    }

    private var topBar: some View {
        HStack(spacing: LSSpacing.lg) {
            BrandMark()
            if !state.isEditing {
                Button(action: actions.skip) {
                    LText(OnboardingStrings.skip)
                        .lsTextStyle(.button)
                        .foregroundStyle(LSColor.primary)
                        .frame(minHeight: LSDimens.minTouchTarget)
                }
                .accessibilityIdentifier(OnboardingID.setupSkip)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, LSSpacing.screenHorizontal)
        .frame(minHeight: LSDimens.topBarHeight)
    }

    private var form: some View {
        VStack(alignment: .leading, spacing: LSSpacing.lg) {
            LSTextField(
                UIText(OnboardingStrings.labelName),
                text: Binding(get: { state.name }, set: actions.name),
                placeholder: UIText(OnboardingStrings.placeholderName),
                error: state.nameError,
                identifier: OnboardingID.setupName,
            )
            VStack(alignment: .leading, spacing: LSSpacing.xs) {
                FieldLabel(UIText(OnboardingStrings.labelAvatar))
                HStack(spacing: LSSpacing.md) {
                    ForEach(0 ..< AppConfig.Setup.avatarCount, id: \.self) { index in
                        Button {
                            actions.avatar(index)
                        } label: {
                            Avatar(tone: index, selected: state.avatar == index)
                        }
                        .buttonStyle(LSPressStyle())
                        .accessibilityLabel(OnboardingStrings.labelAvatar.text(locale))
                        .accessibilityValue(Text(index + 1, format: .number))
                        .accessibilityAddTraits(state.avatar == index ? .isSelected : [])
                        .accessibilityIdentifier(OnboardingID.avatar(index))
                    }
                }
            }
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: LSSpacing.md) {
                    ageSelect
                    languageSelect
                }
                VStack(alignment: .leading, spacing: LSSpacing.lg) {
                    ageSelect
                    languageSelect
                }
            }
            VStack(alignment: .leading, spacing: LSSpacing.sm) {
                FieldLabel(UIText(OnboardingStrings.labelInterests))
                FlowLayout(spacing: LSSpacing.sm) {
                    ForEach(AppConfig.Setup.interestIDs, id: \.self) { id in
                        LSChip(UIText(CoreUIStrings.interest(id)), selected: state.interestIDs.contains(id), multiSelect: true) {
                            actions.interest(id)
                        }
                        .accessibilityIdentifier(OnboardingID.interest(id))
                    }
                }
            }
            VStack(alignment: .leading, spacing: LSSpacing.xs) {
                FieldLabel(UIText(OnboardingStrings.labelDuration))
                LSSegmentedControl(
                    options: AppConfig.Setup.durationOptionsMinutes,
                    selected: state.durationMinutes,
                    label: { CoreUIStrings.metaMinutes(.number($0)) },
                    identifier: OnboardingID.duration,
                    onSelect: actions.duration,
                )
            }
        }
        .padding(LSSpacing.lg)
        .background(LSColor.surface, in: .rect(cornerRadius: LSRadius.large))
        .lsShadow(.soft)
    }

    private var ageSelect: some View {
        LSSelect(
            UIText(OnboardingStrings.labelAge),
            options: Array(AppConfig.Setup.ageRange),
            selected: state.age,
            title: { OnboardingStrings.ageYears(.number($0)) },
            identifier: OnboardingID.setupAge,
            onSelect: actions.age,
        )
    }

    private var languageSelect: some View {
        LSSelect(
            UIText(OnboardingStrings.labelLanguage),
            options: SupportedLanguages.enabled.map(\.tag),
            selected: state.languageTag,
            title: { .verbatim(SupportedLanguages.language(forTag: $0).nativeName) },
            identifier: OnboardingID.setupLanguage,
            onSelect: actions.language,
        )
    }
}
