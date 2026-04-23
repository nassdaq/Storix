import SwiftUI
import StorixCore

public struct CleanupConfirmView: View {
    public let onDone: () -> Void
    public let onCancel: () -> Void

    @State private var cleaning = false

    public init(onDone: @escaping () -> Void, onCancel: @escaping () -> Void) {
        self.onDone = onDone
        self.onCancel = onCancel
    }

    public var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()

            Image(systemName: "trash")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(Theme.warning)

            Text("Confirm cleanup")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Theme.textPrimary)

            VStack(spacing: Theme.Spacing.xs) {
                Text("0 items will be moved to Trash.")
                    .foregroundStyle(Theme.textSecondary)
                Text("Manifest will be written so you can undo this cleanup later.")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textTertiary)
            }

            HStack(spacing: Theme.Spacing.md) {
                Button(action: onCancel) {
                    Text("Cancel")
                        .frame(width: 120, height: 36)
                        .background(Theme.surface)
                        .foregroundStyle(Theme.textPrimary)
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.Radius.small)
                                .stroke(Theme.border)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.small))
                }
                .buttonStyle(.plain)
                .disabled(cleaning)

                Button(action: runCleanup) {
                    Text(cleaning ? "Cleaning…" : "Move to Trash")
                        .frame(width: 180, height: 36)
                        .background(Theme.accent)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.small))
                }
                .buttonStyle(.plain)
                .disabled(cleaning)
            }
            .padding(.top, Theme.Spacing.md)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func runCleanup() {
        cleaning = true
        Task {
            // MARK: TODO — Cleaner.execute(plans:) via AppState
            try? await Task.sleep(nanoseconds: 900_000_000)
            await MainActor.run {
                cleaning = false
                onDone()
            }
        }
    }
}
