#pragma once

#include <Adafruit_PWMServoDriver.h>

// Servo channel assignments on PCA9685
enum Joint : uint8_t {
    JOINT_SHOULDER = 0,
    JOINT_ELBOW    = 1,
    JOINT_GRIPPER  = 2,
    JOINT_COUNT    = 3
};

struct JointConfig {
    uint16_t pulseMin;   // Minimum pulse length (microseconds)
    uint16_t pulseMax;   // Maximum pulse length (microseconds)
    uint8_t  angleMin;   // Minimum angle (degrees)
    uint8_t  angleMax;   // Maximum angle (degrees)
    uint8_t  homeAngle;  // Home/rest position (degrees)
};

class ServoController {
public:
    ServoController();

    bool begin();
    void setJointAngle(Joint joint, uint8_t angle, uint8_t speed = 128);
    void setAllJoints(uint8_t shoulder, uint8_t elbow, uint8_t gripper, uint8_t speed = 128);
    void setGripperPercent(uint8_t percent, uint8_t force = 128);
    void home();
    void stop();

    uint8_t getCurrentAngle(Joint joint) const;
    bool isMoving() const;
    void update(); // Call in loop() for smooth interpolation

private:
    Adafruit_PWMServoDriver pca9685;
    JointConfig configs[JOINT_COUNT];
    uint8_t currentAngles[JOINT_COUNT];
    uint8_t targetAngles[JOINT_COUNT];
    uint8_t speeds[JOINT_COUNT]; // degrees per second
    bool moving;
    unsigned long lastUpdateMs;

    uint16_t angleToPulse(Joint joint, uint8_t angle);
    void applyAngle(Joint joint, uint8_t angle);
};
