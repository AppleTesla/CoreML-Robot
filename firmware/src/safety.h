#pragma once

#include "servo_controller.h"

class SafetyMonitor {
public:
    SafetyMonitor(ServoController& servos);

    void begin();
    void update(); // Call in loop()
    bool isEstopped() const;
    void clearEstop();
    uint8_t getErrorCode() const;

private:
    ServoController& servos;
    bool estopped;
    uint8_t errorCode;
    unsigned long lastCommandMs;
    static const unsigned long COMMAND_TIMEOUT_MS = 5000; // Stop if no commands for 5s
};
