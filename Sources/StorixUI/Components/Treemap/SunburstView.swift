import SwiftUI
import StorixCore

public struct SunburstView: View {
    public let root: FileNode
    public var maxDepth: Int = 5
    @State private var hoveredPath: String? = nil
    @State private var zoomedNodeId: UUID? = nil

    public init(root: FileNode, maxDepth: Int = 5) {
        self.root = root
        self.maxDepth = maxDepth
    }

    public var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            Canvas { context, canvasSize in
                drawSunburst(
                    node: zoomedNode(),
                    context: &context,
                    center: CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2),
                    innerRadius: size * 0.12,
                    ringThickness: (size * 0.40) / CGFloat(maxDepth),
                    startAngle: .zero,
                    endAngle: .degrees(360),
                    depth: 0,
                    totalBytes: zoomedNode().size
                )
            }
            .frame(width: size, height: size)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .background(Theme.background)
        }
    }

    private func zoomedNode() -> FileNode {
        // MARK: TODO — descend to zoomedNodeId
        return root
    }

    private func drawSunburst(
        node: FileNode,
        context: inout GraphicsContext,
        center: CGPoint,
        innerRadius: CGFloat,
        ringThickness: CGFloat,
        startAngle: Angle,
        endAngle: Angle,
        depth: Int,
        totalBytes: Int64
    ) {
        // MARK: TODO — full recursive renderer:
        //   - for each child, compute fraction = child.size / node.size
        //   - sweep = (endAngle - startAngle) * fraction
        //   - draw arc with Theme.colorForSize
        //   - recurse into child for depth+1
        //
        // Placeholder: draw a single ring so the view is visible during stub phase.
        guard depth == 0 else { return }
        let path = Path { p in
            p.addArc(
                center: center,
                radius: innerRadius + ringThickness,
                startAngle: startAngle,
                endAngle: endAngle,
                clockwise: false
            )
        }
        context.stroke(path, with: .color(Theme.accent), lineWidth: ringThickness)
        _ = node
        _ = totalBytes
    }
}
