import DesignSystem
import SwiftUI

/// Accessibility identifiers shared by story components; never user-facing.
public enum StoryComponentID {
    public static func card(_ id: String) -> String { "story.card.\(id)" }
    public static func favourite(_ id: String) -> String { "story.favourite.\(id)" }
    public static func row(_ id: String) -> String { "story.row.\(id)" }
    public static func play(_ id: String) -> String { "story.play.\(id)" }
}

/// Square cover with title and "Category · N min"; the heart toggles the favourite.
/// `width` nil fills the column (grids); a number fixes it (carousels).
public struct StoryCard: View {
    private let item: StoryItem
    private let width: CGFloat?
    private let onOpen: () -> Void
    private let onFavourite: () -> Void
    @Environment(\.locale) private var locale

    public init(
        _ item: StoryItem,
        width: CGFloat? = LSDimens.storyCardWidth,
        onOpen: @escaping () -> Void,
        onFavourite: @escaping () -> Void,
    ) {
        self.item = item
        self.width = width
        self.onOpen = onOpen
        self.onFavourite = onFavourite
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: LSSpacing.sm) {
            Button(action: onOpen) {
                VStack(alignment: .leading, spacing: LSSpacing.sm) {
                    StoryArt(paletteID: item.paletteID, motifID: item.motifID)
                        .aspectRatio(1, contentMode: .fit)
                        .clipShape(.rect(cornerRadius: LSRadius.medium))
                    Text(item.title)
                        .lsTextStyle(.itemTitle)
                        .foregroundStyle(LSColor.textPrimary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2, reservesSpace: true)
                    LText(item.cardMeta)
                        .lsTextStyle(.chip)
                        .foregroundStyle(LSColor.textSecondary)
                }
                .contentShape(.rect)
            }
            .buttonStyle(LSPressStyle())
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier(StoryComponentID.card(item.id))
        }
        .frame(width: width)
        .frame(maxWidth: width == nil ? .infinity : nil, alignment: .leading)
        .overlay(alignment: .topTrailing) {
            LSIconButton(
                item.favourite ? .heartFilled : .heart,
                label: item.favouriteLabel.text(locale),
                active: item.favourite,
                action: onFavourite,
            )
            .padding(LSSpacing.xs)
            .accessibilityIdentifier(StoryComponentID.favourite(item.id))
        }
    }
}

/// What the button at the trailing end of a `StoryRow` does.
public enum StoryRowTrailing {
    case favourite(() -> Void)
    /// "Play <title>" (My Stories); `label` is the spoken name.
    case play(label: UIText, action: () -> Void)
}

/// A list row: small cover, category, title, meta, offline note and a favourite or play button.
public struct StoryRow: View {
    private let item: StoryItem
    private let meta: UIText
    private let onOpen: () -> Void
    private let trailing: StoryRowTrailing
    @Environment(\.locale) private var locale

    public init(_ item: StoryItem, onOpen: @escaping () -> Void, onFavourite: @escaping () -> Void) {
        self.init(item, meta: item.listMeta, onOpen: onOpen, trailing: .favourite(onFavourite))
    }

    /// - Parameter meta: the line under the title; `item.listMeta` ("Ages 4–7 · 6 min") elsewhere.
    public init(_ item: StoryItem, meta: UIText, onOpen: @escaping () -> Void, trailing: StoryRowTrailing) {
        self.item = item
        self.meta = meta
        self.onOpen = onOpen
        self.trailing = trailing
    }

    public var body: some View {
        HStack(spacing: LSSpacing.md) {
            Button(action: onOpen) {
                HStack(spacing: LSSpacing.md) {
                    StoryArt(paletteID: item.paletteID, motifID: item.motifID)
                        .frame(width: LSDimens.listArtWidth, height: LSDimens.listArtHeight)
                        .clipShape(.rect(cornerRadius: LSRadius.small))
                    VStack(alignment: .leading, spacing: LSSpacing.xs) {
                        Text(item.categoryName)
                            .lsTextStyle(.eyebrow)
                            .foregroundStyle(LSColor.primaryVariantLabel)
                        Text(item.title)
                            .lsTextStyle(.itemTitle)
                            .foregroundStyle(LSColor.textPrimary)
                        LText(meta)
                            .lsTextStyle(.chip)
                            .foregroundStyle(LSColor.textSecondary)
                        if item.downloaded {
                            LText(UIText(CoreUIStrings.storyOffline))
                                .lsTextStyle(.chip)
                                .foregroundStyle(LSColor.success)
                        }
                    }
                    .multilineTextAlignment(.leading)
                    Spacer(minLength: 0)
                }
                .contentShape(.rect)
            }
            .buttonStyle(LSPressStyle())
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier(StoryComponentID.row(item.id))
            trailingButton
        }
        .padding(LSSpacing.md)
        .background(LSColor.surface, in: .rect(cornerRadius: LSRadius.large))
        .lsShadow(.soft)
    }

    @ViewBuilder
    private var trailingButton: some View {
        switch trailing {
        case let .favourite(action):
            LSIconButton(
                item.favourite ? .heartFilled : .heart,
                label: item.favouriteLabel.text(locale),
                active: item.favourite,
                action: action,
            )
            .accessibilityIdentifier(StoryComponentID.favourite(item.id))
        case let .play(label, action):
            LSIconButton(.play, label: label.text(locale), action: action)
                .accessibilityIdentifier(StoryComponentID.play(item.id))
        }
    }
}

/// Section title with an optional "See all ›" link at the trailing edge.
public struct SectionHeader: View {
    private let title: UIText
    private let link: UIText?
    private let linkID: String?
    private let onLink: () -> Void

    public init(_ title: UIText, link: UIText? = nil, linkID: String? = nil, onLink: @escaping () -> Void = {}) {
        self.title = title
        self.link = link
        self.linkID = linkID
        self.onLink = onLink
    }

    public var body: some View {
        HStack(alignment: .firstTextBaseline) {
            LText(title)
                .lsTextStyle(.homeTitle)
                .foregroundStyle(LSColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: LSSpacing.sm)
            if let link {
                Button(action: onLink) {
                    HStack(spacing: LSSpacing.xxs) {
                        LText(link).lsTextStyle(.button)
                        LSIconView(.chevron, size: LSDimens.iconSizeSmall)
                    }
                    .foregroundStyle(LSColor.primary)
                    .frame(minHeight: LSDimens.minTouchTarget)
                }
                .buttonStyle(LSPressStyle())
                .accessibilityIdentifier(linkID ?? "")
            }
        }
    }
}
