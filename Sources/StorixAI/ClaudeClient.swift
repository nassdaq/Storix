import Foundation

public enum ClaudeClientError: Error, Sendable {
    case notInstalled
    case invocationFailed(String)
    case nonZeroExit(code: Int32, stderr: String)
}

public struct ClaudePrompt: Sendable {
    public let system: String?
    public let user: String

    public init(system: String? = nil, user: String) {
        self.system = system
        self.user = user
    }
}

public final class ClaudeClient: @unchecked Sendable {
    private let detector: ClaudeDetector

    public init(detector: ClaudeDetector = ClaudeDetector()) {
        self.detector = detector
    }

    /// One-shot prompt via `claude -p`. Returns stdout text.
    /// Fails if the CLI is not installed.
    public func run(_ prompt: ClaudePrompt) async throws -> String {
        guard let install = detector.locate() else {
            throw ClaudeClientError.notInstalled
        }

        return try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = install.executableURL

            var args = ["-p", prompt.user]
            if let system = prompt.system {
                args.append(contentsOf: ["--system-prompt", system])
            }
            process.arguments = args

            let stdout = Pipe()
            let stderr = Pipe()
            process.standardOutput = stdout
            process.standardError = stderr

            process.terminationHandler = { proc in
                let outData = stdout.fileHandleForReading.readDataToEndOfFile()
                let errData = stderr.fileHandleForReading.readDataToEndOfFile()
                let out = String(data: outData, encoding: .utf8) ?? ""
                let err = String(data: errData, encoding: .utf8) ?? ""

                if proc.terminationStatus == 0 {
                    continuation.resume(returning: out.trimmingCharacters(in: .whitespacesAndNewlines))
                } else {
                    continuation.resume(throwing: ClaudeClientError.nonZeroExit(code: proc.terminationStatus, stderr: err))
                }
            }

            do {
                try process.run()
            } catch {
                continuation.resume(throwing: ClaudeClientError.invocationFailed(error.localizedDescription))
            }
        }
    }
}
