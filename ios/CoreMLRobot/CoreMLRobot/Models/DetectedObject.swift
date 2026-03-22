import Foundation
import CoreGraphics

/// Represents an object detected by the vision pipeline
struct DetectedObject: Identifiable {
    let id = UUID()
    let label: String
    let confidence: Float
    let boundingBox: CGRect // Normalized coordinates (0-1)
    let timestamp: Date

    /// Estimated distance based on bounding box size (meters)
    var estimatedDistance: Float {
        // Rough heuristic: larger bounding box = closer object
        let area = Float(boundingBox.width * boundingBox.height)
        guard area > 0 else { return 1.0 }
        return 0.1 / area // Calibrate based on known object sizes
    }

    /// Center point in normalized coordinates
    var center: CGPoint {
        CGPoint(x: boundingBox.midX, y: boundingBox.midY)
    }
}
