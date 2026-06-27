import SwiftUI

/// Application entry point.
///
/// PDF2MD is a single-window macOS utility that converts PDF files to
/// Markdown. See PROJECTBRIEF.md for scope and architecture.
@main
struct PDF2MDApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowResizability(.contentMinSize)
        .commands {
            // Replace the default "New Window" with nothing meaningful for a
            // single-window utility; keep the standard app menu otherwise.
            CommandGroup(replacing: .newItem) {}
        }
    }
}
