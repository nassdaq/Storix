import SwiftUI
import StorixCore

public struct SunburstView: View {
    public let root: FileNode
    public var maxDepth: Int = 5
    public var onSelect: ((FileNode) -> Void)?

    public init(
        root: FileNode,
        maxDepth: Int = 5,
        onSelect: ((FileNode) -> Void)? = nil
    ) {
        self.root = root
        self.maxDepth = maxDepth
        self.onSelect = onSelect
    }

    public var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let innerRadius = size * 0.10
            let ringThickness = (size * 0.45) / CGFloat(maxDepth)

            Canvas { context, canvasSize in
                let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)

                drawCenterLabel(
                    context: &context,
                    center: center,
                    radius: innerRadius - 4,
                    node: root
                )

                drawRings(
                    context: &context,
                    node: root,
                    center: center,
                    innerRadius: innerRadius,
                    ringThickness: ringThickness,
                    startAngle: .degrees(-90),
                    endAngle: .degrees(270),
                    depth: 0,
                    totalBytes: max(root.size, 1)
                )
            }
            .frame(width: size, height: size)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .background(Theme.background)
        }
    }

    private func drawCenterLabel(
        context: inout GraphicsContext,
        center: CGPoint,
        radius: CGFloat,
        node: FileNode
    ) {
        context.fill(
            Path(ellipseIn: CGRect(
                x: center.x - radius,
                y: center.y - radius,
                width: radius * 2,
                height: radius * 2
            )),
            with: .color(Theme.surface)
        )
        let label = ByteCountFormatter.string(fromByteCount: node.size, countStyle: .file)
        let text = Text(label)
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundColor(Theme.textPrimary)
        context.draw(text, at: center, anchor: .center)
    }

    private func drawRings(
        context: inout GraphicsContext,
        node: FileNode,
        center: CGPoint,
        innerRadius: CGFloat,
        ringThickness: CGFloat,
        startAngle: Angle,
        endAngle: Angle,
        depth: Int,
        totalBytes: Int64
    ) {
        guard depth < maxDepth else { return }
        guard node.size > 0, !node.children.isEmpty else { return }

        let ringInner = innerRadius + CGFloat(depth) * ringThickness
        let ringOuter = ringInner + ringThickness
        let totalSweep = endAngle.radians - startAngle.radians
        let parentSize = node.size

        let sorted = node.children.sorted { $0.size > $1.size }
        var cursor = startAngle.radians

        for child in sorted {
            let fraction = Double(child.size) / Double(parentSize)
            let sweep = totalSweep * fraction
            guard sweep > 0.004 else { continue } // <~0.25° — below visual threshold

            let childStart = Angle(radians: cursor)
            let childEnd = Angle(radians: cursor + sweep)

            let segment = arcSegmentPath(
                center: center,
                innerRadius: ringInner,
                outerRadius: ringOuter,
                startAngle: childStart,
                endAngle: childEnd
            )

            let color = Theme.colorForSize(child.size, maxBytes: totalBytes)
                .opacity(1.0 - Double(depth) * 0.08)
            context.fill(segment, with: .color(color))
            context.stroke(segment, with: .color(Theme.background), lineWidth: 0.5)

            if child.isDirectory {
                drawRings(
                    context: &context,
                    node: child,
                    center: center,
                    innerRadius: innerRadius,
                    ringThickness: ringThickness,
                    startAngle: childStart,
                    endAngle: childEnd,
                    depth: depth + 1,
                    totalBytes: totalBytes
                )
            }

            cursor += sweep
        }
    }

    private func arcSegmentPath(
        center: CGPoint,
        innerRadius: CGFloat,
        outerRadius: CGFloat,
        startAngle: Angle,
        endAngle: Angle
    ) -> Path {
        var path = Path()
        let outerStart = point(on: center, radius: outerRadius, angle: startAngle)
        path.move(to: outerStart)
        path.addArc(
            center: center,
            radius: outerRadius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )
        path.addLine(to: point(on: center, radius: innerRadius, angle: endAngle))
        path.addArc(
            center: center,
            radius: innerRadius,
            startAngle: endAngle,
            endAngle: startAngle,
            clockwise: true
        )
        path.closeSubpath()
        return path
    }

    private func point(on center: CGPoint, radius: CGFloat, angle: Angle) -> CGPoint {
        let cosVal: CGFloat = CGFloat(Foundation.cos(angle.radians))
        let sinVal: CGFloat = CGFloat(Foundation.sin(angle.radians))
        return CGPoint(
            x: center.x + radius * cosVal,
            y: center.y + radius * sinVal
        )
    }
}
