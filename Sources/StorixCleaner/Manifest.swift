import Foundation
import StorixCore

public struct CleanupManifest: Codable, Identifiable, Sendable {
    public let id: UUID
    public let timestamp: Date
    public let entries: [ManifestEntry]
    public let totalBytes: Int64

    public init(
        id: UUID = UUID(),
        timestamp: Date = .now,
        entries: [ManifestEntry],
        totalBytes: Int64
    ) {
        self.id = id
        self.timestamp = timestamp
        self.entries = entries
        self.totalBytes = totalBytes
    }
}

public struct ManifestEntry: Codable, Sendable {
    public let originalPath: String
    public let category: String
    public let size: Int64
    public let trashedAt: Date
    public let trashURL: String?

    public init(
        originalPath: String,
        category: JunkCategory,
        size: Int64,
        trashedAt: Date = .now,
        trashURL: URL? = nil
    ) {
        self.originalPath = originalPath
        self.category = category.rawValue
        self.size = size
        self.trashedAt = trashedAt
        self.trashURL = trashURL?.path
    }
}

public struct ManifestStore: Sendable {
    public let directory: URL

    public init(directory: URL = ManifestStore.defaultDirectory) {
        self.directory = directory
    }

    public static var defaultDirectory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return base.appendingPathComponent("Storix/Manifests", isDirectory: true)
    }

    public func save(_ manifest: CleanupManifest) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent("\(manifest.id.uuidString).json")
        let data = try JSONEncoder().encode(manifest)
        try data.write(to: url, options: .atomic)
    }

    public func load(id: UUID) throws -> CleanupManifest {
        let url = directory.appendingPathComponent("\(id.uuidString).json")
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(CleanupManifest.self, from: data)
    }

    public func listAll() throws -> [CleanupManifest] {
        guard FileManager.default.fileExists(atPath: directory.path) else { return [] }
        let files = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "json" }
        return try files.map { try JSONDecoder().decode(CleanupManifest.self, from: try Data(contentsOf: $0)) }
            .sorted { $0.timestamp > $1.timestamp }
    }
}
