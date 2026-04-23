import Foundation

public struct XcodeJunkDetector: CategoryDetector {
    public let category: JunkCategory = .xcodeJunk

    public static let paths: [String] = [
        "Library/Developer/Xcode/DerivedData",
        "Library/Developer/Xcode/Archives",
        "Library/Developer/Xcode/iOS DeviceSupport",
        "Library/Developer/Xcode/watchOS DeviceSupport",
        "Library/Developer/Xcode/tvOS DeviceSupport",
        "Library/Developer/CoreSimulator/Caches",
        "Library/Developer/CoreSimulator/Devices"
    ]

    public init() {}

    public func detect(in tree: FileNode) -> [Finding] {
        // MARK: TODO
        _ = tree
        return []
    }
}
