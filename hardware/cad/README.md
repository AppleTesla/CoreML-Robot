# 3D Printable Parts for CoreML-Robot

Four OpenSCAD files that make up the complete 3-DOF robot arm and iPhone head mount.

## Files

| File | Part | Description |
|------|------|-------------|
| `base_torso.scad` | Base / Torso | Weighted base plate + pillar holding the shoulder MG996R servo |
| `upper_arm.scad` | Upper Arm | Link from shoulder horn to elbow servo pocket (150mm) |
| `forearm_gripper.scad` | Forearm + Gripper | Link from elbow horn to SG90-driven parallel jaw gripper (130mm) |
| `iphone_mount.scad` | iPhone Mount (Head) | Tilted spring-loaded cradle for iPhone 17 Pro (landscape) on a tall post |

> The **moving jaw** of the gripper is a separate piece at the bottom of `forearm_gripper.scad`. Export it independently (see instructions below).

## Assembly Diagram

```
                    ┌──────────────────┐
                    │   iPhone 17 Pro  │  ← Slides into spring-loaded cradle
                    │   (landscape)    │
                    └───────┬──────────┘
                            │
                     ┌──────┴──────┐
                     │ iPhone Mount│  ← 50-degree tilt, camera faces workspace
                     │   (Head)    │
                     └──────┬──────┘
                            │  120mm post
                            │
  ┌──────── upper_arm ──────┤
  │         (150mm)         │
  │                         │
  shoulder              base_torso
  servo (MG996R)         (on table)
  │
  ├──── forearm ────┐
  │     (130mm)     │
  elbow          gripper
  servo (MG996R) servo (SG90)
                    │
               ┌────┴────┐
               │ ← jaws → │
               └──────────┘
```

## How to Export STL for PrusaSlicer

You need [OpenSCAD](https://openscad.org/downloads.html) (free, Mac/Windows/Linux).

### Quick export

1. Open any `.scad` file in OpenSCAD
2. Press **F5** to preview (fast) or **F6** to render (required before export)
3. Go to **File → Export → Export as STL**
4. Save the `.stl` file
5. Open the `.stl` in PrusaSlicer

### Exporting the gripper's moving jaw separately

The `forearm_gripper.scad` file contains two parts: the forearm body and the moving jaw (shown offset below it). To export each:

1. Open `forearm_gripper.scad`
2. Comment out the moving jaw block at the bottom (add `//` before the `translate` line)
3. Render (F6) and export → `forearm_gripper.stl`
4. Undo, then comment out everything *except* the moving jaw block
5. Render (F6) and export → `moving_jaw.stl`

### Batch export (command line)

```bash
cd hardware/cad
openscad -o base_torso.stl base_torso.scad
openscad -o upper_arm.stl upper_arm.scad
openscad -o forearm_gripper.stl forearm_gripper.scad
openscad -o iphone_mount.stl iphone_mount.scad
```

## Print Settings

Tested on Prusa MK3S+ / MK4 with a 0.4mm nozzle.

| Setting | Value | Notes |
|---------|-------|-------|
| Layer height | 0.2mm | Balance of speed and quality |
| Infill | 20% base, 40% arm links | Arm links need more strength |
| Perimeters | 3 | Structural rigidity |
| Material | PLA+ or PETG | PETG preferred for the iPhone mount spring fingers |
| Supports | None | All parts are designed to print flat without supports |
| Brim | Yes for base plate | Helps adhesion on the large flat base |

### Per-Part Orientation

| Part | Orientation on bed | Approx. print time | Filament |
|------|-------------------|--------------------|----|
| Base / Torso | Bottom plate flat down | ~3 hours | ~80g |
| Upper Arm | Flat on wide face | ~1.5 hours | ~30g |
| Forearm + Gripper | Flat on wide face | ~1.5 hours | ~25g |
| Moving Jaw | Flat on back face | ~20 min | ~5g |
| iPhone Mount | Post vertical (base plate down) | ~4 hours | ~90g |

**Total: ~10 hours print time, ~230g filament**

## Hardware Needed for Assembly

After printing, you need these fasteners to assemble (all widely available):

| Item | Size | Qty | Used For |
|------|------|-----|----------|
| M3 x 10mm screws | M3 | 8 | Servo tab clamping (4 per MG996R) |
| M3 nuts | M3 | 8 | Backs for servo screws |
| M2 x 8mm self-tap screws | M2 | 12 | Servo horn to arm links, SG90 tabs |
| M5 x 16mm screws | M5 | 4 | Base plate to table (optional) |
| M3 x 20mm pin or bolt | M3 | 1 | Gripper jaw pivot |
| Wire (1mm steel or stiff) | ~40mm | 1 | Pushrod from SG90 horn to moving jaw |

## Assembly Order

1. **Press-fit the shoulder MG996R** into the base torso pillar. Slide it in from the top so the shaft exits through the side hole. Secure with M3 screws through the pillar walls into the servo tabs.

2. **Attach the upper arm** to the shoulder servo horn using M2 self-tap screws through the horn mount holes. Then screw the horn onto the servo shaft with the included center screw.

3. **Press-fit the elbow MG996R** into the upper arm's elbow pocket. Secure with M3 screws.

4. **Attach the forearm** to the elbow servo horn the same way as step 2.

5. **Insert the SG90** into the forearm's gripper pocket. Secure with M2 self-tap screws through the tab holes.

6. **Install the moving jaw** on the pivot pin (M3 bolt). Bend a short steel wire pushrod from the SG90 horn hole to the moving jaw's pushrod hole.

7. **Mount the iPhone cradle** to the base with M5 screws, behind the arm. The phone slides in from the top — the spring fingers flex outward and clamp it.

## Customization

All dimensions are parametric — change them at the top of each `.scad` file:

- **Different phone?** Edit `phone_w`, `phone_h`, `phone_d` in `iphone_mount.scad`
- **Longer arm?** Edit `arm_length` in `upper_arm.scad` and `forearm_length` in `forearm_gripper.scad`
- **Different servos?** Edit the `servo_body_*` dimensions in the relevant file
- **Softer spring clamp?** Increase `spring_arm_l` or decrease `spring_arm_t` in `iphone_mount.scad`
- **Steeper camera angle?** Edit `tilt_angle` in `iphone_mount.scad` (default 50 degrees)
