// =============================================================
// CoreML-Robot: Base / Torso
// =============================================================
// A weighted base plate with an upright pillar that holds the
// shoulder MG996R servo. The servo is mounted on its side so
// the output shaft points sideways (planar 2-link arm).
//
// Print: 0.2mm layer, 20% infill, no supports needed.
//        Flat on the bottom (large plate down).
// =============================================================

$fn = 60;

// --- Parametric dimensions (mm) ---

// MG996R servo body (without tabs)
servo_body_l  = 40.7;
servo_body_w  = 19.7;
servo_body_h  = 36.0;  // body only, no shaft
servo_tab_w   = 8.0;   // width of each mounting tab
servo_tab_t   = 2.5;   // tab thickness
servo_shaft_offset = 10.0; // shaft center from front face

// Base plate
base_length = 120;
base_width  = 90;
base_height = 5;
base_fillet = 3;

// Pillar (holds the servo)
pillar_width     = servo_body_w + 8; // wall around servo
pillar_depth     = servo_body_l + 8;
pillar_height    = 50;
pillar_wall      = 4;

// Mounting holes in base for table clamp / screws
mount_hole_d     = 5.2;  // M5 clearance
mount_hole_inset = 10;

// Anti-tip weight pocket (fill with coins/washers after print)
weight_pocket_l = 50;
weight_pocket_w = 30;
weight_pocket_d = 3;  // depth into base

// Servo pocket (cut into pillar)
servo_pocket_l = servo_body_l + 0.6;  // tolerance
servo_pocket_w = servo_body_w + 0.6;
servo_pocket_h = servo_body_h + 1.0;

// Screw holes for servo tabs
servo_screw_d = 3.2; // M3 clearance

module base_plate() {
    difference() {
        // Rounded rectangle base
        hull() {
            for (x = [base_fillet, base_length - base_fillet])
                for (y = [base_fillet, base_width - base_fillet])
                    translate([x, y, 0])
                        cylinder(r=base_fillet, h=base_height);
        }

        // Corner mounting holes
        for (x = [mount_hole_inset, base_length - mount_hole_inset])
            for (y = [mount_hole_inset, base_width - mount_hole_inset])
                translate([x, y, -1])
                    cylinder(d=mount_hole_d, h=base_height + 2);

        // Weight pocket (fill with coins for stability)
        translate([base_length/2 - weight_pocket_l/2,
                   base_width/2 - weight_pocket_w/2 - 15,
                   base_height - weight_pocket_d])
            cube([weight_pocket_l, weight_pocket_w, weight_pocket_d + 1]);
    }
}

module servo_pillar() {
    translate([base_length/2 - pillar_depth/2,
               base_width/2 - pillar_width/2,
               base_height]) {
        difference() {
            // Outer pillar
            cube([pillar_depth, pillar_width, pillar_height]);

            // Servo pocket (open on top for insertion)
            translate([pillar_wall,
                       pillar_wall,
                       pillar_height - servo_pocket_h])
                cube([servo_pocket_l, servo_pocket_w, servo_pocket_h + 1]);

            // Tab slots (left and right of servo body)
            // Left tab slot
            translate([pillar_wall - servo_tab_w,
                       pillar_wall - 0.3,
                       pillar_height - servo_pocket_h - servo_tab_t])
                cube([servo_pocket_l + 2 * servo_tab_w,
                      servo_pocket_w + 0.6,
                      servo_tab_t + 0.4]);

            // Shaft exit hole (one side of pillar)
            translate([pillar_wall + servo_shaft_offset,
                       -1,
                       pillar_height - servo_pocket_h/2])
                rotate([-90, 0, 0])
                    cylinder(d=12, h=pillar_wall + 2);

            // Opposite side bearing/cap hole
            translate([pillar_wall + servo_shaft_offset,
                       pillar_width - pillar_wall - 1,
                       pillar_height - servo_pocket_h/2])
                rotate([-90, 0, 0])
                    cylinder(d=8, h=pillar_wall + 2);

            // Screw holes through pillar walls to clamp servo tabs
            for (x_off = [pillar_wall/2,
                          pillar_depth - pillar_wall/2]) {
                translate([x_off,
                           -1,
                           pillar_height - servo_pocket_h - servo_tab_t/2])
                    rotate([-90, 0, 0])
                        cylinder(d=servo_screw_d, h=pillar_width + 2);
            }

            // Wire channel out the back
            translate([pillar_depth - pillar_wall - 1,
                       pillar_width/2 - 4,
                       pillar_height - servo_pocket_h])
                cube([pillar_wall + 2, 8, 15]);
        }
    }
}

// Ribbing for strength
module support_ribs() {
    rib_t = 3;
    rib_h = 20;
    cx = base_length/2;
    cy = base_width/2;

    for (side = [-1, 1]) {
        translate([cx - pillar_depth/2,
                   cy + side * (pillar_width/2) - (side > 0 ? 0 : rib_t),
                   base_height])
            linear_extrude(height = 1)
                polygon([
                    [0, 0],
                    [0, rib_t],
                    [-rib_h, rib_t],
                    [0, 0]
                ]);

        // Triangular gussets on sides
        translate([cx - pillar_depth/2,
                   cy + side * (pillar_width/2 - 0.1),
                   base_height]) {
            rotate([90, 0, 0])
                linear_extrude(height = rib_t, center = true)
                    polygon([
                        [0, 0],
                        [0, rib_h],
                        [-rib_h * 0.7, 0]
                    ]);
        }
    }
}

// --- Assemble ---
color("SlateGray") {
    base_plate();
    servo_pillar();
    support_ribs();
}
