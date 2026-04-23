import Foundation

public struct DuplicateDetector: CategoryDetector {
    public let category: JunkCategory = .duplicate

    public let finder: DuplicateFinder
    public let keeperStrategy: KeeperStrategy

    public init(
        finder: DuplicateFinder = DuplicateFinder(),
        keeperStrategy: KeeperStrategy = .newestModified
    ) {
        self.finder = finder
        self.keeperStrategy = keeperStrategy
    }

    public func detect(in tree: FileNode) async -> [Finding] {
        let groups = await finder.findExactDuplicates(in: tree.allFiles)
        guard !groups.isEmpty else { return [] }

        // Emit ONE finding per duplicate group so the UI can show group context
        // (which file is the keeper, which are deletable).
        return groups.map { group in
            let deletable = group.deletable(strategy: keeperStrategy)
            let keeper = group.preferredKeeper(strategy: keeperStrategy)
            let keeperName = keeper?.url.lastPathComponent ?? "unknown"
            let rationale = "Exact duplicate of \"\(keeperName)\" (\(group.files.count) total copies). Keeping the \(keeperStrategyDescription) copy."
            return Finding(
                category: .duplicate,
                items: deletable,
                rationale: rationale,
                confidence: 1.0
            )
        }
    }

    private var keeperStrategyDescription: String {
        switch keeperStrategy {
        case .newestModified: return "most recently modified"
        case .shortestPath:   return "shallowest"
        case .largest:        return "largest"
        }
    }
}

public struct NearDuplicateDetector: CategoryDetector {
    public let category: JunkCategory = .nearDuplicate

    public let finder: DuplicateFinder
    public let keeperStrategy: KeeperStrategy

    public init(
        finder: DuplicateFinder = DuplicateFinder(),
        keeperStrategy: KeeperStrategy = .largest
    ) {
        self.finder = finder
        self.keeperStrategy = keeperStrategy
    }

    public func detect(in tree: FileNode) async -> [Finding] {
        let groups = await finder.findPerceptualDuplicates(in: tree.allFiles)
        guard !groups.isEmpty else { return [] }

        return groups.map { group in
            let deletable = group.deletable(strategy: keeperStrategy)
            return Finding(
                category: .nearDuplicate,
                items: deletable,
                rationale: "Visually similar media (hamming distance ≤ \(finder.perceptualThreshold)). Keeping the highest-resolution copy.",
                confidence: 0.80
            )
        }
    }
}
