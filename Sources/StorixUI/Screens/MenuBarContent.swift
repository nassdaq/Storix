import SwiftUI
import AppKit
import StorixAgent

public struct MenuBarContent: View {
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

            Button("Quick scan") {
                // MARK: TODO — launch scan window
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.accent)

            Button("Open Storix") {
                NSApp.activate(ignoringOtherApps: true)
            }
            .buttonStyle(.bordered)
        }
        .padding(Theme.Spacing.md)
        .frame(width: 240)
        .background(Theme.background)
    }
}
