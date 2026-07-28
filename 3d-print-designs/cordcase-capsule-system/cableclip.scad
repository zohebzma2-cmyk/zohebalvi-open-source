// =====================================================================
// CordClamp - double-ended snap clip
//
// Two open C-jaws on a common spine. Push a cable past the lips of a jaw
// and it snaps in and is held; use both ends to gather a loop, or to hold
// two runs side by side.
//
// Extruded flat, so every face is vertical: prints on its side with no
// supports and the layer lines run around the jaw, which is the strong
// direction for a part that has to spring open.
// =====================================================================

cable_d   = 6.0;     // cable the jaw is sized for
jaw_wall  = 2.2;     // jaw wall thickness
mouth     = 0.72;    // mouth opening as a fraction of cable_d - under 1 so it snaps
lip       = 0.7;     // retaining bulb at each mouth tip
depth     = 8.0;     // how wide the clip is (the extrusion)
spine_w   = 5.0;     // bar joining the two jaws
gap       = 3.0;     // clear space between the jaws
$fn = 72;

r_in  = cable_d / 2 + 0.25;
r_out = r_in + jaw_wall;
pitch = 2 * r_out + gap;

module jaw_2d() {
    difference() {
        circle(r = r_out);
        circle(r = r_in);
        // mouth, opening toward +Y like the reference
        translate([-cable_d * mouth / 2, 0]) square([cable_d * mouth, r_out + 1]);
    }
    // retaining bulbs so a seated cable cannot fall back out
    for (s = [-1, 1])
        translate([s * (cable_d * mouth / 2 + lip / 2), sqrt(max(r_in*r_in - pow(cable_d*mouth/2,2), 0.01))])
            circle(r = lip);
}

module clamp_2d() {
    for (s = [-1, 1]) translate([s * pitch / 2, 0]) jaw_2d();
    // spine joining them, with a lightening window
    difference() {
        translate([0, -r_out + spine_w / 2]) square([pitch, spine_w], center = true);
        translate([0, -r_out + spine_w / 2]) square([gap * 0.9, spine_w - 2.4], center = true);
    }
}

linear_extrude(depth) clamp_2d();
