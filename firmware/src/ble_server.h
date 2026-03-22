#pragma once

#include <NimBLEDevice.h>
#include "command_parser.h"

// Custom service and characteristic UUIDs
#define SERVICE_UUID        "12345678-1234-1234-1234-123456789abc"
#define COMMAND_CHAR_UUID   "12345678-1234-1234-1234-123456789001"
#define STATUS_CHAR_UUID    "12345678-1234-1234-1234-123456789002"
#define CONFIG_CHAR_UUID    "12345678-1234-1234-1234-123456789003"

class RobotBLEServer {
public:
    RobotBLEServer(CommandParser& parser);

    void begin();
    void notifyStatus(const StatusPacket& status);
    bool isClientConnected() const;
    void resetCommandTimeout();

private:
    CommandParser& parser;
    NimBLEServer* server;
    NimBLECharacteristic* commandChar;
    NimBLECharacteristic* statusChar;
    NimBLECharacteristic* configChar;
    bool clientConnected;
    unsigned long lastCommandMs;

    class ServerCallbacks;
    class CommandCallbacks;

    friend class ServerCallbacks;
    friend class CommandCallbacks;
};
