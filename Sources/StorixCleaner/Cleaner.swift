import Foundation
import AppKit
import StorixCore

public struct CleanupPlan: Sendable {
    public let items: [FileNode]
    public let category: JunkCategory

    public init(items: [FileNode], category: JunkCategory) {
        self.items = items
        self.category = category
    }

    public var totalBytes: Int64 {
        items.reduce(0) { $0 + $1.size }
    }
}

public enum CleanerError: Error, Sendable {
    case notFound(URL)
    case protected(URL)
    case trashFailed(URL, underlying: String)
}

public final class Cleaner: @unchecked Sendable {
    public let manifestStore: ManifestStore

    public init(manifestStore: ManifestStore = ManifestStore()) {
        self.manifestStore = manifestStore
    }

    /// Dry-run preview: returns the plan without side effects.
    public func preview(_ plans: [CleanupPlan]) -> CleanupPreview {
        let total = plans.reduce(Int64(0)) { $0 + $1.totalBytes }
        let count = plans.reduce(0) { $0 + $1.items.count }
        return CleanupPreview(totalBytes: total, itemCount: count, plans: plans)
    }

    /// Execute: move each item to Trash via NSWorkspace.recycle, write manifest.
    @MainActor
    public func execute(_ plans: [CleanupPlan]) async throws -> CleanupManifest {
        var entries: [ManifestEntry] = []
        var total: Int64 = 0

        for plan in plans {
            for item in plan.items {
                let trashURL = try await trash(url: item.url)
                entries.append(
                    ManifestEntry(
                        originalPath: item.url.path,
                        category: plan.category,
                        size: item.size,
                        trashURL: trashURL
                    )
                )
                total += item.size
            }
        }

        let manifest = CleanupManifest(entries: entries, totalBytes: total)
        try manifestStore.save(manifest)
        return manifest
    }

    @MainActor
    private func trash(url: URL) async throws -> URL? {
        return try await withCheckedThrowingContinuation { continuation in
            NSWorkspace.shared.recycle([url]) { result, error in
                if let error {
                    continuation.resume(throwing: CleanerError.trashFailed(url, underlying: error.localizedDescription))
                    return
                }
                continuation.resume(returning: result[url])
            }
        }
    }
}

public struct CleanupPreview: Sendable {
    public let totalBytes: Int64
    public let itemCount: Int
    public let plans: [CleanupPlan]
}
