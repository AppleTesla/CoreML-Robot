#pragma once

#include <cstdint>
#include "servo_controller.h"

// Command types
enum CommandType : uint8_t {
    CMD_MOVE_JOINT   = 0x01,
    CMD_MOVE_ALL     = 0x02,
    CMD_GRIPPER      = 0x03,
    CMD_HOME         = 0x04,
    CMD_STOP         = 0x05,
    CMD_QUERY_STATUS = 0x06,
};

// Command packet structure (12 bytes)
struct CommandPacket {
    uint8_t  cmdType;
    uint8_t  sequence;
    uint8_t  payload[8];
    uint16_t checksum;
} __attribute__((packed));

// Status response (10 bytes)
struct StatusPacket {
    uint8_t  header;      // Always 0xFE
    uint8_t  shoulder;
    uint8_t  elbow;
    uint8_t  gripperPct;
    uint8_t  batteryPct;
    uint8_t  errorCode;
    uint8_t  flags;       // bit0=moving, bit1=connected
    uint8_t  reserved;
    uint16_t checksum;
} __attribute__((packed));

class CommandParser {
public:
    CommandParser(ServoController& servos);

    bool parseAndExecute(const uint8_t* data, size_t length);
    void buildStatusPacket(StatusPacket& status);

private:
    ServoController& servos;
    uint8_t lastSequence;

    uint16_t calculateCRC(const uint8_t* data, size_t length);
    bool validateChecksum(const CommandPacket& packet);
};
