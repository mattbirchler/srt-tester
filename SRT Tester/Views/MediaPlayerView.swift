import SwiftUI
import AVKit

// MARK: - Media Player View

struct MediaPlayerView: View {
    @ObservedObject var viewModel: PlayerViewModel

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Theme.background

                if viewModel.isMediaLoaded {
                    if viewModel.isAudioOnly {
                        audioVisualization
                    } else {
                        videoPlayer
                    }

                    // Subtitle Overlay
                    VStack {
                        Spacer()
                        SubtitleOverlayView(subtitle: viewModel.currentSubtitle)
                            .padding(.bottom, 40)
                            .padding(.horizontal, 20)
                    }

                    // Scanline effect
                    ScanlineOverlay()
                        .opacity(0.3)

                } else {
                    emptyState
                }

                // Corner indicators
                cornerIndicators
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusM))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.radiusM)
                .strokeBorder(Theme.border, lineWidth: 1)
        )
    }

    // MARK: - Video Player

    @ViewBuilder
    private var videoPlayer: some View {
        if let player = viewModel.player {
            VideoPlayerRepresentable(player: player)
                .aspectRatio(16/9, contentMode: .fit)
        }
    }

    // MARK: - Audio Visualization

    private var audioVisualization: some View {
        VStack(spacing: Theme.spacingL) {
            // Audio icon
            ZStack {
                Circle()
                    .fill(Theme.surfaceSecondary)
                    .frame(width: 100, height: 100)

                Circle()
                    .strokeBorder(Theme.accentPrimary.opacity(0.3), lineWidth: 2)
                    .frame(width: 120, height: 120)
                    .scaleEffect(viewModel.isPlaying ? 1.2 : 1.0)
                    .opacity(viewModel.isPlaying ? 0 : 0.5)
                    .animation(
                        viewModel.isPlaying ?
                        Animation.easeOut(duration: 1.0).repeatForever(autoreverses: false) :
                            .default,
                        value: viewModel.isPlaying
                    )

                Image(systemName: viewModel.isPlaying ? "waveform" : "waveform")
                    .font(.system(size: 40, weight: .light))
                    .foregroundColor(Theme.accentPrimary)
                    .symbolEffect(.variableColor.iterative, isActive: viewModel.isPlaying)
            }

            // File name
            if let fileName = viewModel.mediaFileName {
                Text(fileName)
                    .font(Theme.bodyFont)
                    .foregroundColor(Theme.textSecondary)
                    .lineLimit(1)
            }

            // Waveform visualization
            WaveformView(isPlaying: viewModel.isPlaying, progress: viewModel.progress)
                .frame(height: 60)
                .padding(.horizontal, Theme.spacingXL)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: Theme.spacingM) {
            ZStack {
                RoundedRectangle(cornerRadius: Theme.radiusM)
                    .fill(Theme.surfaceSecondary)
                    .frame(width: 80, height: 80)

                Image(systemName: "play.rectangle")
                    .font(.system(size: 32, weight: .light))
                    .foregroundColor(Theme.textTertiary)
            }

            Text("No Media Loaded")
                .font(Theme.headlineFont)
                .foregroundColor(Theme.textSecondary)

            Text("Drop a video or audio file to begin")
                .font(Theme.labelFont)
                .foregroundColor(Theme.textTertiary)
        }
    }

    // MARK: - Corner Indicators

    private var cornerIndicators: some View {
        VStack {
            HStack {
                // Top left - Recording indicator style
                HStack(spacing: Theme.spacingXS) {
                    Circle()
                        .fill(viewModel.isPlaying ? Theme.signalRed : Theme.textTertiary)
                        .frame(width: 8, height: 8)
                        .shadow(color: viewModel.isPlaying ? Theme.signalRed.opacity(0.8) : .clear, radius: 4)

                    if viewModel.isPlaying {
                        Text("PLAY")
                            .font(Theme.labelFontSmall)
                            .foregroundColor(Theme.textSecondary)
                            .tracking(1)
                    }
                }
                .padding(Theme.spacingS)

                Spacer()

                // Top right - Timecode
                Text(viewModel.currentTime.formattedTimecodeCompact)
                    .font(Theme.timecodeFont)
                    .foregroundColor(Theme.accentPrimary)
                    .padding(.horizontal, Theme.spacingS)
                    .padding(.vertical, Theme.spacingXS)
                    .background(Theme.background.opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: Theme.radiusS))
                    .padding(Theme.spacingS)
            }

            Spacer()

            HStack {
                // Bottom left - Format indicator
                if viewModel.isMediaLoaded {
                    Text(viewModel.isAudioOnly ? "AUDIO" : "VIDEO")
                        .font(Theme.labelFontSmall)
                        .foregroundColor(Theme.textTertiary)
                        .tracking(1.2)
                        .padding(.horizontal, Theme.spacingS)
                        .padding(.vertical, Theme.spacingXS)
                        .background(Theme.background.opacity(0.8))
                        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusS))
                        .padding(Theme.spacingS)
                }

                Spacer()

                // Bottom right - Duration
                if viewModel.duration > 0 {
                    Text(viewModel.duration.formattedTimecodeShort)
                        .font(Theme.labelFontSmall)
                        .foregroundColor(Theme.textTertiary)
                        .padding(.horizontal, Theme.spacingS)
                        .padding(.vertical, Theme.spacingXS)
                        .background(Theme.background.opacity(0.8))
                        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusS))
                        .padding(Theme.spacingS)
                }
            }
        }
    }
}

// MARK: - Video Player Representable

struct VideoPlayerRepresentable: NSViewRepresentable {
    let player: AVPlayer

    func makeNSView(context: Context) -> AVPlayerView {
        let view = AVPlayerView()
        view.player = player
        view.controlsStyle = .none
        view.showsFullScreenToggleButton = false
        view.videoGravity = .resizeAspect
        return view
    }

    func updateNSView(_ nsView: AVPlayerView, context: Context) {
        nsView.player = player
    }
}
