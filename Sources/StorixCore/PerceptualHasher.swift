import Foundation

public struct PerceptualHash: Hashable, Sendable {
    public let bits: UInt64
    public init(bits: UInt64) { self.bits = bits }

    public func hammingDistance(to other: PerceptualHash) -> Int {
        (bits ^ other.bits).nonzeroBitCount
    }
}

public struct PerceptualHasher: Sendable {
    public init() {}

    /// Compute a 64-bit dHash for an image file.
    /// Returns nil for non-image files or failures.
    public func imageHash(url: URL) -> PerceptualHash? {
        // MARK: TODO — CGImageSource → 9x8 grayscale → adjacent-pixel compare → 64 bits
        _ = url
        return nil
    }

    /// Extract a keyframe from a video and hash it.
    public func videoHash(url: URL) async -> PerceptualHash? {
        // MARK: TODO — AVAssetImageGenerator keyframe → imageHash
        _ = url
        return nil
    }
}
