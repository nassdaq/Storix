import Foundation

public struct IncompleteDownloadDetector: CategoryDetector {
    public let category: JunkCategory = .incompleteDownload

    public static let extensions: Set<String> = [
        "crdownload",   // Chrome
        "part",         // Firefox / generic
        "download",     // Safari
        "opdownload",   // Opera
        "!ut"           // uTorrent
    ]

    public init() {}

    public func detect(in tree: FileNode) -> [Finding] {
        // MARK: TODO — walk, match file extensions, aggregate
        _ = tree
        return []
    }
}
