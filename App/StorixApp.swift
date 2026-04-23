import SwiftUI
import StorixCore
import StorixCleaner
import StorixAI
import StorixAgent
import StorixUI

@main
struct StorixApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup("Storix") {
            RootView()
                .environmentObject(appState)
                .frame(minWidth: 960, minHeight: 640)
                .background(Theme.background)
                .preferredColorScheme(.dark)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)

        MenuBarExtra("Storix", systemImage: "internaldrive") {
            MenuBarContent()
                .environmentObject(appState)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environmentObject(appState)
                .preferredColorScheme(.dark)
        }
    }
}

@MainActor
final class AppState: ObservableObject {
    @Published var scanResult: ScanResult?
    @Published var isScanning: Bool = false
    @Published var scanProgress: ScanProgress = .idle
    @Published var claudeAvailable: Bool = false

    let scanner: StorageScanner
    let cleaner: Cleaner
    let claudeDetector: ClaudeDetector
    let scheduler: Scheduler

    init() {
        self.scanner = StorageScanner()
        self.cleaner = Cleaner()
        self.claudeDetector = ClaudeDetector()
        self.scheduler = Scheduler()
        self.claudeAvailable = claudeDetector.isAvailable()
    }
}
