import SwiftUI

// MARK: - Waveform View

struct WaveformView: View {
    let isPlaying: Bool
    let progress: Double

    @State private var animationPhase: CGFloat = 0

    private let barCount = 50

    var body: some View {
        GeometryReader { geometry in
            let barWidth = geometry.size.width / CGFloat(barCount)

            HStack(spacing: 2) {
                ForEach(0..<barCount, id: \.self) { index in
                    WaveformBar(
                        index: index,
                        progress: progress,
                        isPlaying: isPlaying,
                        animationPhase: animationPhase,
                        totalBars: barCount
                    )
                    .frame(width: max(2, barWidth - 2))
                }
            }
        }
        .onChange(of: isPlaying) { _, newValue in
            if newValue {
                startAnimation()
            }
        }
        .onAppear {
            if isPlaying {
                startAnimation()
            }
        }
    }

    private func startAnimation() {
        withAnimation(
            .linear(duration: 2.0)
            .repeatForever(autoreverses: false)
        ) {
            animationPhase = 1.0
        }
    }
}

// MARK: - Waveform Bar

struct WaveformBar: View {
    let index: Int
    let progress: Double
    let isPlaying: Bool
    let animationPhase: CGFloat
    let totalBars: Int

    private var normalizedPosition: Double {
        Double(index) / Double(totalBars)
    }

    private var isPastProgress: Bool {
        normalizedPosition < progress
    }

    private var height: CGFloat {
        // Create a pseudo-random but deterministic height pattern
        let baseHeight: CGFloat = 0.3
        let variation = sin(Double(index) * 0.5) * 0.3 +
                       cos(Double(index) * 0.8) * 0.2 +
                       sin(Double(index) * 1.2) * 0.15

        var h = baseHeight + CGFloat(abs(variation))

        // Add animation when playing
        if isPlaying {
            let animatedVariation = sin(Double(index) * 0.3 + Double(animationPhase) * .pi * 4) * 0.15
            h += CGFloat(animatedVariation)
        }

        return max(0.1, min(1.0, h))
    }

    var body: some View {
        GeometryReader { geometry in
            RoundedRectangle(cornerRadius: 1)
                .fill(barColor)
                .frame(height: geometry.size.height * height)
                .frame(maxHeight: .infinity, alignment: .center)
        }
    }

    private var barColor: Color {
        if isPastProgress {
            return Theme.accentPrimary
        } else {
            return Theme.surfaceTertiary
        }
    }
}

// MARK: - Audio Level Meter

struct AudioLevelMeter: View {
    let level: Float // 0.0 to 1.0

    private let segmentCount = 12
    private let greenSegments = 7
    private let yellowSegments = 3
    // red segments = segmentCount - greenSegments - yellowSegments

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<segmentCount, id: \.self) { index in
                let isLit = Float(index) / Float(segmentCount) < level

                RoundedRectangle(cornerRadius: 1)
                    .fill(segmentColor(for: index, isLit: isLit))
                    .frame(width: 4)
            }
        }
    }

    private func segmentColor(for index: Int, isLit: Bool) -> Color {
        if !isLit {
            return Theme.surfaceTertiary
        }

        if index < greenSegments {
            return Theme.signalGreen
        } else if index < greenSegments + yellowSegments {
            return Theme.signalYellow
        } else {
            return Theme.signalRed
        }
    }
}

// MARK: - VU Meter Style Indicator

struct VUMeter: View {
    let value: Float

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background arc
                Arc(startAngle: .degrees(135), endAngle: .degrees(405), clockwise: false)
                    .stroke(Theme.surfaceTertiary, lineWidth: 4)

                // Value arc
                Arc(startAngle: .degrees(135), endAngle: .degrees(135 + Double(value) * 270), clockwise: false)
                    .stroke(
                        AngularGradient(
                            colors: [Theme.signalGreen, Theme.signalYellow, Theme.signalRed],
                            center: .center,
                            startAngle: .degrees(135),
                            endAngle: .degrees(405)
                        ),
                        lineWidth: 4
                    )
                    .mask(
                        Arc(startAngle: .degrees(135), endAngle: .degrees(135 + Double(value) * 270), clockwise: false)
                            .stroke(lineWidth: 4)
                    )

                // Needle
                Rectangle()
                    .fill(Theme.textPrimary)
                    .frame(width: 2, height: geometry.size.height * 0.4)
                    .offset(y: -geometry.size.height * 0.2)
                    .rotationEffect(.degrees(-135 + Double(value) * 270))
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

// MARK: - Arc Shape

struct Arc: Shape {
    var startAngle: Angle
    var endAngle: Angle
    var clockwise: Bool

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2 - 4

        path.addArc(
            center: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: !clockwise
        )

        return path
    }
}
