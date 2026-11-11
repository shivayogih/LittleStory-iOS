import Common
import CoreUI
import DesignSystem
import Domain
import SwiftUI

public struct PlayerRoute: View {
    @State private var viewModel: PlayerViewModel
    private let navigation: ReaderNavigation

    public init(viewModel: @autoclosure @escaping () -> PlayerViewModel, navigation: ReaderNavigation) {
        _viewModel = State(wrappedValue: viewModel())
        self.navigation = navigation
    }

    public var body: some View {
        let viewModel = viewModel
        PlayerScreen(
            state: viewModel.state,
            storyID: viewModel.storyID,
            navigation: navigation,
            actions: PlayerActions(
                playPause: { Task { await viewModel.onPlayPause() } },
                seek: { fraction in Task { await viewModel.onSeek(fraction) } },
                rewind: viewModel.onRewind,
                forward: viewModel.onForward,
                previousChapter: viewModel.onPreviousChapter,
                nextChapter: viewModel.onNextChapter,
                speed: { Task { await viewModel.onSpeed() } },
                volume: viewModel.onVolumeChange,
                sleepTimer: viewModel.onSleepTimer,
                sleepDismiss: viewModel.onSleepSheetDismiss,
                sleepSelected: viewModel.onSleepTimerSelected,
                favourite: { Task { await viewModel.onFavourite() } },
                download: { Task { await viewModel.onDownload() } },
            ),
        )
        .task { await viewModel.start() }
    }
}

struct PlayerActions {
    let playPause: () -> Void
    let seek: (Double) -> Void
    let rewind: () -> Void
    let forward: () -> Void
    let previousChapter: () -> Void
    let nextChapter: () -> Void
    let speed: () -> Void
    let volume: (Int) -> Void
    let sleepTimer: () -> Void
    let sleepDismiss: () -> Void
    let sleepSelected: (SleepTimer) -> Void
    let favourite: () -> Void
    let download: () -> Void
}

/// SCR-11a/b: night player with cover, title, seek bar, transport, actions, volume and the sleep sheet.
struct PlayerScreen: View {
    let state: PlayerState
    let storyID: String
    let navigation: ReaderNavigation
    let actions: PlayerActions

    var body: some View {
        Group {
            if state.loading {
                LoadingIndicator()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if state.notFound {
                EmptyState(
                    icon: .book,
                    title: UIText(ReaderStrings.notFoundTitle),
                    message: UIText(ReaderStrings.notFoundText),
                    actionTitle: UIText(CoreUIStrings.actionBack),
                    action: navigation.back,
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(LSColor.background)
            } else {
                PlayerContent(state: state, storyID: storyID, navigation: navigation, actions: actions)
            }
        }
        .background(LSColor.night.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .sheet(isPresented: Binding(get: { state.sleepSheetOpen }, set: {
            if !$0 {
                actions.sleepDismiss()
            }
        })) {
            SleepSheet(options: state.sleepOptions, onSelect: actions.sleepSelected, onCancel: actions.sleepDismiss)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }
}

private struct PlayerContent: View {
    let state: PlayerState
    let storyID: String
    let navigation: ReaderNavigation
    let actions: PlayerActions
    @Environment(\.locale) private var locale
    @Environment(\.layoutClass) private var layoutClass

    var body: some View {
        ScrollView {
            VStack(spacing: LSSpacing.xl) {
                topBar
                LText(state.eyebrow)
                    .lsTextStyle(.eyebrow)
                    .foregroundStyle(LSColor.accent)
                StoryArt(paletteID: state.paletteID, motifID: state.motifID)
                    .frame(width: coverSize.width, height: coverSize.height)
                    .clipShape(.rect(cornerRadius: LSRadius.sheet))
                    .lsShadow(.primaryButton)
                VStack(spacing: LSSpacing.xs) {
                    Text(state.title)
                        .lsTextStyle(.heroTitle)
                        .foregroundStyle(LSColor.onNight)
                        .multilineTextAlignment(.center)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityIdentifier(ReaderID.playerTitle)
                    LText(state.subtitle)
                        .lsTextStyle(.chip)
                        .foregroundStyle(LSColor.accent)
                }
                seekBar
                transport
                Divider().overlay(LSColor.nightSurface)
                actionRow
                volume
            }
            .padding(.horizontal, LSSpacing.screenHorizontal)
            .padding(.bottom, LSSpacing.screenBottom)
            .frame(maxWidth: LayoutTokens.readableMaxWidth)
            .frame(maxWidth: .infinity)
        }
    }

    private var coverSize: CGSize {
        layoutClass == .compact
            ? CGSize(width: LSDimens.playerCoverCompactWidth, height: LSDimens.playerCoverCompactHeight)
            : CGSize(width: LSDimens.playerCoverWidth, height: LSDimens.playerCoverHeight)
    }

    private var topBar: some View {
        HStack {
            LSIconButton(.back, label: CoreUIStrings.actionBack.text(locale), action: navigation.back)
                .accessibilityIdentifier(ReaderID.playerBack)
            Spacer()
            Button { navigation.read(storyID) } label: {
                HStack(spacing: LSSpacing.sm) {
                    LSIconView(.book, size: LSDimens.iconSizeSmall)
                    LText(ReaderStrings.storyText).lsTextStyle(.chip)
                }
                .foregroundStyle(LSColor.onNight)
                .frame(minHeight: LSDimens.minTouchTarget)
            }
            .accessibilityIdentifier(ReaderID.storyText)
            Spacer()
            // Balances the back button so "Story text" stays centred.
            Color.clear.frame(width: LSDimens.minTouchTarget, height: LSDimens.minTouchTarget)
        }
    }

    private var seekBar: some View {
        VStack(spacing: LSSpacing.xs) {
            Slider(value: Binding(get: { state.position }, set: actions.seek), in: 0 ... 1)
                .tint(LSColor.accent)
                .accessibilityLabel(UIText(ReaderStrings.seek))
                .accessibilityValue(state.elapsedLabel.text(locale))
                .accessibilityIdentifier(ReaderID.seek)
            HStack {
                LText(state.elapsedLabel).accessibilityIdentifier(ReaderID.elapsed)
                Spacer()
                LText(state.totalLabel)
            }
            .lsTextStyle(.chip)
            .foregroundStyle(LSColor.accent)
            .accessibilityHidden(true)
        }
    }

    private var transport: some View {
        HStack {
            TransportButton(icon: .back, label: UIText(ReaderStrings.previousChapter), action: actions.previousChapter)
                .accessibilityIdentifier(ReaderID.previousChapter)
            Spacer()
            TransportButton(icon: .rewind15, label: state.rewindLabel, action: actions.rewind)
                .accessibilityIdentifier(ReaderID.rewind)
            Spacer()
            Button(action: actions.playPause) {
                LSIconView(state.playing ? .pause : .play)
                    .foregroundStyle(LSColor.primary)
                    .frame(width: LSDimens.playerPlayButtonSize, height: LSDimens.playerPlayButtonSize)
                    .background(LSColor.accent, in: .circle)
            }
            .buttonStyle(LSPressStyle())
            .accessibilityLabel(state.playLabel)
            .accessibilityIdentifier(ReaderID.playPause)
            Spacer()
            TransportButton(icon: .forward15, label: state.forwardLabel, action: actions.forward)
                .accessibilityIdentifier(ReaderID.forward)
            Spacer()
            TransportButton(icon: .chevron, label: UIText(ReaderStrings.nextChapter), action: actions.nextChapter)
                .accessibilityIdentifier(ReaderID.nextChapter)
        }
    }

    private var actionRow: some View {
        HStack(alignment: .top) {
            ActionTile(
                icon: .moon,
                title: UIText(ReaderStrings.sleepTimer),
                value: UIText(state.sleepTimerOn ? ReaderStrings.stateOn : ReaderStrings.stateOff),
                active: state.sleepTimerOn,
                action: actions.sleepTimer,
            )
            .accessibilityIdentifier(ReaderID.sleepTimer)
            ActionTile(
                icon: state.downloaded ? .downloadFilled : .download,
                title: UIText(state.downloaded ? ReaderStrings.downloaded : ReaderStrings.download),
                value: nil,
                active: state.downloaded,
                action: actions.download,
            )
            .accessibilityIdentifier(ReaderID.playerDownload)
            ActionTile(
                icon: state.favourite ? .heartFilled : .heart,
                title: UIText(state.favourite ? ReaderStrings.loved : ReaderStrings.favourite),
                value: nil,
                active: state.favourite,
                spoken: state.favouriteLabel,
                action: actions.favourite,
            )
            .accessibilityIdentifier(ReaderID.playerFavourite)
            Button(action: actions.speed) {
                VStack(spacing: LSSpacing.xs) {
                    LText(state.speedValue).lsTextStyle(.button)
                    LText(ReaderStrings.speed).lsTextStyle(.chip)
                }
                .foregroundStyle(LSColor.onNight)
                .frame(maxWidth: .infinity, minHeight: LSDimens.minTouchTarget)
                .contentShape(.rect)
            }
            .buttonStyle(LSPressStyle())
            .accessibilityLabel(state.speedDescription)
            .accessibilityIdentifier(ReaderID.speed)
        }
    }

    private var volume: some View {
        HStack(spacing: LSSpacing.md) {
            LSIconView(.volume, size: LSDimens.iconSizeSmall).foregroundStyle(LSColor.accent)
            Slider(
                value: Binding(get: { Double(state.volumePercent) }, set: { actions.volume(Int($0)) }),
                in: 0 ... Double(AppConfig.Player.volumeMaxPercent),
            )
            .tint(LSColor.accent)
            .accessibilityLabel(UIText(ReaderStrings.volume))
            .accessibilityIdentifier(ReaderID.volume)
        }
    }
}

private struct TransportButton: View {
    let icon: LSIcon
    let label: UIText
    let action: () -> Void
    @Environment(\.locale) private var locale

    var body: some View {
        Button(action: action) {
            LSIconView(icon)
                .foregroundStyle(LSColor.onNight)
                .frame(minWidth: LSDimens.minTouchTarget, minHeight: LSDimens.minTouchTarget)
                .contentShape(.rect)
        }
        .buttonStyle(LSPressStyle())
        .accessibilityLabel(label.text(locale))
    }
}

/// Icon over a caption; `value` is spoken as on/off for toggles.
private struct ActionTile: View {
    let icon: LSIcon
    let title: UIText
    let value: UIText?
    let active: Bool
    var spoken: UIText?
    let action: () -> Void
    @Environment(\.locale) private var locale

    var body: some View {
        Button(action: action) {
            VStack(spacing: LSSpacing.xs) {
                LSIconView(icon)
                LText(title).lsTextStyle(.chip)
            }
            .foregroundStyle(active ? LSColor.highlight : LSColor.accent)
            .frame(maxWidth: .infinity, minHeight: LSDimens.minTouchTarget)
            .contentShape(.rect)
        }
        .buttonStyle(LSPressStyle())
        .accessibilityLabel((spoken ?? title).text(locale))
        .accessibilityValue(value?.resolved(for: locale) ?? "")
    }
}

/// SCR-11b: timer choices, each a full-width row, and Cancel.
private struct SleepSheet: View {
    let options: [SleepOption]
    let onSelect: (SleepTimer) -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: LSSpacing.sm) {
            LText(ReaderStrings.sleepTitle)
                .lsTextStyle(.heroTitle)
                .foregroundStyle(LSColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
            LText(ReaderStrings.sleepBody)
                .lsTextStyle(.body)
                .foregroundStyle(LSColor.textSecondary)
            ForEach(options) { option in
                Button { onSelect(option.timer) } label: {
                    LText(option.label)
                        .lsTextStyle(.itemTitle)
                        .foregroundStyle(LSColor.textPrimary)
                        .frame(maxWidth: .infinity, minHeight: LSDimens.inputHeight, alignment: .leading)
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier(ReaderID.sleepOption(option.id))
                Divider().overlay(LSColor.outline)
            }
            Button(action: onCancel) {
                LText(ReaderStrings.sleepCancel)
                    .lsTextStyle(.button)
                    .foregroundStyle(LSColor.primary)
                    .frame(maxWidth: .infinity, minHeight: LSDimens.minTouchTarget)
            }
            .buttonStyle(.plain)
        }
        .padding(LSSpacing.xxl)
        .background(LSColor.surface)
    }
}
