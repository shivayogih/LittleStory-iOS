import CoreUI
import DesignSystem
import SwiftUI

/// Where Story ready sends the user.
public struct StoryReadyNavigation {
    public let back: () -> Void
    public let listen: (String) -> Void
    public let read: (String) -> Void
    public let myStories: () -> Void

    public init(
        back: @escaping () -> Void,
        listen: @escaping (String) -> Void,
        read: @escaping (String) -> Void,
        myStories: @escaping () -> Void,
    ) {
        self.back = back
        self.listen = listen
        self.read = read
        self.myStories = myStories
    }
}

public struct StoryReadyRoute: View {
    @State private var viewModel: StoryReadyViewModel
    private let navigation: StoryReadyNavigation

    public init(viewModel: @autoclosure @escaping () -> StoryReadyViewModel, navigation: StoryReadyNavigation) {
        _viewModel = State(wrappedValue: viewModel())
        self.navigation = navigation
    }

    public var body: some View {
        let viewModel = viewModel
        StoryReadyScreen(
            state: viewModel.state,
            navigation: navigation,
            onFavourite: { Task { await viewModel.onFavourite() } },
            onDownload: { Task { await viewModel.onDownload() } },
        )
        .task { await viewModel.start() }
    }
}

/// SCR-09: success ribbon, cover, title, meta, synopsis, a peek, Listen and Read.
struct StoryReadyScreen: View {
    let state: StoryReadyState
    let navigation: StoryReadyNavigation
    let onFavourite: () -> Void
    let onDownload: () -> Void

    var body: some View {
        Group {
            switch state {
            case .loading:
                LoadingIndicator()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .notFound:
                EmptyState(
                    icon: .book,
                    title: UIText(CreateStrings.readyNotFoundTitle),
                    message: UIText(CreateStrings.readyNotFoundText),
                    actionTitle: UIText(CoreUIStrings.actionBack),
                    action: navigation.back,
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            case let .loaded(content):
                ReadyContent(content: content, navigation: navigation, onFavourite: onFavourite, onDownload: onDownload)
            }
        }
        .background(LSColor.surface)
        .toolbar(.hidden, for: .navigationBar)
    }
}

private struct ReadyContent: View {
    let content: StoryReadyContent
    let navigation: StoryReadyNavigation
    let onFavourite: () -> Void
    let onDownload: () -> Void
    @Environment(\.locale) private var locale

    var body: some View {
        VStack(spacing: LSSpacing.none) {
            HStack(spacing: LSSpacing.sm) {
                LSIconView(.check, size: LSDimens.iconSizeSmall)
                LText(CreateStrings.readyRibbon).lsTextStyle(.button)
            }
            .foregroundStyle(LSColor.success)
            .frame(maxWidth: .infinity, minHeight: LSDimens.minTouchTarget)
            .background(LSColor.successRibbon)
            .accessibilityAddTraits(.isHeader)
            ScrollView {
                VStack(spacing: LSSpacing.none) {
                    cover
                    details
                        .background(
                            LSColor.surface,
                            in: UnevenRoundedRectangle(topLeadingRadius: LSRadius.sheet, topTrailingRadius: LSRadius.sheet),
                        )
                        .offset(y: -LSDimens.detailSheetOverlap)
                }
            }
        }
    }

    private var cover: some View {
        StoryArt(paletteID: content.paletteID, motifID: content.motifID)
            .frame(height: LSDimens.readyCoverHeight)
            .overlay(alignment: .top) {
                HStack(spacing: LSSpacing.sm) {
                    LSIconButton(.back, label: CoreUIStrings.actionBack.text(locale), action: navigation.back)
                        .accessibilityIdentifier(CreateID.readyBack)
                    Spacer()
                    LSIconButton(
                        content.favourite ? .heartFilled : .heart,
                        label: content.favouriteLabel.text(locale),
                        active: content.favourite,
                        action: onFavourite,
                    )
                    .accessibilityIdentifier(CreateID.readyFavourite)
                    LSIconButton(
                        content.downloaded ? .downloadFilled : .download,
                        label: content.downloadLabel.text(locale),
                        action: onDownload,
                    )
                    .accessibilityIdentifier(CreateID.readyDownload)
                }
                .padding(LSSpacing.lg)
            }
            .overlay(alignment: .bottomLeading) {
                if let madeFor = content.madeFor {
                    LText(madeFor)
                        .lsTextStyle(.chip)
                        .foregroundStyle(LSColor.primary)
                        .padding(.horizontal, LSSpacing.md)
                        .padding(.vertical, LSSpacing.sm)
                        .background(LSColor.surface, in: .capsule)
                        .padding(.horizontal, LSSpacing.screenHorizontal)
                        .padding(.bottom, LSDimens.detailSheetOverlap + LSSpacing.md)
                }
            }
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: LSSpacing.lg) {
            LText(CreateStrings.readyEyebrow)
                .lsTextStyle(.eyebrow)
                .foregroundStyle(LSColor.primaryVariantLabel)
            Text(content.title)
                .lsTextStyle(.displaySetup)
                .foregroundStyle(LSColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier(CreateID.readyTitle)
            LText(content.meta)
                .lsTextStyle(.chip)
                .foregroundStyle(LSColor.textSecondary)
            Text(content.synopsis)
                .lsTextStyle(.bodyLarge)
                .foregroundStyle(LSColor.textSecondary)
            HStack(spacing: LSSpacing.lg) {
                Rectangle().fill(LSColor.accent).frame(width: LSDimens.peekRuleWidth)
                VStack(alignment: .leading, spacing: LSSpacing.xs) {
                    LText(CreateStrings.readyPeekTitle)
                        .lsTextStyle(.itemTitle)
                        .foregroundStyle(LSColor.primary)
                    Text(content.peek)
                        .lsTextStyle(.body)
                        .italic()
                        .foregroundStyle(LSColor.textSecondary)
                }
            }
            .fixedSize(horizontal: false, vertical: true)
            ViewThatFits(in: .horizontal) {
                HStack(spacing: LSSpacing.md) { actions }
                VStack(spacing: LSSpacing.md) { actions }
            }
            Divider().overlay(LSColor.outline)
            Button { navigation.myStories() } label: {
                HStack(spacing: LSSpacing.md) {
                    LSIconView(.book).foregroundStyle(LSColor.textPrimary)
                    VStack(alignment: .leading, spacing: LSSpacing.xxs) {
                        LText(CreateStrings.readySavedTitle)
                            .lsTextStyle(.itemTitle)
                            .foregroundStyle(LSColor.textPrimary)
                        LText(CreateStrings.readySavedBody)
                            .lsTextStyle(.chip)
                            .foregroundStyle(LSColor.textSecondary)
                    }
                    Spacer(minLength: LSSpacing.sm)
                    LSIconView(.chevron, size: LSDimens.iconSizeSmall).foregroundStyle(LSColor.textSecondary)
                }
                .frame(minHeight: LSDimens.minTouchTarget)
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier(CreateID.readySaved)
        }
        .padding(.horizontal, LSSpacing.screenHorizontal)
        .padding(.top, LSSpacing.xxl)
        .padding(.bottom, LSSpacing.xxxl)
        .frame(maxWidth: LayoutTokens.readableMaxWidth, alignment: .leading)
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var actions: some View {
        LSButton(CreateStrings.readyListen.text(locale), leadingIcon: .play) { navigation.listen(content.id) }
            .accessibilityIdentifier(CreateID.readyListen)
        LSButton(CreateStrings.readyRead.text(locale), variant: .secondary, leadingIcon: .book) { navigation.read(content.id) }
            .accessibilityIdentifier(CreateID.readyRead)
    }
}
