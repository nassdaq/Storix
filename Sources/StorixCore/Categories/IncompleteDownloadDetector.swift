import Foundation

public struct IncompleteDownloadDetector: CategoryDetector {
    public let category: JunkCategory = .incompleteDownload

    public static let extensions: Set<String> = [
        "crdownload",
        "part",
        "download",
        "opdownload",
        "!ut"
    ]

    public init() {}

    public func detect(in tree: FileNode) async -> [Finding] {
        let hits = tree.allFiles.filter { file in
            Self.extensions.contains(file.url.pathExtension.lowercased())
        }
        guard !hits.isEmpty else { return [] }
        return [
            Finding(
                category: category,
                items: hits,
                rationale: "Partial downloads abandoned by the browser/torrent client. Safe to remove.",
                confidence: 0.95
            )
        ]
    }
}
