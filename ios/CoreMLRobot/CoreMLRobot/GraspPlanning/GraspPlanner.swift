import Foundation
import CoreGraphics

/// Converts object detections into grasp commands using inverse kinematics
class GraspPlanner {
    let ik = InverseKinematics()

    /// Camera field of view in degrees (approximate for iPhone wide-angle)
    let horizontalFOV: Float = 67.0
    let verticalFOV: Float = 50.0

    /// Workspace bounds (distance from robot base in arm units)
    let minReachDistance: Float = 5.0
    let maxReachDistance: Float = 25.0

    /// Plan a grasp sequence for a detected object
    /// - Parameters:
    ///   - detection: The detected object with bounding box
    ///   - imageSize: Size of the camera image
    /// - Returns: Array of commands to execute in sequence, or empty if object is unreachable
    func planGrasp(for detection: DetectedObject, imageSize: CGSize) -> [GraspCommand] {
        // Convert bounding box center to arm coordinates
        let center = detection.center

        // Map normalized X to horizontal angle offset (not used for 3-DOF arm without base rotation)
        // Map normalized Y to vertical position in the arm's plane
        let targetX = mapToArmX(normalizedY: Float(center.y), distance: detection.estimatedDistance)
        let targetY = mapToArmY(normalizedY: Float(center.y))

        guard let angles = ik.solve(x: targetX, y: targetY) else {
            print("GraspPlanner: Target unreachable at (\(targetX), \(targetY))")
            return []
        }

        // Pre-grasp: position above target with gripper open
        let preGraspY = targetY + 5.0 // 5 units above
        let preGraspAngles = ik.solve(x: targetX, y: preGraspY)

        var commands: [GraspCommand] = []

        // 1. Open gripper
        commands.append(.openGripper())

        // 2. Move to pre-grasp position (above target)
        if let pre = preGraspAngles {
            commands.append(.moveAll(shoulder: pre.shoulder, elbow: pre.elbow, gripper: 180, speed: 80))
        }

        // 3. Move down to grasp position
        commands.append(.moveAll(shoulder: angles.shoulder, elbow: angles.elbow, gripper: 180, speed: 40))

        // 4. Close gripper
        commands.append(.closeGripper(force: 200))

        // 5. Lift object (move back to pre-grasp height)
        if let pre = preGraspAngles {
            commands.append(.moveAll(shoulder: pre.shoulder, elbow: pre.elbow, gripper: 0, speed: 60))
        }

        return commands
    }

    /// Plan a place sequence (put object down at a default location)
    func planPlace() -> [GraspCommand] {
        // Move to a fixed place location and release
        let placeX: Float = 15.0
        let placeY: Float = 5.0

        guard let angles = ik.solve(x: placeX, y: placeY) else { return [] }

        let aboveY: Float = 10.0
        let aboveAngles = ik.solve(x: placeX, y: aboveY)

        var commands: [GraspCommand] = []

        // 1. Move above place location
        if let above = aboveAngles {
            commands.append(.moveAll(shoulder: above.shoulder, elbow: above.elbow, gripper: 0, speed: 80))
        }

        // 2. Lower to place location
        commands.append(.moveAll(shoulder: angles.shoulder, elbow: angles.elbow, gripper: 0, speed: 40))

        // 3. Open gripper to release
        commands.append(.openGripper())

        // 4. Retreat upward
        if let above = aboveAngles {
            commands.append(.moveAll(shoulder: above.shoulder, elbow: above.elbow, gripper: 180, speed: 60))
        }

        // 5. Return home
        commands.append(.home)

        return commands
    }

    // MARK: - Coordinate Mapping

    /// Map normalized camera Y to arm X (forward distance)
    private func mapToArmX(normalizedY: Float, distance: Float) -> Float {
        // Objects lower in frame are closer; scale by estimated distance
        let scaled = distance * 20.0 // Scale factor (calibrate to your setup)
        return max(minReachDistance, min(maxReachDistance, scaled))
    }

    /// Map normalized camera Y to arm Y (height)
    private func mapToArmY(normalizedY: Float) -> Float {
        // Map camera Y (0=bottom, 1=top) to arm height
        // Objects at bottom of frame are at table level (low Y)
        return (1.0 - normalizedY) * 15.0 // Scale to arm workspace height
    }
}
