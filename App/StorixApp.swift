import SwiftUI
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
