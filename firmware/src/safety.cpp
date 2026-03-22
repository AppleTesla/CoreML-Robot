#include "safety.h"
#include <Arduino.h>

SafetyMonitor::SafetyMonitor(ServoController& servos)
    : servos(servos), estopped(false), errorCode(0), lastCommandMs(0) {}

void SafetyMonitor::begin() {
    lastCommandMs = millis();
}

void SafetyMonitor::update() {
    if (estopped) return;

    // Command timeout: stop servos if no command received recently
    if (millis() - lastCommandMs > COMMAND_TIMEOUT_MS && servos.isMoving()) {
        Serial.println("Safety: command timeout, stopping servos");
        servos.stop();
        errorCode = 1; // Timeout error
    }
}

bool SafetyMonitor::isEstopped() const {
    return estopped;
}

void SafetyMonitor::clearEstop() {
    estopped = false;
    errorCode = 0;
}

uint8_t SafetyMonitor::getErrorCode() const {
    return errorCode;
}
