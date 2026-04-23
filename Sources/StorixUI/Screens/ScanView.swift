import SwiftUI
import StorixCore

public struct ScanView: View {
    public let onComplete: () -> Void
    @State private var progress: ScanProgress = .idle
    @State private var scanning: Bool = false

    public init(onComplete: @escaping () -> Void) {
        self.onComplete = onComplete
    }

    public var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            Spacer()

            ZStack {
                Circle()
                    .stroke(Theme.border, lineWidth: 1)
                    .frame(width: 220, height: 220)

                Circle()
                    .trim(from: 0, to: scanning ? 0.75 : 0.0)
                    .stroke(
                        AngularGradient(
                            colors: [Theme.accent, Theme.accent2, Theme.accent3, Theme.accent4, Theme.accent],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 220, height: 220)
                    .rotationEffect(.degrees(scanning ? 360 : 0))
                    .animation(
                        scanning
                            ? .linear(duration: 2.0).repeatForever(autoreverses: false)
                            : .default,
                        value: scanning
                    )

                VStack(spacing: Theme.Spacing.sm) {
                    Text("Storix")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text(statusLabel)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(Theme.textTertiary)
                }
            }

            Button(action: startScan) {
                Text(scanning ? "Scanning…" : "Scan full disk")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(width: 200, height: 40)
                    .background(Theme.accent)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.small))
            }
            .buttonStyle(.plain)
            .disabled(scanning)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var statusLabel: String {
        switch progress {
        case .idle:                               return "Ready"
        case .walking(let seen, let bytes, _):    return "Walking — \(seen) files, \(ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file))"
        case .hashing(let done, let total):       return "Hashing \(done)/\(total)"
        case .classifying:                        return "Classifying"
        case .done:                               return "Done"
        }
    }

    private func startScan() {
        scanning = true
        Task {
            // MARK: TODO — wire to StorixCore.StorageScanner via AppState
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            await MainActor.run {
                scanning = false
                progress = .done
                onComplete()
            }
        }
    }
}
