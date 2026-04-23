import Foundation

public struct FileNode: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let url: URL
    public let name: String
    public let size: Int64
    public let modified: Date
    public let accessed: Date?
    public let isDirectory: Bool
    public let isSymlink: Bool
    public var children: [FileNode]

    public init(
        id: UUID = UUID(),
        url: URL,
        name: String,
        size: Int64,
        modified: Date,
        accessed: Date? = nil,
        isDirectory: Bool,
        isSymlink: Bool = false,
        children: [FileNode] = []
    ) {
        self.id = id
        self.url = url
        self.name = name
        self.size = size
        self.modified = modified
        self.accessed = accessed
        self.isDirectory = isDirectory
        self.isSymlink = isSymlink
        self.children = children
    }

    public var ageInDays: Int {
        Calendar.current.dateComponents([.day], from: modified, to: .now).day ?? 0
    }
}
