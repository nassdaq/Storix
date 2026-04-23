import SwiftUI
import StorixAgent
import StorixUI

@main
struct StorixApp: App {
    @StateObject private var appState = AppState()

    init() {
        if CommandLine.arguments.contains(HeadlessRunner.scheduledFlag) {
            // Block the process here — we never want SwiftUI to build a scene in headless
            // mode. The runner calls exit() itself when the scan finishes.
            let runner = HeadlessRunner()
            let semaphore = DispatchSemaphore(value: 0)
            Task.detached {
                await runner.run()
                semaphore.signal()
            }
            semaphore.wait()
            exit(0)
        }
    }

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
