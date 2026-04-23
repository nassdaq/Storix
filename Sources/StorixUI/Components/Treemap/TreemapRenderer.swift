import SwiftUI
import StorixCore

/// Squarified treemap renderer as an alternative / secondary view alongside the sunburst.
public struct TreemapView: View {
    public let root: FileNode

    public init(root: FileNode) {
        self.root = root
    }

    public var body: some View {
        GeometryReader { geo in
            Canvas { context, size in
                // MARK: TODO — squarified treemap tiling
                _ = context
                _ = size
            }
            .background(Theme.background)
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}
