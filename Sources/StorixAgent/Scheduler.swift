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

public final class Scheduler: @unchecked Sendable {
    public static let launchAgentLabel = "galacha.industries.Storix.weekly"

    public init() {}

    /// Write a LaunchAgent plist into ~/Library/LaunchAgents and `launchctl load` it.
    public func install(config: ScheduleConfig, executable: URL) throws {
        let plistURL = Self.plistURL()
        try FileManager.default.createDirectory(
            at: plistURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        let plist: [String: Any] = [
            "Label": Self.launchAgentLabel,
            "ProgramArguments": [executable.path, "--scheduled-scan"],
            "StartInterval": config.intervalSeconds,
            "RunAtLoad": false,
            "StandardOutPath": "\(NSHomeDirectory())/Library/Logs/Storix/scheduler.log",
            "StandardErrorPath": "\(NSHomeDirectory())/Library/Logs/Storix/scheduler.err.log"
        ]

        let data = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
        try data.write(to: plistURL, options: .atomic)

        // MARK: TODO — `launchctl bootstrap gui/$UID <plist>` via Process
    }

    public func uninstall() throws {
        // MARK: TODO — `launchctl bootout gui/$UID <plist>` then remove plist file
        let plistURL = Self.plistURL()
        if FileManager.default.fileExists(atPath: plistURL.path) {
            try FileManager.default.removeItem(at: plistURL)
        }
    }

    public static func plistURL() -> URL {
        URL(fileURLWithPath: "\(NSHomeDirectory())/Library/LaunchAgents/\(launchAgentLabel).plist")
    }

    public func isInstalled() -> Bool {
        FileManager.default.fileExists(atPath: Self.plistURL().path)
    }
}
