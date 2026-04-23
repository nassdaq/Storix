import Foundation

public struct SystemCacheDetector: CategoryDetector {
    public let category: JunkCategory = .systemCache

    /// Home-relative subtree paths that hold regenerable caches/logs.
    /// Children of each matched directory are reported together (we don't descend further).
    public static let homeRelativePaths: [String] = [
        "Library/Caches",
        "Library/Logs",
        "Library/Application Support/CrashReporter",
        "Library/WebKit"
    ]

    public var minBytes: Int64

    public init(minBytes: Int64 = 10 * 1024 * 1024) {
        self.minBytes = minBytes
    }

    public func detect(in tree: FileNode) -> [Finding] {
        let home = URL(fileURLWithPath: NSHomeDirectory()).standardizedFileURL.path
        let targetPaths = Set(Self.homeRelativePaths.map { "\(home)/\($0)" })

        var hits: [FileNode] = []
        tree.walk { node in
            guard node.isDirectory else { return true }
            if targetPaths.contains(node.url.standardizedFileURL.path) && node.size >= minBytes {
                hits.append(node)
                return false
            }
            return true
        }

        guard !hits.isEmpty else { return [] }
        return [
            Finding(
                category: category,
                items: hits,
                rationale: "App-managed caches and logs. Apps will regenerate what they need on next launch.",
                confidence: 0.90
            )
        ]
    }
}
