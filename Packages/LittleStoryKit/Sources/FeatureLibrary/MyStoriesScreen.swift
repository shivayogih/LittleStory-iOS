import Common
import CoreUI
import DesignSystem
import SwiftUI

public struct MyStoriesRoute: View {
    @State private var viewModel: MyStoriesViewModel
    private let navigation: LibraryNavigation

    public init(viewModel: @autoclosure @escaping () -> MyStoriesViewModel, navigation: LibraryNavigation) {
        _viewModel = State(wrappedValue: viewModel())
        self.navigation = navigation
    }

    public var body: some View {
        let viewModel = viewModel
        MyStoriesScreen(
            state: viewModel.state,
            navigation: navigation,
            actions: MyStoriesActions(
                query: viewModel.onQueryChange,
                clear: viewModel.onClearSearch,
                tab: viewModel.onTabSelected,
            ),
        )
        .task { await viewModel.start() }
    }
}

struct MyStoriesActions {
    let query: (String) -> Void
    let clear: () -> Void
    let tab: (LibraryTab) -> Void
}

/// SCR-12: search, tabs, "Recently played" and the list (two columns on wide windows).
struct MyStoriesScreen: View {
    let state: MyStoriesState
    let navigation: LibraryNavigation
    let actions: MyStoriesActions
    @Environment(\.locale) private var locale
    @Environment(\.layoutClass) private var layoutClass

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: LSSpacing.lg) {
                header
                SearchField(
                    query: state.query,
                    placeholder: UIText(LibraryStrings.search),
                    clearLabel: UIText(LibraryStrings.searchClear),
                    identifier: LibraryID.search,
                    clearIdentifier: LibraryID.clearSearch,
                    onChange: actions.query,
                    onClear: actions.clear,
                )
                tabs
                if let recent = state.recentlyPlayed {
                    SectionHeader(UIText(LibraryStrings.recentlyPlayed))
                    RecentCard(recent: recent) { navigation.play(recent.story.id) }
                }
                list
            }
            .padding(.horizontal, LSSpacing.screenHorizontal)
            .padding(.vertical, LSSpacing.screenTop)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(LSColor.background)
    }

    private var header: some View {
        HStack(spacing: LSSpacing.lg) {
            LText(LibraryStrings.title)
                .lsTextStyle(.topBarTitle)
                .foregroundStyle(LSColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier(LibraryID.title)
            Spacer(minLength: 0)
            LSIconButton(.download, label: LibraryStrings.openDownloads.text(locale), action: navigation.downloads)
                .accessibilityIdentifier(LibraryID.downloads)
        }
        .frame(minHeight: LSDimens.topBarHeight)
    }

    private var tabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: LSSpacing.sm) {
                ForEach(LibraryTab.allCases, id: \.self) { tab in
                    LSChip(tab.label, selected: tab == state.tab) { actions.tab(tab) }
                        .accessibilityIdentifier(LibraryID.tab(tab))
                }
            }
        }
    }

    @ViewBuilder
    private var list: some View {
        if state.loading {
            LoadingIndicator()
        } else if state.stories.isEmpty {
            EmptyState(
                icon: state.tab == .downloaded ? .download : .heart,
                title: state.emptyTitle,
                message: state.emptyText,
                actionTitle: UIText(LibraryStrings.emptyAction),
                action: navigation.discover,
            )
            .frame(maxWidth: .infinity)
            .accessibilityIdentifier(LibraryID.empty)
        } else {
            if state.showsCollectionTitle {
                SectionHeader(UIText(LibraryStrings.collection))
            }
            LazyVGrid(columns: columns, spacing: LSSpacing.md) {
                ForEach(state.stories) { item in
                    StoryRow(
                        item,
                        meta: item.libraryMeta,
                        onOpen: { open(item.id) },
                        trailing: .play(label: item.playLabel, action: { navigation.play(item.id) }),
                    )
                }
            }
        }
    }

    private var columns: [GridItem] {
        let count = layoutClass == .compact ? 1 : 2
        return Array(repeating: GridItem(.flexible(), spacing: LSSpacing.md, alignment: .top), count: count)
    }

    private func open(_ id: String) {
        if state.createdIDs.contains(id) {
            navigation.createdStory(id)
        } else {
            navigation.story(id)
        }
    }
}

/// Cover, title, time left, progress and a round play button.
private struct RecentCard: View {
    let recent: RecentlyPlayed
    let onPlay: () -> Void

    var body: some View {
        Button(action: onPlay) {
            HStack(spacing: LSSpacing.md) {
                StoryArt(paletteID: recent.story.paletteID, motifID: recent.story.motifID)
                    .frame(width: LSDimens.recentArtSize, height: LSDimens.recentArtSize)
                    .clipShape(.rect(cornerRadius: LSRadius.medium))
                VStack(alignment: .leading, spacing: LSSpacing.xs) {
                    Text(recent.story.title)
                        .lsTextStyle(.itemTitle)
                        .foregroundStyle(LSColor.textPrimary)
                    LText(recent.remainingLabel)
                        .lsTextStyle(.chip)
                        .foregroundStyle(LSColor.textSecondary)
                    ProgressView(value: recent.progress)
                        .tint(LSColor.accent)
                }
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                LSIconView(.play, size: LSDimens.iconSize)
                    .foregroundStyle(LSColor.primary)
                    .frame(width: LSDimens.roundPlaySize, height: LSDimens.roundPlaySize)
                    .background(LSColor.secondaryContainer, in: .circle)
            }
            .padding(LSSpacing.md)
            .background(LSColor.surface, in: .rect(cornerRadius: LSRadius.large))
            .lsShadow(.soft)
        }
        .buttonStyle(LSPressStyle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(recent.playLabel)
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier(LibraryID.recent)
    }
}
