import SwiftUI
import StorixAI

public struct NLQueryView: View {
    public let onBack: () -> Void
    @State private var query: String = ""
    @State private var answer: String = ""
    @State private var thinking = false

    public init(onBack: @escaping () -> Void) {
        self.onBack = onBack
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .foregroundStyle(Theme.textSecondary)
                }
                .buttonStyle(.plain)

                Text("Ask Storix")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)

                Spacer()

                Label("Claude", systemImage: "sparkles")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Theme.accent)
            }

            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Theme.textTertiary)
                TextField("e.g. find videos from 2022 over 1 GB", text: $query)
                    .textFieldStyle(.plain)
                    .foregroundStyle(Theme.textPrimary)
                    .onSubmit(runQuery)
            }
            .padding(Theme.Spacing.md)
            .background(Theme.surface)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.small)
                    .stroke(Theme.border)
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.small))

            if thinking {
                ProgressView()
                    .tint(Theme.accent)
                    .padding(.top, Theme.Spacing.sm)
            } else if !answer.isEmpty {
                ScrollView {
                    Text(answer)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundStyle(Theme.textPrimary)
                        .padding(Theme.Spacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Theme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.small))
                }
            }

            Spacer()
        }
        .padding(Theme.Spacing.lg)
    }

    private func runQuery() {
        thinking = true
        Task {
            defer { Task { @MainActor in thinking = false } }
            do {
                let predicate = try await NaturalLanguageQuery().parse(query)
                let desc = "Parsed predicate:\n  minSize: \(String(describing: predicate.minSize))\n  extensions: \(predicate.extensions)\n  minAgeDays: \(String(describing: predicate.minAgeDays))"
                await MainActor.run { answer = desc }
            } catch ClaudeClientError.notInstalled {
                await MainActor.run {
                    answer = "Claude CLI not found.\n\nInstall Claude Code, or disable AI queries in Settings."
                }
            } catch {
                await MainActor.run { answer = "Error: \(error.localizedDescription)" }
            }
        }
    }
}
