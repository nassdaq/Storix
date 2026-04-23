import Testing
import Foundation
@testable import StorixAI
import StorixCore

@Suite("NaturalLanguageQuery.stripCodeFences")
struct NLStripTests {
    @Test("strips ```json fenced block")
    func stripsJSONFence() {
        let raw = """
        ```json
        {"minSize": 1000}
        ```
        """
        let out = NaturalLanguageQuery.stripCodeFences(raw)
        #expect(out == #"{"minSize": 1000}"#)
    }

    @Test("strips plain ``` fenced block")
    func stripsPlainFence() {
        let raw = """
        ```
        {"a": 1}
        ```
        """
        let out = NaturalLanguageQuery.stripCodeFences(raw)
        #expect(out == #"{"a": 1}"#)
    }

    @Test("carves {...} out of surrounding prose when no fence")
    func carvesFromProse() {
        let raw = "Sure! Here is the JSON you asked for: {\"minSize\": 500} Let me know if you need more."
        let out = NaturalLanguageQuery.stripCodeFences(raw)
        #expect(out == #"{"minSize": 500}"#)
    }

    @Test("leaves pure JSON alone")
    func leavesJSONAlone() {
        let raw = #"{"extensions": ["mp4"]}"#
        let out = NaturalLanguageQuery.stripCodeFences(raw)
        #expect(out == raw)
    }
}

@Suite("QueryPredicate matching")
struct QueryPredicateMatchingTests {
    @Test("minSize + extensions filter")
    func matchesSizeAndExtension() {
        let node = makeNode(name: "big.mp4", size: 2_000_000_000)
        let predicate = QueryPredicate(
            minSize: 1_000_000_000,
            extensions: ["mp4"]
        )
        #expect(predicate.matches(node))
    }

    @Test("rejects wrong extension")
    func rejectsWrongExtension() {
        let node = makeNode(name: "doc.pdf", size: 10_000_000)
        let predicate = QueryPredicate(extensions: ["mp4"])
        #expect(!predicate.matches(node))
    }

    private func makeNode(name: String, size: Int64) -> FileNode {
        FileNode(
            url: URL(fileURLWithPath: "/tmp/\(name)"),
            name: name,
            size: size,
            modified: .now,
            isDirectory: false
        )
    }
}
