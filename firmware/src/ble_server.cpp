#include "ble_server.h"
#include <Arduino.h>

// Server connection callbacks
class RobotBLEServer::ServerCallbacks : public NimBLEServerCallbacks {
public:
    ServerCallbacks(RobotBLEServer& ble) : ble(ble) {}

    void onConnect(NimBLEServer* server) override {
        ble.clientConnected = true;
        Serial.println("BLE: Client connected");
    }

    void onDisconnect(NimBLEServer* server) override {
        ble.clientConnected = false;
        Serial.println("BLE: Client disconnected");
        NimBLEDevice::startAdvertising();
    }

private:
    RobotBLEServer& ble;
};

// Command characteristic write callback
class RobotBLEServer::CommandCallbacks : public NimBLECharacteristicCallbacks {
public:
    CommandCallbacks(RobotBLEServer& ble) : ble(ble) {}

    void onWrite(NimBLECharacteristic* characteristic) override {
        std::string value = characteristic->getValue();
        if (value.length() > 0) {
            ble.lastCommandMs = millis();
            bool ok = ble.parser.parseAndExecute(
                (const uint8_t*)value.data(), value.length());
            if (!ok) {
                Serial.println("BLE: Failed to parse command");
            }
        }
    }

private:
    RobotBLEServer& ble;
};

RobotBLEServer::RobotBLEServer(CommandParser& parser)
    : parser(parser), server(nullptr), commandChar(nullptr),
      statusChar(nullptr), configChar(nullptr),
      clientConnected(false), lastCommandMs(0) {}

void RobotBLEServer::begin() {
    NimBLEDevice::init("CoreML-Robot");
    NimBLEDevice::setPower(ESP_PWR_LVL_P9); // Max power for range
    NimBLEDevice::setMTU(64);

    server = NimBLEDevice::createServer();
    server->setCallbacks(new ServerCallbacks(*this));

    // Create service
    NimBLEService* service = server->createService(SERVICE_UUID);

    // Command characteristic (write)
    commandChar = service->createCharacteristic(
        COMMAND_CHAR_UUID,
        NIMBLE_PROPERTY::WRITE | NIMBLE_PROPERTY::WRITE_NR
    );
    commandChar->setCallbacks(new CommandCallbacks(*this));

    // Status characteristic (notify)
    statusChar = service->createCharacteristic(
        STATUS_CHAR_UUID,
        NIMBLE_PROPERTY::READ | NIMBLE_PROPERTY::NOTIFY
    );

    // Config characteristic (read/write)
    configChar = service->createCharacteristic(
        CONFIG_CHAR_UUID,
        NIMBLE_PROPERTY::READ | NIMBLE_PROPERTY::WRITE
    );

    service->start();

    // Start advertising
    NimBLEAdvertising* advertising = NimBLEDevice::getAdvertising();
    advertising->addServiceUUID(SERVICE_UUID);
    advertising->setScanResponse(true);
    advertising->start();

    Serial.println("BLE: Server started, advertising...");
}

void RobotBLEServer::notifyStatus(const StatusPacket& status) {
    if (clientConnected && statusChar) {
        statusChar->setValue((const uint8_t*)&status, sizeof(StatusPacket));
        statusChar->notify();
    }
}

bool RobotBLEServer::isClientConnected() const {
    return clientConnected;
}

void RobotBLEServer::resetCommandTimeout() {
    lastCommandMs = millis();
}
