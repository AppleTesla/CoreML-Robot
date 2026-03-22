#include <Arduino.h>
#include "servo_controller.h"
#include "command_parser.h"
#include "ble_server.h"
#include "safety.h"

ServoController servos;
CommandParser parser(servos);
RobotBLEServer bleServer(parser);
SafetyMonitor safety(servos);

unsigned long lastStatusMs = 0;
const unsigned long STATUS_INTERVAL_MS = 100; // 10Hz status updates

void setup() {
    Serial.begin(115200);
    Serial.println("CoreML-Robot Firmware v1.0");

    // Initialize I2C for PCA9685 (default pins: SDA=21, SCL=22)
    Wire.begin();

    // Initialize servo controller
    if (!servos.begin()) {
        Serial.println("ERROR: Failed to initialize servo controller");
        while (1) delay(1000);
    }
    Serial.println("Servo controller initialized");

    // Initialize BLE server
    bleServer.begin();

    // Initialize safety monitor
    safety.begin();

    Serial.println("Setup complete. Waiting for BLE connection...");
}

void loop() {
    // Update servo interpolation
    servos.update();

    // Safety checks
    safety.update();

    // Send status at 10Hz when connected
    if (bleServer.isClientConnected()) {
        unsigned long now = millis();
        if (now - lastStatusMs >= STATUS_INTERVAL_MS) {
            lastStatusMs = now;
            StatusPacket status;
            parser.buildStatusPacket(status);
            bleServer.notifyStatus(status);
        }
    }
}
