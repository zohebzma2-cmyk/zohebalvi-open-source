// =====================================================================
// CordClip - print-in-place cable clip
//
// One flat piece: a central frame with two through-slots, and two ratcheted
// straps hinged off it. Coil the cable, thread each strap back through its
// slot, and the teeth catch. Prints flat with no supports; the only overhang
// is the slot ceiling, a 6 mm bridge.
//
//   openscad -o clip.stl -D strap_len=52 cableclip.scad
// =====================================================================

strap_len = 52;      // reach of each arm
strap_w   = 6.0;     // arm width
strap_t   = 1.8;     // arm thickness - thin enough to flex in PLA
frame_w   = 26;      // frame across
frame_d   = 26;      // frame deep - wide enough for the slots to sit BESIDE the arm roots
frame_t   = 5.0;     // frame thickness
slot_cl   = 0.45;    // clearance around an arm in its slot
tooth     = 1.0;     // ratchet tooth depth
tooth_p   = 3.0;     // tooth pitch
tip       = 7;       // pull tab at the end of each arm
$fn = 40;

module rr2(w, d, r) offset(r = r) square([max(w - 2*r, 0.2), max(d - 2*r, 0.2)], center = true);

// A ratcheted arm lying flat: teeth on the top face so they catch the slot lip.
module arm(len) {
    n = floor((len - tip - 6) / tooth_p);
    union() {
        linear_extrude(strap_t) rr2(len, strap_w, 1.2);
        for (i = [0:n - 1])
            translate([-len/2 + 6 + i*tooth_p, 0, strap_t - 0.01])
                linear_extrude(tooth, scale = [0.25, 1])
                    square([tooth_p * 0.75, strap_w], center = true);
        // Smooth lead-in tab: it has to pass THROUGH the slot, so it must stay
        // inside the strap's own section. Toothless, so it threads before biting.
        translate([len/2 - tip/2, 0, 0]) linear_extrude(strap_t) rr2(tip, strap_w, 1.2);
    }
}

module clip() {
    slot_h = strap_t + tooth + slot_cl;
    difference() {
        union() {
            linear_extrude(frame_t) rr2(frame_w, frame_d, 3);
            for (s = [-1, 1])
                translate([s * (frame_w/2 + strap_len/2 - 1), 0, 0]) arm(strap_len);
        }
        // two through-slots along X, one either side of the arm roots so they
        // never cut the arm off the frame
        for (s = [-1, 1])
            translate([0, s * (strap_w/2 + slot_cl + 3.6), slot_h/2 + 0.9])
                cube([frame_w + 2, strap_w + 2*slot_cl, slot_h], center = true);
    }
}

clip();
