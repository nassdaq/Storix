import Testing
import Foundation
@testable import StorixCore

@Suite("DuplicateFinder (exact)")
struct DuplicateFinderExactTests {
    @Test("groups byte-identical files and leaves unique files alone")
    func groupsIdenticalFiles() async throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("storix-dup-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let payload = Data(repeating: 0xAB, count: 4096)
        let otherPayload = Data(repeating: 0xCD, count: 4096)

        let a = root.appendingPathComponent("a.bin")
        let b = root.appendingPathComponent("b.bin")
        let c = root.appendingPathComponent("c.bin")
        let d = root.appendingPathComponent("d.bin")

        try payload.write(to: a)
        try payload.write(to: b)      // dup of a
        try payload.write(to: c)      // dup of a
        try otherPayload.write(to: d) // unique

        let nodes: [FileNode] = [a, b, c, d].map {
            FileNode(
                url: $0,
                name: $0.lastPathComponent,
                size: 4096,
                modified: .now,
                isDirectory: false
            )
        }

        let finder = DuplicateFinder(minFileSize: 1)
        let groups = await finder.findExactDuplicates(in: nodes)

        #expect(groups.count == 1)
        #expect(groups.first?.files.count == 3)
    }

    @Test("ignores files below minFileSize")
    func skipsTinyFiles() async throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("storix-tiny-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let a = root.appendingPathComponent("a.bin")
        let b = root.appendingPathComponent("b.bin")
        try Data(count: 10).write(to: a)
        try Data(count: 10).write(to: b)

        let nodes = [a, b].map {
            FileNode(url: $0, name: $0.lastPathComponent, size: 10, modified: .now, isDirectory: false)
        }

        let finder = DuplicateFinder(minFileSize: 1024)
        let groups = await finder.findExactDuplicates(in: nodes)
        #expect(groups.isEmpty)
    }
}

@Suite("DuplicateGroup math")
struct DuplicateGroupMathTests {
    @Test("recoverableBytes equals total minus keeper")
    func recoverableBytesCorrect() {
        let older = Date().addingTimeInterval(-86_400)
        let files = [
            FileNode(url: URL(fileURLWithPath: "/tmp/a"), name: "a", size: 100, modified: older, isDirectory: false),
            FileNode(url: URL(fileURLWithPath: "/tmp/b"), name: "b", size: 100, modified: .now,   isDirectory: false),
            FileNode(url: URL(fileURLWithPath: "/tmp/c"), name: "c", size: 100, modified: older, isDirectory: false)
        ]
        let group = DuplicateGroup(signature: "sig", files: files)
        // Keeper = newest modified (b), recoverable = a + c.
        #expect(group.recoverableBytes == 200)
        #expect(group.preferredKeeper()?.name == "b")
        #expect(group.deletable().map(\.name).sorted() == ["a", "c"])
    }
}

@Suite("PerceptualHash")
struct PerceptualHashTests {
    @Test("hamming distance zero for identical bits")
    func zeroDistance() {
        let h = PerceptualHash(bits: 0xDEAD_BEEF)
        #expect(h.hammingDistance(to: h) == 0)
    }

    @Test("hamming distance counts differing bits")
    func differingBits() {
        let a = PerceptualHash(bits: 0b0000_0000)
        let b = PerceptualHash(bits: 0b0001_1111)
        #expect(a.hammingDistance(to: b) == 5)
    }
}
