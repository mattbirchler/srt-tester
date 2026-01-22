import SwiftUI
import UniformTypeIdentifiers

// MARK: - Drop Zone View

struct DropZoneView: View {
    let title: String
    let subtitle: String
    let icon: String
    let acceptedTypes: [UTType]
    let isLoaded: Bool
    let loadedFileName: String?
    let onDrop: (URL) -> Void
    let onClear: () -> Void

    @State private var isTargeted = false

    var body: some View {
        VStack(spacing: Theme.spacingM) {
            if isLoaded, let fileName = loadedFileName {
                loadedState(fileName: fileName)
            } else {
                emptyState
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: Theme.radiusL)
                .fill(isTargeted ? Theme.surfaceTertiary : Theme.surfaceSecondary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.radiusL)
                .strokeBorder(
                    isTargeted ? Theme.accentPrimary : Theme.border,
                    style: StrokeStyle(
                        lineWidth: isTargeted ? 2 : 1,
                        dash: isLoaded ? [] : [8, 4]
                    )
                )
        )
        .shadow(color: isTargeted ? Theme.accentGlow : .clear, radius: 12)
        .animation(.easeInOut(duration: 0.2), value: isTargeted)
        .onDrop(of: acceptedTypes, isTargeted: $isTargeted) { providers in
            handleDrop(providers: providers)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: Theme.spacingM) {
            ZStack {
                Circle()
                    .fill(Theme.surfaceTertiary)
                    .frame(width: 64, height: 64)

                Image(systemName: icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(isTargeted ? Theme.accentPrimary : Theme.textSecondary)
            }

            VStack(spacing: Theme.spacingXS) {
                Text(title)
                    .font(Theme.headlineFont)
                    .foregroundColor(Theme.textPrimary)

                Text(subtitle)
                    .font(Theme.labelFont)
                    .foregroundColor(Theme.textTertiary)
                    .multilineTextAlignment(.center)
            }

            if isTargeted {
                Text("Release to load")
                    .font(Theme.labelFont)
                    .foregroundColor(Theme.accentPrimary)
                    .padding(.horizontal, Theme.spacingM)
                    .padding(.vertical, Theme.spacingXS)
                    .background(Theme.accentPrimary.opacity(0.15))
                    .clipShape(Capsule())
            }
        }
        .padding(Theme.spacingXL)
    }

    // MARK: - Loaded State

    private func loadedState(fileName: String) -> some View {
        VStack(spacing: Theme.spacingM) {
            HStack(spacing: Theme.spacingS) {
                IndicatorLED(isOn: true, color: Theme.signalGreen)

                Text("LOADED")
                    .font(Theme.labelFontSmall)
                    .foregroundColor(Theme.signalGreen)
                    .tracking(1.5)
            }

            Image(systemName: icon)
                .font(.system(size: 28, weight: .medium))
                .foregroundColor(Theme.accentPrimary)

            Text(fileName)
                .font(Theme.bodyFont)
                .foregroundColor(Theme.textPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.center)

            Button(action: onClear) {
                HStack(spacing: Theme.spacingXS) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                    Text("Clear")
                        .font(Theme.labelFont)
                }
                .foregroundColor(Theme.textSecondary)
                .padding(.horizontal, Theme.spacingM)
                .padding(.vertical, Theme.spacingXS)
                .background(Theme.surfaceTertiary)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .contentShape(Capsule())
        }
        .padding(Theme.spacingL)
    }

    // MARK: - Drop Handling

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }

        for type in acceptedTypes {
            if provider.hasItemConformingToTypeIdentifier(type.identifier) {
                provider.loadItem(forTypeIdentifier: type.identifier, options: nil) { item, error in
                    DispatchQueue.main.async {
                        if let url = item as? URL {
                            onDrop(url)
                        } else if let data = item as? Data,
                                  let url = URL(dataRepresentation: data, relativeTo: nil) {
                            onDrop(url)
                        }
                    }
                }
                return true
            }
        }
        return false
    }
}

// MARK: - Compact Drop Zone

struct CompactDropZone: View {
    let title: String
    let icon: String
    let acceptedTypes: [UTType]
    let isLoaded: Bool
    let loadedFileName: String?
    let onDrop: (URL) -> Void

    @State private var isTargeted = false

    var body: some View {
        HStack(spacing: Theme.spacingS) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isLoaded ? Theme.accentPrimary : Theme.textSecondary)
                .frame(width: 24)

            if let fileName = loadedFileName, isLoaded {
                Text(fileName)
                    .font(Theme.bodyFont)
                    .foregroundColor(Theme.textPrimary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            } else {
                Text(title)
                    .font(Theme.bodyFont)
                    .foregroundColor(Theme.textTertiary)
            }

            Spacer()

            if isLoaded {
                IndicatorLED(isOn: true, color: Theme.signalGreen, size: 6)
            }
        }
        .padding(.horizontal, Theme.spacingM)
        .padding(.vertical, Theme.spacingS)
        .background(
            RoundedRectangle(cornerRadius: Theme.radiusS)
                .fill(isTargeted ? Theme.surfaceTertiary : Theme.surfaceSecondary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.radiusS)
                .strokeBorder(
                    isTargeted ? Theme.accentPrimary : Theme.borderSubtle,
                    lineWidth: 1
                )
        )
        .onDrop(of: acceptedTypes, isTargeted: $isTargeted) { providers in
            handleDrop(providers: providers)
        }
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }

        for type in acceptedTypes {
            if provider.hasItemConformingToTypeIdentifier(type.identifier) {
                provider.loadItem(forTypeIdentifier: type.identifier, options: nil) { item, error in
                    DispatchQueue.main.async {
                        if let url = item as? URL {
                            onDrop(url)
                        } else if let data = item as? Data,
                                  let url = URL(dataRepresentation: data, relativeTo: nil) {
                            onDrop(url)
                        }
                    }
                }
                return true
            }
        }
        return false
    }
}
