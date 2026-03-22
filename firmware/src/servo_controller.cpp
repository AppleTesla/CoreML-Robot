#include "servo_controller.h"
#include <Arduino.h>

ServoController::ServoController()
    : pca9685(0x40), moving(false), lastUpdateMs(0) {
    // MG996R defaults for shoulder and elbow
    configs[JOINT_SHOULDER] = {500, 2500, 0, 180, 90};
    configs[JOINT_ELBOW]    = {500, 2500, 0, 180, 90};
    // SG90 defaults for gripper
    configs[JOINT_GRIPPER]  = {500, 2400, 0, 180, 10}; // 10° = closed

    for (int i = 0; i < JOINT_COUNT; i++) {
        currentAngles[i] = configs[i].homeAngle;
        targetAngles[i] = configs[i].homeAngle;
        speeds[i] = 128;
    }
}

bool ServoController::begin() {
    pca9685.begin();
    pca9685.setOscillatorFrequency(25000000);
    pca9685.setPWMFreq(50); // 50Hz for servos
    delay(10);

    // Move to home positions
    home();
    return true;
}

uint16_t ServoController::angleToPulse(Joint joint, uint8_t angle) {
    angle = constrain(angle, configs[joint].angleMin, configs[joint].angleMax);
    return map(angle,
               configs[joint].angleMin, configs[joint].angleMax,
               configs[joint].pulseMin, configs[joint].pulseMax);
}

void ServoController::applyAngle(Joint joint, uint8_t angle) {
    uint16_t pulse = angleToPulse(joint, angle);
    pca9685.writeMicroseconds(joint, pulse);
    currentAngles[joint] = angle;
}

void ServoController::setJointAngle(Joint joint, uint8_t angle, uint8_t speed) {
    if (joint >= JOINT_COUNT) return;
    angle = constrain(angle, configs[joint].angleMin, configs[joint].angleMax);
    targetAngles[joint] = angle;
    speeds[joint] = max((uint8_t)1, speed);
    moving = true;
}

void ServoController::setAllJoints(uint8_t shoulder, uint8_t elbow, uint8_t gripper, uint8_t speed) {
    setJointAngle(JOINT_SHOULDER, shoulder, speed);
    setJointAngle(JOINT_ELBOW, elbow, speed);
    setJointAngle(JOINT_GRIPPER, gripper, speed);
}

void ServoController::setGripperPercent(uint8_t percent, uint8_t force) {
    percent = constrain(percent, 0, 100);
    // Map 0% (closed) to angleMin, 100% (open) to angleMax
    uint8_t angle = map(percent, 0, 100,
                        configs[JOINT_GRIPPER].angleMin,
                        configs[JOINT_GRIPPER].angleMax);
    setJointAngle(JOINT_GRIPPER, angle, force);
}

void ServoController::home() {
    for (int i = 0; i < JOINT_COUNT; i++) {
        targetAngles[i] = configs[i].homeAngle;
        speeds[i] = 64; // Slow speed for homing
    }
    moving = true;
}

void ServoController::stop() {
    for (int i = 0; i < JOINT_COUNT; i++) {
        targetAngles[i] = currentAngles[i]; // Stop where we are
    }
    moving = false;
}

uint8_t ServoController::getCurrentAngle(Joint joint) const {
    if (joint >= JOINT_COUNT) return 0;
    return currentAngles[joint];
}

bool ServoController::isMoving() const {
    return moving;
}

void ServoController::update() {
    unsigned long now = millis();
    if (now - lastUpdateMs < 20) return; // 50Hz update rate
    float dt = (now - lastUpdateMs) / 1000.0f;
    lastUpdateMs = now;

    bool stillMoving = false;
    for (int i = 0; i < JOINT_COUNT; i++) {
        if (currentAngles[i] == targetAngles[i]) continue;

        stillMoving = true;
        float maxStep = speeds[i] * dt; // degrees this tick

        int diff = (int)targetAngles[i] - (int)currentAngles[i];
        if (abs(diff) <= maxStep) {
            applyAngle((Joint)i, targetAngles[i]);
        } else {
            int step = (diff > 0) ? (int)maxStep : -(int)maxStep;
            if (step == 0) step = (diff > 0) ? 1 : -1;
            applyAngle((Joint)i, currentAngles[i] + step);
        }
    }
    moving = stillMoving;
}
