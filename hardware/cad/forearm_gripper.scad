// =============================================================
// CoreML-Robot: Forearm + Gripper
// =============================================================
// Connects to the elbow servo horn. The forearm extends down
// to a simple parallel-jaw gripper driven by an SG90 servo.
// One jaw is fixed, one jaw moves via a pushrod from the servo.
//
// Print: 0.2mm layer, 40% infill.
//        Print flat on the back face, supports for gripper jaws
//        only if your slicer flags them (usually not needed).
// =============================================================

$fn = 60;

// --- Parametric dimensions (mm) ---

// Forearm link
forearm_length = 130;  // horn center to gripper pivot
forearm_width  = 24;
forearm_thick  = 10;

// MG996R horn mount (at elbow end)
horn_screw_circle_d = 15;
horn_center_hole_d  = 7.5;
horn_screw_d        = 2.2;
horn_screw_count    = 4;

// SG90 servo (gripper actuator)
sg90_body_l = 22.5;
sg90_body_w = 12.0;
sg90_body_h = 22.7;
sg90_tab_w  = 32.2;  // total width with tabs
sg90_tab_t  = 2.5;
sg90_screw_d = 2.2;  // M2 self-tap
sg90_screw_spacing = 28.0; // between tab holes

sg90_pocket_l = sg90_body_l + 0.5;
sg90_pocket_w = sg90_body_w + 0.5;

// Gripper dimensions
jaw_length   = 45;
jaw_width    = 12;
jaw_thick    = 5;
jaw_gap_max  = 70;  // maximum opening between jaws
jaw_grip_pad = 3;   // rubber pad thickness area

// Grip finger serrations
serration_count = 5;
serration_depth = 0.8;
serration_spacing = 5;

// Pushrod linkage
pushrod_hole_d = 2.5;
pushrod_arm    = 12;

module forearm_body() {
    hull() {
        // Elbow end (horn mount)
        translate([0, 0, 0])
            cylinder(d=forearm_width, h=forearm_thick);
        // Gripper end
        translate([forearm_length, 0, 0])
            cylinder(d=forearm_width + 6, h=forearm_thick);
    }
}

module horn_mount_holes() {
    translate([0, 0, -1]) {
        cylinder(d=horn_center_hole_d, h=forearm_thick + 2);
        for (i = [0:horn_screw_count-1]) {
            angle = i * 360 / horn_screw_count + 45;
            translate([cos(angle) * horn_screw_circle_d/2,
                       sin(angle) * horn_screw_circle_d/2, 0])
                cylinder(d=horn_screw_d, h=forearm_thick + 2);
        }
    }
}

module sg90_pocket() {
    // SG90 sits at the gripper end, shaft pointing down toward jaws
    translate([forearm_length, 0, 0]) {
        // Body pocket
        translate([-sg90_pocket_l/2, -sg90_pocket_w/2, -1])
            cube([sg90_pocket_l, sg90_pocket_w, forearm_thick + 2]);

        // Tab slots
        translate([-sg90_tab_w/2, -sg90_pocket_w/2, forearm_thick/2 - sg90_tab_t/2])
            cube([sg90_tab_w, sg90_pocket_w, sg90_tab_t + 0.3]);

        // Tab screw holes
        for (x_off = [-sg90_screw_spacing/2, sg90_screw_spacing/2])
            translate([x_off, 0, -1])
                cylinder(d=sg90_screw_d, h=forearm_thick + 2);
    }
}

module lightening_holes() {
    spacing = forearm_length / 4;
    for (i = [1:2]) {
        translate([i * spacing, 0, -1])
            hull() {
                translate([-6, 0, 0]) cylinder(d=10, h=forearm_thick + 2);
                translate([ 6, 0, 0]) cylinder(d=10, h=forearm_thick + 2);
            }
    }
}

// --- Gripper Jaws ---

module fixed_jaw() {
    // Fixed jaw extends down-right from the gripper mount
    translate([forearm_length - jaw_width/2,
               forearm_width/2 + 2,
               0]) {
        difference() {
            cube([jaw_width, jaw_length, jaw_thick]);

            // Grip serrations on inner face
            for (i = [0:serration_count-1])
                translate([-1,
                           jaw_length - 8 - i * serration_spacing,
                           jaw_thick/2])
                    rotate([0, 90, 0])
                        cylinder(d=serration_depth*2, h=jaw_width + 2, $fn=4);
        }
    }
}

module moving_jaw() {
    // Moving jaw on the opposite side, pivots on a pin
    pivot_x = forearm_length;
    pivot_y = -(forearm_width/2 + 2);

    translate([pivot_x - jaw_width/2, pivot_y - jaw_length, 0]) {
        difference() {
            union() {
                // Jaw body
                cube([jaw_width, jaw_length, jaw_thick]);

                // Pivot boss at top
                translate([jaw_width/2, jaw_length, jaw_thick/2])
                    rotate([0, 0, 0])
                        cylinder(d=jaw_width, h=jaw_thick, center=true);

                // Pushrod arm extending back toward servo
                translate([jaw_width/2, jaw_length, 0])
                    hull() {
                        cylinder(d=8, h=jaw_thick);
                        translate([-pushrod_arm, 5, 0])
                            cylinder(d=6, h=jaw_thick);
                    }
            }

            // Pivot hole
            translate([jaw_width/2, jaw_length, -1])
                cylinder(d=3.2, h=jaw_thick + 2);

            // Pushrod hole
            translate([jaw_width/2 - pushrod_arm, jaw_length + 5, -1])
                cylinder(d=pushrod_hole_d, h=jaw_thick + 2);

            // Grip serrations
            for (i = [0:serration_count-1])
                translate([-1, jaw_length - 8 - i * serration_spacing, jaw_thick/2])
                    rotate([0, 90, 0])
                        cylinder(d=serration_depth*2, h=jaw_width + 2, $fn=4);
        }
    }
}

module jaw_pivot_post() {
    // Fixed pivot post for the moving jaw
    translate([forearm_length,
               -(forearm_width/2 + 2),
               0]) {
        difference() {
            cylinder(d=jaw_width + 4, h=forearm_thick);
            translate([0, 0, -1])
                cylinder(d=3.2, h=forearm_thick + 2);
        }
    }
}

// --- Assemble ---
color("OrangeRed") {
    difference() {
        union() {
            forearm_body();
            fixed_jaw();
            jaw_pivot_post();
        }
        horn_mount_holes();
        sg90_pocket();
        lightening_holes();
    }

    // Moving jaw printed separately (comment out to export forearm only)
    // Uncomment to preview assembly:
    // color("Tomato", 0.7) moving_jaw();
}

// === MOVING JAW (export separately) ===
// Translate away for independent export
translate([0, -60, 0])
    color("Tomato") moving_jaw();
