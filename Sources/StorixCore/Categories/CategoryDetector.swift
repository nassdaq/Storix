import Foundation

public protocol CategoryDetector: Sendable {
    var category: JunkCategory { get }
    func detect(in tree: FileNode) async -> [Finding]
}

public struct DetectorRegistry: Sendable {
    public let detectors: [any CategoryDetector]

    public init(detectors: [any CategoryDetector] = DetectorRegistry.defaults) {
        self.detectors = detectors
    }

    /// Built-in detectors run on every scan.
    public static var defaults: [any CategoryDetector] {
        [
            DevCacheDetector(),
            SystemCacheDetector(),
            XcodeJunkDetector(),
            IncompleteDownloadDetector(),
            LargeOldDetector(),
            DuplicateDetector()
        ]
    }

    /// Run every detector concurrently and flatten findings.
    public func runAll(on tree: FileNode) async -> [Finding] {
        await withTaskGroup(of: [Finding].self) { group in
            for detector in detectors {
                group.addTask { await detector.detect(in: tree) }
            }
            var all: [Finding] = []
            for await partial in group {
                all.append(contentsOf: partial)
            }
            return all
        }
    }
}
