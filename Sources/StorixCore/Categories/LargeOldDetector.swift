import Foundation

public struct LargeOldDetector: CategoryDetector {
    public let category: JunkCategory = .largeOld

    public var minBytes: Int64
    public var minAgeDays: Int

    public init(minBytes: Int64 = 500 * 1024 * 1024, minAgeDays: Int = 180) {
        self.minBytes = minBytes
        self.minAgeDays = minAgeDays
    }

    public func detect(in tree: FileNode) async -> [Finding] {
        let hits = tree.allFiles.filter { file in
            file.size >= minBytes && file.ageInDays >= minAgeDays
        }
        guard !hits.isEmpty else { return [] }
        let sizeLabel = ByteCountFormatter.string(fromByteCount: minBytes, countStyle: .file)
        return [
            Finding(
                category: category,
                items: hits.sorted { $0.size > $1.size },
                rationale: "Files larger than \(sizeLabel) that haven't been modified in \(minAgeDays)+ days. Review before deleting.",
                confidence: 0.55
            )
        ]
    }
}
