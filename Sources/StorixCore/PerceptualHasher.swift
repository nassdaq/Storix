import Foundation
import CoreGraphics
import ImageIO
import AVFoundation

public struct PerceptualHash: Hashable, Sendable {
    public let bits: UInt64
    public init(bits: UInt64) { self.bits = bits }

    public func hammingDistance(to other: PerceptualHash) -> Int {
        (bits ^ other.bits).nonzeroBitCount
    }
}

public struct PerceptualHasher: Sendable {
    /// Standard image extensions supported by ImageIO.
    public static let imageExtensions: Set<String> = [
        "jpg", "jpeg", "png", "heic", "heif", "gif", "bmp", "tiff", "webp"
    ]

    /// Common video extensions. Non-exhaustive but covers >95% of what users store.
    public static let videoExtensions: Set<String> = [
        "mov", "mp4", "m4v", "avi", "mkv", "webm", "3gp"
    ]

    public init() {}

    /// dHash: resize to 9x8 grayscale, compare each pixel to its right neighbor, 1 bit per comparison.
    /// Returns nil for files ImageIO can't decode.
    public func imageHash(url: URL) -> PerceptualHash? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let cg = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            return nil
        }
        return dHash(cgImage: cg)
    }

    /// Grab a frame from the video near t=1s (avoids pure-black intros) and hash it.
    public func videoHash(url: URL) async -> PerceptualHash? {
        let asset = AVURLAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 128, height: 128)

        let time = CMTime(seconds: 1.0, preferredTimescale: 600)
        do {
            let (cg, _) = try await generator.image(at: time)
            return dHash(cgImage: cg)
        } catch {
            return nil
        }
    }

    /// Core dHash computation. Produces a 64-bit perceptual fingerprint.
    private func dHash(cgImage: CGImage) -> PerceptualHash? {
        let width = 9
        let height = 8
        let bytesPerRow = width
        var pixels = [UInt8](repeating: 0, count: width * height)

        let colorSpace = CGColorSpaceCreateDeviceGray()
        guard let ctx = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else {
            return nil
        }

        ctx.interpolationQuality = .medium
        ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        var bits: UInt64 = 0
        var position = 0
        for row in 0..<height {
            for col in 0..<(width - 1) {
                let left = pixels[row * width + col]
                let right = pixels[row * width + col + 1]
                if left > right {
                    bits |= (UInt64(1) << position)
                }
                position += 1
            }
        }
        return PerceptualHash(bits: bits)
    }
}
