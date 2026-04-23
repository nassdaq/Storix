import Testing
import Foundation
@testable import StorixCore

@Suite("JunkCategory")
struct JunkCategoryTests {
    @Test("every case has a display name")
    func allCategoriesHaveDisplayName() {
        for category in JunkCategory.allCases {
            #expect(!category.displayName.isEmpty)
        }
    }

    @Test("risk levels")
    func riskLevels() {
        #expect(JunkCategory.devCache.riskLevel == .low)
        #expect(JunkCategory.duplicate.riskLevel == .medium)
        #expect(JunkCategory.largeOld.riskLevel == .high)
    }
}

@Suite("FileNode")
struct FileNodeTests {
    @Test("ageInDays computes from modified date")
    func ageInDays() {
        let thirtyDaysAgo = Date().addingTimeInterval(-30 * 24 * 60 * 60)
        let node = FileNode(
            url: URL(fileURLWithPath: "/tmp/x"),
            name: "x",
            size: 100,
            modified: thirtyDaysAgo,
            isDirectory: false
        )
        #expect(node.ageInDays == 30)
    }
}
