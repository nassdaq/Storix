import Foundation

public struct ClaudeInstallation: Sendable {
    public let executableURL: URL
    public let version: String?
}

public final class ClaudeDetector: @unchecked Sendable {
    public init() {}

    /// Well-known install locations checked when `$PATH` and `$CLAUDE_BIN` don't resolve.
    /// Priority order mirrors the most common Claude Code install flows.
    public static let searchPaths: [String] = [
        "/opt/homebrew/bin/claude",
        "/usr/local/bin/claude",
        "\(NSHomeDirectory())/.claude/local/claude",
        "\(NSHomeDirectory())/.npm-global/bin/claude",
        "\(NSHomeDirectory())/.volta/bin/claude",
        "\(NSHomeDirectory())/.bun/bin/claude"
    ]

    public func isAvailable() -> Bool {
        locate() != nil
    }

    /// Resolve the first runnable `claude` executable.
    ///
    /// Resolution order:
    /// 1. `$CLAUDE_BIN` (explicit override)
    /// 2. `$PATH` lookup
    /// 3. Well-known paths above
    public func locate() -> ClaudeInstallation? {
        let fm = FileManager.default

        if let override = ProcessInfo.processInfo.environment["CLAUDE_BIN"],
           !override.isEmpty,
           fm.isExecutableFile(atPath: override) {
            let url = URL(fileURLWithPath: override)
            return ClaudeInstallation(executableURL: url, version: probeVersion(at: url))
        }

        if let onPath = resolveInPATH(binary: "claude") {
            return ClaudeInstallation(executableURL: onPath, version: probeVersion(at: onPath))
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
            let raw = String(data: data, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

            // Output looks like "1.0.12 (Claude Code)" — extract the first semver-ish token.
            if let match = raw.range(of: #"\d+\.\d+\.\d+"#, options: .regularExpression) {
                return String(raw[match])
            }
            return raw.isEmpty ? nil : raw
        } catch {
            return nil
        }
    }
}
