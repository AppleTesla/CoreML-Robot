import AVFoundation
import UIKit
import Observation

/// Manages AVCaptureSession for real-time camera input, delivering frames via AsyncStream
@MainActor
@Observable
final class CameraManager: NSObject {
    var isRunning = false
    var error: String?

    let captureSession = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let processingQueue = DispatchQueue(label: "com.coremlrobot.camera", qos: .userInteractive)

    // MARK: - Frame stream keyed by subscriber UUID
    private var frameContinuations: [UUID: AsyncStream<CMSampleBuffer>.Continuation] = [:]

    func configure() {
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .hd1920x1080

        // Camera input
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: camera) else {
            error = "Failed to access camera"
            captureSession.commitConfiguration()
            return
        }

        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        }

        // Video output
        videoOutput.setSampleBufferDelegate(self, queue: processingQueue)
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]

        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }

        // Set orientation
        if let connection = videoOutput.connection(with: .video) {
            connection.videoRotationAngle = 90
        }

        captureSession.commitConfiguration()
    }

    func start() {
        guard !captureSession.isRunning else { return }
        processingQueue.async { [weak self] in
            self?.captureSession.startRunning()
            Task { @MainActor [weak self] in
                self?.isRunning = true
            }
        }
    }

    func stop() {
        guard captureSession.isRunning else { return }
        processingQueue.async { [weak self] in
            self?.captureSession.stopRunning()
            Task { @MainActor [weak self] in
                self?.isRunning = false
            }
        }
    }

    /// Subscribe to camera frames. Returns a stream and its subscriber ID (for unsubscription).
    func frameStream() -> (id: UUID, stream: AsyncStream<CMSampleBuffer>) {
        let id = UUID()
        let stream = AsyncStream<CMSampleBuffer> { continuation in
            frameContinuations[id] = continuation
            continuation.onTermination = { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.frameContinuations.removeValue(forKey: id)
                }
            }
        }
        return (id, stream)
    }

    /// Remove a frame subscriber
    func removeSubscriber(_ id: UUID) {
        frameContinuations.removeValue(forKey: id)?.finish()
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    nonisolated func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        // Yield to all subscribers from the processing queue
        // frameContinuations is MainActor-isolated, but yield is safe to call from any context
        // We capture the continuations snapshot on MainActor then yield
        Task { @MainActor [weak self] in
            guard let self else { return }
            for continuation in self.frameContinuations.values {
                continuation.yield(sampleBuffer)
            }
        }
    }
}
