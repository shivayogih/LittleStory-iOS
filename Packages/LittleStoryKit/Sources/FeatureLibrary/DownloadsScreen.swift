import Common
import CoreUI
import DesignSystem
import SwiftUI

public struct DownloadsRoute: View {
    @State private var viewModel: DownloadsViewModel
    private let navigation: LibraryNavigation

    public init(viewModel: @autoclosure @escaping () -> DownloadsViewModel, navigation: LibraryNavigation) {
        _viewModel = State(wrappedValue: viewModel())
        self.navigation = navigation
    }

    public var body: some View {
        let viewModel = viewModel
        DownloadsScreen(
            state: viewModel.state,
            navigation: navigation,
            onRemove: { id in Task { await viewModel.onRemove(storyID: id) } },
        )
        .task { await viewModel.start() }
    }
}

/// SCR-17: simulated storage card, saved stories with a remove button, and the privacy tip.
struct DownloadsScreen: View {
    let state: DownloadsState
    let navigation: LibraryNavigation
    let onRemove: (String) -> Void
    @Environment(\.locale) private var locale

    var body: some View {
        VStack(spacing: LSSpacing.none) {
            topBar
            ScrollView {
                VStack(alignment: .leading, spacing: LSSpacing.md) {
                    StorageCard(state: state)
                    if state.loading, state.items.isEmpty {
                        LoadingIndicator()
                    } else if state.isEmpty {
                        EmptyState(
                            icon: .download,
                            title: UIText(LibraryStrings.downloadsEmptyTitle),
                            message: UIText(LibraryStrings.downloadsEmptyText),
                            actionTitle: UIText(LibraryStrings.downloadsEmptyAction),
                            action: navigation.discover,
                        )
                        .frame(maxWidth: .infinity)
                        .accessibilityIdentifier(LibraryID.downloadsEmpty)
                    }
                    ForEach(state.items) { item in
                        DownloadRow(item: item) { onRemove(item.storyID) }
                    }
                    NotesBanner(UIText(LibraryStrings.downloadsTip), icon: .check)
                }
                .frame(maxWidth: LayoutTokens.readableMaxWidth)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, LSSpacing.screenHorizontal)
                .padding(.vertical, LSSpacing.md)
            }
        }
        .background(LSColor.background)
    }

    private var topBar: some View {
        HStack {
            LSIconButton(.back, label: CoreUIStrings.actionBack.text(locale), action: navigation.back)
                .accessibilityIdentifier(LibraryID.downloadsBack)
            Spacer()
            LText(LibraryStrings.downloadsTitle)
                .lsTextStyle(.topBarTitle)
                .foregroundStyle(LSColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier(LibraryID.downloadsTitle)
            Spacer()
            // Keeps the title centred against the back button.
            Color.clear.frame(width: LSDimens.minTouchTarget, height: LSDimens.minTouchTarget)
        }
        .padding(.horizontal, LSSpacing.screenHorizontal)
        .frame(minHeight: LSDimens.topBarHeight)
    }
}

/// "24 MB used", "1 GB available for stories" and the storage bar on the primary colour.
private struct StorageCard: View {
    let state: DownloadsState

    var body: some View {
        VStack(alignment: .leading, spacing: LSSpacing.sm) {
            LText(state.usedLabel)
                .lsTextStyle(.homeTitle)
                .foregroundStyle(LSColor.onPrimary)
            LText(state.quotaLabel)
                .lsTextStyle(.chip)
                .foregroundStyle(LSColor.secondaryContainer)
            GeometryReader { proxy in
                Capsule()
                    .fill(LSColor.primaryVariantLabel)
                    .overlay(alignment: .leading) {
                        Capsule()
                            .fill(LSColor.onPrimary)
                            .frame(width: proxy.size.width * state.usedFraction)
                    }
            }
            .frame(height: LSDimens.progressBarHeight)
            .accessibilityHidden(true)
        }
        .padding(LSSpacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LSColor.primary, in: .rect(cornerRadius: LSRadius.large))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(LibraryID.storage)
    }
}

private struct DownloadRow: View {
    let item: DownloadItem
    let onRemove: () -> Void
    @Environment(\.locale) private var locale

    var body: some View {
        HStack(spacing: LSSpacing.md) {
            StoryArt(paletteID: item.paletteID, motifID: item.motifID)
                .frame(width: LSDimens.recentArtSize, height: LSDimens.recentArtSize)
                .clipShape(.rect(cornerRadius: LSRadius.medium))
            VStack(alignment: .leading, spacing: LSSpacing.xxs) {
                HStack(spacing: LSSpacing.xxs) {
                    LSIconView(.check, size: LSDimens.iconSizeSmall)
                    LText(LibraryStrings.downloadsAvailable).lsTextStyle(.eyebrow)
                }
                .foregroundStyle(LSColor.success)
                Text(item.title)
                    .lsTextStyle(.itemTitle)
                    .foregroundStyle(LSColor.textPrimary)
                LText(item.sizeLabel)
                    .lsTextStyle(.chip)
                    .foregroundStyle(LSColor.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
            LSIconButton(.close, label: item.removeLabel.text(locale), action: onRemove)
                .accessibilityIdentifier(LibraryID.remove(item.storyID))
        }
        .padding(LSSpacing.md)
        .background(LSColor.surface, in: .rect(cornerRadius: LSRadius.large))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(LibraryID.download(item.storyID))
    }
}
