#include "command_parser.h"
#include <Arduino.h>

CommandParser::CommandParser(ServoController& servos)
    : servos(servos), lastSequence(0) {}

uint16_t CommandParser::calculateCRC(const uint8_t* data, size_t length) {
    uint16_t crc = 0xFFFF;
    for (size_t i = 0; i < length; i++) {
        crc ^= data[i];
        for (int j = 0; j < 8; j++) {
            if (crc & 1)
                crc = (crc >> 1) ^ 0xA001;
            else
                crc >>= 1;
        }
    }
    return crc;
}

bool CommandParser::validateChecksum(const CommandPacket& packet) {
    // CRC over first 10 bytes (cmdType + sequence + payload)
    uint16_t computed = calculateCRC((const uint8_t*)&packet, 10);
    return computed == packet.checksum;
}

bool CommandParser::parseAndExecute(const uint8_t* data, size_t length) {
    if (length < sizeof(CommandPacket)) {
        Serial.println("Packet too short");
        return false;
    }

    CommandPacket packet;
    memcpy(&packet, data, sizeof(CommandPacket));

    if (!validateChecksum(packet)) {
        Serial.println("Checksum mismatch");
        return false;
    }

    lastSequence = packet.sequence;

    switch (packet.cmdType) {
        case CMD_MOVE_JOINT: {
            uint8_t jointId = packet.payload[0];
            uint8_t angle = packet.payload[1];
            uint8_t speed = packet.payload[2];
            if (jointId < JOINT_COUNT) {
                servos.setJointAngle((Joint)jointId, angle, speed);
            }
            break;
        }
        case CMD_MOVE_ALL: {
            uint8_t shoulder = packet.payload[0];
            uint8_t elbow = packet.payload[1];
            uint8_t gripper = packet.payload[2];
            uint8_t speed = packet.payload[3];
            servos.setAllJoints(shoulder, elbow, gripper, speed);
            break;
        }
        case CMD_GRIPPER: {
            uint8_t percent = packet.payload[0];
            uint8_t force = packet.payload[1];
            servos.setGripperPercent(percent, force);
            break;
        }
        case CMD_HOME:
            servos.home();
            break;
        case CMD_STOP:
            servos.stop();
            break;
        case CMD_QUERY_STATUS:
            // Status will be sent by the BLE notify characteristic
            break;
        default:
            Serial.printf("Unknown command: 0x%02X\n", packet.cmdType);
            return false;
    }
    return true;
}

void CommandParser::buildStatusPacket(StatusPacket& status) {
    status.header = 0xFE;
    status.shoulder = servos.getCurrentAngle(JOINT_SHOULDER);
    status.elbow = servos.getCurrentAngle(JOINT_ELBOW);
    status.gripperPct = map(servos.getCurrentAngle(JOINT_GRIPPER), 0, 180, 0, 100);
    status.batteryPct = 100; // TODO: read from ADC
    status.errorCode = 0;
    status.flags = servos.isMoving() ? 0x01 : 0x00;
    status.flags |= 0x02; // connected flag
    status.reserved = 0;
    status.checksum = calculateCRC((const uint8_t*)&status, 8);
}
