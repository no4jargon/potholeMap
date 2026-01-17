import SwiftUI

@main
struct PotholeRecorderApp: App {
    @StateObject private var manager = RecordingManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(manager)
        }
    }
}
