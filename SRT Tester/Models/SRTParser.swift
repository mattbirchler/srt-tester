import Foundation

// MARK: - Subtitle Model

struct Subtitle: Identifiable, Equatable {
    let id: Int
    let index: Int
    let startTime: TimeInterval
    let endTime: TimeInterval
    let text: String

    var duration: TimeInterval {
        endTime - startTime
    }

    var formattedStartTime: String {
        formatTime(startTime)
    }

    var formattedEndTime: String {
        formatTime(endTime)
    }

    var formattedDuration: String {
        formatTime(duration)
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = (Int(time) % 3600) / 60
        let seconds = Int(time) % 60
        let milliseconds = Int((time.truncatingRemainder(dividingBy: 1)) * 1000)
        return String(format: "%02d:%02d:%02d,%03d", hours, minutes, seconds, milliseconds)
    }
}

// MARK: - SRT Parser

class SRTParser {
    enum ParseError: Error, LocalizedError {
        case invalidFile
        case invalidTimestamp(line: Int)
        case invalidFormat(line: Int)

        var errorDescription: String? {
            switch self {
            case .invalidFile:
                return "Could not read the SRT file"
            case .invalidTimestamp(let line):
                return "Invalid timestamp format at line \(line)"
            case .invalidFormat(let line):
                return "Invalid SRT format at line \(line)"
            }
        }
    }

    static func parse(url: URL) throws -> [Subtitle] {
        let content: String
        do {
            content = try String(contentsOf: url, encoding: .utf8)
        } catch {
            // Try other encodings
            if let latin1Content = try? String(contentsOf: url, encoding: .isoLatin1) {
                content = latin1Content
            } else {
                throw ParseError.invalidFile
            }
        }

        return try parse(content: content)
    }

    static func parse(content: String) throws -> [Subtitle] {
        var subtitles: [Subtitle] = []

        // Normalize line endings and split into blocks
        let normalizedContent = content
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")

        // Split by double newlines to get subtitle blocks
        let blocks = normalizedContent.components(separatedBy: "\n\n")

        for (blockIndex, block) in blocks.enumerated() {
            let lines = block.components(separatedBy: "\n").filter { !$0.isEmpty }

            guard lines.count >= 2 else { continue }

            // First line should be the index number
            guard let index = Int(lines[0].trimmingCharacters(in: .whitespaces)) else {
                continue
            }

            // Second line should be the timestamp
            let timestampLine = lines[1]
            guard let (startTime, endTime) = parseTimestamp(timestampLine) else {
                throw ParseError.invalidTimestamp(line: blockIndex * 4 + 2)
            }

            // Remaining lines are the subtitle text
            let textLines = Array(lines.dropFirst(2))
            let text = textLines.joined(separator: "\n")

            let subtitle = Subtitle(
                id: index,
                index: index,
                startTime: startTime,
                endTime: endTime,
                text: text
            )
            subtitles.append(subtitle)
        }

        return subtitles.sorted { $0.startTime < $1.startTime }
    }

    private static func parseTimestamp(_ line: String) -> (TimeInterval, TimeInterval)? {
        // Format: 00:00:00,000 --> 00:00:00,000
        let pattern = #"(\d{2}):(\d{2}):(\d{2})[,.](\d{3})\s*-->\s*(\d{2}):(\d{2}):(\d{2})[,.](\d{3})"#

        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)) else {
            return nil
        }

        func extractTime(hourIndex: Int, minuteIndex: Int, secondIndex: Int, msIndex: Int) -> TimeInterval? {
            guard let hourRange = Range(match.range(at: hourIndex), in: line),
                  let minuteRange = Range(match.range(at: minuteIndex), in: line),
                  let secondRange = Range(match.range(at: secondIndex), in: line),
                  let msRange = Range(match.range(at: msIndex), in: line),
                  let hours = Int(line[hourRange]),
                  let minutes = Int(line[minuteRange]),
                  let seconds = Int(line[secondRange]),
                  let milliseconds = Int(line[msRange]) else {
                return nil
            }

            return TimeInterval(hours * 3600 + minutes * 60 + seconds) + TimeInterval(milliseconds) / 1000.0
        }

        guard let startTime = extractTime(hourIndex: 1, minuteIndex: 2, secondIndex: 3, msIndex: 4),
              let endTime = extractTime(hourIndex: 5, minuteIndex: 6, secondIndex: 7, msIndex: 8) else {
            return nil
        }

        return (startTime, endTime)
    }
}

// MARK: - Time Formatting Utilities

extension TimeInterval {
    var formattedTimecode: String {
        let hours = Int(self) / 3600
        let minutes = (Int(self) % 3600) / 60
        let seconds = Int(self) % 60
        let frames = Int((self.truncatingRemainder(dividingBy: 1)) * 100)

        if hours > 0 {
            return String(format: "%d:%02d:%02d.%02d", hours, minutes, seconds, frames)
        } else {
            return String(format: "%02d:%02d.%02d", minutes, seconds, frames)
        }
    }

    var formattedTimecodeShort: String {
        let minutes = Int(self) / 60
        let seconds = Int(self) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var formattedTimecodeCompact: String {
        let hours = Int(self) / 3600
        let minutes = (Int(self) % 3600) / 60
        let seconds = Int(self) % 60
        let milliseconds = Int((self.truncatingRemainder(dividingBy: 1)) * 1000)

        if hours > 0 {
            return String(format: "%d:%02d:%02d.%03d", hours, minutes, seconds, milliseconds)
        } else {
            return String(format: "%02d:%02d.%03d", minutes, seconds, milliseconds)
        }
    }
}
