import Foundation

public enum JunkCategory: String, CaseIterable, Identifiable, Sendable {
    case devCache
    case systemCache
    case appCache
    case duplicate
    case nearDuplicate
    case largeOld
    case trashAging
    case incompleteDownload
    case xcodeJunk
    case dockerJunk
    case unknown

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .devCache:           return "Dev caches"
        case .systemCache:        return "System caches"
        case .appCache:           return "App caches"
        case .duplicate:          return "Duplicates"
        case .nearDuplicate:      return "Near-duplicates"
        case .largeOld:           return "Large & old"
        case .trashAging:         return "Trash / old downloads"
        case .incompleteDownload: return "Incomplete downloads"
        case .xcodeJunk:          return "Xcode junk"
        case .dockerJunk:         return "Docker junk"
        case .unknown:            return "Uncategorized"
        }
    }

    public var riskLevel: RiskLevel {
        switch self {
        case .devCache, .systemCache, .appCache, .incompleteDownload, .xcodeJunk, .dockerJunk:
            return .low
        case .duplicate, .trashAging:
            return .medium
        case .nearDuplicate, .largeOld, .unknown:
            return .high
        }
    }
}

public enum RiskLevel: String, Sendable {
    case low, medium, high
}
