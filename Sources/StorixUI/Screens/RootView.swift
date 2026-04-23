import SwiftUI
import StorixCore

public enum Route: Hashable {
    case scan
    case results
    case confirm
    case afterClean
    case nlQuery
    case settings
}

public struct RootView: View {
    @State private var route: Route = .scan

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                Group {
                    switch route {
                    case .scan:       ScanView(onComplete: { route = .results })
                    case .results:    ResultsView(onClean: { route = .confirm }, onQuery: { route = .nlQuery })
                    case .confirm:    CleanupConfirmView(onDone: { route = .afterClean }, onCancel: { route = .results })
                    case .afterClean: BeforeAfterView(onDone: { route = .scan })
                    case .nlQuery:    NLQueryView(onBack: { route = .results })
                    case .settings:   SettingsView()
                    }
                }
                .transition(.opacity)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        route = .settings
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Theme.textSecondary)
                }
            }
        }
    }
}
