import SwiftUI
import StorixAI
import StorixAgent

public struct SettingsView: View {
    @State private var weeklyScans = true
    @State private var menuBarEnabled = true
    @State private var claudeVersion: String = "—"
    @State private var claudePath: String = "—"

    public init() {}

    public var body: some View {
        Form {
            Section("Automation") {
                Toggle("Menu bar indicator", isOn: $menuBarEnabled)
                Toggle("Weekly background scan", isOn: $weeklyScans)
            }

            Section("AI backend") {
                LabeledContent("Claude CLI") {
                    Text(claudePath)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(Theme.textSecondary)
                        .textSelection(.enabled)
                }
                LabeledContent("Version") {
                    Text(claudeVersion)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(Theme.textSecondary)
                        .textSelection(.enabled)
                }
                HStack {
                    Text("Manual discovery fallback")
                    Spacer()
                    Text("Heuristics only when Claude CLI not found")
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.textTertiary)
                }
            }

            Section("Safety") {
                Text("All deletions go through the Trash. A JSON manifest is written for every cleanup so you can restore any batch as long as the Trash hasn't been emptied.")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textTertiary)
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .background(Theme.background)
        .frame(width: 460, height: 420)
        .onAppear(perform: refreshClaudeStatus)
    }

    private func refreshClaudeStatus() {
        let detector = ClaudeDetector()
        if let install = detector.locate() {
            claudePath = install.executableURL.path
            claudeVersion = install.version ?? "unknown"
        } else {
            claudePath = "not found"
            claudeVersion = "—"
        }
    }
}
