import Common
import CoreUI
import DesignSystem
import Domain
import SwiftUI

/// Where Create sends the user; the app maps these to its routes.
public struct CreateNavigation {
    public let startGeneration: (String) -> Void

    public init(startGeneration: @escaping (String) -> Void) {
        self.startGeneration = startGeneration
    }
}

public struct CreateRoute: View {
    @State private var viewModel: CreateViewModel
    private let navigation: CreateNavigation

    public init(viewModel: @autoclosure @escaping () -> CreateViewModel, navigation: CreateNavigation) {
        _viewModel = State(wrappedValue: viewModel())
        self.navigation = navigation
    }

    public var body: some View {
        let viewModel = viewModel
        CreateScreen(
            state: viewModel.state,
            actions: CreateActions(
                prompt: viewModel.onPromptChange,
                hero: viewModel.onHeroSelected,
                theme: viewModel.onThemeSelected,
                mood: viewModel.onMoodSelected,
                duration: viewModel.onDurationSelected,
                language: viewModel.onLanguageSelected,
                toggleMore: viewModel.onToggleMoreOptions,
                create: { Task { await viewModel.onCreate() } },
            ),
        )
        .task { await viewModel.start() }
        .task {
            for await effect in viewModel.effects {
                switch effect {
                case let .startGeneration(requestID): navigation.startGeneration(requestID)
                }
            }
        }
    }
}

struct CreateActions {
    let prompt: (String) -> Void
    let hero: (String) -> Void
    let theme: (String) -> Void
    let mood: (String) -> Void
    let duration: (Int) -> Void
    let language: (String) -> Void
    let toggleMore: () -> Void
    let create: () -> Void
}

/// SCR-07: describe the day, pick the hero and theme, optional mood, length and language.
struct CreateScreen: View {
    let state: CreateState
    let actions: CreateActions
    @Environment(\.locale) private var locale

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: LSSpacing.xl) {
                topBar
                intro
                PromptCard(state: state, onChange: actions.prompt)
                if state.showEmptyError {
                    LText(CreateStrings.errorEmpty)
                        .lsTextStyle(.body)
                        .foregroundStyle(LSColor.error)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(LSSpacing.md)
                        .background(LSColor.favouriteContainer, in: .rect(cornerRadius: LSRadius.small))
                        .accessibilityIdentifier(CreateID.error)
                }
                suggestions
                if let hero = state.hero {
                    HeroCard(hero: hero, heroes: state.heroes, onSelect: actions.hero)
                }
                themes
                MoreOptions(state: state, actions: actions)
                NotesBanner(UIText(CreateStrings.safetyNote), icon: .moon)
                LSButton(CreateStrings.submit.text(locale), action: actions.create)
                    .disabled(state.submitting)
                    .accessibilityIdentifier(CreateID.submit)
            }
            .padding(.horizontal, LSSpacing.screenHorizontal)
            .padding(.bottom, LSSpacing.screenBottom)
            .frame(maxWidth: LayoutTokens.readableMaxWidth)
            .frame(maxWidth: .infinity)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(LSColor.background)
    }

    private var topBar: some View {
        HStack(spacing: LSSpacing.sm) {
            LText(CreateStrings.title)
                .lsTextStyle(.topBarTitle)
                .foregroundStyle(LSColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier(CreateID.title)
            Spacer(minLength: LSSpacing.sm)
            HStack(spacing: LSSpacing.xs) {
                LSIconView(.check, size: LSDimens.iconSizeSmall)
                LText(CreateStrings.parentGuided).lsTextStyle(.chip)
            }
            .foregroundStyle(LSColor.success)
        }
        .frame(minHeight: LSDimens.topBarHeight)
    }

    private var intro: some View {
        HStack(alignment: .top, spacing: LSSpacing.lg) {
            Sparkle()
                .fill(LSColor.highlight)
                .frame(width: LSDimens.sparkleSize, height: LSDimens.sparkleSize)
                .frame(width: LSDimens.createOrbSize, height: LSDimens.createOrbSize)
                .background(LSColor.primary, in: .rect(cornerRadius: LSRadius.medium))
                .lsShadow(.primaryButton)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: LSSpacing.xs) {
                LText(CreateStrings.introTitle)
                    .lsTextStyle(.heroTitle)
                    .foregroundStyle(LSColor.textPrimary)
                LText(CreateStrings.introBody)
                    .lsTextStyle(.body)
                    .foregroundStyle(LSColor.textSecondary)
            }
        }
    }

    private var suggestions: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: LSSpacing.sm) {
                ForEach(state.suggestions) { suggestion in
                    Button {
                        actions.prompt(suggestion.fill.resolved(for: locale))
                    } label: {
                        HStack(spacing: LSSpacing.xs) {
                            LSIconView(.plus, size: LSDimens.iconSizeSmall).foregroundStyle(LSColor.primary)
                            LText(suggestion.label).lsTextStyle(.chip).foregroundStyle(LSColor.textPrimary)
                        }
                        .padding(.horizontal, LSSpacing.md)
                        .frame(minHeight: LSDimens.minTouchTarget)
                        .background(LSColor.surface, in: .capsule)
                        .overlay(Capsule().strokeBorder(LSColor.outline, lineWidth: LSDimens.borderWidth))
                    }
                    .buttonStyle(LSPressStyle())
                    .accessibilityIdentifier(CreateID.suggestion(suggestion.id))
                }
            }
        }
        .scrollClipDisabled()
    }

    private var themes: some View {
        VStack(alignment: .leading, spacing: LSSpacing.md) {
            LText(CreateStrings.themeTitle)
                .lsTextStyle(.itemTitle)
                .foregroundStyle(LSColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
            FlowLayout(spacing: LSSpacing.sm) {
                ForEach(AppConfig.Create.themes, id: \.self) { id in
                    LSChip(UIText(CreateStrings.theme(id)), selected: state.themeID == id) { actions.theme(id) }
                        .accessibilityIdentifier(CreateID.theme(id))
                }
            }
        }
    }
}

/// The multi-line prompt with its label and character counter.
private struct PromptCard: View {
    let state: CreateState
    let onChange: (String) -> Void
    @Environment(\.locale) private var locale
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: LSSpacing.sm) {
            LText(CreateStrings.promptLabel)
                .lsTextStyle(.itemTitle)
                .foregroundStyle(LSColor.textPrimary)
            TextField(
                text: Binding(get: { state.prompt }, set: onChange),
                prompt: state.placeholder.text(locale).foregroundStyle(LSColor.textSecondary),
                axis: .vertical,
            ) {
                LText(CreateStrings.promptLabel)
            }
            .focused($focused)
            .lsTextStyle(.bodyLarge)
            .foregroundStyle(LSColor.textPrimary)
            .frame(minHeight: LSDimens.promptMinHeight, alignment: .topLeading)
            .accessibilityIdentifier(CreateID.prompt)
            LText(state.counter)
                .lsTextStyle(.chip)
                .foregroundStyle(LSColor.textSecondary)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .accessibilityIdentifier(CreateID.counter)
        }
        .padding(LSSpacing.lg)
        .background(LSColor.surface, in: .rect(cornerRadius: LSRadius.large))
        .overlay(
            RoundedRectangle(cornerRadius: LSRadius.large)
                .strokeBorder(state.showEmptyError ? LSColor.error : LSColor.outline, lineWidth: LSDimens.borderWidth),
        )
        .contentShape(.rect)
        .onTapGesture { focused = true }
    }
}

/// The story hero; a menu changes it when the family has more than one child.
private struct HeroCard: View {
    let hero: HeroOption
    let heroes: [HeroOption]
    let onSelect: (String) -> Void
    @Environment(\.locale) private var locale

    var body: some View {
        if heroes.count > 1 {
            Menu {
                ForEach(heroes) { option in
                    Button { onSelect(option.id) } label: { LText(option.label) }
                }
            } label: {
                card(showsChevron: true)
            }
            .accessibilityHint(CreateStrings.heroChange.text(locale))
            .accessibilityIdentifier(CreateID.hero)
        } else {
            card(showsChevron: false)
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier(CreateID.hero)
        }
    }

    private func card(showsChevron: Bool) -> some View {
        HStack(spacing: LSSpacing.md) {
            Avatar(tone: hero.avatarTone)
            VStack(alignment: .leading, spacing: LSSpacing.xxs) {
                LText(CreateStrings.heroEyebrow)
                    .lsTextStyle(.eyebrow)
                    .foregroundStyle(LSColor.textSecondary)
                LText(hero.label)
                    .lsTextStyle(.itemTitle)
                    .foregroundStyle(LSColor.textPrimary)
            }
            Spacer(minLength: LSSpacing.sm)
            if showsChevron {
                LSIconView(.chevron, size: LSDimens.iconSizeSmall).foregroundStyle(LSColor.textSecondary)
            }
        }
        .padding(LSSpacing.md)
        .background(LSColor.surface, in: .rect(cornerRadius: LSRadius.large))
        .overlay(RoundedRectangle(cornerRadius: LSRadius.large).strokeBorder(LSColor.outline, lineWidth: LSDimens.borderWidth))
    }
}

/// Mood, length and story language behind a disclosure row.
private struct MoreOptions: View {
    let state: CreateState
    let actions: CreateActions
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.locale) private var locale

    var body: some View {
        VStack(alignment: .leading, spacing: LSSpacing.lg) {
            Divider().overlay(LSColor.outline)
            Button(action: actions.toggleMore) {
                HStack {
                    LText(CreateStrings.moreOptions)
                        .lsTextStyle(.itemTitle)
                        .foregroundStyle(LSColor.primary)
                    Spacer()
                    LSIconView(.chevron, size: LSDimens.iconSizeSmall)
                        .foregroundStyle(LSColor.primary)
                        .rotationEffect(.degrees(state.moreOptionsExpanded ? Chevron.up : Chevron.down))
                        .animation(LSMotion.standard(LSMotion.chevron, reduceMotion: reduceMotion), value: state.moreOptionsExpanded)
                }
                .frame(minHeight: LSDimens.minTouchTarget)
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityValue((state.moreOptionsExpanded ? CreateStrings.moreOptionsExpanded : CreateStrings.moreOptionsCollapsed)
                .text(locale))
            .accessibilityIdentifier(CreateID.moreOptions)
            if state.moreOptionsExpanded {
                options
            }
            Divider().overlay(LSColor.outline)
        }
    }

    private var options: some View {
        VStack(alignment: .leading, spacing: LSSpacing.lg) {
            FieldLabel(UIText(CreateStrings.moodTitle))
            FlowLayout(spacing: LSSpacing.sm) {
                ForEach(AppConfig.Create.moods, id: \.self) { id in
                    LSChip(UIText(CreateStrings.mood(id)), selected: state.moodID == id) { actions.mood(id) }
                        .accessibilityIdentifier(CreateID.mood(id))
                }
            }
            FieldLabel(UIText(CreateStrings.durationTitle))
            FlowLayout(spacing: LSSpacing.sm) {
                ForEach(AppConfig.Create.durationOptionsMinutes, id: \.self) { minutes in
                    LSChip(CreateStrings.durationMinutes(.number(minutes)), selected: state.durationMinutes == minutes) {
                        actions.duration(minutes)
                    }
                    .accessibilityIdentifier(CreateID.duration(minutes))
                }
            }
            LSSelect(
                UIText(CreateStrings.languageTitle),
                options: SupportedLanguages.enabled.map(\.tag),
                selected: state.languageTag,
                title: { .verbatim(SupportedLanguages.language(forTag: $0).nativeName) },
                identifier: CreateID.language,
                onSelect: actions.language,
            )
        }
        .padding(LSSpacing.lg)
        .background(LSColor.surface, in: .rect(cornerRadius: LSRadius.large))
    }

    /// The chevron icon points to the trailing side; rotated to point down or up.
    private enum Chevron {
        static let down = 90.0
        static let up = -90.0
    }
}
