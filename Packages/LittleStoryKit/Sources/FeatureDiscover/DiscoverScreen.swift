import Common
import CoreUI
import DesignSystem
import SwiftUI

public struct DiscoverRoute: View {
    @State private var viewModel: DiscoverViewModel
    private let navigation: DiscoverNavigation

    public init(viewModel: @autoclosure @escaping () -> DiscoverViewModel, navigation: DiscoverNavigation) {
        _viewModel = State(wrappedValue: viewModel())
        self.navigation = navigation
    }

    public var body: some View {
        let viewModel = viewModel
        DiscoverScreen(
            state: viewModel.state,
            navigation: navigation,
            actions: DiscoverActions(
                query: viewModel.onQueryChange,
                filter: viewModel.onFilterSelected,
                clear: viewModel.onClearSearch,
                favourite: { id in Task { await viewModel.onFavourite(storyID: id) } },
            ),
        )
        .task { await viewModel.start() }
    }
}

struct DiscoverActions {
    let query: (String) -> Void
    let filter: (String) -> Void
    let clear: () -> Void
    let favourite: (String) -> Void
}

struct DiscoverScreen: View {
    let state: DiscoverState
    let navigation: DiscoverNavigation
    let actions: DiscoverActions
    @Environment(\.locale) private var locale

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: LSSpacing.xl) {
                header
                SearchField(query: state.query, onChange: actions.query, onClear: actions.clear)
                if state.loading {
                    LoadingIndicator()
                } else {
                    if let featured = state.featured {
                        FeaturedCard(item: featured) { navigation.story(featured.story.id) }
                    }
                    filters
                    if state.hasNoResults {
                        EmptyState(
                            icon: .search,
                            title: UIText(DiscoverStrings.emptyTitle),
                            message: UIText(DiscoverStrings.emptyText),
                            actionTitle: UIText(DiscoverStrings.emptyAction),
                            action: actions.clear,
                        )
                        .frame(maxWidth: .infinity)
                        .accessibilityIdentifier(DiscoverID.empty)
                    } else {
                        results
                    }
                    if !state.bedtime.isEmpty {
                        bedtime
                    }
                }
            }
            .padding(.horizontal, LSSpacing.screenHorizontal)
            .padding(.vertical, LSSpacing.screenTop)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(LSColor.background)
    }

    private var header: some View {
        HStack(spacing: LSSpacing.lg) {
            BrandMark()
            LText(DiscoverStrings.title)
                .lsTextStyle(.topBarTitle)
                .foregroundStyle(LSColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier(DiscoverID.title)
            Spacer(minLength: 0)
            LSIconButton(.bell, label: DiscoverStrings.notifications.text(locale), action: navigation.notifications)
        }
        .frame(minHeight: LSDimens.topBarHeight)
    }

    private var filters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: LSSpacing.sm) {
                ForEach(state.filters) { chip in
                    LSChip(chip.label, selected: chip.id == state.selectedFilter) { actions.filter(chip.id) }
                        .accessibilityIdentifier(DiscoverID.filter(chip.id))
                }
            }
        }
    }

    private var results: some View {
        VStack(alignment: .leading, spacing: LSSpacing.md) {
            SectionHeader(
                state.sectionTitle,
                link: state.showViewAll ? UIText(DiscoverStrings.viewAll) : nil,
                linkID: DiscoverID.viewAll,
            ) { navigation.category(state.selectedFilter) }
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: LayoutTokens.cardMinWidth), spacing: LSSpacing.md, alignment: .top)],
                alignment: .leading,
                spacing: LSSpacing.xl,
            ) {
                ForEach(state.results) { item in
                    StoryCard(item, width: nil, onOpen: { navigation.story(item.id) }, onFavourite: { actions.favourite(item.id) })
                }
            }
        }
    }

    private var bedtime: some View {
        VStack(alignment: .leading, spacing: LSSpacing.md) {
            SectionHeader(UIText(DiscoverStrings.bedtime))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: LSSpacing.md) {
                    ForEach(state.bedtime) { item in
                        StoryCard(item, onOpen: { navigation.story(item.id) }, onFavourite: { actions.favourite(item.id) })
                    }
                }
            }
        }
    }
}

private struct SearchField: View {
    let query: String
    let onChange: (String) -> Void
    let onClear: () -> Void
    @Environment(\.locale) private var locale

    var body: some View {
        HStack(spacing: LSSpacing.sm) {
            LSIconView(.search, size: LSDimens.iconSizeSmall)
                .foregroundStyle(LSColor.textSecondary)
            TextField(
                text: Binding(get: { query }, set: onChange),
                prompt: DiscoverStrings.searchPlaceholder.text(locale).foregroundStyle(LSColor.textSecondary),
            ) {
                LText(DiscoverStrings.searchPlaceholder)
            }
            .submitLabel(.search)
            .autocorrectionDisabled()
            .lsTextStyle(.body)
            .foregroundStyle(LSColor.textPrimary)
            .accessibilityIdentifier(DiscoverID.search)
            if !query.isEmpty {
                Button(action: onClear) {
                    LSIconView(.close, label: DiscoverStrings.searchClear.text(locale), size: LSDimens.iconSizeSmall)
                        .foregroundStyle(LSColor.textSecondary)
                        .frame(minWidth: LSDimens.minTouchTarget, minHeight: LSDimens.minTouchTarget)
                }
                .accessibilityIdentifier(DiscoverID.clearSearch)
            }
        }
        .padding(.horizontal, LSSpacing.lg)
        .frame(minHeight: LSDimens.inputHeight)
        .background(LSColor.surface, in: .rect(cornerRadius: LSRadius.button))
        .overlay(RoundedRectangle(cornerRadius: LSRadius.button).strokeBorder(LSColor.outline, lineWidth: LSDimens.borderWidth))
    }
}

/// Dark card: kicker, title, synopsis, "Listen now ▷", cover at the trailing side.
private struct FeaturedCard: View {
    let item: FeaturedItem
    let onOpen: () -> Void

    var body: some View {
        Button(action: onOpen) {
            HStack(spacing: LSSpacing.none) {
                VStack(alignment: .leading, spacing: LSSpacing.sm) {
                    LText(DiscoverStrings.featuredKicker)
                        .lsTextStyle(.heroKicker)
                        .foregroundStyle(LSColor.highlight)
                    Text(item.story.title)
                        .lsTextStyle(.homeTitle)
                        .foregroundStyle(LSColor.onNight)
                    Text(item.synopsis)
                        .lsTextStyle(.body)
                        .foregroundStyle(LSColor.onNight)
                        .lineLimit(Self.synopsisLines)
                    HStack(spacing: LSSpacing.xs) {
                        LText(DiscoverStrings.featuredAction).lsTextStyle(.button)
                        LSIconView(.play, size: LSDimens.iconSizeSmall)
                    }
                    .foregroundStyle(LSColor.onNight)
                }
                .multilineTextAlignment(.leading)
                .padding(LSSpacing.xl)
                .frame(maxWidth: .infinity, alignment: .leading)
                StoryArt(paletteID: item.story.paletteID, motifID: item.story.motifID)
                    .frame(width: LSDimens.featuredArtWidth)
            }
            .background(LSColor.nightSurface)
            .clipShape(.rect(cornerRadius: LSRadius.large))
        }
        .buttonStyle(LSPressStyle())
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(DiscoverID.featured)
    }

    private static let synopsisLines = 3
}
