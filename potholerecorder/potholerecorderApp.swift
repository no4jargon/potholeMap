import SwiftUI

@main
struct potholerecorderApp: App {
    @StateObject private var manager = RecordingManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(manager)
        }
    }
}
