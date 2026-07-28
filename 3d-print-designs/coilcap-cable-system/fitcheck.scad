// Assembly tests for the CoilCap system.
//
// Each test renders the INTERSECTION of two mating parts in their assembled
// position. With nudge = [0,0,0] a correct fit is empty: the parts do not
// collide. Re-run with a small nudge that pushes them together and the
// intersection must become non-empty, which proves the joint actually engages
// instead of floating with a sloppy gap.
//
//   openscad -o t.stl -D 'test="box_in_plate"' -D 'nudge=[0,0,-0.4]' fitcheck.scad

use <coilcap_system.scad>

test  = "box_in_plate";
nudge = [0, 0, 0];

// foot_drop() is imported from coilcap_system.scad so it cannot drift
// out of sync with the geometry it describes.
pitch = 25;
lab_h = 18;
lab_pocket = 2.0;
socket_floor = foot_drop();

module label_in_box(u, hh, txt)
    translate(nudge + [0, -3 * pitch / 2 + lab_pocket, hh - lab_h + (lab_h - 0.4) / 2])
        rotate([90, 0, 0]) label(u, txt);

if (test == "box_in_plate")
    intersection() {
        plate(2, 3);
        translate(nudge + [0, 0, socket_floor]) box(2, 3, 40);
    }

else if (test == "box_in_tray")
    intersection() {
        tray(3, 3);
        translate(nudge + [0, 0, socket_floor]) box(3, 3, 40);
    }

else if (test == "box_on_box")
    intersection() {
        box(2, 3, 40);
        translate(nudge + [0, 0, 40]) box(2, 3, 25);
    }

else if (test == "box_on_box_wide")
    intersection() {
        box(4, 3, 25);
        translate(nudge + [0, 0, 25]) box(4, 3, 55);
    }

else if (test == "label_in_pocket")
    intersection() {
        box(2, 3, 40);
        label_in_box(2, 40, "Lightning");
    }

else if (test == "label_in_pocket_small")
    intersection() {
        box(1, 3, 25);
        label_in_box(1, 25, "USB-C");
    }

else if (test == "plate_to_plate_x")
    intersection() {
        plate(2, 3);
        translate(nudge + [2 * pitch, 0, 0]) plate(2, 3);
    }

else if (test == "plate_to_plate_y")
    intersection() {
        plate(2, 3);
        translate(nudge + [0, 3 * pitch, 0]) plate(2, 3);
    }
