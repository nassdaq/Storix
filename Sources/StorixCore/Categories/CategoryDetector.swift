import Foundation

public protocol CategoryDetector: Sendable {
    var category: JunkCategory { get }
    func detect(in tree: FileNode) -> [Finding]
}

public struct DetectorRegistry: Sendable {
    public let detectors: [any CategoryDetector]

    public init(detectors: [any CategoryDetector] = DetectorRegistry.defaults) {
        self.detectors = detectors
    }

    public static var defaults: [any CategoryDetector] {
        [
            DevCacheDetector(),
            SystemCacheDetector(),
            LargeOldDetector(),
            XcodeJunkDetector(),
            IncompleteDownloadDetector()
        ]
    }

    public func runAll(on tree: FileNode) -> [Finding] {
        detectors.flatMap { $0.detect(in: tree) }
    }
}
