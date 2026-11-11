import CoreUI
import DesignSystem
import SwiftUI

/// Where the Reader and Player send the user.
public struct ReaderNavigation {
    public let back: () -> Void
    public let listen: (String) -> Void
    public let read: (String) -> Void

    public init(back: @escaping () -> Void, listen: @escaping (String) -> Void, read: @escaping (String) -> Void) {
        self.back = back
        self.listen = listen
        self.read = read
    }
}

public struct ReaderRoute: View {
    @State private var viewModel: ReaderViewModel
    @Environment(\.layoutClass) private var layoutClass
    private let navigation: ReaderNavigation

    public init(viewModel: @autoclosure @escaping () -> ReaderViewModel, navigation: ReaderNavigation) {
        _viewModel = State(wrappedValue: viewModel())
        self.navigation = navigation
    }

    public var body: some View {
        let viewModel = viewModel
        ReaderScreen(
            state: viewModel.state,
            navigation: navigation,
            actions: ReaderActions(
                next: { Task { await viewModel.onNext() } },
                previous: { Task { await viewModel.onPrevious() } },
                smaller: { Task { await viewModel.onTextSmaller() } },
                larger: { Task { await viewModel.onTextLarger() } },
                favourite: { Task { await viewModel.onFavourite() } },
            ),
        )
        .task { await viewModel.start() }
        .onChange(of: layoutClass.showsReaderSpread, initial: true) { _, spread in
            viewModel.onSpreadChanged(spread)
        }
    }
}

struct ReaderActions {
    let next: () -> Void
    let previous: () -> Void
    let smaller: () -> Void
    let larger: () -> Void
    let favourite: () -> Void
}

/// SCR-10: one page at a time on a warm page colour, with text size and page controls; two pages
/// side by side on a wide window.
struct ReaderScreen: View {
    let state: ReaderState
    let navigation: ReaderNavigation
    let actions: ReaderActions

    var body: some View {
        Group {
            switch state {
            case .loading:
                LoadingIndicator()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .notFound:
                EmptyState(
                    icon: .book,
                    title: UIText(ReaderStrings.notFoundTitle),
                    message: UIText(ReaderStrings.notFoundText),
                    actionTitle: UIText(CoreUIStrings.actionBack),
                    action: navigation.back,
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            case let .loaded(content):
                ReaderPage(content: content, navigation: navigation, actions: actions)
            }
        }
        .background(LSColor.readerBackground)
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
    }
}

private struct ReaderPage: View {
    let content: ReaderContent
    let navigation: ReaderNavigation
    let actions: ReaderActions
    @Environment(\.locale) private var locale
    @Environment(\.layoutDirection) private var layoutDirection

    var body: some View {
        VStack(spacing: LSSpacing.none) {
            topBar
            ProgressLine(progress: content.progress)
            ScrollView {
                Group {
                    if let facing = content.facingText {
                        HStack(alignment: .top, spacing: LSSpacing.xxl) {
                            leadingPage
                            PageText(text: facing, scale: content.textScale, identifier: ReaderID.facingText)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    } else {
                        leadingPage
                    }
                }
                .padding(.horizontal, LSSpacing.screenHorizontal)
                .padding(.vertical, LSSpacing.xl)
                .frame(maxWidth: content.facingText == nil ? LayoutTokens.readableMaxWidth : LayoutTokens.readerSpreadMaxWidth)
                .frame(maxWidth: .infinity)
            }
            .id(content.page)
            .simultaneousGesture(swipe)
            bottomBar
        }
    }

    /// Title, art and the current page; the leading page of a spread.
    private var leadingPage: some View {
        VStack(spacing: LSSpacing.xl) {
            Text(content.title)
                .lsTextStyle(.heroTitle)
                .foregroundStyle(LSColor.textPrimary)
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)
            StoryArt(paletteID: content.paletteID, motifID: content.motifID)
                .frame(height: LSDimens.readerCoverHeight)
                .clipShape(.rect(cornerRadius: LSRadius.large))
            PageText(text: content.text, scale: content.textScale, identifier: ReaderID.text)
            Sparkle()
                .fill(LSColor.accent)
                .frame(width: LSDimens.sparkleSize, height: LSDimens.sparkleSize)
                .accessibilityHidden(true)
        }
        .frame(maxWidth: .infinity)
    }

    private var topBar: some View {
        VStack(spacing: LSSpacing.sm) {
            HStack {
                LSIconButton(.back, label: CoreUIStrings.actionBack.text(locale), action: navigation.back)
                    .accessibilityIdentifier(ReaderID.back)
                Spacer()
                LText(ReaderStrings.title)
                    .lsTextStyle(.topBarTitle)
                    .foregroundStyle(LSColor.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier(ReaderID.title)
                Spacer()
                LSIconButton(
                    content.favourite ? .heartFilled : .heart,
                    label: content.favouriteLabel.text(locale),
                    active: content.favourite,
                    action: actions.favourite,
                )
                .accessibilityIdentifier(ReaderID.favourite)
            }
            HStack(spacing: LSSpacing.sm) {
                LText(content.pageLabel)
                    .lsTextStyle(.chip)
                    .foregroundStyle(LSColor.textSecondary)
                    .accessibilityIdentifier(ReaderID.pageLabel)
                Spacer()
                SizeButton(
                    label: ReaderStrings.textSmallerLabel,
                    spoken: ReaderStrings.textSmaller,
                    enabled: content.canShrink,
                    action: actions.smaller,
                )
                .accessibilityIdentifier(ReaderID.smaller)
                SizeButton(
                    label: ReaderStrings.textLargerLabel,
                    spoken: ReaderStrings.textLarger,
                    enabled: content.canGrow,
                    action: actions.larger,
                )
                .accessibilityIdentifier(ReaderID.larger)
            }
        }
        .padding(.horizontal, LSSpacing.lg)
        .padding(.bottom, LSSpacing.sm)
    }

    private var bottomBar: some View {
        HStack {
            PageButton(icon: .back, label: ReaderStrings.previous, enabled: content.canGoBack, action: actions.previous)
                .keyboardShortcut(layoutDirection == .leftToRight ? .leftArrow : .rightArrow, modifiers: [])
                .accessibilityIdentifier(ReaderID.previous)
            Spacer()
            Button { navigation.listen(content.id) } label: {
                LSIconView(.play)
                    .foregroundStyle(LSColor.onPrimary)
                    .frame(width: LSDimens.readerPlayButtonSize, height: LSDimens.readerPlayButtonSize)
                    .background(LSColor.primary, in: .circle)
            }
            .buttonStyle(LSPressStyle())
            .accessibilityLabel(UIText(ReaderStrings.play))
            .accessibilityIdentifier(ReaderID.play)
            Spacer()
            PageButton(icon: .chevron, label: ReaderStrings.next, enabled: content.canGoForward, action: actions.next)
                .keyboardShortcut(layoutDirection == .leftToRight ? .rightArrow : .leftArrow, modifiers: [])
                .accessibilityIdentifier(ReaderID.next)
        }
        .padding(.horizontal, LSSpacing.xxl)
        .padding(.vertical, LSSpacing.md)
        .background(LSColor.surface)
        .overlay(alignment: .top) { Divider().overlay(LSColor.outline) }
    }

    /// Swiping toward the leading edge turns the page forward (mirrored in right-to-left).
    private var swipe: some Gesture {
        DragGesture(minimumDistance: LSSpacing.xxxl).onEnded { value in
            let width = value.translation.width
            guard abs(width) > abs(value.translation.height) else {
                return
            }
            let forward = layoutDirection == .leftToRight ? width < 0 : width > 0
            if forward {
                actions.next()
            } else {
                actions.previous()
            }
        }
    }
}

/// One page of story text at the child's chosen size.
private struct PageText: View {
    let text: String
    let scale: Double
    let identifier: String
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Text(text)
            .lsTextStyle(.readerBody, extraScale: scale)
            .foregroundStyle(LSColor.textReader)
            .frame(maxWidth: .infinity, alignment: .leading)
            .animation(LSMotion.standard(LSMotion.readerFontSize, reduceMotion: reduceMotion), value: scale)
            .accessibilityIdentifier(identifier)
    }
}

/// The thin line under the top bar showing how far into the story the child is.
private struct ProgressLine: View {
    let progress: Double
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Rectangle().fill(LSColor.outline)
                Rectangle().fill(LSColor.accent).frame(width: proxy.size.width * progress)
            }
        }
        .frame(height: LSDimens.readingProgressHeight)
        .animation(LSMotion.standard(LSMotion.readingProgress, reduceMotion: reduceMotion), value: progress)
        .accessibilityHidden(true)
    }
}

/// A− / A+ with a spoken label.
private struct SizeButton: View {
    let label: LocalizedKey
    let spoken: LocalizedKey
    let enabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            LText(label)
                .lsTextStyle(.button)
                .foregroundStyle(LSColor.textSecondary)
                .frame(minWidth: LSDimens.minTouchTarget, minHeight: LSDimens.minTouchTarget)
                .background(LSColor.surface, in: .rect(cornerRadius: LSRadius.small))
                .overlay(RoundedRectangle(cornerRadius: LSRadius.small).strokeBorder(LSColor.outline, lineWidth: LSDimens.borderWidth))
        }
        .buttonStyle(LSPressStyle())
        .disabled(!enabled)
        .opacity(enabled ? 1 : LSDimens.disabledOpacity)
        .accessibilityLabel(UIText(spoken))
    }
}

/// Previous / Next with an icon and a word.
private struct PageButton: View {
    let icon: LSIcon
    let label: LocalizedKey
    let enabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: LSSpacing.xxs) {
                LSIconView(icon, size: LSDimens.iconSizeSmall)
                LText(label).lsTextStyle(.chip)
            }
            .foregroundStyle(enabled ? LSColor.primary : LSColor.textSecondary)
            .frame(minWidth: LSDimens.minTouchTarget, minHeight: LSDimens.minTouchTarget)
            .contentShape(.rect)
        }
        .buttonStyle(LSPressStyle())
        .disabled(!enabled)
    }
}
