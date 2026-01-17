import SwiftUI

@main
struct accelsensordatarecordingApp: App {
    @StateObject private var manager = RecordingManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(manager)
        }
    }
}
