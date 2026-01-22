import SwiftUI

// MARK: - Subtitle Overlay View

struct SubtitleOverlayView: View {
    let subtitle: Subtitle?

    @State private var isVisible = false

    var body: some View {
        Group {
            if let subtitle = subtitle {
                subtitleDisplay(subtitle)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .animation(.easeInOut(duration: 0.15), value: subtitle?.id)
    }

    private func subtitleDisplay(_ subtitle: Subtitle) -> some View {
        VStack(spacing: Theme.spacingXS) {
            // Subtitle index badge
            HStack(spacing: Theme.spacingXS) {
                Text("#\(subtitle.index)")
                    .font(Theme.timecodeFontSmall)
                    .foregroundColor(Theme.accentPrimary)

                Text("•")
                    .foregroundColor(Theme.textTertiary)

                Text(subtitle.formattedStartTime)
                    .font(Theme.timecodeFontSmall)
                    .foregroundColor(Theme.textTertiary)
            }
            .padding(.horizontal, Theme.spacingS)
            .padding(.vertical, 2)
            .background(Theme.background.opacity(0.7))
            .clipShape(Capsule())

            // Main subtitle text
            Text(subtitle.text)
                .font(Theme.subtitleDisplayFont)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .shadow(color: .black, radius: 2, x: 0, y: 1)
                .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 2)
                .padding(.horizontal, Theme.spacingL)
                .padding(.vertical, Theme.spacingM)
                .background(
                    RoundedRectangle(cornerRadius: Theme.radiusS)
                        .fill(Color.black.opacity(0.75))
                )
        }
    }
}

// MARK: - Large Subtitle Display (for sidebar)

struct LargeSubtitleDisplay: View {
    let subtitle: Subtitle?
    let currentTime: TimeInterval

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacingM) {
            // Header
            HStack {
                MonitorLabel(text: "Current Subtitle", isHighlighted: subtitle != nil)

                Spacer()

                if let subtitle = subtitle {
                    HStack(spacing: Theme.spacingXS) {
                        IndicatorLED(isOn: true, color: Theme.signalGreen, size: 6)
                        Text("#\(subtitle.index)")
                            .font(Theme.timecodeFontSmall)
                            .foregroundColor(Theme.accentPrimary)
                    }
                }
            }

            if let subtitle = subtitle {
                // Progress within subtitle
                let progress = subtitleProgress(subtitle: subtitle, currentTime: currentTime)

                VStack(alignment: .leading, spacing: Theme.spacingS) {
                    // Timing info
                    HStack(spacing: Theme.spacingM) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("IN")
                                .font(Theme.labelFontSmall)
                                .foregroundColor(Theme.textTertiary)
                            Text(subtitle.formattedStartTime)
                                .font(Theme.timecodeFont)
                                .foregroundColor(Theme.textSecondary)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("OUT")
                                .font(Theme.labelFontSmall)
                                .foregroundColor(Theme.textTertiary)
                            Text(subtitle.formattedEndTime)
                                .font(Theme.timecodeFont)
                                .foregroundColor(Theme.textSecondary)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("DUR")
                                .font(Theme.labelFontSmall)
                                .foregroundColor(Theme.textTertiary)
                            Text(String(format: "%.1fs", subtitle.duration))
                                .font(Theme.timecodeFont)
                                .foregroundColor(Theme.accentPrimary)
                        }
                    }

                    // Progress bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Theme.surfaceTertiary)

                            RoundedRectangle(cornerRadius: 2)
                                .fill(Theme.accentGradient)
                                .frame(width: geo.size.width * progress)
                        }
                    }
                    .frame(height: 4)

                    // Subtitle text
                    Text(subtitle.text)
                        .font(Theme.bodyFont)
                        .foregroundColor(Theme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(Theme.spacingS)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Theme.background)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusS))
                }
            } else {
                // Empty state
                VStack(spacing: Theme.spacingS) {
                    Text("—")
                        .font(Theme.timecodeFontLarge)
                        .foregroundColor(Theme.textTertiary)

                    Text("No active subtitle")
                        .font(Theme.labelFont)
                        .foregroundColor(Theme.textTertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.spacingL)
            }
        }
        .padding(Theme.spacingM)
        .background(Theme.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusM))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.radiusM)
                .strokeBorder(Theme.border, lineWidth: 1)
        )
    }

    private func subtitleProgress(subtitle: Subtitle, currentTime: TimeInterval) -> Double {
        guard subtitle.duration > 0 else { return 0 }
        let elapsed = currentTime - subtitle.startTime
        return max(0, min(1, elapsed / subtitle.duration))
    }
}
