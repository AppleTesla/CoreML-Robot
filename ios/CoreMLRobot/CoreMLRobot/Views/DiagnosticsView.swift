import SwiftUI

/// Diagnostics view showing robot status, BLE signal, and servo positions
struct DiagnosticsView: View {
    @Environment(BLEManager.self) var bleManager

    var body: some View {
        NavigationView {
            List {
                Section("Connection") {
                    StatusRow(label: "BLE Status",
                              value: bleManager.isConnected ? "Connected" : "Disconnected",
                              color: bleManager.isConnected ? .green : .red)
                    StatusRow(label: "Scanning",
                              value: bleManager.isScanning ? "Yes" : "No",
                              color: bleManager.isScanning ? .orange : .secondary)
                }

                Section("Joint Positions") {
                    StatusRow(label: "Shoulder",
                              value: "\(bleManager.robotState.shoulderAngle) deg")
                    StatusRow(label: "Elbow",
                              value: "\(bleManager.robotState.elbowAngle) deg")
                    StatusRow(label: "Gripper",
                              value: "\(bleManager.robotState.gripperPercent)%")
                }

                Section("System") {
                    StatusRow(label: "Battery",
                              value: "\(bleManager.robotState.batteryPercent)%",
                              color: bleManager.robotState.batteryPercent > 20 ? .green : .red)
                    StatusRow(label: "Moving",
                              value: bleManager.robotState.isMoving ? "Yes" : "No")
                    StatusRow(label: "Error Code",
                              value: bleManager.robotState.errorCode == 0 ? "None" : "0x\(String(format: "%02X", bleManager.robotState.errorCode))",
                              color: bleManager.robotState.errorCode == 0 ? .green : .red)
                }

                Section {
                    Button("Reconnect") {
                        bleManager.disconnect()
                        bleManager.startScanning()
                    }
                    Button("Emergency Stop") {
                        bleManager.send(.stop)
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Diagnostics")
        }
    }
}

struct StatusRow: View {
    let label: String
    let value: String
    var color: Color = .primary

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .foregroundColor(color)
                .fontWeight(.medium)
        }
    }
}
