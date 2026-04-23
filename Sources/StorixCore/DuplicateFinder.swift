import Foundation

public struct DuplicateGroup: Identifiable, Sendable {
    public let id: UUID
    public let signature: String
    public let files: [FileNode]

    public init(id: UUID = UUID(), signature: String, files: [FileNode]) {
        self.id = id
        self.signature = signature
        self.files = files
    }

    /// Bytes reclaimable if we keep one copy and delete the rest.
    public var recoverableBytes: Int64 {
        guard files.count > 1 else { return 0 }
        let keeperSize = preferredKeeper()?.size ?? 0
        return files.reduce(0) { $0 + $1.size } - keeperSize
    }

    public func preferredKeeper(strategy: KeeperStrategy = .newestModified) -> FileNode? {
        switch strategy {
        case .newestModified:
            return files.max(by: { $0.modified < $1.modified })
        case .shortestPath:
            return files.min(by: { $0.url.path.count < $1.url.path.count })
        case .largest:
            return files.max(by: { $0.size < $1.size })
        }
    }

    /// Files that may be safely deleted (everything except the preferred keeper).
    public func deletable(strategy: KeeperStrategy = .newestModified) -> [FileNode] {
        guard let keeper = preferredKeeper(strategy: strategy) else { return [] }
        return files.filter { $0.id != keeper.id }
    }
}

public enum KeeperStrategy: Sendable {
    case newestModified, shortestPath, largest
}

public final class DuplicateFinder: @unchecked Sendable {
    public let hasher: FileHasher
    public let perceptualHasher: PerceptualHasher
    public let perceptualThreshold: Int
    public let minFileSize: Int64

    /// - Parameters:
    ///   - minFileSize: files smaller than this are ignored for exact-dup detection
    ///                  (cheap pruning — 4-byte zero files aren't interesting).
    ///   - perceptualThreshold: max hamming distance (out of 64) still considered a match.
    public init(
        hasher: FileHasher = FileHasher(),
        perceptualHasher: PerceptualHasher = PerceptualHasher(),
        perceptualThreshold: Int = 6,
        minFileSize: Int64 = 1024
    ) {
        self.hasher = hasher
        self.perceptualHasher = perceptualHasher
        self.perceptualThreshold = perceptualThreshold
        self.minFileSize = minFileSize
    }

    /// Find files that are byte-for-byte identical.
    /// Pipeline: size bucket → quick-hash bucket → full SHA-256 bucket.
    public func findExactDuplicates(in files: [FileNode]) async -> [DuplicateGroup] {
        let candidates = files.filter { !$0.isDirectory && $0.size >= minFileSize }

        // Stage 1: group by size.
        var bySize: [Int64: [FileNode]] = [:]
        for file in candidates {
            bySize[file.size, default: []].append(file)
        }
        let sizeBuckets = bySize.values.filter { $0.count > 1 }

        // Stage 2: quick-hash (head+tail+size).
        let quickGroups = await hashBuckets(buckets: sizeBuckets, using: { try self.hasher.quickHash(url: $0) })

        // Stage 3: full SHA-256 only for colliding quick-hashes.
        let fullGroups = await hashBuckets(buckets: quickGroups, using: { try self.hasher.hash(url: $0) })

        return fullGroups.compactMap { group in
            guard group.count > 1 else { return nil }
            let signature = (try? hasher.hash(url: group[0].url).hex) ?? UUID().uuidString
            return DuplicateGroup(signature: signature, files: group)
        }
    }

    /// Hash each file in each bucket concurrently; re-bucket by resulting hash. Buckets of
    /// size 1 are discarded (can't be a duplicate).
    private func hashBuckets(
        buckets: [[FileNode]],
        using hash: @Sendable @escaping (URL) throws -> FileHash
    ) async -> [[FileNode]] {
        await withTaskGroup(of: [(FileHash, FileNode)].self) { group in
            for bucket in buckets {
                group.addTask {
                    var out: [(FileHash, FileNode)] = []
                    for file in bucket {
                        if let h = try? hash(file.url) {
                            out.append((h, file))
                        }
                    }
                    return out
                }
            }

            var byHash: [String: [FileNode]] = [:]
            for await results in group {
                for (h, file) in results {
                    byHash[h.hex, default: []].append(file)
                }
            }
            return byHash.values.filter { $0.count > 1 }
        }
    }

    /// Find images/videos with similar visual content via dHash + hamming distance.
    /// Exhaustive O(n²) comparison — acceptable because `n` here is "images in user's tree",
    /// typically a few thousand.
    public func findPerceptualDuplicates(in files: [FileNode]) async -> [DuplicateGroup] {
        let media = files.filter { file in
            guard !file.isDirectory else { return false }
            let ext = file.url.pathExtension.lowercased()
            return PerceptualHasher.imageExtensions.contains(ext)
                || PerceptualHasher.videoExtensions.contains(ext)
        }

        let hashed: [(FileNode, PerceptualHash)] = await withTaskGroup(of: (FileNode, PerceptualHash?).self) { group in
            for file in media {
                let h = perceptualHasher
                group.addTask {
                    let ext = file.url.pathExtension.lowercased()
                    if PerceptualHasher.imageExtensions.contains(ext) {
                        return (file, h.imageHash(url: file.url))
                    } else {
                        return (file, await h.videoHash(url: file.url))
                    }
                }
            }
            var out: [(FileNode, PerceptualHash)] = []
            for await (file, hash) in group {
                if let hash { out.append((file, hash)) }
            }
            return out
        }

        // Union-find over hamming-close pairs.
        var parent = Array(0..<hashed.count)
        func find(_ i: Int) -> Int {
            var x = i
            while parent[x] != x { parent[x] = parent[parent[x]]; x = parent[x] }
            return x
        }
        func union(_ a: Int, _ b: Int) {
            let ra = find(a); let rb = find(b)
            if ra != rb { parent[ra] = rb }
        }

        for i in 0..<hashed.count {
            for j in (i + 1)..<hashed.count {
                let dist = hashed[i].1.hammingDistance(to: hashed[j].1)
                if dist <= perceptualThreshold {
                    union(i, j)
                }
            }
        }

        var groups: [Int: [FileNode]] = [:]
        for i in 0..<hashed.count {
            groups[find(i), default: []].append(hashed[i].0)
        }

        return groups.values.filter { $0.count > 1 }.map { files in
            let signature = "phash-\(UUID().uuidString.prefix(8))"
            return DuplicateGroup(signature: signature, files: files)
        }
    }
}
