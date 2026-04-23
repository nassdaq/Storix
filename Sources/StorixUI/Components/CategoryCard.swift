import SwiftUI
import StorixCore

public struct CategoryCard: View {
    public let category: JunkCategory
    public let totalBytes: Int64
    public let itemCount: Int
    public let selected: Bool
    public let onTap: () -> Void

    public init(
        category: JunkCategory,
        totalBytes: Int64,
        itemCount: Int,
        selected: Bool = false,
        onTap: @escaping () -> Void
    ) {
        self.category = category
        self.totalBytes = totalBytes
        self.itemCount = itemCount
        self.selected = selected
        self.onTap = onTap
    }

    public var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                HStack {
                    Text(category.displayName)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()
                    riskBadge
                }

                Text(ByteCountFormatter.string(fromByteCount: totalBytes, countStyle: .file))
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                    .monospacedDigit()

                Text("\(itemCount) item\(itemCount == 1 ? "" : "s")")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textTertiary)
            }
            .padding(Theme.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.surface)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.medium)
                    .stroke(selected ? Theme.accent : Theme.border, lineWidth: selected ? 1.5 : 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium))
        }
        .buttonStyle(.plain)
    }

    private var riskBadge: some View {
        let (text, color): (String, Color) = {
            switch category.riskLevel {
            case .low:    return ("SAFE", Theme.success)
            case .medium: return ("REVIEW", Theme.warning)
            case .high:   return ("CAUTION", Theme.danger)
            }
        }()
        return Text(text)
            .font(.system(size: 9, weight: .bold, design: .monospaced))
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .foregroundStyle(color)
            .background(color.opacity(0.15))
            .clipShape(Capsule())
    }
}
