import SwiftUI

@main
struct CoreMLRobotApp: App {
    @State private var bleManager = BLEManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(bleManager)
        }
    }
}
