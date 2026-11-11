import CoreUI
import DesignSystem
import SwiftUI

public struct StoryDetailRoute: View {
    @State private var viewModel: StoryDetailViewModel
    private let navigation: DiscoverNavigation

    public init(viewModel: @autoclosure @escaping () -> StoryDetailViewModel, navigation: DiscoverNavigation) {
        _viewModel = State(wrappedValue: viewModel())
        self.navigation = navigation
    }

    public var body: some View {
        let viewModel = viewModel
        StoryDetailScreen(
            state: viewModel.state,
            navigation: navigation,
            onFavourite: { Task { await viewModel.onFavourite() } },
            onDownload: { Task { await viewModel.onDownload() } },
        )
        .task { await viewModel.start() }
    }
}

/// SCR-06: full-bleed cover with back, favourite and download; details on a sheet; Listen and Read.
struct StoryDetailScreen: View {
    let state: StoryDetailState
    let navigation: DiscoverNavigation
    let onFavourite: () -> Void
    let onDownload: () -> Void

    var body: some View {
        switch state {
        case .loading:
            LoadingIndicator()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(LSColor.surface)
        case .notFound:
            EmptyState(
                icon: .book,
                title: UIText(DiscoverStrings.detailNotFoundTitle),
                message: UIText(DiscoverStrings.detailNotFoundText),
                actionTitle: UIText(CoreUIStrings.actionBack),
                action: navigation.back,
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(LSColor.background)
        case let .loaded(content):
            LoadedDetail(content: content, navigation: navigation, onFavourite: onFavourite, onDownload: onDownload)
        }
    }
}

private struct LoadedDetail: View {
    let content: StoryDetailContent
    let navigation: DiscoverNavigation
    let onFavourite: () -> Void
    let onDownload: () -> Void
    @Environment(\.locale) private var locale

    var body: some View {
        VStack(spacing: LSSpacing.none) {
            ScrollView {
                VStack(spacing: LSSpacing.none) {
                    StoryArt(paletteID: content.paletteID, motifID: content.motifID)
                        .frame(height: LSDimens.detailCoverHeight)
                    details
                        .background(
                            LSColor.surface,
                            in: UnevenRoundedRectangle(topLeadingRadius: LSRadius.sheet, topTrailingRadius: LSRadius.sheet),
                        )
                        .offset(y: -LSDimens.detailSheetOverlap)
                }
            }
            .ignoresSafeArea(edges: .top)
            actionBar
        }
        .background(LSColor.surface)
        .overlay(alignment: .top) { topButtons }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var topButtons: some View {
        HStack(spacing: LSSpacing.sm) {
            LSIconButton(.back, label: CoreUIStrings.actionBack.text(locale), action: navigation.back)
                .accessibilityIdentifier(DiscoverID.detailBack)
            Spacer()
            LSIconButton(
                content.favourite ? .heartFilled : .heart,
                label: content.favouriteLabel.text(locale),
                active: content.favourite,
                action: onFavourite,
            )
            .accessibilityIdentifier(DiscoverID.detailFavourite)
            LSIconButton(content.downloaded ? .downloadFilled : .download, label: content.downloadLabel.text(locale), action: onDownload)
                .accessibilityIdentifier(DiscoverID.detailDownload)
        }
        .padding(.horizontal, LSSpacing.lg)
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: LSSpacing.lg) {
            Text(content.categoryName)
                .lsTextStyle(.chip)
                .foregroundStyle(LSColor.onSecondaryContainer)
                .padding(.horizontal, LSSpacing.md)
                .padding(.vertical, LSSpacing.sm)
                .background(LSColor.secondaryContainer, in: .capsule)
            Text(content.title)
                .lsTextStyle(.displaySetup)
                .foregroundStyle(LSColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier(DiscoverID.detailTitle)
            LText(content.meta)
                .lsTextStyle(.chip)
                .foregroundStyle(LSColor.textSecondary)
            Text(content.synopsis)
                .lsTextStyle(.bodyLarge)
                .foregroundStyle(LSColor.textSecondary)
            HStack(alignment: .top, spacing: LSSpacing.md) {
                LSIconView(.heart)
                    .foregroundStyle(LSColor.textPrimary)
                    .frame(width: LSDimens.settingsIconTile, height: LSDimens.settingsIconTile)
                    .background(LSColor.warmAccent, in: .rect(cornerRadius: LSRadius.small))
                VStack(alignment: .leading, spacing: LSSpacing.xs) {
                    LText(DiscoverStrings.detailLessonTitle)
                        .lsTextStyle(.itemTitle)
                        .foregroundStyle(LSColor.textPrimary)
                    Text(content.lesson)
                        .lsTextStyle(.body)
                        .foregroundStyle(LSColor.textSecondary)
                }
                Spacer(minLength: 0)
            }
            .padding(LSSpacing.lg)
            .background(LSColor.lessonPanel, in: .rect(cornerRadius: LSRadius.large))
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: LSSpacing.xs) {
                    LText(DiscoverStrings.detailNarrationTitle)
                        .lsTextStyle(.itemTitle)
                        .foregroundStyle(LSColor.textPrimary)
                    LText(content.narration)
                        .lsTextStyle(.chip)
                        .foregroundStyle(LSColor.textSecondary)
                }
                Spacer(minLength: LSSpacing.sm)
                HStack(spacing: LSSpacing.xs) {
                    LSIconView(.check, size: LSDimens.iconSizeSmall)
                    LText(DiscoverStrings.detailNarrationAvailable).lsTextStyle(.chip)
                }
                .foregroundStyle(LSColor.success)
            }
        }
        .padding(.horizontal, LSSpacing.screenHorizontal)
        .padding(.top, LSSpacing.xxl)
        .padding(.bottom, LSSpacing.xxxl)
        .frame(maxWidth: LayoutTokens.readableMaxWidth, alignment: .leading)
        .frame(maxWidth: .infinity)
    }

    private var actionBar: some View {
        HStack(spacing: LSSpacing.md) {
            LSButton(DiscoverStrings.detailListen.text(locale), leadingIcon: .play) { navigation.listen(content.id) }
                .accessibilityIdentifier(DiscoverID.detailListen)
            LSButton(DiscoverStrings.detailRead.text(locale), variant: .secondary, leadingIcon: .book) { navigation.read(content.id) }
                .accessibilityIdentifier(DiscoverID.detailRead)
        }
        .padding(.horizontal, LSSpacing.screenHorizontal)
        .padding(.vertical, LSSpacing.md)
        .background(LSColor.surface)
    }
}
