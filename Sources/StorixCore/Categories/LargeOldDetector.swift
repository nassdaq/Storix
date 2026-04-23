import Foundation

public struct LargeOldDetector: CategoryDetector {
    public let category: JunkCategory = .largeOld

    public var minBytes: Int64
    public var minAgeDays: Int

    public init(minBytes: Int64 = 500 * 1024 * 1024, minAgeDays: Int = 180) {
        self.minBytes = minBytes
        self.minAgeDays = minAgeDays
    }

    public func detect(in tree: FileNode) -> [Finding] {
        // MARK: TODO — DFS, collect leaf files where size >= minBytes && ageInDays >= minAgeDays
        _ = tree
        return []
    }
}
