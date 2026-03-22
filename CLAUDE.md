# CoreML-Robot

Pick-and-place robot: iPhone (camera + CoreML object detection + grasp planning) communicates over BLE to ESP32 (servo control).

## Architecture

- **ios/CoreMLRobot/** — Swift 6.2 SwiftUI app (SPM package). Uses `@Observable`, `AsyncStream`, `@MainActor`. No Combine.
- **firmware/** — ESP32 PlatformIO project (C++). BLE GATT server, PCA9685 PWM servo driver, command parser, safety module.
- **ml/** — CreateML / YOLOv8n training pipeline (Python scripts + notebooks).

## BLE Protocol

- Service UUID: `12345678-1234-1234-1234-123456789abc`
- Command char (write): `...-123456789001` — 12-byte packets with CRC-16 Modbus
- Status char (notify): `...-123456789002` — 10-byte state packets (prefix `0xFE`)
- Command types: `MOVE_JOINT(0x01)`, `MOVE_ALL(0x02)`, `GRIPPER(0x03)`, `HOME(0x04)`, `STOP(0x05)`, `QUERY(0x06)`

## Build

- **iOS:** Open `ios/CoreMLRobot/` in Xcode. Requires iOS 17+. Swift 6.2 language mode.
- **Firmware:** `cd firmware && pio run --target upload` (ESP32-WROOM-32)

## Key Patterns

- `BLEManager` is the central `@Observable` class shared via `.environment()`. NSObject subclass for CoreBluetooth delegates.
- `CameraManager` exposes `AsyncStream<CMSampleBuffer>` for frame delivery instead of delegate pattern.
- `ObjectDetector` consumes camera frames via async iteration, publishes `[DetectedObject]` on `@MainActor`.
- `PickPlaceStateMachine` uses `Task`-based sequencing instead of `Timer`.
- All model structs (`RobotState`, `DetectedObject`, `GraspCommand`) are `Sendable`.
- IK solver is a pure 2-link planar analytical solver (`InverseKinematics`).
