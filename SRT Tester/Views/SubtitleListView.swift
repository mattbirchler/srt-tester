import SwiftUI

// MARK: - Subtitle List View

struct SubtitleListView: View {
    let subtitles: [Subtitle]
    let currentSubtitle: Subtitle?
    let duration: TimeInterval
    @Binding var selectedIndex: Int?
    let onSelect: (Subtitle) -> Void

    @State private var searchText = ""
    @State private var scrollProxy: ScrollViewProxy?

    private var filteredSubtitles: [Subtitle] {
        if searchText.isEmpty {
            return subtitles
        }
        return subtitles.filter { $0.text.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            header

            Divider()
                .background(Theme.border)

            // Search
            searchBar
                .padding(Theme.spacingS)

            Divider()
                .background(Theme.border)

            // List
            if subtitles.isEmpty {
                emptyState
            } else if filteredSubtitles.isEmpty {
                noResultsState
            } else {
                subtitleList
            }
        }
        .background(Theme.surfacePrimary)
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            MonitorLabel(text: "Subtitles", isHighlighted: true)

            Spacer()

            HStack(spacing: Theme.spacingXS) {
                IndicatorLED(isOn: !subtitles.isEmpty, color: Theme.signalGreen, size: 6)
                Text("\(subtitles.count)")
                    .font(Theme.timecodeFont)
                    .foregroundColor(Theme.textSecondary)
            }
        }
        .padding(.horizontal, Theme.spacingM)
        .padding(.vertical, Theme.spacingS)
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: Theme.spacingS) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12))
                .foregroundColor(Theme.textTertiary)

            TextField("Search subtitles...", text: $searchText)
                .textFieldStyle(.plain)
                .font(Theme.bodyFont)
                .foregroundColor(Theme.textPrimary)

            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textTertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, Theme.spacingS)
        .padding(.vertical, Theme.spacingXS)
        .background(Theme.background)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusS))
    }

    // MARK: - Subtitle List

    private var subtitleList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 1) {
                    ForEach(filteredSubtitles) { subtitle in
                        SubtitleRow(
                            subtitle: subtitle,
                            duration: duration,
                            isActive: subtitle == currentSubtitle,
                            isSelected: selectedIndex == subtitles.firstIndex(of: subtitle)
                        )
                        .id(subtitle.id)
                        .onTapGesture {
                            onSelect(subtitle)
                        }
                    }
                }
                .padding(.vertical, Theme.spacingXS)
            }
            .onAppear {
                scrollProxy = proxy
            }
            .onChange(of: currentSubtitle) { _, newValue in
                if let subtitle = newValue {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        proxy.scrollTo(subtitle.id, anchor: .center)
                    }
                }
            }
        }
    }

    // MARK: - Empty States

    private var emptyState: some View {
        VStack(spacing: Theme.spacingM) {
            Image(systemName: "text.bubble")
                .font(.system(size: 32, weight: .light))
                .foregroundColor(Theme.textTertiary)

            Text("No Subtitles")
                .font(Theme.headlineFont)
                .foregroundColor(Theme.textSecondary)

            Text("Drop an SRT file to load subtitles")
                .font(Theme.labelFont)
                .foregroundColor(Theme.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(Theme.spacingXL)
    }

    private var noResultsState: some View {
        VStack(spacing: Theme.spacingM) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 24, weight: .light))
                .foregroundColor(Theme.textTertiary)

            Text("No Results")
                .font(Theme.headlineFont)
                .foregroundColor(Theme.textSecondary)

            Text("No subtitles match \"\(searchText)\"")
                .font(Theme.labelFont)
                .foregroundColor(Theme.textTertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(Theme.spacingXL)
    }
}

// MARK: - Subtitle Row

struct SubtitleRow: View {
    let subtitle: Subtitle
    let duration: TimeInterval
    let isActive: Bool
    let isSelected: Bool

    var body: some View {
        HStack(spacing: Theme.spacingS) {
            // Index
            Text("\(subtitle.index)")
                .font(Theme.timecodeFont)
                .foregroundColor(isActive ? Theme.accentPrimary : Theme.textTertiary)
                .frame(width: 32, alignment: .trailing)

            // Content
            VStack(alignment: .leading, spacing: Theme.spacingXS) {
                // Timing
                HStack(spacing: Theme.spacingXS) {
                    Text(subtitle.formattedStartTime)
                        .font(Theme.timecodeFontSmall)
                        .foregroundColor(Theme.textSecondary)

                    Image(systemName: "arrow.right")
                        .font(.system(size: 8))
                        .foregroundColor(Theme.textTertiary)

                    Text(subtitle.formattedEndTime)
                        .font(Theme.timecodeFontSmall)
                        .foregroundColor(Theme.textSecondary)

                    Spacer()

                    Text(String(format: "%.1fs", subtitle.duration))
                        .font(Theme.timecodeFontSmall)
                        .foregroundColor(Theme.textTertiary)
                }

                // Text
                Text(subtitle.text)
                    .font(Theme.bodyFont)
                    .foregroundColor(isActive ? Theme.textPrimary : Theme.textSecondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                // Mini timeline
                MiniTimeline(subtitle: subtitle, duration: duration, isActive: isActive)
            }
        }
        .padding(.horizontal, Theme.spacingM)
        .padding(.vertical, Theme.spacingS)
        .background(rowBackground)
        .overlay(
            Rectangle()
                .fill(isActive ? Theme.accentPrimary : Color.clear)
                .frame(width: 3)
                .frame(maxHeight: .infinity),
            alignment: .leading
        )
    }

    private var rowBackground: Color {
        if isActive {
            return Theme.accentPrimary.opacity(0.1)
        } else if isSelected {
            return Theme.surfaceSecondary
        } else {
            return Color.clear
        }
    }
}

// MARK: - Stats View

struct SubtitleStatsView: View {
    let subtitles: [Subtitle]
    let duration: TimeInterval

    private var totalSubtitleTime: TimeInterval {
        subtitles.reduce(0) { $0 + $1.duration }
    }

    private var averageDuration: TimeInterval {
        guard !subtitles.isEmpty else { return 0 }
        return totalSubtitleTime / Double(subtitles.count)
    }

    private var coverage: Double {
        guard duration > 0 else { return 0 }
        return totalSubtitleTime / duration
    }

    var body: some View {
        HStack(spacing: Theme.spacingL) {
            StatItem(label: "Count", value: "\(subtitles.count)")
            StatItem(label: "Avg Dur", value: String(format: "%.1fs", averageDuration))
            StatItem(label: "Coverage", value: String(format: "%.0f%%", coverage * 100))
        }
        .padding(Theme.spacingS)
        .background(Theme.background)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusS))
    }
}

struct StatItem: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(label.uppercased())
                .font(Theme.labelFontSmall)
                .foregroundColor(Theme.textTertiary)
                .tracking(0.8)

            Text(value)
                .font(Theme.timecodeFont)
                .foregroundColor(Theme.accentPrimary)
        }
    }
}
