import SwiftUI

/// Calibration interface for setting joint positions and limits
struct CalibrationView: View {
    @EnvironmentObject var bleManager: BLEManager
    @State private var shoulderAngle: Double = 90
    @State private var elbowAngle: Double = 90
    @State private var gripperAngle: Double = 90

    var body: some View {
        NavigationView {
            Form {
                Section("Connection") {
                    HStack {
                        Text("Status")
                        Spacer()
                        Text(bleManager.isConnected ? "Connected" : "Scanning...")
                            .foregroundColor(bleManager.isConnected ? .green : .orange)
                    }
                }

                Section("Shoulder") {
                    Slider(value: $shoulderAngle, in: 0...180, step: 1) {
                        Text("Angle")
                    }
                    Text("\(Int(shoulderAngle)) degrees")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .onChange(of: shoulderAngle) { _, _ in sendPositions() }

                Section("Elbow") {
                    Slider(value: $elbowAngle, in: 0...180, step: 1) {
                        Text("Angle")
                    }
                    Text("\(Int(elbowAngle)) degrees")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .onChange(of: elbowAngle) { _, _ in sendPositions() }

                Section("Gripper") {
                    Slider(value: $gripperAngle, in: 0...180, step: 1) {
                        Text("Angle")
                    }
                    Text("\(Int(gripperAngle)) degrees")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .onChange(of: gripperAngle) { _, _ in sendPositions() }

                Section {
                    Button("Home Position") {
                        shoulderAngle = 90
                        elbowAngle = 90
                        gripperAngle = 90
                        bleManager.send(.home)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Calibration")
        }
    }

    private func sendPositions() {
        let command = GraspCommand.moveAll(
            shoulder: UInt8(shoulderAngle),
            elbow: UInt8(elbowAngle),
            gripper: UInt8(gripperAngle),
            speed: 60
        )
        bleManager.sendWithoutResponse(command)
    }
}
