import SwiftUI

@main
struct MUFFApp: App {
    @State private var appState = AppState()

    init() {
        // Purge old history and cache on launch
        try? AppDatabase.shared.purgeOldHistory()
        try? AppDatabase.shared.purgeOldCache()

        // Preload ad blocker so WKWebView subsystem + rule compilation
        // finish before the user opens the first article
        if AppSettings.shared.adBlockEnabled {
            _ = AdBlocker.shared
        }
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if appState.hasCompletedOnboarding {
                    ContentView()
                } else {
                    WelcomeView {
                        appState.completeOnboarding()
                    }
                }
            }
            .environment(appState)
            .preferredColorScheme(AppSettings.shared.darkModeEnabled ? .dark : .light)
        }
    }
}
