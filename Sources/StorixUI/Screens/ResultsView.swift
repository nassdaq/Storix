import SwiftUI
import StorixCore

public struct ResultsView: View {
    public let onClean: () -> Void
    public let onQuery: () -> Void
    @EnvironmentObject private var appState: AppState

    public init(onClean: @escaping () -> Void, onQuery: @escaping () -> Void) {
        self.onClean = onClean
        self.onQuery = onQuery
    }

    public var body: some View {
        HStack(spacing: 0) {
            // Left: category list
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                HStack {
                    Text("Findings")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()
                    Button(action: onQuery) {
                        Label("Ask", systemImage: "sparkles")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Theme.accent)
                }
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.top, Theme.Spacing.lg)

                ScrollView {
                    LazyVStack(spacing: Theme.Spacing.sm) {
                        ForEach(categoriesWithFindings, id: \.self) { cat in
                            let items = appState.scanResult?.findings(in: cat).flatMap(\.items) ?? []
                            CategoryCard(
                                category: cat,
                                totalBytes: items.reduce(Int64(0)) { $0 + $1.size },
                                itemCount: items.count,
                                selected: appState.selectedCategory == cat,
                                onTap: { appState.selectedCategory = cat }
                            )
                        }

                        if categoriesWithFindings.isEmpty {
                            emptyState
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.lg)
                }

                Divider().background(Theme.border)

                HStack {
                    VStack(alignment: .leading) {
                        Text("Total recoverable")
                            .font(.system(size: 10))
                            .foregroundStyle(Theme.textTertiary)
                        Text(totalRecoverableLabel)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.textPrimary)
                    }
                    Spacer()
                    Button(action: onClean) {
                        Text("Clean selected")
                            .font(.system(size: 13, weight: .semibold))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(appState.selectedCategory == nil ? Theme.border : Theme.accent)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.small))
                    }
                    .buttonStyle(.plain)
                    .disabled(appState.selectedCategory == nil)
                }
                .padding(Theme.Spacing.lg)
            }
            .frame(width: 380)
            .background(Theme.surface)

            // Right: sunburst
            SunburstView(root: appState.scanResult?.rootNode ?? emptyRoot)
                .padding(Theme.Spacing.lg)
        }
    }

    private var categoriesWithFindings: [JunkCategory] {
        let result = appState.scanResult
        return JunkCategory.allCases.filter { cat in
            !(result?.findings(in: cat).isEmpty ?? true)
        }
    }

    private var totalRecoverableLabel: String {
        let bytes = appState.scanResult?.totalRecoverableBytes ?? 0
        return ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }

    private var emptyState: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "sparkles")
                .font(.system(size: 32))
                .foregroundStyle(Theme.textTertiary)
            Text("Nothing to clean")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Theme.textSecondary)
            Text("Your disk looks tidy.")
                .font(.system(size: 11))
                .foregroundStyle(Theme.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.xl)
    }

    private var emptyRoot: FileNode {
        FileNode(
            url: URL(fileURLWithPath: NSHomeDirectory()),
            name: "Home",
            size: 0,
            modified: .now,
            isDirectory: true
        )
    }
}
