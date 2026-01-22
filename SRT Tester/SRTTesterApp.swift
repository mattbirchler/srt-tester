import SwiftUI

@main
struct SRTTesterApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 900, minHeight: 600)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1200, height: 800)
        .commands {
            // File commands
            CommandGroup(replacing: .newItem) {
                Button("Open Media...") {
                    NotificationCenter.default.post(name: .openMedia, object: nil)
                }
                .keyboardShortcut("o", modifiers: .command)

                Button("Open SRT...") {
                    NotificationCenter.default.post(name: .openSRT, object: nil)
                }
                .keyboardShortcut("o", modifiers: [.command, .shift])
            }

            // Playback commands
            CommandMenu("Playback") {
                Button("Play/Pause") {
                    NotificationCenter.default.post(name: .togglePlayPause, object: nil)
                }
                .keyboardShortcut(.space, modifiers: [])

                Divider()

                Button("Skip Forward") {
                    NotificationCenter.default.post(name: .skipForward, object: nil)
                }
                .keyboardShortcut(.rightArrow, modifiers: [])

                Button("Skip Backward") {
                    NotificationCenter.default.post(name: .skipBackward, object: nil)
                }
                .keyboardShortcut(.leftArrow, modifiers: [])

                Divider()

                Button("Previous Subtitle") {
                    NotificationCenter.default.post(name: .previousSubtitle, object: nil)
                }
                .keyboardShortcut(.upArrow, modifiers: [])

                Button("Next Subtitle") {
                    NotificationCenter.default.post(name: .nextSubtitle, object: nil)
                }
                .keyboardShortcut(.downArrow, modifiers: [])
            }
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let openMedia = Notification.Name("openMedia")
    static let openSRT = Notification.Name("openSRT")
    static let togglePlayPause = Notification.Name("togglePlayPause")
    static let skipForward = Notification.Name("skipForward")
    static let skipBackward = Notification.Name("skipBackward")
    static let previousSubtitle = Notification.Name("previousSubtitle")
    static let nextSubtitle = Notification.Name("nextSubtitle")
}
