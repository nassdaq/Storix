import Foundation

public struct ClaudeInstallation: Sendable {
    public let executableURL: URL
    public let version: String?
}

public final class ClaudeDetector: @unchecked Sendable {
    public init() {}

    /// Locations we search for the `claude` CLI, in priority order.
    /// Covers the three common install flows: npm global, Homebrew, manual.
    public static let searchPaths: [String] = [
        "/opt/homebrew/bin/claude",
        "/usr/local/bin/claude",
        "\(NSHomeDirectory())/.claude/local/claude",
        "\(NSHomeDirectory())/.npm-global/bin/claude",
        "\(NSHomeDirectory())/.volta/bin/claude",
        "\(NSHomeDirectory())/.nvm/versions/node/current/bin/claude"
    ]

    /// Returns true if `claude` CLI is runnable anywhere on the machine.
    public func isAvailable() -> Bool {
        locate() != nil
    }

    /// Find the first runnable `claude` binary. Checks `$PATH` first, then well-known locations.
    public func locate() -> ClaudeInstallation? {
        let fm = FileManager.default

        if let onPath = resolveInPATH(binary: "claude") {
            let version = probeVersion(at: onPath)
            return ClaudeInstallation(executableURL: onPath, version: version)
        }

        for candidate in Self.searchPaths where fm.isExecutableFile(atPath: candidate) {
            let url = URL(fileURLWithPath: candidate)
            return ClaudeInstallation(executableURL: url, version: probeVersion(at: url))
        }

        return nil
    }

    private func resolveInPATH(binary: String) -> URL? {
        guard let pathEnv = ProcessInfo.processInfo.environment["PATH"] else { return nil }
        let fm = FileManager.default
        for dir in pathEnv.split(separator: ":") {
            let candidate = URL(fileURLWithPath: String(dir)).appendingPathComponent(binary)
            if fm.isExecutableFile(atPath: candidate.path) {
                return candidate
            }
        }
        return nil
    }

    private func probeVersion(at url: URL) -> String? {
        let process = Process()
        process.executableURL = url
        process.arguments = ["--version"]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            return nil
        }
    }
}
