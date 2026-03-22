import Foundation

/// Motor command types matching the firmware protocol
enum CommandType: UInt8, Sendable {
    case moveJoint   = 0x01
    case moveAll     = 0x02
    case gripper     = 0x03
    case home        = 0x04
    case stop        = 0x05
    case queryStatus = 0x06
}

/// A single command to send to the robot
struct GraspCommand: Sendable {
    let type: CommandType
    let shoulderAngle: UInt8
    let elbowAngle: UInt8
    let gripperPercent: UInt8
    let speed: UInt8

    static func moveAll(shoulder: UInt8, elbow: UInt8, gripper: UInt8, speed: UInt8 = 128) -> GraspCommand {
        GraspCommand(type: .moveAll, shoulderAngle: shoulder, elbowAngle: elbow, gripperPercent: gripper, speed: speed)
    }

    static func openGripper(force: UInt8 = 128) -> GraspCommand {
        GraspCommand(type: .gripper, shoulderAngle: 0, elbowAngle: 0, gripperPercent: 100, speed: force)
    }

    static func closeGripper(force: UInt8 = 128) -> GraspCommand {
        GraspCommand(type: .gripper, shoulderAngle: 0, elbowAngle: 0, gripperPercent: 0, speed: force)
    }

    static let home = GraspCommand(type: .home, shoulderAngle: 0, elbowAngle: 0, gripperPercent: 0, speed: 0)
    static let stop = GraspCommand(type: .stop, shoulderAngle: 0, elbowAngle: 0, gripperPercent: 0, speed: 0)
}
