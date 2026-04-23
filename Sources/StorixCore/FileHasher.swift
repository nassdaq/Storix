import Foundation
import CryptoKit

public struct FileHash: Hashable, Sendable {
    public let hex: String
    public init(hex: String) { self.hex = hex }
}

public struct FileHasher: Sendable {
    public init() {}

    /// Streaming SHA-256 hash. Reads in 1 MB chunks so multi-GB files don't blow memory.
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

    /// Cheap identity hash based on the first + last N bytes plus size.
    /// Used to prune obvious non-dupes before the full streaming hash.
    public func quickHash(url: URL, sampleBytes: Int = 4096) throws -> FileHash {
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }

        let attrs = try FileManager.default.attributesOfItem(atPath: url.path)
        let size = (attrs[.size] as? NSNumber)?.int64Value ?? 0

        var hasher = SHA256()
        withUnsafeBytes(of: size.littleEndian) { hasher.update(bufferPointer: $0) }

        if let head = try handle.read(upToCount: sampleBytes) {
            hasher.update(data: head)
        }
        if size > Int64(sampleBytes * 2) {
            try handle.seek(toOffset: UInt64(size - Int64(sampleBytes)))
            if let tail = try handle.read(upToCount: sampleBytes) {
                hasher.update(data: tail)
            }
        }

        let digest = hasher.finalize()
        return FileHash(hex: digest.map { String(format: "%02x", $0) }.joined())
    }
}
