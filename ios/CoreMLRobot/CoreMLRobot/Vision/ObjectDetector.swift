import Vision
import CoreML
import AVFoundation
import Combine

/// Runs CoreML object detection on camera frames
class ObjectDetector: ObservableObject {
    @Published var detections: [DetectedObject] = []
    @Published var inferenceTime: TimeInterval = 0

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
        // Look for a compiled model in the app bundle
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
            self?.processResults(request.results)
        }
        request?.imageCropAndScaleOption = .scaleFill
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
            let elapsed = CACurrentMediaTime() - startTime
            DispatchQueue.main.async {
                self.inferenceTime = elapsed
            }
        } catch {
            print("ObjectDetector error: \(error)")
        }
        isProcessing = false
    }

    private func processResults(_ results: [Any]?) {
        guard let observations = results as? [VNRecognizedObjectObservation] else { return }

        let detected = observations
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

        DispatchQueue.main.async {
            self.detections = detected
        }
    }
}

// MARK: - CameraManagerDelegate
extension ObjectDetector: CameraManagerDelegate {
    func cameraManager(_ manager: CameraManager, didOutput sampleBuffer: CMSampleBuffer) {
        detect(in: sampleBuffer)
    }
}
