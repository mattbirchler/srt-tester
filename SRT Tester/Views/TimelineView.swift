import SwiftUI

// MARK: - Playback Timeline View

struct PlaybackTimelineView: View {
    let progress: Double
    let duration: TimeInterval
    let subtitles: [Subtitle]
    let currentSubtitle: Subtitle?
    let onSeek: (Double) -> Void
    let onDragStart: () -> Void
    let onDragUpdate: (Double) -> Void
    let onDragEnd: () -> Void

    @State private var isHovering = false
    @State private var hoverPosition: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                Rectangle()
                    .fill(Theme.background)

                // Subtitle regions
                subtitleRegions(width: geometry.size.width)

                // Progress fill
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Theme.accentPrimary.opacity(0.4),
                                Theme.accentPrimary.opacity(0.2)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * progress)

                // Playhead
                playhead(at: geometry.size.width * progress, height: geometry.size.height)

                // Hover indicator
                if isHovering {
                    hoverIndicator(at: hoverPosition, height: geometry.size.height, totalWidth: geometry.size.width)
                }

                // Time markers
                timeMarkers(width: geometry.size.width)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if !isHovering {
                            onDragStart()
                        }
                        let progress = max(0, min(1, value.location.x / geometry.size.width))
                        onDragUpdate(progress)
                        hoverPosition = value.location.x
                        isHovering = true
                    }
                    .onEnded { _ in
                        isHovering = false
                        onDragEnd()
                    }
            )
            .onHover { hovering in
                isHovering = hovering
            }
            .onContinuousHover { phase in
                switch phase {
                case .active(let location):
                    hoverPosition = location.x
                    isHovering = true
                case .ended:
                    isHovering = false
                }
            }
        }
    }

    // MARK: - Subtitle Regions

    private func subtitleRegions(width: CGFloat) -> some View {
        ForEach(subtitles) { subtitle in
            let startX = (subtitle.startTime / duration) * width
            let endX = (subtitle.endTime / duration) * width
            let regionWidth = max(2, endX - startX)

            Rectangle()
                .fill(
                    subtitle == currentSubtitle ?
                    Theme.accentPrimary.opacity(0.5) :
                    Theme.signalBlue.opacity(0.3)
                )
                .frame(width: regionWidth)
                .offset(x: startX)
        }
    }

    // MARK: - Playhead

    private func playhead(at x: CGFloat, height: CGFloat) -> some View {
        ZStack {
            // Glow
            Rectangle()
                .fill(Theme.accentPrimary.opacity(0.5))
                .frame(width: 4)
                .blur(radius: 4)

            // Line
            Rectangle()
                .fill(Theme.accentPrimary)
                .frame(width: 2)

            // Handle
            VStack {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Theme.accentPrimary)
                    .frame(width: 12, height: 8)
                    .shadow(color: Theme.shadowMedium, radius: 2)

                Spacer()
            }
        }
        .frame(height: height)
        .offset(x: x - 1)
    }

    // MARK: - Hover Indicator

    private func hoverIndicator(at x: CGFloat, height: CGFloat, totalWidth: CGFloat) -> some View {
        let time = (x / totalWidth) * duration

        return ZStack {
            // Line
            Rectangle()
                .fill(Theme.textTertiary.opacity(0.5))
                .frame(width: 1)
                .frame(height: height)

            // Time tooltip
            VStack {
                Text(time.formattedTimecodeCompact)
                    .font(Theme.timecodeFontSmall)
                    .foregroundColor(Theme.textPrimary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Theme.surfaceTertiary)
                    .clipShape(RoundedRectangle(cornerRadius: 3))

                Spacer()
            }
        }
        .offset(x: x)
    }

    // MARK: - Time Markers

    private func timeMarkers(width: CGFloat) -> some View {
        let markerCount = max(1, Int(duration / 30)) // Marker every 30 seconds
        let markerSpacing = width / CGFloat(markerCount)

        return ZStack(alignment: .bottom) {
            ForEach(0..<markerCount, id: \.self) { index in
                let x = CGFloat(index) * markerSpacing

                VStack {
                    Spacer()
                    Rectangle()
                        .fill(Theme.border)
                        .frame(width: 1, height: index % 2 == 0 ? 8 : 4)
                }
                .offset(x: x)
            }
        }
    }
}

// MARK: - Mini Timeline (for subtitle list)

struct MiniTimeline: View {
    let subtitle: Subtitle
    let duration: TimeInterval
    let isActive: Bool

    var body: some View {
        GeometryReader { geometry in
            let startX = (subtitle.startTime / duration) * geometry.size.width
            let endX = (subtitle.endTime / duration) * geometry.size.width
            let regionWidth = max(2, endX - startX)

            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 2)
                    .fill(Theme.surfaceTertiary)

                // Region
                RoundedRectangle(cornerRadius: 2)
                    .fill(isActive ? Theme.accentPrimary : Theme.signalBlue.opacity(0.6))
                    .frame(width: regionWidth)
                    .offset(x: startX)
            }
        }
        .frame(height: 4)
    }
}
