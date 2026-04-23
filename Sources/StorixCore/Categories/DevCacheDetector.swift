import Foundation

public struct DevCacheDetector: CategoryDetector {
    public let category: JunkCategory = .devCache

    /// Folder names that are almost always regenerable via a package manager.
    public static let patterns: [String] = [
        "node_modules",
        ".venv",
        "venv",
        "__pycache__",
        ".pytest_cache",
        ".mypy_cache",
        ".ruff_cache",
        "target",           // Rust
        ".gradle",
        "build",            // Gradle/Android
        ".next",
        ".nuxt",
        ".turbo",
        ".cache",
        "dist",
        ".parcel-cache",
        "DerivedData",
        ".idea",
        ".vscode"
    ]

    public init() {}

    public func detect(in tree: FileNode) -> [Finding] {
        // MARK: TODO — DFS, match patterns against directory names, stop descending once matched
        _ = tree
        return []
    }
}
