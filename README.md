# CoreML-Robot

A pick-and-place robot that uses an iPhone as its "head" for vision and AI processing via CoreML. The iPhone sees objects through its camera, runs object detection locally, and sends motor commands over Bluetooth (BLE) to an ESP32 that drives the robot's arm servos.

## Architecture

```
iPhone (Head/Brain)          ESP32 (Spine)
┌─────────────────┐    BLE    ┌──────────────────┐
│ Camera → CoreML │ ──────── │ Command Parser   │
│ Object Detection│ commands │ Servo Controller │
│ Grasp Planning  │ ◄──────  │ Safety Module    │
│ IK Solver       │  status  │ PCA9685 (I2C)    │
└─────────────────┘          └──────┬───────────┘
                                    │ PWM
                              ┌─────┴─────┐
                              │  3-DOF Arm │
                              │  Shoulder  │
                              │  Elbow     │
                              │  Gripper   │
                              └───────────┘
```

## Hardware

| Component | Part | Qty |
|-----------|------|-----|
| MCU | ESP32-WROOM-32 DevKit | 1 |
| PWM Driver | PCA9685 16-ch I2C | 1 |
| Shoulder/Elbow Servos | MG996R (11 kg-cm) | 2 |
| Gripper Servo | SG90 (1.8 kg-cm) | 1 |
| Power Supply | 6V 5A DC | 1 |
| iPhone Mount | 3D printed cradle | 1 |

## Project Structure

- `ios/` — Swift/SwiftUI iPhone app (camera, CoreML, BLE, grasp planning)
- `firmware/` — ESP32 PlatformIO project (BLE server, servo control)
- `ml/` — CreateML training project and helper scripts
- `hardware/` — CAD files and bill of materials

## Setup

### Firmware (ESP32)
1. Install [PlatformIO](https://platformio.org/)
2. `cd firmware && pio run --target upload`

### iOS App
1. Open `ios/CoreMLRobot/` in Xcode
2. Select your iPhone as the target device
3. Build and run

### Wiring
- PCA9685 SDA → ESP32 GPIO 21
- PCA9685 SCL → ESP32 GPIO 22
- PCA9685 V+ → 6V power supply
- PCA9685 GND → Common ground with ESP32
- Servos → PCA9685 channels 0 (shoulder), 1 (elbow), 2 (gripper)
