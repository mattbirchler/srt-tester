import SwiftUI

// MARK: - Playback Controls View

struct PlaybackControlsView: View {
    @ObservedObject var viewModel: PlayerViewModel

    @State private var isDraggingTimeline = false
    @State private var dragProgress: Double = 0

    var body: some View {
        VStack(spacing: 0) {
            // Timeline
            PlaybackTimelineView(
                progress: isDraggingTimeline ? dragProgress : viewModel.progress,
                duration: viewModel.duration,
                subtitles: viewModel.subtitles,
                currentSubtitle: viewModel.currentSubtitle,
                onSeek: { progress in
                    viewModel.seekToProgress(progress)
                },
                onDragStart: {
                    isDraggingTimeline = true
                    dragProgress = viewModel.progress
                },
                onDragUpdate: { progress in
                    dragProgress = progress
                },
                onDragEnd: {
                    viewModel.seekToProgress(dragProgress)
                    isDraggingTimeline = false
                }
            )
            .frame(height: 48)

            Divider()
                .background(Theme.border)

            // Controls Bar
            HStack(spacing: Theme.spacingM) {
                // Left side - Timecode
                timecodeDisplay

                Spacer()

                // Center - Transport controls
                transportControls

                Spacer()

                // Right side - Additional controls
                additionalControls
            }
            .padding(.horizontal, Theme.spacingM)
            .padding(.vertical, Theme.spacingS)
        }
        .background(Theme.surfacePrimary)
    }

    // MARK: - Timecode Display

    private var timecodeDisplay: some View {
        HStack(spacing: Theme.spacingXS) {
            // Current time
            Text(viewModel.currentTime.formattedTimecodeCompact)
                .font(Theme.timecodeFont)
                .foregroundColor(Theme.accentPrimary)
                .frame(width: 90, alignment: .leading)

            Text("/")
                .font(Theme.timecodeFont)
                .foregroundColor(Theme.textTertiary)

            // Duration
            Text(viewModel.duration.formattedTimecodeCompact)
                .font(Theme.timecodeFont)
                .foregroundColor(Theme.textSecondary)
                .frame(width: 90, alignment: .leading)
        }
        .padding(.horizontal, Theme.spacingS)
        .padding(.vertical, Theme.spacingXS)
        .background(Theme.background)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusS))
    }

    // MARK: - Transport Controls

    private var transportControls: some View {
        HStack(spacing: Theme.spacingS) {
            // Previous subtitle
            TransportButton(icon: "backward.end.fill", size: .small) {
                viewModel.seekToPreviousSubtitle()
            }
            .disabled(viewModel.subtitles.isEmpty)

            // Skip backward
            TransportButton(icon: "gobackward.5", size: .small) {
                viewModel.skipBackward()
            }

            // Play/Pause
            TransportButton(
                icon: viewModel.isPlaying ? "pause.fill" : "play.fill",
                size: .large
            ) {
                viewModel.togglePlayPause()
            }
            .disabled(!viewModel.isMediaLoaded)

            // Skip forward
            TransportButton(icon: "goforward.5", size: .small) {
                viewModel.skipForward()
            }

            // Next subtitle
            TransportButton(icon: "forward.end.fill", size: .small) {
                viewModel.seekToNextSubtitle()
            }
            .disabled(viewModel.subtitles.isEmpty)
        }
    }

    // MARK: - Additional Controls

    private var additionalControls: some View {
        HStack(spacing: Theme.spacingM) {
            // Playback rate
            Menu {
                ForEach([0.5, 0.75, 1.0, 1.25, 1.5, 2.0], id: \.self) { rate in
                    Button(action: { viewModel.setPlaybackRate(Float(rate)) }) {
                        HStack {
                            Text("\(rate, specifier: "%.2g")×")
                            if viewModel.playbackRate == Float(rate) {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text("\(viewModel.playbackRate, specifier: "%.2g")×")
                        .font(Theme.labelFont)
                        .foregroundColor(viewModel.playbackRate != 1.0 ? Theme.accentPrimary : Theme.textSecondary)
                }
                .padding(.horizontal, Theme.spacingS)
                .padding(.vertical, Theme.spacingXS)
                .background(Theme.surfaceSecondary)
                .clipShape(RoundedRectangle(cornerRadius: Theme.radiusS))
            }
            .menuStyle(.borderlessButton)

            // Volume
            HStack(spacing: Theme.spacingXS) {
                Image(systemName: volumeIcon)
                    .font(.system(size: 12))
                    .foregroundColor(Theme.textSecondary)
                    .frame(width: 16)

                Slider(value: $viewModel.volume, in: 0...1)
                    .frame(width: 70)
                    .tint(Theme.accentPrimary)
            }
        }
    }

    private var volumeIcon: String {
        if viewModel.volume == 0 {
            return "speaker.slash.fill"
        } else if viewModel.volume < 0.5 {
            return "speaker.wave.1.fill"
        } else {
            return "speaker.wave.2.fill"
        }
    }
}

// MARK: - Transport Button

struct TransportButton: View {
    enum Size {
        case small, large

        var buttonSize: CGFloat {
            switch self {
            case .small: return 32
            case .large: return 44
            }
        }

        var iconSize: CGFloat {
            switch self {
            case .small: return 12
            case .large: return 18
            }
        }
    }

    let icon: String
    var size: Size = .small
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            ZStack {
                // Background
                Circle()
                    .fill(size == .large ? Theme.accentGradient : LinearGradient(colors: [Theme.surfaceTertiary], startPoint: .top, endPoint: .bottom))
                    .frame(width: size.buttonSize, height: size.buttonSize)

                // Border
                Circle()
                    .strokeBorder(
                        size == .large ? Theme.accentSecondary : Theme.border,
                        lineWidth: 1
                    )
                    .frame(width: size.buttonSize, height: size.buttonSize)

                // Icon
                Image(systemName: icon)
                    .font(.system(size: size.iconSize, weight: .semibold))
                    .foregroundColor(size == .large ? Theme.background : Theme.textSecondary)
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}
