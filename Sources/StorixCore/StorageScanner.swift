import Foundation

public struct ScanOptions: Sendable {
    public var roots: [URL]
    public var followSymlinks: Bool
    public var skipHiddenSystemVolumes: Bool
    public var protectedPaths: [URL]
    public var minInterestingSize: Int64

    public init(
        roots: [URL] = [URL(fileURLWithPath: NSHomeDirectory())],
        followSymlinks: Bool = false,
        skipHiddenSystemVolumes: Bool = true,
        protectedPaths: [URL] = [],
        minInterestingSize: Int64 = 10 * 1024 * 1024 // 10 MB
    ) {
        self.roots = roots
        self.followSymlinks = followSymlinks
        self.skipHiddenSystemVolumes = skipHiddenSystemVolumes
        self.protectedPaths = protectedPaths
        self.minInterestingSize = minInterestingSize
    }
}

public final class StorageScanner: @unchecked Sendable {
    public init() {}

    /// Walk roots, build FileNode tree, invoke category detectors, return ScanResult.
    ///
    /// - Parameters:
    ///   - options: scan configuration
    ///   - progress: called on the main actor with incremental progress
    public func scan(
        options: ScanOptions,
        progress: @escaping @Sendable (ScanProgress) -> Void
    ) async throws -> ScanResult {
        let started = Date()
        progress(.walking(filesSeen: 0, bytesSeen: 0, currentPath: ""))

        // MARK: TODO — parallel walk with FileManager.enumerator
        // MARK: TODO — honor protectedPaths, skip .Trashes, .fseventsd, Time Machine
        // MARK: TODO — emit progress every N files or every 100 ms

        let root = options.roots.first ?? URL(fileURLWithPath: NSHomeDirectory())
        let placeholderNode = FileNode(
            url: root,
            name: root.lastPathComponent,
            size: 0,
            modified: .now,
            isDirectory: true
        )

        progress(.classifying)
        let findings: [Finding] = [] // MARK: TODO — run all detectors
        progress(.done)

        return ScanResult(
            root: root,
            startedAt: started,
            completedAt: .now,
            root_node: placeholderNode,
            findings: findings
        )
    }
}
