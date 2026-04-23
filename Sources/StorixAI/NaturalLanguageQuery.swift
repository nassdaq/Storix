import Foundation
import StorixCore

public struct QueryPredicate: Sendable {
    public var minSize: Int64?
    public var maxSize: Int64?
    public var minAgeDays: Int?
    public var maxAgeDays: Int?
    public var extensions: Set<String>
    public var pathContains: [String]
    public var mimeTypes: Set<String>

    public init(
        minSize: Int64? = nil,
        maxSize: Int64? = nil,
        minAgeDays: Int? = nil,
        maxAgeDays: Int? = nil,
        extensions: Set<String> = [],
        pathContains: [String] = [],
        mimeTypes: Set<String> = []
    ) {
        self.minSize = minSize
        self.maxSize = maxSize
        self.minAgeDays = minAgeDays
        self.maxAgeDays = maxAgeDays
        self.extensions = extensions
        self.pathContains = pathContains
        self.mimeTypes = mimeTypes
    }

    public func matches(_ node: FileNode) -> Bool {
        if let min = minSize, node.size < min { return false }
        if let max = maxSize, node.size > max { return false }
        if let minAge = minAgeDays, node.ageInDays < minAge { return false }
        if let maxAge = maxAgeDays, node.ageInDays > maxAge { return false }
        if !extensions.isEmpty {
            let ext = node.url.pathExtension.lowercased()
            if !extensions.contains(ext) { return false }
        }
        if !pathContains.isEmpty {
            let path = node.url.path.lowercased()
            if !pathContains.contains(where: { path.contains($0.lowercased()) }) { return false }
        }
        return true
    }
}

public final class NaturalLanguageQuery: @unchecked Sendable {
    private let client: ClaudeClient

    public init(client: ClaudeClient = ClaudeClient()) {
        self.client = client
    }

    /// Ask Claude to translate a human query into a structured predicate.
    /// Example: "find videos from 2022 over 1GB" → extensions: [mp4,mov,...], minSize: 1GB, minAgeDays, maxAgeDays
    public func parse(_ query: String) async throws -> QueryPredicate {
        let systemPrompt = """
        You translate a user's natural-language file-search query into a strict JSON object with keys:
        { "minSize": int|null, "maxSize": int|null, "minAgeDays": int|null, "maxAgeDays": int|null,
          "extensions": [string], "pathContains": [string] }
        Sizes are in bytes. Output JSON only — no prose, no code fences.
        """
        let raw = try await client.run(ClaudePrompt(system: systemPrompt, user: query))
        return try decode(raw)
    }

    private func decode(_ raw: String) throws -> QueryPredicate {
        guard let data = raw.data(using: .utf8) else {
            return QueryPredicate()
        }
        struct DTO: Decodable {
            var minSize: Int64?
            var maxSize: Int64?
            var minAgeDays: Int?
            var maxAgeDays: Int?
            var extensions: [String]?
            var pathContains: [String]?
        }
        let dto = try JSONDecoder().decode(DTO.self, from: data)
        return QueryPredicate(
            minSize: dto.minSize,
            maxSize: dto.maxSize,
            minAgeDays: dto.minAgeDays,
            maxAgeDays: dto.maxAgeDays,
            extensions: Set((dto.extensions ?? []).map { $0.lowercased() }),
            pathContains: dto.pathContains ?? []
        )
    }
}
