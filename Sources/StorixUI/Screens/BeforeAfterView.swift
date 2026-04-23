import SwiftUI
import AppKit

public struct BeforeAfterView: View {
    public let onDone: () -> Void
    @EnvironmentObject private var appState: AppState
    @State private var animateNumber = false

    public init(onDone: @escaping () -> Void) {
        self.onDone = onDone
    }

    private var freedBytes: Int64 {
        appState.lastCleanup?.totalBytes ?? 0
    }

    private var freedLabel: String {
        ByteCountFormatter.string(fromByteCount: freedBytes, countStyle: .file)
    }

    public var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()

            Image(systemName: "sparkles")
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(Theme.accent)

            Text("You freed")
                .font(.system(size: 14))
                .foregroundStyle(Theme.textSecondary)

            Text(freedLabel)
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
                .monospacedDigit()
                .scaleEffect(animateNumber ? 1.0 : 0.8)
                .opacity(animateNumber ? 1.0 : 0.0)
                .animation(.spring(response: 0.6, dampingFraction: 0.7), value: animateNumber)
                .onAppear { animateNumber = true }

            Text("Undo any time from Settings → Cleanup history.")
                .font(.system(size: 11))
                .foregroundStyle(Theme.textTertiary)

            HStack(spacing: Theme.Spacing.md) {
                Button(action: share) {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .frame(width: 140, height: 36)
                        .background(Theme.surface)
                        .foregroundStyle(Theme.textPrimary)
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.Radius.small)
                                .stroke(Theme.border)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.small))
                }
                .buttonStyle(.plain)
                .disabled(freedBytes == 0)

                Button(action: onDone) {
                    Text("Done")
                        .frame(width: 140, height: 36)
                        .background(Theme.accent)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.small))
                }
                .buttonStyle(.plain)
            }
            .padding(.top, Theme.Spacing.md)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @MainActor
    private func share() {
        let card = ShareCard(freedLabel: freedLabel)
        let renderer = ImageRenderer(content: card)
        renderer.scale = 2.0
        guard let nsImage = renderer.nsImage else { return }

        let panel = NSSavePanel()
        panel.allowedContentTypes = [.png]
        panel.nameFieldStringValue = "storix-cleanup.png"
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            guard let tiff = nsImage.tiffRepresentation,
                  let rep = NSBitmapImageRep(data: tiff),
                  let pngData = rep.representation(using: .png, properties: [:])
            else { return }
            try? pngData.write(to: url)
        }
    }
}

/// Square share card rendered off-screen by `ImageRenderer`.
private struct ShareCard: View {
    let freedLabel: String

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Theme.accent, Theme.accent2, Theme.accent3],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 18) {
                Text("Storix")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))
                Text("freed")
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.7))
                Text(freedLabel)
                    .font(.system(size: 96, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .monospacedDigit()
                Text("on my Mac")
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .frame(width: 720, height: 720)
    }
}
