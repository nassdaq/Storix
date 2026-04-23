import Foundation
import UserNotifications
import StorixCore

/// Headless entry point invoked by the scheduled LaunchAgent.
///
/// Runs a scan, writes the result summary as a manifest JSON under
/// `~/Library/Application Support/Storix/scheduled`, and posts a user notification
/// summarizing how much is recoverable. Exits the process when done.
public struct HeadlessRunner: Sendable {
    public static let scheduledFlag = "--scheduled-scan"

    public init() {}

    public func run() async {
        let scanner = StorageScanner()
        let options = ScanOptions(roots: [URL(fileURLWithPath: NSHomeDirectory())])

        guard let result = try? await scanner.scan(options: options, progress: { _ in }) else {
            await postFailure()
            exit(1)
        }

        await writeSummary(result)
        await postSuccess(bytes: result.totalRecoverableBytes, findings: result.findings.count)
        exit(0)
    }

    private func writeSummary(_ result: ScanResult) async {
        let dir = URL(fileURLWithPath: "\(NSHomeDirectory())/Library/Application Support/Storix/scheduled")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        let summary = ScheduledScanSummary(
            id: result.id,
            timestamp: .now,
            root: result.root.path,
            durationSeconds: result.duration,
            totalRecoverableBytes: result.totalRecoverableBytes,
            findingCount: result.findings.count
        )
        let file = dir.appendingPathComponent("\(result.id.uuidString).json")
        if let data = try? JSONEncoder().encode(summary) {
            try? data.write(to: file, options: .atomic)
        }
    }

    private func postSuccess(bytes: Int64, findings: Int) async {
        let size = ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
        await postNotification(
            title: "Storix scan complete",
            body: bytes > 0
                ? "\(size) recoverable across \(findings) findings. Open Storix to review."
                : "Nothing to clean — your disk is tidy."
        )
    }

    private func postFailure() async {
        await postNotification(
            title: "Storix scan failed",
            body: "The scheduled scan could not finish. Check ~/Library/Logs/Storix/scheduler.err.log."
        )
    }

    private func postNotification(title: String, body: String) async {
        let center = UNUserNotificationCenter.current()
        _ = try? await center.requestAuthorization(options: [.alert, .sound])

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        try? await center.add(request)
    }
}

public struct ScheduledScanSummary: Codable, Sendable {
    public let id: UUID
    public let timestamp: Date
    public let root: String
    public let durationSeconds: TimeInterval
    public let totalRecoverableBytes: Int64
    public let findingCount: Int
}
