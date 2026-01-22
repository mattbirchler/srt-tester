import SwiftUI
import UniformTypeIdentifiers

// MARK: - Content View

struct ContentView: View {
    @StateObject private var viewModel = PlayerViewModel()

    private var isReadyForAuditing: Bool {
        viewModel.isMediaLoaded && viewModel.isSRTLoaded
    }

    var body: some View {
        Group {
            if isReadyForAuditing {
                // Full auditing UI with sidebar
                HSplitView {
                    // Main content area
                    auditingContent
                        .frame(minWidth: 500)

                    // Sidebar
                    sidebar
                        .frame(minWidth: 280, idealWidth: 320, maxWidth: 400)
                }
            } else {
                // Setup view - drop zones for loading files
                setupContent
            }
        }
        .background(Theme.background)
        .preferredColorScheme(.dark)
        .onAppear {
            setupKeyboardShortcuts()
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
    }

    // MARK: - Setup Content (before both files loaded)

    private var setupContent: some View {
        VStack(spacing: 0) {
            // Top toolbar
            toolbar
                .padding(.horizontal, Theme.spacingM)
                .padding(.vertical, Theme.spacingS)

            Divider()
                .background(Theme.border)

            // Drop zones
            dropZones
                .padding(Theme.spacingL)
        }
    }

    // MARK: - Auditing Content (both files loaded)

    private var auditingContent: some View {
        VStack(spacing: 0) {
            // Top toolbar
            toolbar
                .padding(.horizontal, Theme.spacingM)
                .padding(.vertical, Theme.spacingS)

            Divider()
                .background(Theme.border)

            // Player view
            MediaPlayerView(viewModel: viewModel)
                .padding(Theme.spacingM)

            // Playback controls
            PlaybackControlsView(viewModel: viewModel)
        }
    }

    // MARK: - Toolbar

    private var toolbar: some View {
        HStack(spacing: Theme.spacingM) {
            // App title
            HStack(spacing: Theme.spacingS) {
                Image(systemName: "captions.bubble")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Theme.accentPrimary)

                Text("SRT Tester")
                    .font(Theme.headlineFont)
                    .foregroundColor(Theme.textPrimary)
            }

            Spacer()

            // File info
            if viewModel.isMediaLoaded || viewModel.isSRTLoaded {
                HStack(spacing: Theme.spacingM) {
                    if let mediaName = viewModel.mediaFileName {
                        FileInfoBadge(
                            icon: viewModel.isAudioOnly ? "waveform" : "film",
                            name: mediaName,
                            isLoaded: true
                        )
                    }

                    if let srtName = viewModel.srtFileName {
                        FileInfoBadge(
                            icon: "text.bubble",
                            name: srtName,
                            isLoaded: true
                        )
                    }
                }
            }

            Spacer()

            // Clear all button (only show when files are loaded)
            if viewModel.isMediaLoaded || viewModel.isSRTLoaded {
                Button(action: { viewModel.clearAll() }) {
                    HStack(spacing: Theme.spacingXS) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 11))
                        Text("Start Over")
                            .font(Theme.labelFont)
                    }
                }
                .buttonStyle(ToolbarButtonStyle())
            }
        }
    }

    // MARK: - Drop Zones

    private var dropZones: some View {
        HStack(spacing: Theme.spacingL) {
            DropZoneView(
                title: "Drop Video or Audio",
                subtitle: "MP4, MOV, MP3, WAV, AIFF",
                icon: "play.rectangle",
                acceptedTypes: [.movie, .audio, .mpeg4Movie, .quickTimeMovie, .mp3, .wav, .aiff],
                isLoaded: viewModel.isMediaLoaded,
                loadedFileName: viewModel.mediaFileName,
                onDrop: { url in
                    viewModel.loadMedia(url: url)
                },
                onClear: {
                    viewModel.clearMedia()
                }
            )

            DropZoneView(
                title: "Drop SRT File",
                subtitle: "SubRip subtitle format",
                icon: "text.bubble",
                acceptedTypes: [UTType(filenameExtension: "srt")!],
                isLoaded: viewModel.isSRTLoaded,
                loadedFileName: viewModel.srtFileName,
                onDrop: { url in
                    viewModel.loadSRT(url: url)
                },
                onClear: {
                    viewModel.clearSRT()
                }
            )
        }
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        VStack(spacing: 0) {
            // Current subtitle display
            LargeSubtitleDisplay(
                subtitle: viewModel.currentSubtitle,
                currentTime: viewModel.currentTime
            )
            .padding(Theme.spacingM)

            Divider()
                .background(Theme.border)

            // Stats
            SubtitleStatsView(
                subtitles: viewModel.subtitles,
                duration: viewModel.duration
            )
            .padding(Theme.spacingM)

            Divider()
                .background(Theme.border)

            // Subtitle list
            SubtitleListView(
                subtitles: viewModel.subtitles,
                currentSubtitle: viewModel.currentSubtitle,
                duration: viewModel.duration,
                selectedIndex: $viewModel.selectedSubtitleIndex,
                onSelect: { subtitle in
                    viewModel.seekToSubtitle(subtitle)
                }
            )
        }
        .background(Theme.surfacePrimary)
    }

    // MARK: - Helpers

    private func setupKeyboardShortcuts() {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            switch event.keyCode {
            case 49: // Space
                viewModel.togglePlayPause()
                return nil
            case 123: // Left arrow
                viewModel.skipBackward()
                return nil
            case 124: // Right arrow
                viewModel.skipForward()
                return nil
            case 125: // Down arrow
                viewModel.seekToNextSubtitle()
                return nil
            case 126: // Up arrow
                viewModel.seekToPreviousSubtitle()
                return nil
            default:
                return event
            }
        }
    }
}

// MARK: - Supporting Views

struct FileInfoBadge: View {
    let icon: String
    let name: String
    let isLoaded: Bool

    var body: some View {
        HStack(spacing: Theme.spacingXS) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundColor(Theme.accentPrimary)

            Text(name)
                .font(Theme.labelFont)
                .foregroundColor(Theme.textSecondary)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .padding(.horizontal, Theme.spacingS)
        .padding(.vertical, Theme.spacingXS)
        .background(Theme.surfaceSecondary)
        .clipShape(Capsule())
    }
}

struct ToolbarButtonStyle: ButtonStyle {
    var isDestructive: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(isDestructive ? Theme.signalRed : Theme.textSecondary)
            .padding(.horizontal, Theme.spacingS)
            .padding(.vertical, Theme.spacingXS)
            .background(
                configuration.isPressed ?
                Theme.surfaceTertiary :
                Theme.surfaceSecondary
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusS))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.radiusS)
                    .strokeBorder(Theme.borderSubtle, lineWidth: 1)
            )
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .frame(width: 1200, height: 800)
}
