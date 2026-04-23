import Foundation

public struct ScanResult: Identifiable, Sendable {
    public let id: UUID
    public let root: URL
    public let startedAt: Date
    public let completedAt: Date
    public let rootNode: FileNode
    public let findings: [Finding]

    public init(
        id: UUID = UUID(),
        root: URL,
        startedAt: Date,
        completedAt: Date,
        rootNode: FileNode,
        findings: [Finding]
    ) {
        self.id = id
        self.root = root
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.rootNode = rootNode
        self.findings = findings
    }

    public var totalRecoverableBytes: Int64 {
        findings.reduce(0) { $0 + $1.totalBytes }
    }

    public var duration: TimeInterval {
        completedAt.timeIntervalSince(startedAt)
    }

    public func findings(in category: JunkCategory) -> [Finding] {
        findings.filter { $0.category == category }
    }
}

public struct Finding: Identifiable, Sendable {
    public let id: UUID
    public let category: JunkCategory
    public let items: [FileNode]
    public let rationale: String
    public let confidence: Double // 0.0 – 1.0

    public init(
        id: UUID = UUID(),
        category: JunkCategory,
        items: [FileNode],
        rationale: String,
        confidence: Double = 1.0
    ) {
        self.id = id
        self.category = category
        self.items = items
        self.rationale = rationale
        self.confidence = confidence
    }

    public var totalBytes: Int64 {
        items.reduce(0) { $0 + $1.size }
    }
}

public enum ScanProgress: Sendable, Equatable {
    case idle
    case walking(filesSeen: Int, bytesSeen: Int64, currentPath: String)
    case hashing(filesDone: Int, filesTotal: Int)
    case classifying
    case done
}
