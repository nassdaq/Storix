import SwiftUI
import AppKit
import StorixAgent

public struct MenuBarContent: View {
    @EnvironmentObject private var appState: AppState
    @State private var freeBytes: Int64 = MenuBarController.freeBootVolumeBytes()

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack {
                Image(systemName: "internaldrive")
                    .foregroundStyle(Theme.accent)
                Text("Storix")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
            }

            Divider().background(Theme.border)

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text("Free space")
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.textTertiary)
                Text(ByteCountFormatter.string(fromByteCount: freeBytes, countStyle: .file))
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                    .monospacedDigit()
            }

            Button(action: quickScan) {
                HStack {
                    if appState.isScanning {
                        ProgressView().controlSize(.small).tint(.white)
                        Text("Scanning…")
                    } else {
                        Text("Quick scan")
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.accent)
            .disabled(appState.isScanning)

            Button("Open Storix") {
                NSApp.activate(ignoringOtherApps: true)
                NSApp.windows.first?.makeKeyAndOrderFront(nil)
            }
            .buttonStyle(.bordered)
        }
        .padding(Theme.Spacing.md)
        .frame(width: 240)
        .background(Theme.background)
        .onAppear { freeBytes = MenuBarController.freeBootVolumeBytes() }
    }

    private func quickScan() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.windows.first?.makeKeyAndOrderFront(nil)
        Task { await appState.runScan() }
    }
}
