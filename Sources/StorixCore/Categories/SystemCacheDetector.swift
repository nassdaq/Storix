import Foundation

public struct SystemCacheDetector: CategoryDetector {
    public let category: JunkCategory = .systemCache

    /// Relative paths under the user home that hold regenerable caches/logs.
    public static let userCachePaths: [String] = [
        "Library/Caches",
        "Library/Logs",
        "Library/Application Support/CrashReporter",
        "Library/WebKit",
        "Library/Containers/*/Data/Library/Caches"
    ]

    public init() {}

    public func detect(in tree: FileNode) -> [Finding] {
        // MARK: TODO — match relative subtrees, aggregate sizes, emit findings
        _ = tree
        return []
    }
}
