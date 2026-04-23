import Testing
import Foundation
@testable import StorixCore

@Suite("StorageScanner")
struct StorageScannerTests {
    @Test("walks a real temp directory and aggregates sizes")
    func walksRealDirectory() async throws {
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent("storix-test-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tmp) }

        // Layout:
        //   tmp/
        //     a.txt       (100 bytes)
        //     sub/
        //       b.txt     (200 bytes)
        //       node_modules/   ← dev cache pattern
        //         pkg.txt (300 bytes)
        try Data(count: 100).write(to: tmp.appendingPathComponent("a.txt"))

        let sub = tmp.appendingPathComponent("sub", isDirectory: true)
        try FileManager.default.createDirectory(at: sub, withIntermediateDirectories: true)
        try Data(count: 200).write(to: sub.appendingPathComponent("b.txt"))

        let nm = sub.appendingPathComponent("node_modules", isDirectory: true)
        try FileManager.default.createDirectory(at: nm, withIntermediateDirectories: true)
        try Data(count: 300).write(to: nm.appendingPathComponent("pkg.txt"))

        let scanner = StorageScanner()
        let result = try await scanner.scan(
            options: ScanOptions(roots: [tmp]),
            progress: { _ in }
        )

        #expect(result.rootNode.size >= 600)
        #expect(result.rootNode.isDirectory)
        #expect(result.rootNode.allFiles.count == 3)
    }

    @Test("emits progress while walking")
    func emitsProgress() async throws {
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent("storix-prog-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tmp) }

        for i in 0..<5 {
            try Data(count: 50).write(to: tmp.appendingPathComponent("f\(i).bin"))
        }

        actor ProgressSink {
            var events: [ScanProgress] = []
            func add(_ p: ScanProgress) { events.append(p) }
            func snapshot() -> [ScanProgress] { events }
        }
        let sink = ProgressSink()

        _ = try await StorageScanner().scan(
            options: ScanOptions(roots: [tmp], progressThrottleMillis: 0),
            progress: { progress in
                Task { await sink.add(progress) }
            }
        )

        // Give the async progress tasks a tick to land.
        try await Task.sleep(nanoseconds: 100_000_000)
        let events = await sink.snapshot()
        #expect(events.contains { if case .done = $0 { return true } else { return false } })
    }
}
