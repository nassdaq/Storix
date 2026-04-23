import Foundation
import CryptoKit

public struct FileHash: Hashable, Sendable {
    public let hex: String
    public init(hex: String) { self.hex = hex }
}

public enum HashAlgorithm: Sendable {
    case sha256
    // MARK: TODO — add .blake3 via swift-blake3 dependency for ~3x speedup
}

public struct FileHasher: Sendable {
    public let algorithm: HashAlgorithm

    public init(algorithm: HashAlgorithm = .sha256) {
        self.algorithm = algorithm
    }

    /// Streaming hash of the file at `url`. Reads in 1 MB chunks to avoid loading large files.
    public func hash(url: URL) throws -> FileHash {
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }

        var hasher = SHA256()
        let chunkSize = 1024 * 1024
        while true {
            let chunk = try handle.read(upToCount: chunkSize) ?? Data()
            if chunk.isEmpty { break }
            hasher.update(data: chunk)
        }
        let digest = hasher.finalize()
        let hex = digest.map { String(format: "%02x", $0) }.joined()
        return FileHash(hex: hex)
    }
}
