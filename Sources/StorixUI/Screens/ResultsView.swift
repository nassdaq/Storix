import SwiftUI
import StorixCore

public struct ResultsView: View {
    public let onClean: () -> Void
    public let onQuery: () -> Void

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
                        ForEach(JunkCategory.allCases) { cat in
                            CategoryCard(
                                category: cat,
                                totalBytes: 0,
                                itemCount: 0,
                                selected: false,
                                onTap: {}
                            )
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
                        Text("0 B")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.textPrimary)
                    }
                    Spacer()
                    Button(action: onClean) {
                        Text("Clean selected")
                            .font(.system(size: 13, weight: .semibold))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Theme.accent)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.small))
                    }
                    .buttonStyle(.plain)
                }
                .padding(Theme.Spacing.lg)
            }
            .frame(width: 380)
            .background(Theme.surface)

            // Right: sunburst
            SunburstView(root: placeholderRoot)
                .padding(Theme.Spacing.lg)
        }
    }

    private var placeholderRoot: FileNode {
        FileNode(
            url: URL(fileURLWithPath: NSHomeDirectory()),
            name: "Home",
            size: 0,
            modified: .now,
            isDirectory: true
        )
    }
}
