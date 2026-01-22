import SwiftUI
import AVFoundation
import Combine

// MARK: - Player View Model

@MainActor
class PlayerViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var mediaURL: URL?
    @Published var srtURL: URL?
    @Published var subtitles: [Subtitle] = []
    @Published var currentSubtitle: Subtitle?
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var isPlaying: Bool = false
    @Published var isMediaLoaded: Bool = false
    @Published var isSRTLoaded: Bool = false
    @Published var volume: Float = 1.0
    @Published var playbackRate: Float = 1.0
    @Published var errorMessage: String?
    @Published var selectedSubtitleIndex: Int?
    @Published var isAudioOnly: Bool = false

    // MARK: - Player

    private(set) var player: AVPlayer?
    private var timeObserver: Any?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Computed Properties

    var hasMedia: Bool {
        mediaURL != nil
    }

    var hasSRT: Bool {
        !subtitles.isEmpty
    }

    var progress: Double {
        guard duration > 0 else { return 0 }
        return currentTime / duration
    }

    var mediaFileName: String? {
        mediaURL?.lastPathComponent
    }

    var srtFileName: String? {
        srtURL?.lastPathComponent
    }

    // MARK: - Initialization

    init() {
        setupVolumeObserver()
        setupRateObserver()
    }

    deinit {
        if let observer = timeObserver, let player = player {
            player.removeTimeObserver(observer)
        }
    }

    // MARK: - Media Loading

    func loadMedia(url: URL) {
        // Clean up existing player
        removeTimeObserver()
        player?.pause()

        mediaURL = url
        errorMessage = nil

        // Check if it's audio or video
        let asset = AVURLAsset(url: url)
        Task {
            do {
                let tracks = try await asset.loadTracks(withMediaType: .video)
                isAudioOnly = tracks.isEmpty

                let durationValue = try await asset.load(.duration)
                duration = CMTimeGetSeconds(durationValue)

                let playerItem = AVPlayerItem(asset: asset)
                player = AVPlayer(playerItem: playerItem)
                player?.volume = volume
                player?.rate = 0

                setupTimeObserver()
                setupEndObserver()

                isMediaLoaded = true
                currentTime = 0

            } catch {
                errorMessage = "Failed to load media: \(error.localizedDescription)"
                isMediaLoaded = false
            }
        }
    }

    func loadSRT(url: URL) {
        srtURL = url
        errorMessage = nil

        do {
            subtitles = try SRTParser.parse(url: url)
            isSRTLoaded = true
            updateCurrentSubtitle()
        } catch {
            errorMessage = "Failed to parse SRT: \(error.localizedDescription)"
            subtitles = []
            isSRTLoaded = false
        }
    }

    // MARK: - Playback Controls

    func play() {
        player?.rate = playbackRate
        isPlaying = true
    }

    func pause() {
        player?.pause()
        isPlaying = false
    }

    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }

    func seek(to time: TimeInterval) {
        let cmTime = CMTime(seconds: time, preferredTimescale: 600)
        player?.seek(to: cmTime, toleranceBefore: .zero, toleranceAfter: .zero)
        currentTime = time
        updateCurrentSubtitle()
    }

    func seekToProgress(_ progress: Double) {
        let time = progress * duration
        seek(to: time)
    }

    func skipForward(seconds: TimeInterval = 5) {
        let newTime = min(currentTime + seconds, duration)
        seek(to: newTime)
    }

    func skipBackward(seconds: TimeInterval = 5) {
        let newTime = max(currentTime - seconds, 0)
        seek(to: newTime)
    }

    func seekToSubtitle(_ subtitle: Subtitle) {
        seek(to: subtitle.startTime)
        selectedSubtitleIndex = subtitles.firstIndex(of: subtitle)
    }

    func seekToPreviousSubtitle() {
        guard !subtitles.isEmpty else { return }

        // Find the subtitle before current time
        let previousSubtitles = subtitles.filter { $0.startTime < currentTime - 0.5 }
        if let previous = previousSubtitles.last {
            seekToSubtitle(previous)
        } else if let first = subtitles.first {
            seekToSubtitle(first)
        }
    }

    func seekToNextSubtitle() {
        guard !subtitles.isEmpty else { return }

        // Find the subtitle after current time
        let nextSubtitles = subtitles.filter { $0.startTime > currentTime + 0.1 }
        if let next = nextSubtitles.first {
            seekToSubtitle(next)
        }
    }

    func setPlaybackRate(_ rate: Float) {
        playbackRate = rate
        if isPlaying {
            player?.rate = rate
        }
    }

    // MARK: - Private Methods

    private func setupTimeObserver() {
        let interval = CMTime(seconds: 0.05, preferredTimescale: 600)
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            Task { @MainActor in
                self?.currentTime = CMTimeGetSeconds(time)
                self?.updateCurrentSubtitle()
            }
        }
    }

    private func setupEndObserver() {
        NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime, object: player?.currentItem)
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.isPlaying = false
                    self?.seek(to: 0)
                }
            }
            .store(in: &cancellables)
    }

    private func removeTimeObserver() {
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
            timeObserver = nil
        }
    }

    private func setupVolumeObserver() {
        $volume
            .sink { [weak self] newVolume in
                self?.player?.volume = newVolume
            }
            .store(in: &cancellables)
    }

    private func setupRateObserver() {
        $playbackRate
            .sink { [weak self] newRate in
                if self?.isPlaying == true {
                    self?.player?.rate = newRate
                }
            }
            .store(in: &cancellables)
    }

    private func updateCurrentSubtitle() {
        let activeSubtitle = subtitles.first { subtitle in
            currentTime >= subtitle.startTime && currentTime <= subtitle.endTime
        }

        if activeSubtitle != currentSubtitle {
            currentSubtitle = activeSubtitle
            if let subtitle = activeSubtitle {
                selectedSubtitleIndex = subtitles.firstIndex(of: subtitle)
            }
        }
    }

    // MARK: - Reset

    func clearMedia() {
        removeTimeObserver()
        player?.pause()
        player = nil
        mediaURL = nil
        isMediaLoaded = false
        isPlaying = false
        currentTime = 0
        duration = 0
        isAudioOnly = false
    }

    func clearSRT() {
        subtitles = []
        srtURL = nil
        isSRTLoaded = false
        currentSubtitle = nil
        selectedSubtitleIndex = nil
    }

    func clearAll() {
        clearMedia()
        clearSRT()
        errorMessage = nil
    }
}
