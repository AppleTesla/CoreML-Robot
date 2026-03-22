import Foundation

/// Analytical 2D inverse kinematics solver for a 2-link planar arm (shoulder + elbow)
struct InverseKinematics {
    /// Link lengths in arbitrary units (calibrate to your arm)
    let link1Length: Float // Shoulder to elbow
    let link2Length: Float // Elbow to gripper

    /// Shoulder servo home angle offset (degrees)
    let shoulderOffset: Float
    /// Elbow servo home angle offset (degrees)
    let elbowOffset: Float

    init(link1: Float = 15.0, link2: Float = 15.0,
         shoulderOffset: Float = 90, elbowOffset: Float = 90) {
        self.link1Length = link1
        self.link2Length = link2
        self.shoulderOffset = shoulderOffset
        self.elbowOffset = elbowOffset
    }

    /// Solve IK for a target position in the arm's vertical plane
    /// - Parameters:
    ///   - x: Horizontal distance from shoulder pivot (forward)
    ///   - y: Vertical distance from shoulder pivot (up is positive)
    /// - Returns: (shoulderAngle, elbowAngle) in servo degrees (0-180), or nil if unreachable
    func solve(x: Float, y: Float) -> (shoulder: UInt8, elbow: UInt8)? {
        let distSquared = x * x + y * y
        let dist = sqrt(distSquared)

        // Check reachability
        let maxReach = link1Length + link2Length
        let minReach = abs(link1Length - link2Length)
        guard dist <= maxReach && dist >= minReach else { return nil }

        // Law of cosines for elbow angle
        let cosElbow = (distSquared - link1Length * link1Length - link2Length * link2Length) /
                       (2 * link1Length * link2Length)
        let clampedCosElbow = max(-1, min(1, cosElbow))
        let elbowAngleRad = acos(clampedCosElbow)

        // Shoulder angle
        let atan2Val = atan2(y, x)
        let cosVal = (link1Length * link1Length + distSquared - link2Length * link2Length) /
                     (2 * link1Length * dist)
        let clampedCosVal = max(-1, min(1, cosVal))
        let shoulderAngleRad = atan2Val - acos(clampedCosVal)

        // Convert to degrees and apply offsets
        let shoulderDeg = shoulderAngleRad * 180 / .pi + shoulderOffset
        let elbowDeg = elbowAngleRad * 180 / .pi + elbowOffset

        // Clamp to servo range
        guard shoulderDeg >= 0 && shoulderDeg <= 180 &&
              elbowDeg >= 0 && elbowDeg <= 180 else { return nil }

        return (shoulder: UInt8(shoulderDeg), elbow: UInt8(elbowDeg))
    }

    /// Forward kinematics: compute gripper position from joint angles
    func forward(shoulderDeg: Float, elbowDeg: Float) -> (x: Float, y: Float) {
        let shoulderRad = (shoulderDeg - shoulderOffset) * .pi / 180
        let elbowRad = (elbowDeg - elbowOffset) * .pi / 180

        let x1 = link1Length * cos(shoulderRad)
        let y1 = link1Length * sin(shoulderRad)
        let x2 = x1 + link2Length * cos(shoulderRad + elbowRad)
        let y2 = y1 + link2Length * sin(shoulderRad + elbowRad)

        return (x: x2, y: y2)
    }
}
