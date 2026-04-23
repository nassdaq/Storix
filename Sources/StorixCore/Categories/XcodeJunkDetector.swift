import Foundation

public struct XcodeJunkDetector: CategoryDetector {
    public let category: JunkCategory = .xcodeJunk

    /// Home-relative subtree paths considered junk. Each is reported as a single directory
    /// and its children are not traversed further.
    public static let homeRelativePaths: [String] = [
        "Library/Developer/Xcode/DerivedData",
        "Library/Developer/Xcode/Archives",
        "Library/Developer/Xcode/iOS DeviceSupport",
        "Library/Developer/Xcode/watchOS DeviceSupport",
        "Library/Developer/Xcode/tvOS DeviceSupport",
        "Library/Developer/Xcode/UserData/IB Support",
        "Library/Developer/Xcode/UserData/Previews",
        "Library/Developer/CoreSimulator/Caches"
    ]

    public init() {}

    public func detect(in tree: FileNode) -> [Finding] {
        let home = URL(fileURLWithPath: NSHomeDirectory()).standardizedFileURL.path
        let targetPaths = Set(Self.homeRelativePaths.map { "\(home)/\($0)" })

        var hits: [FileNode] = []
        tree.walk { node in
            guard node.isDirectory else { return true }
            if targetPaths.contains(node.url.standardizedFileURL.path) {
                hits.append(node)
                return false
            }
            return true
        }

        guard !hits.isEmpty else { return [] }
        return [
            Finding(
                category: category,
                items: hits,
                rationale: "Xcode-generated caches, archives, and device support. All regenerable — Xcode rebuilds on next open.",
                confidence: 0.97
            )
        ]
    }
}
