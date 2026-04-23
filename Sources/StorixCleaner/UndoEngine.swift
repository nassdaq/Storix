import Foundation

public struct UndoResult: Sendable {
    public let restored: Int
    public let failed: [(path: String, reason: String)]
    public let bytesRestored: Int64
}

public final class UndoEngine: @unchecked Sendable {
    public let manifestStore: ManifestStore

    public init(manifestStore: ManifestStore = ManifestStore()) {
        self.manifestStore = manifestStore
    }

    /// Restore every entry in the manifest from its Trash URL back to its original path.
    /// Fails softly — files already purged from Trash are reported in `failed`.
    public func undo(manifest: CleanupManifest) throws -> UndoResult {
        var restored = 0
        var failed: [(String, String)] = []
        var bytes: Int64 = 0

        let fm = FileManager.default
        for entry in manifest.entries {
            guard let trashPath = entry.trashURL else {
                failed.append((entry.originalPath, "no trash URL recorded"))
                continue
            }
            let src = URL(fileURLWithPath: trashPath)
            let dst = URL(fileURLWithPath: entry.originalPath)

            guard fm.fileExists(atPath: src.path) else {
                failed.append((entry.originalPath, "file already purged from Trash"))
                continue
            }

            do {
                try fm.createDirectory(at: dst.deletingLastPathComponent(), withIntermediateDirectories: true)
                try fm.moveItem(at: src, to: dst)
                restored += 1
                bytes += entry.size
            } catch {
                failed.append((entry.originalPath, error.localizedDescription))
            }
        }

        return UndoResult(restored: restored, failed: failed, bytesRestored: bytes)
    }

    public func undoLast() throws -> UndoResult? {
        guard let latest = try manifestStore.listAll().first else { return nil }
        return try undo(manifest: latest)
    }
}
