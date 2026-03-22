import Foundation

/// Represents the current state of the robot's joints and connection
struct RobotState {
    var shoulderAngle: UInt8 = 90
    var elbowAngle: UInt8 = 90
    var gripperPercent: UInt8 = 0 // 0 = closed, 100 = open
    var batteryPercent: UInt8 = 100
    var errorCode: UInt8 = 0
    var isMoving: Bool = false
    var isConnected: Bool = false
}
