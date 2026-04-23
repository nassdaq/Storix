import Foundation

public struct ScanOptions: Sendable {
    public var roots: [URL]
    public var followSymlinks: Bool
    public var skipHiddenSystemVolumes: Bool
    public var protectedPaths: [URL]
    public var minInterestingSize: Int64
    public var progressThrottleMillis: Int

    public init(
        roots: [URL] = [URL(fileURLWithPath: NSHomeDirectory())],
        followSymlinks: Bool = false,
        skipHiddenSystemVolumes: Bool = true,
        protectedPaths: [URL] = [],
        minInterestingSize: Int64 = 10 * 1024 * 1024,
        progressThrottleMillis: Int = 100
    ) {
        self.roots = roots
        self.followSymlinks = followSymlinks
        self.skipHiddenSystemVolumes = skipHiddenSystemVolumes
        self.protectedPaths = protectedPaths
        self.minInterestingSize = minInterestingSize
        self.progressThrottleMillis = progressThrottleMillis
    }
}

/// Directory names we always skip. Scanning them either wastes time (virtual FS) or risks
/// tripping macOS protection (Time Machine metadata, Spotlight indices).
public let defaultScanSkipNames: Set<String> = [
    ".Trash",
    ".Trashes",
    ".Spotlight-V100",
    ".fseventsd",
    ".DocumentRevisions-V100",
    ".TemporaryItems",
    ".MobileBackups",
    ".PKInstallSandboxManager",
    ".PKInstallSandboxManager-SystemSoftware"
]

public final class StorageScanner: @unchecked Sendable {
    public init() {}

    public func scan(
        options: ScanOptions,
        progress: @escaping @Sendable (ScanProgress) -> Void,
        detectors: DetectorRegistry = DetectorRegistry()
    ) async throws -> ScanResult {
        let started = Date()

        let counter = ScanCounter(
            throttle: options.progressThrottleMillis,
            emit: progress
        )
        counter.begin()

        let primaryRoot = options.roots.first ?? URL(fileURLWithPath: NSHomeDirectory())
        var rootChildren: [FileNode] = []
        for root in options.roots {
            if let node = try walk(
                url: root,
                options: options,
                counter: counter
            ) {
                rootChildren.append(node)
            }
        }

        let rootNode: FileNode
        if options.roots.count == 1, let only = rootChildren.first {
            rootNode = only
        } else {
            let totalSize = rootChildren.reduce(Int64(0)) { $0 + $1.size }
            rootNode = FileNode(
                url: primaryRoot,
                name: "Scan",
                size: totalSize,
                modified: .now,
                isDirectory: true,
                children: rootChildren
            )
        }

        progress(.classifying)
        let findings = await detectors.runAll(on: rootNode)
        progress(.done)

        return ScanResult(
            root: primaryRoot,
            startedAt: started,
            completedAt: .now,
            rootNode: rootNode,
            findings: findings
        )
    }

    private func walk(
        url: URL,
        options: ScanOptions,
        counter: ScanCounter
    ) throws -> FileNode? {
        let fm = FileManager.default

        let resourceKeys: Set<URLResourceKey> = [
            .isDirectoryKey,
            .isSymbolicLinkKey,
            .totalFileAllocatedSizeKey,
            .fileSizeKey,
            .contentModificationDateKey,
            .contentAccessDateKey,
            .nameKey
        ]

        let values = try url.resourceValues(forKeys: resourceKeys)
        let isDir = values.isDirectory ?? false
        let isSymlink = values.isSymbolicLink ?? false
        let name = values.name ?? url.lastPathComponent
        let modified = values.contentModificationDate ?? Date(timeIntervalSince1970: 0)
        let accessed = values.contentAccessDate

        if !options.followSymlinks && isSymlink {
            return nil
        }

        for protected in options.protectedPaths where url.standardizedFileURL.path == protected.standardizedFileURL.path {
            return nil
        }

        if options.skipHiddenSystemVolumes && defaultScanSkipNames.contains(name) {
            return nil
        }

        if !isDir {
            let size = Int64(values.totalFileAllocatedSize ?? values.fileSize ?? 0)
            counter.observeFile(bytes: size, path: url.path)
            return FileNode(
                url: url,
                name: name,
                size: size,
                modified: modified,
                accessed: accessed,
                isDirectory: false,
                isSymlink: isSymlink
            )
        }

        var children: [FileNode] = []
        var total: Int64 = 0

        let contents: [URL]
        do {
            contents = try fm.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: Array(resourceKeys),
                options: [.skipsPackageDescendants]
            )
        } catch {
            return FileNode(
                url: url,
                name: name,
                size: 0,
                modified: modified,
                accessed: accessed,
                isDirectory: true,
                isSymlink: isSymlink
            )
        }

        for child in contents {
            do {
                if let node = try walk(url: child, options: options, counter: counter) {
                    total += node.size
                    children.append(node)
                }
            } catch {
                continue
            }
        }

        counter.observeDirectory()

        return FileNode(
            url: url,
            name: name,
            size: total,
            modified: modified,
            accessed: accessed,
            isDirectory: true,
            isSymlink: isSymlink,
            children: children
        )
    }
}

/// Thread-safe counter that throttles progress emissions to avoid flooding the UI.
final class ScanCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var filesSeen: Int = 0
    private var dirsSeen: Int = 0
    private var bytesSeen: Int64 = 0
    private var lastEmit: Date = .distantPast
    private let throttleSeconds: Double
    private let emit: @Sendable (ScanProgress) -> Void

    init(throttle: Int, emit: @escaping @Sendable (ScanProgress) -> Void) {
        self.throttleSeconds = Double(throttle) / 1000.0
        self.emit = emit
    }

    func begin() {
        emit(.walking(filesSeen: 0, bytesSeen: 0, currentPath: ""))
    }

    func observeFile(bytes: Int64, path: String) {
        lock.lock()
        filesSeen += 1
        bytesSeen += bytes
        let shouldEmit = Date().timeIntervalSince(lastEmit) >= throttleSeconds
        let snapshotFiles = filesSeen
        let snapshotBytes = bytesSeen
        if shouldEmit { lastEmit = .now }
        lock.unlock()

        if shouldEmit {
            emit(.walking(filesSeen: snapshotFiles, bytesSeen: snapshotBytes, currentPath: path))
        }
    }

    func observeDirectory() {
        lock.lock()
        dirsSeen += 1
        lock.unlock()
    }
}
