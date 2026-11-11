import Common
import CoreUI
import DesignSystem
import SwiftUI

public struct CategoryRoute: View {
    @State private var viewModel: CategoryViewModel
    private let navigation: DiscoverNavigation

    public init(viewModel: @autoclosure @escaping () -> CategoryViewModel, navigation: DiscoverNavigation) {
        _viewModel = State(wrappedValue: viewModel())
        self.navigation = navigation
    }

    public var body: some View {
        let viewModel = viewModel
        CategoryScreen(
            state: viewModel.state,
            navigation: navigation,
            onSort: viewModel.onSortSelected,
            onFavourite: { id in Task { await viewModel.onFavourite(storyID: id) } },
        )
        .task { await viewModel.start() }
    }
}

/// SCR-05: collection header, sort chips and the story list (two columns on wide windows).
struct CategoryScreen: View {
    let state: CategoryState
    let navigation: DiscoverNavigation
    let onSort: (String) -> Void
    let onFavourite: (String) -> Void
    @Environment(\.layoutClass) private var layoutClass

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: LSSpacing.lg) {
                VStack(alignment: .leading, spacing: LSSpacing.sm) {
                    LText(state.countLabel)
                        .lsTextStyle(.eyebrow)
                        .foregroundStyle(LSColor.primaryVariantLabel)
                    LText(state.title)
                        .lsTextStyle(.displaySetup)
                        .foregroundStyle(LSColor.textPrimary)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityIdentifier(DiscoverID.categoryTitle)
                    LText(state.summary)
                        .lsTextStyle(.bodyLarge)
                        .foregroundStyle(LSColor.textSecondary)
                }
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: LSSpacing.sm) {
                        ForEach(state.sortOptions) { option in
                            LSChip(option.label, selected: option.id == state.selectedSort) { onSort(option.id) }
                                .accessibilityIdentifier(DiscoverID.sort(option.id))
                        }
                    }
                }
                .accessibilityElement(children: .contain)
                .accessibilityLabel(UIText(DiscoverStrings.sortLabel))
                if state.loading {
                    LoadingIndicator()
                } else if state.stories.isEmpty {
                    EmptyState(
                        icon: .book,
                        title: UIText(DiscoverStrings.categoryEmptyTitle),
                        message: UIText(DiscoverStrings.categoryEmptyText),
                    )
                    .frame(maxWidth: .infinity)
                } else {
                    LazyVGrid(columns: columns, spacing: LSSpacing.md) {
                        ForEach(state.stories) { item in
                            StoryRow(item, onOpen: { navigation.story(item.id) }, onFavourite: { onFavourite(item.id) })
                        }
                    }
                }
            }
            .padding(.horizontal, LSSpacing.screenHorizontal)
            .padding(.vertical, LSSpacing.screenTop)
        }
        .background(LSColor.background)
    }

    private var columns: [GridItem] {
        let count = layoutClass == .compact ? 1 : 2
        return Array(repeating: GridItem(.flexible(), spacing: LSSpacing.md, alignment: .top), count: count)
    }
}
