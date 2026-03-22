import SwiftUI

/// Primary control interface with camera preview, detection overlay, and pick-and-place controls
struct MainControlView: View {
    @EnvironmentObject var bleManager: BLEManager
    @StateObject private var cameraManager = CameraManager()
    @StateObject private var objectDetector = ObjectDetector()
    @State private var stateMachine: PickPlaceStateMachine?

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Camera preview with detection overlay
                ZStack {
                    CameraPreviewView(session: cameraManager.captureSession)
                        .ignoresSafeArea()

                    GeometryReader { geometry in
                        DetectionOverlayView(
                            detections: objectDetector.detections,
                            viewSize: geometry.size
                        )
                    }

                    // Status overlay
                    VStack {
                        HStack {
                            connectionIndicator
                            Spacer()
                            inferenceLabel
                        }
                        .padding()
                        Spacer()
                    }
                }
                .frame(maxHeight: .infinity)

                // Controls
                controlPanel
            }
            .navigationTitle("CoreML Robot")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                cameraManager.configure()
                cameraManager.delegate = objectDetector
                objectDetector.configure()
                cameraManager.start()
                stateMachine = PickPlaceStateMachine(bleManager: bleManager)
            }
            .onDisappear {
                cameraManager.stop()
            }
        }
    }

    // MARK: - Subviews

    private var connectionIndicator: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(bleManager.isConnected ? Color.green : Color.red)
                .frame(width: 10, height: 10)
            Text(bleManager.isConnected ? "Connected" : "Disconnected")
                .font(.caption)
                .foregroundColor(.white)
        }
        .padding(6)
        .background(Color.black.opacity(0.5))
        .cornerRadius(8)
    }

    private var inferenceLabel: some View {
        Text(String(format: "%.0f ms", objectDetector.inferenceTime * 1000))
            .font(.caption)
            .foregroundColor(.white)
            .padding(6)
            .background(Color.black.opacity(0.5))
            .cornerRadius(8)
    }

    private var controlPanel: some View {
        VStack(spacing: 12) {
            // State machine status
            if let sm = stateMachine {
                Text(sm.statusMessage)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 16) {
                // Pick and place button
                Button(action: {
                    stateMachine?.startPickAndPlace()
                }) {
                    Label("Pick & Place", systemImage: "hand.point.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!bleManager.isConnected)

                // Stop button
                Button(action: {
                    stateMachine?.stop()
                }) {
                    Label("Stop", systemImage: "stop.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.red)

                // Home button
                Button(action: {
                    bleManager.send(.home)
                }) {
                    Label("Home", systemImage: "house")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(!bleManager.isConnected)
            }

            // Manual gripper control
            HStack {
                Button("Open Gripper") {
                    bleManager.send(.openGripper())
                }
                .buttonStyle(.bordered)
                .disabled(!bleManager.isConnected)

                Button("Close Gripper") {
                    bleManager.send(.closeGripper())
                }
                .buttonStyle(.bordered)
                .disabled(!bleManager.isConnected)
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
}
