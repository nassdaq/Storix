import SwiftUI
import StorixCore

public struct FindingItemsList: View {
    public let findings: [Finding]

    public init(findings: [Finding]) {
        self.findings = findings
    }

    public var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                ForEach(findings) { finding in
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        HStack(alignment: .top) {
                            Text(finding.category.displayName)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Theme.accent)
                            Spacer()
                            Text(ByteCountFormatter.string(fromByteCount: finding.totalBytes, countStyle: .file))
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                .foregroundStyle(Theme.textPrimary)
                        }

                        Text(finding.rationale)
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.textTertiary)
                            .fixedSize(horizontal: false, vertical: true)

                        VStack(alignment: .leading, spacing: 2) {
                            ForEach(finding.items.prefix(8)) { item in
                                HStack {
                                    Image(systemName: item.isDirectory ? "folder" : "doc")
                                        .font(.system(size: 10))
                                        .foregroundStyle(Theme.textTertiary)
                                    Text(item.url.path)
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundStyle(Theme.textSecondary)
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                    Spacer()
                                    Text(ByteCountFormatter.string(fromByteCount: item.size, countStyle: .file))
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundStyle(Theme.textTertiary)
                                }
                            }
                            if finding.items.count > 8 {
                                Text("…and \(finding.items.count - 8) more")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(Theme.textTertiary)
                                    .padding(.top, 2)
                            }
                        }
                        .padding(.top, 4)
                    }
                    .padding(Theme.Spacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium))
                }
            }
            .padding(Theme.Spacing.md)
        }
    }
}
