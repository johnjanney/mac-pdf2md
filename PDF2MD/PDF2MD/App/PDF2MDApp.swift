import SwiftUI

/// Application entry point.
///
/// PDF2MD is a single-window macOS utility that converts PDF files to
/// Markdown. See PROJECTBRIEF.md for scope and architecture.
@main
struct PDF2MDApp: App {
    @StateObject private var settings = SettingsStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settings)
        }
        .windowResizability(.contentMinSize)
        .commands {
            // Replace the default "New Window" with nothing meaningful for a
            // single-window utility; keep the standard app menu otherwise.
            CommandGroup(replacing: .newItem) {}
        }

        Settings {
            SettingsView()
                .environmentObject(settings)
        }
    }
}
