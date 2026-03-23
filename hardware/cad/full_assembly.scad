// =============================================================
// CoreML-Robot: Full Assembly Visualization
// =============================================================
// Shows all printed parts, servos, and ESP32 board in their
// final assembled positions. Includes poseable joint angles.
//
// This file is for visualization only — do NOT export this as
// a single STL. Export each part from its own .scad file.
//
// Usage:
//   - Open in OpenSCAD and press F5 to preview
//   - Adjust joint angles below to pose the arm
//   - Use the Animation feature (View → Animate) with $t
// =============================================================

$fn = 40;  // lower for faster preview; raise to 80+ for renders

// ===================== POSEABLE JOINT ANGLES =====================
// Change these to pose the robot arm (degrees)

shoulder_angle = 45;   // 0 = horizontal forward, 90 = straight up
elbow_angle    = -30;  // relative to upper arm
gripper_open   = 20;   // jaw opening angle (0 = closed, ~30 = full open)

// ===================== KEY DIMENSIONS ============================
// Duplicated from individual part files for assembly positioning.

// Base
base_length = 120;
base_width  = 90;
base_height = 5;
base_fillet = 3;

// MG996R servo
mg_body_l  = 40.7;
mg_body_w  = 19.7;
mg_body_h  = 36.0;
mg_tab_w   = 8.0;
mg_tab_t   = 2.5;
mg_shaft_offset = 10.0;
mg_shaft_d = 6.0;
mg_shaft_h = 4.0;
mg_horn_d  = 21.0;
mg_horn_h  = 3.5;

// SG90 servo
sg_body_l = 22.5;
sg_body_w = 12.0;
sg_body_h = 22.7;
sg_tab_w  = 32.2;
sg_tab_t  = 2.5;
sg_shaft_d = 4.5;
sg_shaft_h = 3.5;

// Pillar
pillar_wall   = 4;
pillar_width  = mg_body_w + 8;
pillar_depth  = mg_body_l + 8;
pillar_height = 50;

// Arm links
arm_length     = 150;
arm_width      = 28;
arm_thickness  = 12;
forearm_length = 130;
forearm_width  = 24;
forearm_thick  = 10;

// Gripper
jaw_length = 45;
jaw_width  = 12;
jaw_thick  = 5;

// iPhone mount
mount_plate_w = 60;
mount_plate_d = 40;
mount_plate_h = 5;
post_height   = 120;
post_width    = 20;
post_depth    = 20;
tilt_angle    = 50;
phone_w       = 150.0;
phone_h       = 72.0;
phone_d       = 8.5;
cradle_tol    = 1.5;

// ESP32 DevKit V1 (ESP32-WROOM-32)
esp_pcb_l   = 51.0;
esp_pcb_w   = 25.5;
esp_pcb_h   = 1.6;
esp_mod_l   = 18.0;
esp_mod_w   = 25.5;
esp_mod_h   = 3.2;
esp_usb_w   = 8.0;
esp_usb_d   = 6.0;
esp_usb_h   = 3.0;
esp_pin_h   = 8.5;  // header pin height below PCB
esp_header_w = 2.54;

// Derived positions
shoulder_x = base_length/2 - pillar_depth/2 + pillar_wall + mg_shaft_offset;
shoulder_y = base_width/2 - pillar_width/2;  // shaft exits this side
shoulder_z = base_height + pillar_height - (mg_body_h + 1)/2;


// ===================== ELECTRONIC COMPONENT MODELS ===============

module mg996r_servo() {
    // MG996R standard servo — body + tabs + shaft + horn
    // Origin at the output shaft center, shaft points up (+Z)
    color("DimGray") {
        // Main body
        translate([-mg_shaft_offset, -mg_body_w/2, -mg_body_h/2])
            cube([mg_body_l, mg_body_w, mg_body_h]);

        // Mounting tabs
        translate([-mg_shaft_offset - mg_tab_w, -mg_body_w/2, mg_body_h/2 - mg_tab_t])
            cube([mg_body_l + 2*mg_tab_w, mg_body_w, mg_tab_t]);
    }

    // Shaft
    color("Silver")
        cylinder(d=mg_shaft_d, h=mg_body_h/2 + mg_shaft_h);

    // Round horn (semi-transparent to see mounting)
    color("White", 0.8)
        translate([0, 0, mg_body_h/2 + mg_shaft_h - 1])
            cylinder(d=mg_horn_d, h=mg_horn_h);

    // Wire stub
    color("DarkRed")
        translate([mg_body_l - mg_shaft_offset - 2, -2, -mg_body_h/2])
            cube([4, 4, -8]);

    // Label
    color("White")
        translate([-mg_shaft_offset + 3, -mg_body_w/2 + 2, mg_body_h/2 - mg_tab_t - 0.1])
            linear_extrude(0.2)
                text("MG996R", size=4, font="Liberation Sans:style=Bold");
}

module sg90_servo() {
    // SG90 micro servo
    // Origin at the output shaft center, shaft points up (+Z)
    sg_shaft_offset = 6.0; // shaft offset from center

    color("RoyalBlue") {
        // Main body
        translate([-sg_body_l/2, -sg_body_w/2, -sg_body_h/2])
            cube([sg_body_l, sg_body_w, sg_body_h]);

        // Mounting tabs (wider than body)
        translate([-sg_tab_w/2, -sg_body_w/2, sg_body_h/2 - sg_body_h + 16])
            cube([sg_tab_w, sg_body_w, sg_tab_t]);
    }

    // Shaft
    color("White")
        cylinder(d=sg_shaft_d, h=sg_body_h/2 + sg_shaft_h);

    // Single-arm horn
    color("White", 0.8)
        translate([0, 0, sg_body_h/2 + sg_shaft_h - 0.5]) {
            cylinder(d=7, h=1.5);
            translate([0, -2, 0])
                cube([14, 4, 1.5]);
        }
}

module esp32_devkit() {
    // ESP32-WROOM-32 DevKit V1
    // Origin at center of PCB, components face up (+Z)

    // PCB
    color("DarkGreen") {
        translate([-esp_pcb_l/2, -esp_pcb_w/2, 0])
            cube([esp_pcb_l, esp_pcb_w, esp_pcb_h]);

        // Rounded corners (simplified)
        translate([-esp_pcb_l/2 + 1, -esp_pcb_w/2 + 1, 0])
            cylinder(r=1, h=esp_pcb_h);
    }

    // WROOM-32 module (metal shield)
    color("Silver")
        translate([esp_pcb_l/2 - esp_mod_l - 1, -esp_mod_w/2, esp_pcb_h])
            cube([esp_mod_l, esp_mod_w, esp_mod_h]);

    // Antenna area (end of module)
    color("DarkGoldenrod")
        translate([esp_pcb_l/2 - 4, -esp_mod_w/2 + 2, esp_pcb_h + esp_mod_h])
            cube([3, esp_mod_w - 4, 0.5]);

    // Micro USB connector
    color("Silver")
        translate([-esp_pcb_l/2 - esp_usb_d/2, -esp_usb_w/2, esp_pcb_h])
            cube([esp_usb_d, esp_usb_w, esp_usb_h]);

    // Pin headers (two rows along the long edges)
    color("Black") {
        // Left header
        translate([-esp_pcb_l/2 + 1.5, -esp_pcb_w/2 + 0.5, -esp_pin_h])
            cube([esp_pcb_l - 3, esp_header_w, esp_pin_h + esp_pcb_h + 2.5]);
        // Right header
        translate([-esp_pcb_l/2 + 1.5, esp_pcb_w/2 - 0.5 - esp_header_w, -esp_pin_h])
            cube([esp_pcb_l - 3, esp_header_w, esp_pin_h + esp_pcb_h + 2.5]);
    }

    // Gold pins visible below headers
    color("Gold") {
        for (side = [-1, 1]) {
            pin_y = side * (esp_pcb_w/2 - 1.27);
            for (i = [0:14]) {
                translate([-esp_pcb_l/2 + 3 + i * 2.54, pin_y, -esp_pin_h])
                    cube([0.6, 0.6, esp_pin_h]);
            }
        }
    }

    // EN and BOOT buttons
    color("Gray") {
        translate([-esp_pcb_l/2 + 8, -3, esp_pcb_h])
            cube([3, 2.5, 1.5]);
        translate([-esp_pcb_l/2 + 14, -3, esp_pcb_h])
            cube([3, 2.5, 1.5]);
    }

    // Power LED
    color("Red", 0.9)
        translate([-esp_pcb_l/2 + 5, 5, esp_pcb_h])
            cube([1.6, 0.8, 0.8]);

    // Label
    color("White")
        translate([-10, -5, esp_pcb_h + esp_mod_h + 0.1])
            linear_extrude(0.2)
                text("ESP32", size=4, font="Liberation Sans:style=Bold");
}

module iphone_17_pro() {
    // iPhone 17 Pro in landscape orientation
    // Origin at center of phone
    color("Black", 0.85) {
        difference() {
            // Body with rounded edges
            hull() {
                for (x = [-phone_w/2+4, phone_w/2-4])
                    for (y = [-phone_h/2+4, phone_h/2-4])
                        translate([x, y, 0])
                            cylinder(r=4, h=phone_d, center=true);
            }

            // Screen (slight inset on front)
            translate([0, 0, phone_d/2 - 0.3])
                hull() {
                    for (x = [-phone_w/2+6, phone_w/2-6])
                        for (y = [-phone_h/2+6, phone_h/2-6])
                            translate([x, y, 0])
                                cylinder(r=4, h=0.5);
                }
        }
    }

    // Screen (dark blue-ish when off)
    color("MidnightBlue", 0.9)
        translate([0, 0, phone_d/2 - 0.2])
            hull() {
                for (x = [-phone_w/2+6, phone_w/2-6])
                    for (y = [-phone_h/2+6, phone_h/2-6])
                        translate([x, y, 0])
                            cylinder(r=3, h=0.3);
            }

    // Camera bump (landscape: top-left becomes one end)
    color("DarkSlateGray")
        translate([-phone_w/2 + 20, phone_h/2 - 22, -phone_d/2 - 1.5])
            hull() {
                for (dx = [0, 18])
                    for (dy = [0, -14])
                        translate([dx, dy, 0])
                            cylinder(r=4, h=1.5);
            }

    // Camera lenses
    for (pos = [[-phone_w/2+22, phone_h/2-18], [-phone_w/2+36, phone_h/2-18], [-phone_w/2+29, phone_h/2-30]])
        color("VeryDarkGray")
            translate([pos[0], pos[1], -phone_d/2 - 2])
                cylinder(d=10, h=2.2);
}


// ===================== SIMPLIFIED PRINTED PARTS ==================
// Dimensionally accurate simplified representations for assembly.

module printed_base_torso() {
    color("SlateGray") {
        // Base plate
        hull() {
            for (x = [base_fillet, base_length - base_fillet])
                for (y = [base_fillet, base_width - base_fillet])
                    translate([x, y, 0])
                        cylinder(r=base_fillet, h=base_height);
        }

        // Pillar
        translate([base_length/2 - pillar_depth/2,
                   base_width/2 - pillar_width/2,
                   base_height])
            cube([pillar_depth, pillar_width, pillar_height]);

        // Gusset ribs (simplified triangles)
        for (side = [-1, 1]) {
            translate([base_length/2 - pillar_depth/2,
                       base_width/2 + side * pillar_width/2,
                       base_height])
                rotate([90, 0, 0])
                    linear_extrude(3, center=true)
                        polygon([[0,0], [0, 20], [-14, 0]]);
        }
    }
}

module printed_upper_arm() {
    color("DodgerBlue") {
        difference() {
            // Arm body (hull between two cylinders)
            hull() {
                cylinder(d=arm_width, h=arm_thickness);
                translate([arm_length, 0, 0])
                    cylinder(d=arm_width, h=arm_thickness);
            }

            // Elbow servo pocket (simplified)
            translate([arm_length, 0, -1])
                cube([mg_body_l + 1, mg_body_w + 1, arm_thickness + 2], center=true);

            // Lightening holes
            for (i = [1:3]) {
                translate([i * arm_length/4, 0, -1])
                    hull() {
                        translate([-8, 0, 0]) cylinder(d=12, h=arm_thickness+2);
                        translate([ 8, 0, 0]) cylinder(d=12, h=arm_thickness+2);
                    }
            }

            // Horn mount center hole
            translate([0, 0, -1])
                cylinder(d=7.5, h=arm_thickness+2);
        }

        // Wider elbow mounting area
        translate([arm_length, 0, 0])
            hull() {
                for (x = [-mg_body_l/2-6, mg_body_l/2+6])
                    for (y = [-mg_body_w/2-5, mg_body_w/2+5])
                        translate([x, y, 0])
                            cylinder(r=2, h=arm_thickness);
            }
    }
}

module printed_forearm_gripper() {
    color("OrangeRed") {
        difference() {
            // Forearm body
            hull() {
                cylinder(d=forearm_width, h=forearm_thick);
                translate([forearm_length, 0, 0])
                    cylinder(d=forearm_width + 6, h=forearm_thick);
            }

            // SG90 pocket
            translate([forearm_length - sg_body_l/2, -sg_body_w/2, -1])
                cube([sg_body_l + 0.5, sg_body_w + 0.5, forearm_thick + 2]);

            // Horn center hole
            translate([0, 0, -1])
                cylinder(d=7.5, h=forearm_thick+2);

            // Lightening holes
            for (i = [1:2]) {
                translate([i * forearm_length/4, 0, -1])
                    hull() {
                        translate([-6, 0, 0]) cylinder(d=10, h=forearm_thick+2);
                        translate([ 6, 0, 0]) cylinder(d=10, h=forearm_thick+2);
                    }
            }
        }

        // Fixed jaw
        translate([forearm_length - jaw_width/2,
                   forearm_width/2 + 2, 0])
            cube([jaw_width, jaw_length, jaw_thick]);
    }

    // Moving jaw (poseable)
    color("Tomato")
        translate([forearm_length, -(forearm_width/2 + 2), 0])
            rotate([0, 0, -gripper_open])
                translate([-jaw_width/2, -jaw_length, 0])
                    cube([jaw_width, jaw_length, jaw_thick]);
}

module printed_iphone_mount() {
    color("DarkSlateGray") {
        // Base plate
        translate([-mount_plate_w/2, -mount_plate_d/2, 0])
            hull() {
                for (x = [3, mount_plate_w-3])
                    for (y = [3, mount_plate_d-3])
                        translate([x, y, 0])
                            cylinder(r=3, h=mount_plate_h);
            }

        // Post
        translate([-post_width/2, -post_depth/2, mount_plate_h])
            cube([post_width, post_depth, post_height]);

        // Gussets
        for (side = [-1, 1])
            translate([side * post_width/2, 0, mount_plate_h])
                rotate([0, side * -90, 0])
                    linear_extrude(4, center=true)
                        polygon([[0, -post_depth/2], [0, post_depth/2], [25, 0]]);
    }

    // Cradle at top of post
    cradle_w = phone_w + cradle_tol * 2;
    cradle_h = phone_h + cradle_tol;

    color("ForestGreen")
        translate([0, 0, mount_plate_h + post_height])
            rotate([tilt_angle, 0, 0]) {
                // Back wall
                translate([-cradle_w/2 - 4, -3, -4])
                    cube([cradle_w + 8, 3, cradle_h + 12]);

                // Bottom shelf
                translate([-cradle_w/2 - 4, -3, -4])
                    cube([cradle_w + 8, phone_d + cradle_tol*2 + 7, 9]);

                // Left wall
                translate([-cradle_w/2 - 4, -3, -4])
                    cube([4, phone_d + cradle_tol*2 + 12, cradle_h + 12]);

                // Right wall + spring jaw block
                translate([cradle_w/2, -3, -4])
                    cube([12, phone_d + cradle_tol*2 + 7, cradle_h + 12]);
            }
}


// ===================== PCA9685 PWM DRIVER =========================

module pca9685_board() {
    // PCA9685 16-channel PWM/Servo driver board
    // Origin at center of PCB

    pca_l = 62.0;
    pca_w = 25.5;
    pca_h = 1.6;

    // PCB
    color("DarkBlue") {
        translate([-pca_l/2, -pca_w/2, 0])
            cube([pca_l, pca_w, pca_h]);
    }

    // Servo pin headers (3-pin rows along long edge)
    color("Black")
        translate([-pca_l/2 + 2, -pca_w/2 + 1, pca_h])
            cube([pca_l - 8, 7.62, 2.5]);

    // IC chip
    color("DimGray")
        translate([0, 2, pca_h])
            cube([8, 8, 1.5], center=true);

    // Screw terminals
    color("DodgerBlue") {
        translate([-pca_l/2 + 2, pca_w/2 - 6, pca_h])
            cube([8, 5, 5]);
    }

    // Capacitor
    color("DarkGoldenrod")
        translate([10, 5, pca_h])
            cylinder(d=6, h=7);

    // Label
    color("White")
        translate([-12, -2, pca_h + 0.1])
            linear_extrude(0.2)
                text("PCA9685", size=3, font="Liberation Sans:style=Bold");
}


// ===================== WIRING (simplified) ========================

module wire_bundle(start, end, d=2) {
    color("DarkSlateGray", 0.6)
        hull() {
            translate(start) sphere(d=d);
            translate(end) sphere(d=d);
        }
}


// ===================== FULL ASSEMBLY =============================

// --- Base ---
printed_base_torso();

// --- Shoulder servo (in pillar) ---
// Servo mounted on its side in pillar, shaft exits toward -Y
translate([shoulder_x,
           shoulder_y,
           shoulder_z])
    rotate([90, 0, 0])  // shaft points toward -Y (exits through pillar wall)
        mg996r_servo();

// --- Upper arm (attached to shoulder horn) ---
// Pivots around shoulder servo shaft
translate([shoulder_x,
           shoulder_y - mg_body_h/2 - mg_shaft_h - mg_horn_h + 1,
           shoulder_z])
    rotate([0, -shoulder_angle, 0])  // shoulder rotation in XZ plane
        translate([0, 0, -arm_thickness/2]) {
            printed_upper_arm();

            // --- Elbow servo (in upper arm pocket) ---
            translate([arm_length, 0, arm_thickness/2])
                rotate([90, 0, 0])
                    mg996r_servo();

            // --- Forearm (attached to elbow horn) ---
            translate([arm_length,
                       -(mg_body_h/2 + mg_shaft_h + mg_horn_h - 1),
                       arm_thickness/2])
                rotate([0, -elbow_angle, 0])
                    translate([0, 0, -forearm_thick/2]) {
                        printed_forearm_gripper();

                        // --- SG90 gripper servo ---
                        translate([forearm_length, 0, forearm_thick/2])
                            rotate([90, 0, 0])
                                sg90_servo();
                    }
        }

// --- iPhone mount (behind the arm) ---
translate([base_length/2 + 40,
           base_width/2,
           0]) {
    printed_iphone_mount();

    // iPhone in the cradle
    translate([0, 0, mount_plate_h + post_height])
        rotate([tilt_angle, 0, 0])
            translate([0, phone_d/2 + cradle_tol + 2, phone_h/2 + cradle_tol])
                iphone_17_pro();
}

// --- ESP32 DevKit (mounted on base plate, near back) ---
translate([base_length/2 + 40,
           base_width/2 - 30,
           base_height + esp_pin_h + esp_pcb_h])
    rotate([0, 0, 90])
        esp32_devkit();

// --- PCA9685 PWM driver (near ESP32) ---
translate([base_length/2 + 40,
           base_width/2 + 25,
           base_height + 3])
    rotate([0, 0, 90])
        pca9685_board();

// --- Simplified wiring ---
// BLE antenna area indicator
color("Cyan", 0.3)
    translate([base_length/2 + 40 + esp_pcb_l/4,
               base_width/2 - 30,
               base_height + esp_pin_h + esp_pcb_h + 8])
        sphere(d=15);

// Wire hints (servo to PCA9685)
wire_bundle(
    [shoulder_x + 15, shoulder_y, shoulder_z - 10],
    [base_length/2 + 40, base_width/2 + 25, base_height + 8]
);

wire_bundle(
    [base_length/2 + 40, base_width/2 + 25, base_height + 8],
    [base_length/2 + 40, base_width/2 - 30, base_height + esp_pin_h + esp_pcb_h]
);


// ===================== ANNOTATIONS ================================

// Floor / workspace surface reference
color("BurlyWood", 0.15)
    translate([-50, -50, -1])
        cube([300, 250, 1]);

// Workspace area indicator
color("LimeGreen", 0.08)
    translate([shoulder_x, shoulder_y, 0])
        cylinder(r=arm_length + forearm_length - 30, h=0.5);
