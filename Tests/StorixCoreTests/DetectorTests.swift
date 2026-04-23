import Testing
import Foundation
@testable import StorixCore

/// Build a small synthetic FileNode tree so we can test detectors without hitting the disk.
private func makeNode(
    name: String,
    size: Int64 = 0,
    modified: Date = .now,
    isDirectory: Bool = false,
    children: [FileNode] = [],
    parentURL: URL = URL(fileURLWithPath: "/tmp")
) -> FileNode {
    let url = parentURL.appendingPathComponent(name, isDirectory: isDirectory)
    return FileNode(
        url: url,
        name: name,
        size: size,
        modified: modified,
        isDirectory: isDirectory,
        children: children
    )
}

@Suite("DevCacheDetector")
struct DevCacheDetectorTests {
    @Test("reports node_modules directory as a single finding")
    func reportsNodeModules() async {
        let tree = makeNode(
            name: "project",
            size: 110_000_000,
            isDirectory: true,
            children: [
                makeNode(name: "src", isDirectory: true),
                makeNode(name: "node_modules", size: 100_000_000, isDirectory: true, children: [
                    makeNode(name: "lodash", size: 50_000_000, isDirectory: true),
                    makeNode(name: "react", size: 50_000_000, isDirectory: true)
                ])
            ]
        )

        let findings = await DevCacheDetector().detect(in: tree)
        #expect(findings.count == 1)
        #expect(findings.first?.items.count == 1)
        #expect(findings.first?.items.first?.name == "node_modules")
        #expect(findings.first?.items.first?.size == 100_000_000)
    }

    @Test("ignores matches below minBytes")
    func respectsMinBytes() async {
        let tree = makeNode(
            name: "project",
            isDirectory: true,
            children: [
                makeNode(name: "node_modules", size: 500, isDirectory: true)
            ]
        )
        let findings = await DevCacheDetector(minBytes: 1_000_000).detect(in: tree)
        #expect(findings.isEmpty)
    }

    @Test("does not descend into a matched node_modules")
    func doesNotDescend() async {
        // Nested node_modules inside node_modules must not produce duplicate findings.
        let tree = makeNode(
            name: "project",
            isDirectory: true,
            children: [
                makeNode(name: "node_modules", size: 200_000_000, isDirectory: true, children: [
                    makeNode(name: "dep", size: 100_000_000, isDirectory: true, children: [
                        makeNode(name: "node_modules", size: 50_000_000, isDirectory: true)
                    ])
                ])
            ]
        )
        let findings = await DevCacheDetector().detect(in: tree)
        #expect(findings.first?.items.count == 1)
    }
}

@Suite("LargeOldDetector")
struct LargeOldDetectorTests {
    @Test("reports files that are both large and old")
    func reportsLargeOld() async {
        let oneYearAgo = Date().addingTimeInterval(-365 * 86_400)
        let recent = Date().addingTimeInterval(-7 * 86_400)
        let bigBytes: Int64 = 600 * 1024 * 1024
        let smallBytes: Int64 = 10 * 1024 * 1024

        let tree = makeNode(
            name: "home",
            isDirectory: true,
            children: [
                makeNode(name: "old-video.mov",      size: bigBytes,   modified: oneYearAgo),
                makeNode(name: "recent-big.mov",     size: bigBytes,   modified: recent),
                makeNode(name: "old-small.txt",      size: smallBytes, modified: oneYearAgo)
            ]
        )

        let findings = await LargeOldDetector().detect(in: tree)
        #expect(findings.count == 1)
        #expect(findings.first?.items.count == 1)
        #expect(findings.first?.items.first?.name == "old-video.mov")
    }
}

@Suite("IncompleteDownloadDetector")
struct IncompleteDownloadDetectorTests {
    @Test("matches .crdownload and .part files")
    func matchesExtensions() async {
        let tree = makeNode(
            name: "Downloads",
            isDirectory: true,
            children: [
                makeNode(name: "movie.mp4",             size: 1000),
                makeNode(name: "movie.mp4.crdownload",  size: 500),
                makeNode(name: "broken.part",           size: 200),
                makeNode(name: "doc.pdf",               size: 100)
            ]
        )
        let findings = await IncompleteDownloadDetector().detect(in: tree)
        #expect(findings.first?.items.count == 2)
    }
}
