import Foundation
import SwiftUI
import StorixCore
import StorixCleaner
import StorixAI
import StorixAgent

@MainActor
public final class AppState: ObservableObject {
    @Published public var scanResult: ScanResult?
    @Published public var isScanning: Bool = false
    @Published public var scanProgress: ScanProgress = .idle
    @Published public var claudeAvailable: Bool = false
    @Published public var selectedCategory: JunkCategory?
    @Published public var lastCleanup: CleanupManifest?

    public let scanner: StorageScanner
    public let cleaner: Cleaner
    public let undoEngine: UndoEngine
    public let claudeDetector: ClaudeDetector
    public let scheduler: Scheduler

    public init() {
        let store = ManifestStore()
        self.scanner = StorageScanner()
        self.cleaner = Cleaner(manifestStore: store)
        self.undoEngine = UndoEngine(manifestStore: store)
        self.claudeDetector = ClaudeDetector()
        self.scheduler = Scheduler()
        self.claudeAvailable = claudeDetector.isAvailable()
    }

    public func runScan(options: ScanOptions = ScanOptions()) async {
        isScanning = true
        scanProgress = .walking(filesSeen: 0, bytesSeen: 0, currentPath: "")

        do {
            let result = try await scanner.scan(options: options) { [weak self] progress in
                Task { @MainActor in
                    self?.scanProgress = progress
                }
            }
            self.scanResult = result
            self.scanProgress = .done
        } catch {
            self.scanProgress = .idle
        }

        isScanning = false
    }

    public func cleanup(category: JunkCategory) async {
        guard let findings = scanResult?.findings(in: category), !findings.isEmpty else { return }
        let plans = findings.map { CleanupPlan(items: $0.items, category: category) }
        do {
            let manifest = try await cleaner.execute(plans)
            lastCleanup = manifest
        } catch {
            // surfaced via UI later
        }
    }

    public func cleanup(plans: [CleanupPlan]) async {
        do {
            lastCleanup = try await cleaner.execute(plans)
        } catch {
            // surfaced via UI later
        }
    }

    public func undoLast() {
        _ = try? undoEngine.undoLast()
    }
}
