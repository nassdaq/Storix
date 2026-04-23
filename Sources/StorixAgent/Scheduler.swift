import Foundation

public struct ScheduleConfig: Codable, Sendable {
    public var enabled: Bool
    public var intervalSeconds: Int

    public static let weekly = ScheduleConfig(enabled: true, intervalSeconds: 7 * 24 * 60 * 60)

    public init(enabled: Bool, intervalSeconds: Int) {
        self.enabled = enabled
        self.intervalSeconds = intervalSeconds
    }
}

public enum SchedulerError: Error, Sendable {
    case plistWriteFailed(String)
    case launchctlFailed(code: Int32, stderr: String)
}

public final class Scheduler: @unchecked Sendable {
    public static let launchAgentLabel = "galacha.industries.Storix.weekly"

    public init() {}

    /// Write the LaunchAgent plist, then register it with launchd so it runs in the
    /// current user's GUI session.
    public func install(config: ScheduleConfig, executable: URL) throws {
        let plistURL = Self.plistURL()
        try FileManager.default.createDirectory(
            at: plistURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        let logDir = URL(fileURLWithPath: "\(NSHomeDirectory())/Library/Logs/Storix")
        try? FileManager.default.createDirectory(at: logDir, withIntermediateDirectories: true)

        let plist: [String: Any] = [
            "Label": Self.launchAgentLabel,
            "ProgramArguments": [executable.path, "--scheduled-scan"],
            "StartInterval": config.intervalSeconds,
            "RunAtLoad": false,
            "StandardOutPath": logDir.appendingPathComponent("scheduler.log").path,
            "StandardErrorPath": logDir.appendingPathComponent("scheduler.err.log").path,
            "ProcessType": "Background"
        ]

        do {
            let data = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
            try data.write(to: plistURL, options: .atomic)
        } catch {
            throw SchedulerError.plistWriteFailed(error.localizedDescription)
        }

        if config.enabled {
            try bootstrap(plistURL: plistURL)
        }
    }

    public func uninstall() throws {
        let plistURL = Self.plistURL()
        if FileManager.default.fileExists(atPath: plistURL.path) {
            try? bootout()
            try FileManager.default.removeItem(at: plistURL)
        }
    }

    public func isInstalled() -> Bool {
        FileManager.default.fileExists(atPath: Self.plistURL().path)
    }

    public static func plistURL() -> URL {
        URL(fileURLWithPath: "\(NSHomeDirectory())/Library/LaunchAgents/\(launchAgentLabel).plist")
    }

    private func bootstrap(plistURL: URL) throws {
        let uid = getuid()
        let target = "gui/\(uid)"
        try runLaunchctl(arguments: ["bootstrap", target, plistURL.path])
    }

    private func bootout() throws {
        let uid = getuid()
        let target = "gui/\(uid)/\(Self.launchAgentLabel)"
        try runLaunchctl(arguments: ["bootout", target])
    }

    private func runLaunchctl(arguments: [String]) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        process.arguments = arguments
        let stderr = Pipe()
        process.standardError = stderr
        process.standardOutput = Pipe()

        try process.run()
        process.waitUntilExit()

        if process.terminationStatus != 0 {
            let err = String(
                data: stderr.fileHandleForReading.readDataToEndOfFile(),
                encoding: .utf8
            ) ?? ""
            throw SchedulerError.launchctlFailed(code: process.terminationStatus, stderr: err)
        }
    }
}
