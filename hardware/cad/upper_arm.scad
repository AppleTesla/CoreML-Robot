// =============================================================
// CoreML-Robot: Upper Arm Link
// =============================================================
// Connects the shoulder servo horn to the elbow servo.
// One end has a servo horn mount (bolts to the shoulder MG996R
// horn). The other end has a pocket for the elbow MG996R servo.
//
// Print: 0.2mm layer, 40% infill for strength, no supports
//        needed if printed flat on the wide face.
// =============================================================

$fn = 60;

// --- Parametric dimensions (mm) ---

// Arm link
arm_length    = 150;  // center-to-center between shoulder and elbow
arm_width     = 28;
arm_thickness = 12;
arm_fillet    = 4;

// MG996R servo horn (the star/disc that comes with the servo)
// Standard MG996R round horn: ~21mm diameter, center hole ~6mm
horn_screw_circle_d = 15;  // diameter of screw circle on horn
horn_center_hole_d  = 7.5; // clearance for center screw
horn_screw_d        = 2.2; // M2 self-tap holes
horn_screw_count    = 4;

// MG996R servo body pocket at elbow end
servo_body_l  = 40.7;
servo_body_w  = 19.7;
servo_body_h  = 36.0;
servo_tab_w   = 8.0;
servo_tab_t   = 2.5;
servo_shaft_offset = 10.0;

servo_pocket_l = servo_body_l + 0.6;
servo_pocket_w = servo_body_w + 0.6;
servo_pocket_h = servo_body_h + 1.0;

// Bolt holes for clamping the elbow servo
servo_screw_d = 3.2;  // M3

// Lightening holes to reduce weight
lighten_hole_d = 12;
lighten_count  = 3;

module arm_body() {
    hull() {
        // Shoulder end (rounded)
        translate([0, 0, 0])
            cylinder(d=arm_width, h=arm_thickness);
        // Elbow end (rounded)
        translate([arm_length, 0, 0])
            cylinder(d=arm_width, h=arm_thickness);
    }
}

module horn_mount_holes() {
    // Center hole for servo horn screw
    translate([0, 0, -1])
        cylinder(d=horn_center_hole_d, h=arm_thickness + 2);

    // Screw holes matching the servo horn
    for (i = [0:horn_screw_count-1]) {
        angle = i * 360 / horn_screw_count + 45;
        translate([cos(angle) * horn_screw_circle_d/2,
                   sin(angle) * horn_screw_circle_d/2,
                   -1])
            cylinder(d=horn_screw_d, h=arm_thickness + 2);
    }
}

module elbow_servo_pocket() {
    // The servo sits perpendicular to the arm at the elbow end,
    // with its shaft pointing sideways (same plane as shoulder).

    translate([arm_length, 0, 0]) {
        // Main servo body pocket (through the arm thickness)
        translate([-servo_pocket_l/2, -servo_pocket_w/2, -1])
            cube([servo_pocket_l, servo_pocket_w, arm_thickness + 2]);

        // Tab relief slots on both sides
        translate([-(servo_pocket_l/2 + servo_tab_w), -servo_pocket_w/2, arm_thickness/2 - servo_tab_t/2])
            cube([servo_pocket_l + 2*servo_tab_w, servo_pocket_w, servo_tab_t + 0.3]);

        // Shaft exit hole
        translate([servo_shaft_offset - servo_pocket_l/2, 0, -1])
            cylinder(d=12, h=arm_thickness + 2);
    }
}

module elbow_mount_plate() {
    // Wider area around the elbow for servo mounting
    translate([arm_length, 0, 0])
        hull() {
            translate([-servo_pocket_l/2 - 6, -servo_pocket_w/2 - 5, 0])
                cylinder(r=2, h=arm_thickness);
            translate([servo_pocket_l/2 + 6, -servo_pocket_w/2 - 5, 0])
                cylinder(r=2, h=arm_thickness);
            translate([-servo_pocket_l/2 - 6, servo_pocket_w/2 + 5, 0])
                cylinder(r=2, h=arm_thickness);
            translate([servo_pocket_l/2 + 6, servo_pocket_w/2 + 5, 0])
                cylinder(r=2, h=arm_thickness);
        }
}

module elbow_screw_holes() {
    // M3 screws through the side walls to clamp servo tabs
    translate([arm_length, 0, 0]) {
        for (x_off = [-servo_pocket_l/2 - 3,
                       servo_pocket_l/2 + 3]) {
            translate([x_off, 0, arm_thickness/2])
                rotate([90, 0, 0])
                    cylinder(d=servo_screw_d, h=arm_width + 20, center=true);
        }
    }
}

module lightening_holes() {
    // Oval holes along the arm span to save plastic and weight
    spacing = arm_length / (lighten_count + 1);
    for (i = [1:lighten_count]) {
        translate([i * spacing, 0, -1])
            hull() {
                translate([-8, 0, 0]) cylinder(d=lighten_hole_d, h=arm_thickness + 2);
                translate([ 8, 0, 0]) cylinder(d=lighten_hole_d, h=arm_thickness + 2);
            }
    }
}

// --- Assemble ---
color("DodgerBlue")
difference() {
    union() {
        arm_body();
        elbow_mount_plate();
    }

    horn_mount_holes();
    elbow_servo_pocket();
    elbow_screw_holes();
    lightening_holes();
}
