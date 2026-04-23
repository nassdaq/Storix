import SwiftUI
import StorixCore

public struct ScanView: View {
    public let onComplete: () -> Void
    @EnvironmentObject private var appState: AppState

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
                    .trim(from: 0, to: appState.isScanning ? 0.75 : 0.0)
                    .stroke(
                        AngularGradient(
                            colors: [Theme.accent, Theme.accent2, Theme.accent3, Theme.accent4, Theme.accent],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 220, height: 220)
                    .rotationEffect(.degrees(appState.isScanning ? 360 : 0))
                    .animation(
                        appState.isScanning
                            ? .linear(duration: 2.0).repeatForever(autoreverses: false)
                            : .default,
                        value: appState.isScanning
                    )

                VStack(spacing: Theme.Spacing.sm) {
                    Text("Storix")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text(statusLabel)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(Theme.textTertiary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .frame(maxWidth: 240)
                }
            }

            Button(action: startScan) {
                Text(appState.isScanning ? "Scanning…" : "Scan home directory")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(width: 220, height: 40)
                    .background(Theme.accent)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.small))
            }
            .buttonStyle(.plain)
            .disabled(appState.isScanning)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var statusLabel: String {
        switch appState.scanProgress {
        case .idle:
            return "Ready"
        case .walking(let seen, let bytes, let path):
            let sizeStr = ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
            if path.isEmpty { return "\(seen) files · \(sizeStr)" }
            let shortPath = URL(fileURLWithPath: path).lastPathComponent
            return "\(seen) · \(sizeStr) · \(shortPath)"
        case .hashing(let done, let total):
            return "Hashing \(done)/\(total)"
        case .classifying:
            return "Classifying"
        case .done:
            return "Done"
        }
    }

    private func startScan() {
        Task {
            await appState.runScan()
            if appState.scanResult != nil {
                onComplete()
            }
        }
    }
}
