import SwiftUI

/// Renders bounding boxes for detected objects over the camera preview
struct DetectionOverlayView: View {
    let detections: [DetectedObject]
    let viewSize: CGSize

    var body: some View {
        ForEach(detections) { detection in
            let rect = convertBoundingBox(detection.boundingBox)
            ZStack(alignment: .topLeading) {
                Rectangle()
                    .stroke(Color.green, lineWidth: 2)
                    .frame(width: rect.width, height: rect.height)

                Text("\(detection.label) \(Int(detection.confidence * 100))%")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(2)
                    .background(Color.green.opacity(0.7))
                    .cornerRadius(4)
                    .offset(y: -20)
            }
            .position(x: rect.midX, y: rect.midY)
        }
    }

    /// Convert Vision normalized coordinates (origin bottom-left) to SwiftUI coordinates (origin top-left)
    private func convertBoundingBox(_ box: CGRect) -> CGRect {
        let x = box.minX * viewSize.width
        let y = (1 - box.maxY) * viewSize.height // Flip Y axis
        let width = box.width * viewSize.width
        let height = box.height * viewSize.height
        return CGRect(x: x, y: y, width: width, height: height)
    }
}
