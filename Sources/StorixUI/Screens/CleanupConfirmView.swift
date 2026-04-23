import SwiftUI
import StorixCore

public struct CleanupConfirmView: View {
    public let onDone: () -> Void
    public let onCancel: () -> Void
    @EnvironmentObject private var appState: AppState
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
                Text("\(itemCount) item\(itemCount == 1 ? "" : "s") — \(sizeLabel) will be moved to Trash.")
                    .foregroundStyle(Theme.textSecondary)
                Text("A manifest is written so you can undo this cleanup later.")
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
                .disabled(cleaning || itemCount == 0)
            }
            .padding(.top, Theme.Spacing.md)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var findingsForSelected: [Finding] {
        guard let cat = appState.selectedCategory else { return [] }
        return appState.scanResult?.findings(in: cat) ?? []
    }

    private var itemCount: Int {
        findingsForSelected.reduce(0) { $0 + $1.items.count }
    }

    private var sizeLabel: String {
        let bytes = findingsForSelected.reduce(Int64(0)) { $0 + $1.totalBytes }
        return ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }

    private func runCleanup() {
        guard let cat = appState.selectedCategory else { return }
        cleaning = true
        Task {
            await appState.cleanup(category: cat)
            cleaning = false
            onDone()
        }
    }
}
