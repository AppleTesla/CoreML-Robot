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

## Project Structure

- `ios/` — Swift/SwiftUI iPhone app (camera, CoreML, BLE, grasp planning)
- `firmware/` — ESP32 PlatformIO project (BLE server, servo control)
- `ml/` — CreateML training project and helper scripts
- `hardware/` — CAD files and bill of materials

---

## Hardware: Complete Shopping List

If you have never touched electronics before, this section tells you exactly what to buy and where. Every part is available online. You do not need to solder anything for the basic setup — everything connects with plug-in wires.

### What You Need to Buy

| # | Component | Specific Part | Qty | Approx. Price | Where to Buy |
|---|-----------|---------------|-----|---------------|--------------|
| 1 | **Microcontroller** | ESP32-WROOM-32 DevKit V1 (30-pin) | 1 | $6–10 | [Amazon](https://www.amazon.com/s?k=ESP32+DevKit+V1), [AliExpress](https://www.aliexpress.com/w/wholesale-esp32-devkit-v1.html), [Adafruit](https://www.adafruit.com/product/3405) |
| 2 | **Servo driver board** | PCA9685 16-Channel 12-bit PWM Driver | 1 | $3–6 | [Amazon](https://www.amazon.com/s?k=PCA9685), [Adafruit](https://www.adafruit.com/product/815) |
| 3 | **Large servos** (shoulder + elbow) | MG996R (11 kg-cm torque) | 2 | $5–8 each | [Amazon](https://www.amazon.com/s?k=MG996R+servo), [AliExpress](https://www.aliexpress.com/w/wholesale-mg996r.html) |
| 4 | **Small servo** (gripper) | SG90 Micro Servo (1.8 kg-cm) | 1 | $2–4 | [Amazon](https://www.amazon.com/s?k=SG90+servo), [AliExpress](https://www.aliexpress.com/w/wholesale-sg90.html) |
| 5 | **Power supply** | 6V 5A DC Barrel Jack Power Supply | 1 | $8–12 | [Amazon](https://www.amazon.com/s?k=6V+5A+DC+power+supply) |
| 6 | **Barrel jack adapter** | Female DC barrel jack to screw terminal | 1 | $1–3 | [Amazon](https://www.amazon.com/s?k=DC+barrel+jack+screw+terminal) |
| 7 | **Jumper wires** | Male-to-Female Dupont wires (20cm, pack of 40) | 1 pack | $3–5 | [Amazon](https://www.amazon.com/s?k=dupont+jumper+wires+male+female) |
| 8 | **USB cable** | Micro-USB data cable (not charge-only!) | 1 | $3–5 | Any electronics store |
| 9 | **Breadboard** *(optional)* | Half-size solderless breadboard | 1 | $2–4 | [Amazon](https://www.amazon.com/s?k=solderless+breadboard) |

**Total cost: ~$40–60 USD** (not including the iPhone or 3D-printed arm parts).

> **Important notes for beginners:**
> - The ESP32 DevKit has a **Micro-USB** port. Make sure your cable is a **data cable**, not a charge-only cable. If your computer does not detect the board, the cable is almost certainly charge-only.
> - You do **not** need any resistors, capacitors, or soldering for this project. Everything plugs in.
> - The MG996R servos draw a lot of current. **Never power servos from the ESP32's 5V pin** — they will brown out the board or damage it. Always use the separate 6V power supply through the PCA9685.

---

## ESP32 Setup: Step-by-Step Guide (From Zero)

This section assumes you have never programmed a microcontroller before.

### Step 1: Install the Software

You need **two things** on your computer: VS Code (a code editor) and PlatformIO (a plugin that knows how to compile and upload code to the ESP32).

1. Download and install [Visual Studio Code](https://code.visualstudio.com/) (free, works on Mac/Windows/Linux)
2. Open VS Code
3. Click the **Extensions** icon in the left sidebar (it looks like 4 squares)
4. Search for **"PlatformIO IDE"** and click **Install**
5. Wait for PlatformIO to finish installing (it downloads compilers and tools — this takes a few minutes)
6. Restart VS Code when prompted

### Step 2: Install the USB Driver

The ESP32 DevKit uses a **CP2102** or **CH340** USB-to-serial chip. Your computer needs a driver to talk to it.

- **Mac:** Usually works out of the box on macOS 11+. If not, install the [CP210x driver](https://www.silabs.com/developers/usb-to-uart-bridge-vcp-drivers) or [CH340 driver](https://github.com/WCHSoftwareGroup/ch34xser_macos)
- **Windows:** Install the [CP210x driver](https://www.silabs.com/developers/usb-to-uart-bridge-vcp-drivers) or [CH340 driver](https://www.wch-ic.com/downloads/CH341SER_EXE.html) (check which chip your board has — it's printed on the chip near the USB port)
- **Linux:** Drivers are built into the kernel. No install needed.

### Step 3: Connect the ESP32 to Your Computer

```
┌─────────────────────────┐
│   ESP32 DevKit Board    │
│                         │
│  [  ] [  ] ... [  ] [  ]│  ← Pin headers (2 rows of 15 pins)
│                         │
│    ┌────────────────┐   │
│    │  ESP32-WROOM   │   │  ← The metal-shielded WiFi/BLE module
│    │                │   │
│    └────────────────┘   │
│                         │
│  [  ] [  ] ... [  ] [  ]│  ← Pin headers (other side)
│         [USB]           │  ← Micro-USB port
└─────────────────────────┘
         │
    Micro-USB cable
         │
    Your Computer
```

1. Plug the Micro-USB cable into the ESP32's USB port
2. Plug the other end into your computer
3. You should see a small red LED light up on the ESP32 — this means it has power

### Step 4: Verify the Connection

1. In VS Code, click the **PlatformIO** icon in the left sidebar (alien head icon)
2. Or open a terminal in VS Code (Terminal → New Terminal) and run:
   ```
   pio device list
   ```
3. You should see a serial port listed:
   - **Mac:** `/dev/cu.usbserial-XXXXX` or `/dev/cu.SLAB_USBtoUART`
   - **Windows:** `COM3` or `COM4` (the number varies)
   - **Linux:** `/dev/ttyUSB0` or `/dev/ttyACM0`
4. If you see **no devices**, try a different USB cable (yours may be charge-only)

### Step 5: Open the Firmware Project

1. In VS Code, go to **File → Open Folder**
2. Navigate to the `firmware/` directory inside this repo
3. PlatformIO will automatically detect `platformio.ini` and configure the project
4. Wait for PlatformIO to download the ESP32 toolchain and libraries (first time only, takes 2–5 minutes)

The `platformio.ini` file already has everything configured:

```ini
[env:esp32]
platform = espressif32
board = esp32dev
framework = arduino
monitor_speed = 115200
lib_deps =
    h2zero/NimBLE-Arduino@^1.4.1
    adafruit/Adafruit PWM Servo Driver Library@^3.0.1
```

This tells PlatformIO: "Use an ESP32 board, with the Arduino framework, and download the NimBLE (Bluetooth) and PCA9685 (servo driver) libraries."

### Step 6: Compile the Firmware

1. Click the **checkmark icon** (✓) in the blue PlatformIO toolbar at the bottom of VS Code
   - Or run in the terminal: `pio run`
2. Wait for compilation. You should see `SUCCESS` at the end:
   ```
   =============== [SUCCESS] Took 30.42 seconds ===============
   ```
3. If you see errors about missing libraries, PlatformIO should auto-download them. If not, run: `pio pkg install`

### Step 7: Upload Firmware to the ESP32

1. Make sure the ESP32 is plugged in via USB
2. Click the **right-arrow icon** (→) in the blue PlatformIO toolbar
   - Or run in the terminal: `pio run --target upload`
3. PlatformIO will compile (if needed) and then upload. You'll see:
   ```
   Connecting........_____
   Writing at 0x00010000... (XX %)
   ```
4. **If it says "Connecting........_____" and fails:** Hold down the **BOOT** button on the ESP32 while PlatformIO is trying to connect, then release it once uploading starts. Some boards need this.
5. When done, you'll see:
   ```
   =============== [SUCCESS] Took 45.12 seconds ===============
   ```

### Step 8: Verify It's Working (Serial Monitor)

1. Click the **plug icon** in the PlatformIO toolbar (Serial Monitor)
   - Or run: `pio device monitor`
2. You should see boot messages from the ESP32:
   ```
   CoreML-Robot Firmware v1.0
   Initializing servo controller...
   PCA9685 initialized at 50Hz
   Starting BLE server...
   BLE advertising started: CoreML-Robot
   ```
3. The ESP32 is now advertising itself over Bluetooth as "CoreML-Robot". The iPhone app can discover and connect to it.

Press `Ctrl+C` to exit the serial monitor.

---

## Wiring Guide

### Overview Diagram

```
    ┌────────────┐          ┌──────────────┐
    │  6V 5A     │          │   ESP32      │
    │  Power     │          │   DevKit     │
    │  Supply    │          │              │
    └─────┬──────┘          │  3V3 ── VCC  │
          │                 │  GND ──┐GND  │
          │   ┌─────────────│─ G21   │     │
          │   │ ┌───────────│─ G22   │     │
          │   │ │           └────────│─────┘
          │   │ │                    │
    ┌─────┴───┴─┴────────────────────┴──────────┐
    │         PCA9685 Servo Driver               │
    │                                            │
    │  V+   GND   SDA  SCL  VCC  GND            │
    │  (6V)  │     │    │   (3V3) │              │
    │                                            │
    │  CH0        CH1        CH2                 │
    │  ┌──┐       ┌──┐       ┌──┐               │
    │  │S0│       │S1│       │S2│               │
    └──┴──┴───────┴──┴───────┴──┴───────────────┘
       │             │           │
    Shoulder      Elbow      Gripper
    (MG996R)     (MG996R)    (SG90)
```

### Pin-by-Pin Wiring Table

Connect these wires one at a time. Use the male-to-female Dupont jumper wires for all connections.

| Wire # | From | To | Wire Color (suggested) | Notes |
|--------|------|----|----------------------|-------|
| 1 | ESP32 **GPIO 21** | PCA9685 **SDA** | Blue or White | I2C data line |
| 2 | ESP32 **GPIO 22** | PCA9685 **SCL** | Yellow or Green | I2C clock line |
| 3 | ESP32 **GND** | PCA9685 **GND** (logic side) | Black | Shared ground (critical!) |
| 4 | ESP32 **3V3** | PCA9685 **VCC** (logic side) | Red | Powers the PCA9685 chip logic |
| 5 | 6V Power Supply **+** | PCA9685 **V+** (servo power) | Red (thick) | Powers the servos |
| 6 | 6V Power Supply **−** | PCA9685 **GND** (servo power) | Black (thick) | Servo power ground |

> **The most common mistake:** Forgetting wire #3 (shared ground). The ESP32 and PCA9685 **must** share a common ground for I2C communication to work. If your servos twitch randomly or don't respond, check this wire first.

### Connecting the Servos to the PCA9685

Each servo has a 3-wire connector (usually brown/red/orange or black/red/white):

```
Servo Connector:
  Brown/Black = GND
  Red         = V+ (power)
  Orange/White = Signal (PWM)

PCA9685 Channel Header:
  ┌─────────┐
  │ GND V+ S│  ← Each channel has 3 pins
  └─────────┘
```

Plug the servo connectors directly into the PCA9685 channel headers:

| Servo | PCA9685 Channel | Connector Orientation |
|-------|----------------|-----------------------|
| Shoulder (MG996R) | **CH 0** | Brown/GND faces the board edge |
| Elbow (MG996R) | **CH 1** | Brown/GND faces the board edge |
| Gripper (SG90) | **CH 2** | Brown/GND faces the board edge |

The connectors only fit one way if you match GND-V+-Signal to the labeled pins on the PCA9685 board.

### ESP32 Pin Reference

```
          ┌───────────────┐
          │   ESP32 DevKit│
          │               │
     3V3 ─┤ 3V3      VIN ├─ 5V (from USB)
     GND ─┤ GND      GND ├─ GND
  GPIO 15─┤ D15      D13 ├─ GPIO 13
   GPIO 2─┤ D2       D12 ├─ GPIO 12
   GPIO 4─┤ D4       D14 ├─ GPIO 14
  GPIO 16─┤ RX2      D27 ├─ GPIO 27
  GPIO 17─┤ TX2      D26 ├─ GPIO 26
   GPIO 5─┤ D5       D25 ├─ GPIO 25
  GPIO 18─┤ D18      D33 ├─ GPIO 33
  GPIO 19─┤ D19      D32 ├─ GPIO 32
 *GPIO 21─┤ D21      D35 ├─ GPIO 35 (input only)
   GPIO 3─┤ RX0      D34 ├─ GPIO 34 (input only)
   GPIO 1─┤ TX0       VN ├─ GPIO 39 (input only)
 *GPIO 22─┤ D22       VP ├─ GPIO 36 (input only)
  GPIO 23─┤ D23       EN ├─ Enable
          │    [USB]      │
          └───────────────┘

    * = Used in this project (I2C to PCA9685)
```

### Power Wiring Detail

```
    Wall Outlet
         │
    ┌────┴─────┐
    │  6V 5A   │      ┌──── Barrel Jack ────┐
    │  Adapter │──────┤  + (center)  - (sleeve)│
    └──────────┘      └──┬──────────────┬───┘
                         │              │
                   Screw Terminal Adapter
                         │              │
                      RED wire       BLACK wire
                         │              │
                    PCA9685 V+     PCA9685 GND
                   (servo power)  (servo power)
```

1. Plug the 6V power supply into the wall
2. Connect its barrel jack to the screw-terminal barrel jack adapter
3. Use jumper wires from the screw terminals to the PCA9685's **V+** and **GND** (the servo power side, not the logic side)
4. **Do NOT plug the 6V supply into the ESP32** — the ESP32 gets its power from USB

### Safety Checklist Before Powering On

- [ ] ESP32 GND is connected to PCA9685 GND (wire #3)
- [ ] 6V power goes to PCA9685 V+ only, **NOT** to the ESP32
- [ ] ESP32 is powered by USB only
- [ ] Servos are plugged into PCA9685 channels 0, 1, 2 (not directly into ESP32)
- [ ] No bare wires touching each other
- [ ] Servo connectors are oriented correctly (GND/V+/Signal match the PCA9685 labels)

---

## Troubleshooting (ESP32)

| Problem | Solution |
|---------|----------|
| Computer doesn't detect ESP32 | Try a different USB cable — many cables are charge-only and lack data wires |
| `pio run --target upload` hangs at "Connecting..." | Hold the **BOOT** button on the ESP32 during upload, release when you see "Writing..." |
| Upload succeeds but serial monitor shows garbage | Check `monitor_speed = 115200` in `platformio.ini` matches the baud rate |
| Servos don't move | Check the 6V power supply is ON and connected to PCA9685 V+/GND |
| Servos jitter or move randomly | Check the shared GND wire between ESP32 and PCA9685 |
| BLE not showing up on iPhone | Make sure the serial monitor shows "BLE advertising started". Restart ESP32 if needed |
| "Permission denied" on serial port (Linux) | Run `sudo usermod -a -G dialout $USER` then log out and back in |

---

## Setup

### Firmware (ESP32)
1. Install [VS Code](https://code.visualstudio.com/) and the [PlatformIO IDE extension](https://platformio.org/install/ide?install=vscode)
2. Connect the ESP32 to your computer via Micro-USB
3. Open the `firmware/` folder in VS Code
4. Click the upload button (→) in the PlatformIO toolbar, or run:
   ```
   cd firmware && pio run --target upload
   ```
5. Open the serial monitor to verify: `pio device monitor`

### iOS App
1. Open `ios/CoreMLRobot/` in Xcode (requires Xcode 16+, iOS 17+)
2. Select your iPhone as the target device
3. Build and run
