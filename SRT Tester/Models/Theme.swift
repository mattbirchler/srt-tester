import SwiftUI

// MARK: - Studio Monitor Theme
// Professional broadcast monitoring aesthetic with amber accents

enum Theme {
    // MARK: - Core Colors
    static let background = Color(hex: "0D0D0D")
    static let surfacePrimary = Color(hex: "161616")
    static let surfaceSecondary = Color(hex: "1E1E1E")
    static let surfaceTertiary = Color(hex: "262626")
    static let border = Color(hex: "333333")
    static let borderSubtle = Color(hex: "2A2A2A")

    // MARK: - Amber Accent (VU Meter inspired)
    static let accentPrimary = Color(hex: "F5A623")
    static let accentSecondary = Color(hex: "D4920F")
    static let accentTertiary = Color(hex: "8B6914")
    static let accentGlow = Color(hex: "F5A623").opacity(0.3)

    // MARK: - Signal Colors
    static let signalGreen = Color(hex: "2ECC71")
    static let signalRed = Color(hex: "E74C3C")
    static let signalYellow = Color(hex: "F1C40F")
    static let signalBlue = Color(hex: "3498DB")

    // MARK: - Text Colors
    static let textPrimary = Color(hex: "FAFAFA")
    static let textSecondary = Color(hex: "A0A0A0")
    static let textTertiary = Color(hex: "666666")
    static let textMuted = Color(hex: "4A4A4A")

    // MARK: - Typography
    static let timecodeFont = Font.custom("SF Mono", size: 13).monospacedDigit()
    static let timecodeFontLarge = Font.custom("SF Mono", size: 24).monospacedDigit()
    static let timecodeFontSmall = Font.custom("SF Mono", size: 11).monospacedDigit()

    static let labelFont = Font.system(size: 11, weight: .medium)
    static let labelFontSmall = Font.system(size: 10, weight: .medium)
    static let bodyFont = Font.system(size: 13, weight: .regular)
    static let headlineFont = Font.system(size: 15, weight: .semibold)
    static let subtitleDisplayFont = Font.system(size: 18, weight: .medium)

    // MARK: - Spacing
    static let spacingXS: CGFloat = 4
    static let spacingS: CGFloat = 8
    static let spacingM: CGFloat = 12
    static let spacingL: CGFloat = 16
    static let spacingXL: CGFloat = 24
    static let spacingXXL: CGFloat = 32

    // MARK: - Corner Radius
    static let radiusS: CGFloat = 4
    static let radiusM: CGFloat = 6
    static let radiusL: CGFloat = 8
    static let radiusXL: CGFloat = 12

    // MARK: - Shadows
    static let shadowSubtle = Color.black.opacity(0.3)
    static let shadowMedium = Color.black.opacity(0.5)
    static let shadowStrong = Color.black.opacity(0.7)

    // MARK: - Gradients
    static let scanlineGradient = LinearGradient(
        colors: [
            Color.white.opacity(0.02),
            Color.clear,
            Color.white.opacity(0.02),
            Color.clear
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    static let surfaceGradient = LinearGradient(
        colors: [surfaceSecondary, surfacePrimary],
        startPoint: .top,
        endPoint: .bottom
    )

    static let accentGradient = LinearGradient(
        colors: [accentPrimary, accentSecondary],
        startPoint: .top,
        endPoint: .bottom
    )
}

// MARK: - Color Extension for Hex

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - View Modifiers

struct PanelStyle: ViewModifier {
    var padding: CGFloat = Theme.spacingM

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Theme.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusM))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.radiusM)
                    .strokeBorder(Theme.border, lineWidth: 1)
            )
    }
}

struct InsetPanelStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(Theme.spacingM)
            .background(Theme.background)
            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusS))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.radiusS)
                    .strokeBorder(Theme.borderSubtle, lineWidth: 1)
            )
    }
}

struct GlowingBorderStyle: ViewModifier {
    var isActive: Bool
    var color: Color = Theme.accentPrimary

    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: Theme.radiusM)
                    .strokeBorder(
                        isActive ? color : Theme.border,
                        lineWidth: isActive ? 2 : 1
                    )
            )
            .shadow(color: isActive ? color.opacity(0.4) : .clear, radius: 8)
    }
}

struct ScanlineOverlay: View {
    var body: some View {
        Canvas { context, size in
            for y in stride(from: 0, to: size.height, by: 2) {
                let rect = CGRect(x: 0, y: y, width: size.width, height: 1)
                context.fill(Path(rect), with: .color(.black.opacity(0.1)))
            }
        }
        .allowsHitTesting(false)
    }
}

extension View {
    func panelStyle(padding: CGFloat = Theme.spacingM) -> some View {
        modifier(PanelStyle(padding: padding))
    }

    func insetPanelStyle() -> some View {
        modifier(InsetPanelStyle())
    }

    func glowingBorder(isActive: Bool, color: Color = Theme.accentPrimary) -> some View {
        modifier(GlowingBorderStyle(isActive: isActive, color: color))
    }
}

// MARK: - Indicator LED View

struct IndicatorLED: View {
    let isOn: Bool
    var color: Color = Theme.signalGreen
    var size: CGFloat = 8

    var body: some View {
        Circle()
            .fill(isOn ? color : Theme.surfaceTertiary)
            .frame(width: size, height: size)
            .overlay(
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.white.opacity(0.6), .clear],
                            center: .topLeading,
                            startRadius: 0,
                            endRadius: size * 0.6
                        )
                    )
            )
            .shadow(color: isOn ? color.opacity(0.8) : .clear, radius: 4)
    }
}

// MARK: - Label Style

struct MonitorLabel: View {
    let text: String
    var isHighlighted: Bool = false

    var body: some View {
        Text(text.uppercased())
            .font(Theme.labelFontSmall)
            .foregroundColor(isHighlighted ? Theme.accentPrimary : Theme.textTertiary)
            .tracking(1.2)
    }
}
