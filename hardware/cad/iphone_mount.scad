// =============================================================
// CoreML-Robot: iPhone 17 Pro Mount (Head)
// =============================================================
// Spring-loaded cradle that holds the iPhone horizontally
// (landscape). A fixed L-shelf on one side and a flexure-spring
// jaw on the other clamp the phone. The phone slides in from
// the top against the spring jaw.
//
// Mounts on a post above and behind the robot arm so the rear
// camera has a clear view of the workspace.
//
// Print: 0.2mm layer, 40% infill.
//        Print upright (post vertical). No supports needed.
//        The flex spring should be printed in PETG or PLA+
//        for fatigue resistance. Regular PLA works but the
//        spring may weaken over many cycles.
// =============================================================

$fn = 60;

// --- iPhone 17 Pro dimensions (landscape orientation) ---
// Width in landscape = phone height, Height in landscape = phone width
phone_w     = 150.0;  // iPhone 17 Pro height (now horizontal span)
phone_h     = 72.0;   // iPhone 17 Pro width (now vertical span)
phone_d     = 8.5;    // thickness (with slight tolerance for thin case)
tolerance   = 1.5;    // extra room on each side

// Cradle internal dimensions
cradle_w = phone_w + tolerance * 2;  // horizontal opening
cradle_h = phone_h + tolerance;      // vertical depth (open top)
cradle_d = phone_d + tolerance * 2;  // thickness slot

// Cradle structure
wall         = 4.0;
lip          = 8.0;   // how far the front lip extends over the phone face
bottom_shelf = 5.0;   // ledge the phone rests on
back_wall    = 3.0;   // wall behind the phone

// Flex spring jaw
spring_arm_count  = 3;     // number of parallel spring fingers
spring_arm_w      = 6.0;   // width of each finger
spring_arm_t      = 1.6;   // thickness (controls spring force)
spring_arm_l      = 50.0;  // length of flex arm (longer = softer)
spring_travel     = 8.0;   // how far the spring compresses
spring_gap        = 2.0;   // gap between fingers

// Post (connects to base)
post_height  = 120;  // tall enough to look over the arm
post_width   = 20;
post_depth   = 20;

// Base mount plate (screws to the robot base)
mount_plate_w = 60;
mount_plate_d = 40;
mount_plate_h = 5;
mount_hole_d  = 5.2;  // M5

// Tilt angle (camera looks down at workspace)
tilt_angle = 50;  // degrees from vertical


// ==================== MODULES ====================

module mount_base_plate() {
    difference() {
        // Plate
        translate([-mount_plate_w/2, -mount_plate_d/2, 0])
            hull() {
                for (x = [3, mount_plate_w - 3])
                    for (y = [3, mount_plate_d - 3])
                        translate([x, y, 0])
                            cylinder(r=3, h=mount_plate_h);
            }

        // Mounting holes
        for (x = [-mount_plate_w/2 + 8, mount_plate_w/2 - 8])
            for (y = [-mount_plate_d/2 + 8, mount_plate_d/2 - 8])
                translate([x, y, -1])
                    cylinder(d=mount_hole_d, h=mount_plate_h + 2);
    }
}

module post() {
    translate([-post_width/2, -post_depth/2, mount_plate_h])
        cube([post_width, post_depth, post_height]);

    // Gussets at base of post for rigidity
    gusset_h = 25;
    for (side = [-1, 1]) {
        translate([side * post_width/2, 0, mount_plate_h])
            rotate([0, side * -90, 0])
                linear_extrude(height=wall)
                    polygon([[0, -post_depth/2],
                             [0, post_depth/2],
                             [gusset_h, 0]]);
    }
}

module phone_cradle() {
    // Positioned at top of post, tilted forward
    translate([0, 0, mount_plate_h + post_height])
    rotate([tilt_angle, 0, 0]) {
        difference() {
            union() {
                // Back wall
                translate([-cradle_w/2 - wall, -back_wall, -wall])
                    cube([cradle_w + 2*wall, back_wall, cradle_h + wall + lip]);

                // Bottom shelf
                translate([-cradle_w/2 - wall, -back_wall, -wall])
                    cube([cradle_w + 2*wall, back_wall + cradle_d + wall, bottom_shelf + wall]);

                // Fixed side wall (left)
                translate([-cradle_w/2 - wall, -back_wall, -wall])
                    cube([wall, back_wall + cradle_d + lip, cradle_h + wall + lip]);

                // Front lip (bottom part, holds phone from falling forward)
                translate([-cradle_w/2 - wall, cradle_d, -wall])
                    cube([cradle_w + 2*wall, wall, bottom_shelf + wall + 6]);
            }

            // Camera cutout in back wall (for rear cameras)
            translate([-35, -back_wall - 1, cradle_h/2 - 15])
                cube([70, back_wall + 2, 30]);

            // Charging port cutout in bottom shelf
            translate([-10, 0, -wall - 1])
                cube([20, cradle_d, wall + 2]);
        }

        // Spring jaw (right side) — clamping mechanism
        translate([cradle_w/2, 0, 0])
            spring_jaw();
    }
}

module spring_jaw() {
    // The spring jaw is a set of cantilevered flex arms that push
    // inward against the phone. They bend outward when the phone
    // is inserted, providing clamping force.

    total_spring_h = spring_arm_count * spring_arm_w +
                     (spring_arm_count - 1) * spring_gap;
    start_z = (cradle_h - total_spring_h) / 2;

    // Anchor block (fixed to cradle)
    translate([0, -back_wall, -wall])
        cube([wall + spring_travel, back_wall + cradle_d + wall, cradle_h + wall + lip]);

    // Flex spring fingers
    for (i = [0:spring_arm_count - 1]) {
        z = start_z + i * (spring_arm_w + spring_gap);

        // Each finger is a U-shaped cantilever:
        // anchored at the right wall, curves back left to press on phone
        translate([0, cradle_d + wall, z])
            spring_finger(z);
    }

    // Contact bar (connects all finger tips for even pressure)
    translate([-(spring_travel - 2), cradle_d/2 - 2, start_z])
        cube([3, 4, total_spring_h]);
}

module spring_finger(z_pos) {
    // Single flex finger: goes from anchor, forward, then curves
    // back to create a spring that pushes inward.
    //
    // Geometry (top view, X = left-right, Y = front-back):
    //   Anchor (right) → extends forward → bends left → tip pushes on phone

    // Outward arm (along Y, from anchor toward front)
    translate([0, -cradle_d - wall, 0])
        cube([spring_arm_t, spring_arm_l, spring_arm_w]);

    // Return arm (comes back inward, creating the spring)
    translate([-(spring_travel - 2), -cradle_d - wall, 0])
        cube([spring_arm_t, spring_arm_l, spring_arm_w]);

    // Connecting bridge at the far end
    translate([-(spring_travel - 2), -cradle_d - wall + spring_arm_l - spring_arm_t, 0])
        cube([spring_travel, spring_arm_t, spring_arm_w]);
}


// ==================== ASSEMBLY ====================

color("DarkSlateGray") {
    mount_base_plate();
    post();
}

color("ForestGreen") {
    phone_cradle();
}
