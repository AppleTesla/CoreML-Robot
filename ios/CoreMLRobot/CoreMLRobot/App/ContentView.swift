import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            MainControlView()
                .tabItem {
                    Label("Control", systemImage: "gamecontroller")
                }

            CalibrationView()
                .tabItem {
                    Label("Calibrate", systemImage: "slider.horizontal.3")
                }

            DiagnosticsView()
                .tabItem {
                    Label("Diagnostics", systemImage: "waveform.path.ecg")
                }
        }
    }
}
