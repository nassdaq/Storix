import SwiftUI
import StorixAI
import StorixAgent
import StorixCleaner

public struct SettingsView: View {
    @EnvironmentObject private var appState: AppState

    @AppStorage("menuBarEnabled") private var menuBarEnabled = true
    @AppStorage("weeklyScansEnabled") private var weeklyScansEnabled = false

    @State private var claudeVersion: String = "—"
    @State private var claudePath: String = "—"
    @State private var schedulerError: String?
    @State private var recentCleanups: [CleanupManifest] = []

    public init() {}

    public var body: some View {
        Form {
            Section("Automation") {
                Toggle("Menu bar indicator", isOn: $menuBarEnabled)
                    .help("Show free-space and quick-scan in the system menu bar.")

                Toggle("Weekly background scan", isOn: $weeklyScansEnabled)
                    .onChange(of: weeklyScansEnabled) { _, enabled in
                        applyScheduler(enabled: enabled)
                    }
                if let err = schedulerError {
                    Text(err)
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.danger)
                }
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
                    Text("Fallback")
                    Spacer()
                    Text("Heuristics only when Claude CLI not found")
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.textTertiary)
                }
            }

            Section("Cleanup history") {
                if recentCleanups.isEmpty {
                    Text("No cleanups yet.")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textTertiary)
                } else {
                    ForEach(recentCleanups.prefix(5)) { manifest in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(manifest.timestamp.formatted(date: .abbreviated, time: .shortened))
                                    .font(.system(size: 11))
                                    .foregroundStyle(Theme.textPrimary)
                                Text("\(manifest.entries.count) items")
                                    .font(.system(size: 10))
                                    .foregroundStyle(Theme.textTertiary)
                            }
                            Spacer()
                            Text(ByteCountFormatter.string(fromByteCount: manifest.totalBytes, countStyle: .file))
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(Theme.textSecondary)
                            Button("Undo") {
                                undo(manifest: manifest)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                }
            }

            Section("Safety") {
                Text("All deletions are sent to Trash via NSWorkspace. A JSON manifest is written for every cleanup so any batch can be restored until the Trash is emptied.")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textTertiary)
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .background(Theme.background)
        .frame(width: 500, height: 560)
        .onAppear(perform: refresh)
    }

    private func refresh() {
        if let install = appState.claudeDetector.locate() {
            claudePath = install.executableURL.path
            claudeVersion = install.version ?? "unknown"
        } else {
            claudePath = "not found"
            claudeVersion = "—"
        }

        recentCleanups = (try? appState.cleaner.manifestStore.listAll()) ?? []
    }

    private func applyScheduler(enabled: Bool) {
        schedulerError = nil
        do {
            if enabled {
                try appState.scheduler.install(
                    config: .weekly,
                    executable: URL(fileURLWithPath: CommandLine.arguments[0])
                )
            } else {
                try appState.scheduler.uninstall()
            }
        } catch let SchedulerError.launchctlFailed(_, stderr) {
            schedulerError = "launchctl: \(stderr)"
            weeklyScansEnabled = false
        } catch {
            schedulerError = error.localizedDescription
            weeklyScansEnabled = false
        }
    }

    private func undo(manifest: CleanupManifest) {
        _ = try? appState.undoEngine.undo(manifest: manifest)
        refresh()
    }
}
