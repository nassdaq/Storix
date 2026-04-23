import Foundation

public struct DevCacheDetector: CategoryDetector {
    public let category: JunkCategory = .devCache

    /// Folder names that are almost always regenerable via a package manager or toolchain.
    /// Matched on exact directory name — any directory in the tree with one of these names
    /// is reported as a single finding and its children are not traversed further.
    ///
    /// Note: generic names like `build`, `dist`, `.cache` are intentionally omitted —
    /// too many false positives (non-dev projects have these too).
    public static let patterns: Set<String> = [
        "node_modules",
        ".venv",
        "venv",
        "__pycache__",
        ".pytest_cache",
        ".mypy_cache",
        ".ruff_cache",
        "target",
        ".gradle",
        ".next",
        ".nuxt",
        ".turbo",
        ".parcel-cache",
        ".expo",
        ".svelte-kit",
        ".angular"
    ]

    public var minBytes: Int64

    public init(minBytes: Int64 = 1 * 1024 * 1024) {
        self.minBytes = minBytes
    }

    public func detect(in tree: FileNode) async -> [Finding] {
        var hits: [FileNode] = []
        tree.walk { node in
            guard node.isDirectory else { return true }
            if Self.patterns.contains(node.name) && node.size >= minBytes {
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
                rationale: "Regenerable package/tool caches. Safe to delete — recreated on next build/install.",
                confidence: 0.98
            )
        ]
    }
}
