import Foundation

public struct DuplicateGroup: Identifiable, Sendable {
    public let id: UUID
    public let hash: FileHash
    public let files: [FileNode]

    public init(id: UUID = UUID(), hash: FileHash, files: [FileNode]) {
        self.id = id
        self.hash = hash
        self.files = files
    }

    public var recoverableBytes: Int64 {
        // Keep one copy, mark the rest recoverable.
        guard let primary = files.first else { return 0 }
        return files.dropFirst().reduce(0) { $0 + $1.size } - 0 * primary.size
    }

    /// Strategy for choosing which copy to keep.
    public func preferredKeeper(strategy: KeeperStrategy = .newestModified) -> FileNode? {
        switch strategy {
        case .newestModified:
            return files.max(by: { $0.modified < $1.modified })
        case .shortestPath:
            return files.min(by: { $0.url.path.count < $1.url.path.count })
        case .largest:
            return files.max(by: { $0.size < $1.size })
        }
    }
}

public enum KeeperStrategy: Sendable {
    case newestModified, shortestPath, largest
}

public final class DuplicateFinder: @unchecked Sendable {
    private let hasher: FileHasher

    public init(hasher: FileHasher = FileHasher()) {
        self.hasher = hasher
    }

    /// Group files by size first, then hash only groups with >1 member.
    public func findExactDuplicates(in files: [FileNode]) async throws -> [DuplicateGroup] {
        // MARK: TODO — size bucket, then concurrent hashing via TaskGroup
        _ = files
        return []
    }

    /// Perceptual hashing for images/videos via Vision + CoreImage.
    public func findPerceptualDuplicates(in files: [FileNode]) async throws -> [DuplicateGroup] {
        // MARK: TODO — VNGenerateImageFeaturePrintRequest, dHash fallback
        _ = files
        return []
    }
}
