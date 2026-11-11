import Common
import CoreUI
import DesignSystem
import Domain
import SwiftUI

/// Where Home sends the child. Home never knows other features' routes; the app supplies these.
public struct HomeNavigation {
    public var notifications: () -> Void
    public var profiles: () -> Void
    public var create: () -> Void
    public var resume: (String) -> Void
    public var discover: () -> Void
    public var category: (String) -> Void
    public var story: (String) -> Void

    public init(
        notifications: @escaping () -> Void,
        profiles: @escaping () -> Void,
        create: @escaping () -> Void,
        resume: @escaping (String) -> Void,
        discover: @escaping () -> Void,
        category: @escaping (String) -> Void,
        story: @escaping (String) -> Void,
    ) {
        self.notifications = notifications
        self.profiles = profiles
        self.create = create
        self.resume = resume
        self.discover = discover
        self.category = category
        self.story = story
    }
}

public struct HomeRoute: View {
    @State private var viewModel: HomeViewModel
    private let navigation: HomeNavigation

    public init(viewModel: @autoclosure @escaping () -> HomeViewModel, navigation: HomeNavigation) {
        _viewModel = State(wrappedValue: viewModel())
        self.navigation = navigation
    }

    public var body: some View {
        let viewModel = viewModel
        HomeScreen(state: viewModel.state, navigation: navigation) { id in
            Task { await viewModel.onFavourite(storyID: id) }
        }
        .task { await viewModel.start() }
    }
}

struct HomeScreen: View {
    let state: HomeState
    let navigation: HomeNavigation
    let onFavourite: (String) -> Void
    @Environment(\.layoutClass) private var layoutClass

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: LSSpacing.xxl) {
                header
                HeroCard(onCreate: navigation.create)
                if state.loading {
                    LoadingIndicator()
                } else {
                    if let item = state.continueListening {
                        ContinueSection(item: item) { navigation.resume(item.story.id) }
                    }
                    if !state.categories.isEmpty {
                        exploreSection
                    }
                    if !state.madeFor.isEmpty {
                        madeForSection
                    }
                }
                CultureBanner { navigation.category(AppConfig.Home.cultureCategoryID) }
            }
            .padding(.horizontal, LSSpacing.screenHorizontal)
            .padding(.vertical, LSSpacing.screenTop)
            .frame(maxWidth: layoutClass == .compact ? nil : LayoutTokens.readableMaxWidth * Self.wideContentScale)
            .frame(maxWidth: .infinity)
        }
        .background(LSColor.background)
    }

    /// On iPad the column is wider than reading text but still centred.
    private static let wideContentScale = 1.4

    private var header: some View {
        HStack(spacing: LSSpacing.sm) {
            VStack(alignment: .leading, spacing: LSSpacing.xxs) {
                LText(HomeStrings.greeting)
                    .lsTextStyle(.chip)
                    .foregroundStyle(LSColor.textSecondary)
                LText(state.title)
                    .lsTextStyle(.homeTitle)
                    .foregroundStyle(LSColor.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier(HomeID.title)
            }
            Spacer(minLength: 0)
            HeaderButtons(avatarTone: state.avatarTone, navigation: navigation)
        }
    }

    private var exploreSection: some View {
        VStack(alignment: .leading, spacing: LSSpacing.md) {
            SectionHeader(
                UIText(HomeStrings.exploreTitle),
                link: UIText(HomeStrings.seeAll),
                linkID: HomeID.seeAllExplore,
                onLink: navigation.discover,
            )
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: LSSpacing.xs) {
                    ForEach(state.categories) { category in
                        CategoryTile(category: category) { navigation.category(category.id) }
                    }
                }
            }
        }
    }

    private var madeForSection: some View {
        VStack(alignment: .leading, spacing: LSSpacing.md) {
            SectionHeader(state.madeForTitle, link: UIText(HomeStrings.seeAll), linkID: HomeID.seeAllMadeFor, onLink: navigation.discover)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: LSSpacing.md) {
                    ForEach(state.madeFor) { item in
                        StoryCard(item, onOpen: { navigation.story(item.id) }, onFavourite: { onFavourite(item.id) })
                    }
                }
            }
        }
    }
}

private struct HeaderButtons: View {
    let avatarTone: Int?
    let navigation: HomeNavigation
    @Environment(\.locale) private var locale

    var body: some View {
        LSIconButton(.bell, label: HomeStrings.notifications.text(locale), action: navigation.notifications)
            .accessibilityIdentifier(HomeID.bell)
        Button(action: navigation.profiles) {
            Avatar(tone: avatarTone ?? 0, size: LSDimens.homeAvatarSize)
                .frame(minWidth: LSDimens.minTouchTarget, minHeight: LSDimens.minTouchTarget)
        }
        .buttonStyle(LSPressStyle())
        .accessibilityLabel(UIText(HomeStrings.profiles))
        .accessibilityIdentifier(HomeID.avatar)
    }
}

/// "Tonight, anything is possible." with the Create button; the scene sits at the trailing side.
private struct HeroCard: View {
    let onCreate: () -> Void

    var body: some View {
        ZStack(alignment: .leading) {
            LSColor.primary
            HStack {
                Spacer()
                HeroScene()
                    .frame(width: LSDimens.heroSceneWidth)
            }
            VStack(alignment: .leading, spacing: LSSpacing.sm) {
                LText(HomeStrings.heroKicker)
                    .lsTextStyle(.heroKicker)
                    .foregroundStyle(LSColor.accent)
                LText(HomeStrings.heroTitle)
                    .lsTextStyle(.heroTitle)
                    .foregroundStyle(LSColor.onPrimary)
                    .accessibilityAddTraits(.isHeader)
                LText(HomeStrings.heroBody)
                    .lsTextStyle(.body)
                    .foregroundStyle(LSColor.onPrimary)
                Button(action: onCreate) {
                    HStack(spacing: LSSpacing.sm) {
                        LSIconView(.plus)
                        LText(HomeStrings.heroAction).lsTextStyle(.button)
                    }
                    .foregroundStyle(LSColor.primary)
                    .padding(.horizontal, LSSpacing.lg)
                    .frame(minHeight: LSDimens.minTouchTarget)
                    .background(LSColor.surface, in: .rect(cornerRadius: LSRadius.button))
                }
                .buttonStyle(LSPressStyle())
                .padding(.top, LSSpacing.sm)
                .accessibilityIdentifier(HomeID.create)
            }
            .padding(LSSpacing.xl)
            .padding(.trailing, LSDimens.heroSceneWidth / 2)
        }
        .frame(minHeight: LSDimens.heroMinHeight)
        .clipShape(.rect(cornerRadius: LSRadius.hero))
        .lsShadow(.hero)
    }
}

/// Moon and child on a hill, filling the hero's trailing side.
private struct HeroScene: View {
    var body: some View {
        GeometryReader { proxy in
            let unit = proxy.size.width
            ZStack {
                Moon(size: unit * Self.moon)
                    .position(x: unit * Self.moonX, y: proxy.size.height * Self.moonY)
                Circle()
                    .fill(LSColor.primaryVariantLabel)
                    .frame(width: unit * Self.hill, height: unit * Self.hill)
                    .position(x: unit * Self.hillX, y: proxy.size.height)
                ChildFigure(unit: unit, top: LSColor.Illustration.heroShirt)
                    .position(x: unit * Self.childX, y: proxy.size.height * Self.childY)
            }
        }
        .accessibilityHidden(true)
    }

    private static let moon = 0.6
    private static let moonX = 0.55
    private static let moonY = 0.28
    private static let hill = 1.3
    private static let hillX = 0.75
    private static let childX = 0.55
    private static let childY = 0.82
}

private struct Moon: View {
    let size: CGFloat
    private static let bite = 0.3

    var body: some View {
        Circle()
            .fill(LSColor.highlight)
            .overlay(Circle().fill(LSColor.primary).offset(x: -size * Self.bite, y: -size * Self.bite / 2))
            .clipShape(.circle)
            .frame(width: size, height: size)
    }
}

private struct ContinueSection: View {
    let item: ContinueItem
    let onResume: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: LSSpacing.md) {
            SectionHeader(UIText(HomeStrings.continueTitle))
            Button(action: onResume) {
                HStack(spacing: LSSpacing.lg) {
                    StoryArt(paletteID: item.story.paletteID, motifID: item.story.motifID)
                        .frame(width: LSDimens.listArtWidth, height: LSDimens.listArtHeight)
                        .clipShape(.rect(cornerRadius: LSRadius.small))
                    VStack(alignment: .leading, spacing: LSSpacing.sm) {
                        LText(item.eyebrow)
                            .lsTextStyle(.eyebrow)
                            .foregroundStyle(LSColor.primaryVariantLabel)
                        Text(item.story.title)
                            .lsTextStyle(.itemTitle)
                            .foregroundStyle(LSColor.textPrimary)
                        ProgressView(value: Double(item.percent), total: Double(Self.percent))
                            .tint(LSColor.accent)
                        HStack(spacing: LSSpacing.sm) {
                            LSIconView(.play, size: LSDimens.iconSizeSmall)
                            LText(HomeStrings.continueResume).lsTextStyle(.button)
                        }
                        .foregroundStyle(LSColor.primary)
                    }
                    .multilineTextAlignment(.leading)
                }
                .padding(LSSpacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(LSColor.surface, in: .rect(cornerRadius: LSRadius.large))
                .lsShadow(.soft)
            }
            .buttonStyle(LSPressStyle())
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier(HomeID.continueCard)
        }
    }

    private static let percent = 100
}

private struct CategoryTile: View {
    let category: CategoryTileItem
    let onOpen: () -> Void

    var body: some View {
        Button(action: onOpen) {
            VStack(spacing: LSSpacing.sm) {
                LSIconView(style.icon)
                    .foregroundStyle(LSColor.primary)
                    .frame(width: LSDimens.categoryTileSize, height: LSDimens.categoryTileSize)
                    .background(style.tint, in: .rect(cornerRadius: LSRadius.medium))
                Text(category.name)
                    .lsTextStyle(.chip)
                    .foregroundStyle(LSColor.textPrimary)
                    .multilineTextAlignment(.center)
            }
            .frame(width: LSDimens.categoryTileItemWidth)
        }
        .buttonStyle(LSPressStyle())
        .accessibilityIdentifier(HomeID.category(category.id))
    }

    /// Icon and pastel per category; others use the lavender book tile.
    private var style: (icon: LSIcon, tint: Color) {
        switch category.id {
        case "bedtime": (.moon, LSColor.CategoryTile.lavender)
        case "animals": (.book, LSColor.CategoryTile.peach)
        case "adventure": (.compass, LSColor.CategoryTile.mint)
        case "friendship": (.heart, LSColor.CategoryTile.pink)
        case "indian_tales": (.book, LSColor.CategoryTile.butter)
        default: (.book, LSColor.CategoryTile.lavender)
        }
    }
}

/// "Stories from every corner of India" banner with a gateway drawing at the trailing bottom.
private struct CultureBanner: View {
    let onOpen: () -> Void
    private static let archRatio = 0.55

    var body: some View {
        Button(action: onOpen) {
            VStack(alignment: .leading, spacing: LSSpacing.sm) {
                LText(HomeStrings.cultureKicker)
                    .lsTextStyle(.eyebrow)
                    .foregroundStyle(LSColor.primaryVariantLabel)
                LText(HomeStrings.cultureTitle)
                    .lsTextStyle(.homeTitle)
                    .foregroundStyle(LSColor.textPrimary)
                LText(HomeStrings.cultureBody)
                    .lsTextStyle(.body)
                    .foregroundStyle(LSColor.textSecondary)
                HStack(spacing: LSSpacing.xxs) {
                    LText(HomeStrings.cultureLink).lsTextStyle(.button)
                    LSIconView(.chevron, size: LSDimens.iconSizeSmall)
                }
                .foregroundStyle(LSColor.primary)
                .padding(.trailing, LSDimens.cultureArtWidth)
            }
            .multilineTextAlignment(.leading)
            .padding(LSSpacing.xl)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(alignment: .bottomTrailing) {
                UnevenRoundedRectangle(
                    topLeadingRadius: LSDimens.cultureArtWidth * Self.archRatio / 2,
                    topTrailingRadius: LSDimens.cultureArtWidth * Self.archRatio / 2,
                )
                .fill(LSColor.Illustration.terracotta)
                .frame(width: LSDimens.cultureArtWidth, height: LSDimens.cultureArtHeight)
                .padding(.trailing, LSSpacing.lg)
                .accessibilityHidden(true)
            }
            .background(LSColor.cultureBanner, in: .rect(cornerRadius: LSRadius.large))
            .clipShape(.rect(cornerRadius: LSRadius.large))
        }
        .buttonStyle(LSPressStyle())
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(HomeID.culture)
    }
}
