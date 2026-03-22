import Vision
import CoreML
import AVFoundation
import Observation

/// Runs CoreML object detection on camera frames
@MainActor
@Observable
final class ObjectDetector {
    var detections: [DetectedObject] = []
    var inferenceTime: TimeInterval = 0

    private var visionModel: VNCoreMLModel?
    private var request: VNCoreMLRequest?
    private var isProcessing = false
    private var frameSkipCount = 0
    private let processEveryNthFrame = 3 // Process every 3rd frame to save battery

    /// Confidence threshold for filtering detections
    var confidenceThreshold: Float = 0.7

    func configure() {
        // Try to load a custom model first, fall back to built-in
        if let model = loadCustomModel() {
            setupVisionRequest(with: model)
        } else {
            print("ObjectDetector: No custom model found. Using placeholder.")
            print("ObjectDetector: Train a model with CreateML and add ObjectDetector.mlmodel to the project.")
        }
    }

    private func loadCustomModel() -> VNCoreMLModel? {
        guard let modelURL = Bundle.main.url(forResource: "ObjectDetector", withExtension: "mlmodelc"),
              let mlModel = try? MLModel(contentsOf: modelURL),
              let visionModel = try? VNCoreMLModel(for: mlModel) else {
            return nil
        }
        return visionModel
    }

    private func setupVisionRequest(with model: VNCoreMLModel) {
        self.visionModel = model
        request = VNCoreMLRequest(model: model) { [weak self] request, error in
            let results = request.results
            Task { @MainActor [weak self] in
                self?.processResults(results)
            }
        }
        request?.imageCropAndScaleOption = .scaleFill
    }

    /// Start consuming frames from a CameraManager's stream
    func startDetecting(from cameraManager: CameraManager) {
        let (subscriberID, stream) = cameraManager.frameStream()
        Task { [weak self] in
            for await sampleBuffer in stream {
                guard let self else { break }
                await self.detect(in: sampleBuffer)
            }
            // Clean up if the task is cancelled
            await cameraManager.removeSubscriber(subscriberID)
        }
    }

    func detect(in sampleBuffer: CMSampleBuffer) {
        // Skip frames to reduce processing load
        frameSkipCount += 1
        guard frameSkipCount >= processEveryNthFrame else { return }
        frameSkipCount = 0

        guard !isProcessing, let request = request else { return }
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        isProcessing = true
        let startTime = CACurrentMediaTime()

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        do {
            try handler.perform([request])
            inferenceTime = CACurrentMediaTime() - startTime
        } catch {
            print("ObjectDetector error: \(error)")
        }
        isProcessing = false
    }

    private func processResults(_ results: [Any]?) {
        guard let observations = results as? [VNRecognizedObjectObservation] else { return }

        detections = observations
            .filter { $0.confidence >= confidenceThreshold }
            .map { observation -> DetectedObject in
                let label = observation.labels.first?.identifier ?? "unknown"
                return DetectedObject(
                    label: label,
                    confidence: observation.confidence,
                    boundingBox: observation.boundingBox,
                    timestamp: Date()
                )
            }
    }
}
