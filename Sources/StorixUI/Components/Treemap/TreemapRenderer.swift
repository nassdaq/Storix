import SwiftUI
import StorixCore

/// Squarified-treemap view. Each child of `root` becomes a labeled rectangle sized
/// proportional to its bytes. Tap a tile to zoom in via `onSelect`.
public struct TreemapView: View {
    public let root: FileNode
    public let onSelect: ((FileNode) -> Void)?

    public init(root: FileNode, onSelect: ((FileNode) -> Void)? = nil) {
        self.root = root
        self.onSelect = onSelect
    }

    public var body: some View {
        GeometryReader { geo in
            let tiles = Treemap.squarify(
                children: root.children.filter { $0.size > 0 }.sorted { $0.size > $1.size },
                in: CGRect(origin: .zero, size: geo.size)
            )
            let maxSize = root.children.map(\.size).max() ?? 1

            ZStack(alignment: .topLeading) {
                ForEach(tiles, id: \.node.id) { tile in
                    TreemapTile(
                        node: tile.node,
                        rect: tile.rect,
                        color: Theme.colorForSize(tile.node.size, maxBytes: maxSize),
                        onTap: { onSelect?(tile.node) }
                    )
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .background(Theme.background)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium))
        }
    }
}

private struct TreemapTile: View {
    let node: FileNode
    let rect: CGRect
    let color: Color
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .topLeading) {
                Rectangle()
                    .fill(color.opacity(0.85))
                    .overlay(
                        Rectangle()
                            .stroke(Theme.background, lineWidth: 1)
                    )

                if rect.width > 60 && rect.height > 28 {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(node.name)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Theme.textPrimary)
                            .lineLimit(1)
                        Text(ByteCountFormatter.string(fromByteCount: node.size, countStyle: .file))
                            .font(.system(size: 9, weight: .regular, design: .monospaced))
                            .foregroundStyle(Theme.textPrimary.opacity(0.75))
                    }
                    .padding(6)
                }
            }
        }
        .buttonStyle(.plain)
        .frame(width: rect.width, height: rect.height)
        .offset(x: rect.origin.x, y: rect.origin.y)
    }
}

/// Squarified treemap layout (Bruls, Huijing, van Wijk 2000).
/// Given values sorted descending, places each into rows along the shortest side,
/// minimizing worst-case aspect ratio.
enum Treemap {
    struct Tile {
        let node: FileNode
        let rect: CGRect
    }

    static func squarify(children: [FileNode], in rect: CGRect) -> [Tile] {
        guard !children.isEmpty else { return [] }
        let total = children.reduce(Int64(0)) { $0 + $1.size }
        guard total > 0 else { return [] }

        let totalArea = Double(rect.width * rect.height)
        let scaled: [(FileNode, Double)] = children.map { node in
            (node, Double(node.size) / Double(total) * totalArea)
        }

        var tiles: [Tile] = []
        squarifyHelper(values: scaled, row: [], rect: rect, output: &tiles)
        return tiles
    }

    private static func squarifyHelper(
        values: [(FileNode, Double)],
        row: [(FileNode, Double)],
        rect: CGRect,
        output: inout [Tile]
    ) {
        guard let first = values.first else {
            if !row.isEmpty { layoutRow(row: row, in: rect, output: &output, final: true) }
            return
        }

        let shortSide = Double(min(rect.width, rect.height))
        let newRow = row + [first]
        let oldRatio = worstRatio(row: row, side: shortSide)
        let newRatio = worstRatio(row: newRow, side: shortSide)

        if row.isEmpty || newRatio <= oldRatio {
            squarifyHelper(
                values: Array(values.dropFirst()),
                row: newRow,
                rect: rect,
                output: &output
            )
        } else {
            let remaining = layoutRow(row: row, in: rect, output: &output, final: false)
            squarifyHelper(values: values, row: [], rect: remaining, output: &output)
        }
    }

    /// Returns the worst (largest) aspect ratio among rectangles that would form if we
    /// placed `row` along the shortest side.
    private static func worstRatio(row: [(FileNode, Double)], side: Double) -> Double {
        guard !row.isEmpty, side > 0 else { return .infinity }
        let total = row.reduce(0.0) { $0 + $1.1 }
        let maxVal = row.map(\.1).max() ?? 0
        let minVal = row.map(\.1).min() ?? 0
        guard minVal > 0, total > 0 else { return .infinity }
        let s2 = side * side
        let t2 = total * total
        return max(s2 * maxVal / t2, t2 / (s2 * minVal))
    }

    /// Lay `row` along the shortest side and return the remaining rectangle.
    @discardableResult
    private static func layoutRow(
        row: [(FileNode, Double)],
        in rect: CGRect,
        output: inout [Tile],
        final: Bool
    ) -> CGRect {
        let total = row.reduce(0.0) { $0 + $1.1 }
        guard total > 0 else { return rect }

        if rect.width <= rect.height {
            let rowHeight = CGFloat(total / Double(rect.width))
            var x = rect.minX
            for (node, value) in row {
                let width = CGFloat(value / Double(rowHeight))
                output.append(Tile(node: node, rect: CGRect(x: x, y: rect.minY, width: width, height: rowHeight)))
                x += width
            }
            return CGRect(x: rect.minX, y: rect.minY + rowHeight, width: rect.width, height: rect.height - rowHeight)
        } else {
            let rowWidth = CGFloat(total / Double(rect.height))
            var y = rect.minY
            for (node, value) in row {
                let height = CGFloat(value / Double(rowWidth))
                output.append(Tile(node: node, rect: CGRect(x: rect.minX, y: y, width: rowWidth, height: height)))
                y += height
            }
            return CGRect(x: rect.minX + rowWidth, y: rect.minY, width: rect.width - rowWidth, height: rect.height)
        }
    }
}
