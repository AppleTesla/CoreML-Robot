import Foundation

/// Serializes GraspCommands into the binary protocol expected by the ESP32 firmware
struct RobotCommandProtocol {
    private static var sequenceNumber: UInt8 = 0

    /// Serialize a command into a 12-byte packet
    static func serialize(_ command: GraspCommand) -> Data {
        var packet = Data(count: 12)
        sequenceNumber &+= 1

        packet[0] = command.type.rawValue
        packet[1] = sequenceNumber

        switch command.type {
        case .moveJoint:
            // payload: [joint_id, angle, speed, ...]
            packet[2] = 0 // joint ID (set externally if needed)
            packet[3] = command.shoulderAngle
            packet[4] = command.speed
        case .moveAll:
            packet[2] = command.shoulderAngle
            packet[3] = command.elbowAngle
            packet[4] = command.gripperPercent
            packet[5] = command.speed
        case .gripper:
            packet[2] = command.gripperPercent
            packet[3] = command.speed
        case .home, .stop, .queryStatus:
            break // No payload needed
        }

        // CRC-16 over first 10 bytes
        let crc = calculateCRC(Array(packet[0..<10]))
        packet[10] = UInt8(crc & 0xFF)
        packet[11] = UInt8((crc >> 8) & 0xFF)

        return packet
    }

    /// Parse a 10-byte status response from the robot
    static func parseStatus(_ data: Data) -> RobotState? {
        guard data.count >= 10, data[0] == 0xFE else { return nil }

        var state = RobotState()
        state.shoulderAngle = data[1]
        state.elbowAngle = data[2]
        state.gripperPercent = data[3]
        state.batteryPercent = data[4]
        state.errorCode = data[5]
        state.isMoving = (data[6] & 0x01) != 0
        state.isConnected = (data[6] & 0x02) != 0
        return state
    }

    /// CRC-16 (Modbus) matching the firmware implementation
    private static func calculateCRC(_ data: [UInt8]) -> UInt16 {
        var crc: UInt16 = 0xFFFF
        for byte in data {
            crc ^= UInt16(byte)
            for _ in 0..<8 {
                if crc & 1 != 0 {
                    crc = (crc >> 1) ^ 0xA001
                } else {
                    crc >>= 1
                }
            }
        }
        return crc
    }
}
