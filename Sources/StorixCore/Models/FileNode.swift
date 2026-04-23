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

    /// Depth-first traversal. Return `false` from `visit` to stop descending into the current node's children.
    public func walk(_ visit: (FileNode) -> Bool) {
        let descend = visit(self)
        guard descend else { return }
        for child in children {
            child.walk(visit)
        }
    }

    /// Collect every leaf (non-directory) file in the subtree.
    public var allFiles: [FileNode] {
        var out: [FileNode] = []
        walk { node in
            if !node.isDirectory { out.append(node) }
            return true
        }
        return out
    }

    /// Collect every directory in the subtree, including self.
    public var allDirectories: [FileNode] {
        var out: [FileNode] = []
        walk { node in
            if node.isDirectory { out.append(node) }
            return true
        }
        return out
    }
}
