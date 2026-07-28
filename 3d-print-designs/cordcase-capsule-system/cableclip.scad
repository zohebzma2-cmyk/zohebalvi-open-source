// =====================================================================
// CordClamp - two-hook cable clip
//
// A big open hook at one end and a smaller opposed hook at the other, joined
// by a flat frame with lightening windows. Loop a cable, drop the bundle into
// the big jaw and the tail into the small one; because the jaws face opposite
// ways the loop is trapped rather than able to roll out.
//
// Extruded flat: every face vertical, no supports, and the layers stack through
// the thickness so each jaw flexes WITHIN a layer rather than across layer
// bonds - the strong direction for a part whose job is to spring.
// =====================================================================

cable_d   = 6.0;     // cable the big jaw is sized for
small_f   = 0.60;    // small jaw as a fraction of the big one
jaw_wall  = 2.2;     // jaw wall thickness
mouth     = 0.72;    // FINAL opening as a fraction of the jaw's cable, lips included
lip       = 0.7;     // retaining lip radius at each mouth tip
depth     = 8.0;     // extrusion - how wide the clip is
frame_rail = 2.4;    // frame rail thickness - slim, so the jaws stand proud
window    = 0.40;    // window length as a fraction of span - must not reach the bores
$fn = 72;

function r_i(cd) = cd/2 + 0.25;
function r_o(cd) = r_i(cd) + jaw_wall;

// Solid ring for a jaw; the bore and mouth are cut later, after the frame is
// joined on, so the frame can never end up filling the opening.
module ring_2d(cd) circle(r = r_o(cd));

// The cut that opens a jaw: bore plus a mouth facing `ang`, minus the lips.
module jaw_cut_2d(cd, ang) {
    oh = cd * mouth / 2;
    ch = oh + lip;
    ri = r_i(cd);
    difference() {
        union() {
            circle(r = ri);
            rotate(ang) translate([-ch, 0]) square([2 * ch, r_o(cd) + 1]);
        }
        // lips stay behind: they narrow the mouth to the specified opening
        rotate(ang) for (s = [-1, 1])
            translate([s * ch, sqrt(max(ri*ri - ch*ch, 0.04))]) circle(r = lip);
    }
}

module clamp_2d(cd) {
    cds = cd * small_f;
    span = r_o(cd) + r_o(cds) + cd * 2.2;     // centre to centre
    fh   = 2 * r_o(cd);                        // body as deep as the big jaw
    difference() {
        union() {
            hull() {                           // body bar between the two jaws
                translate([-span/2, 0]) square([0.01, fh], center = true);
                translate([ span/2, 0]) square([0.01, 2 * r_o(cds)], center = true);
            }
            translate([-span/2, 0]) ring_2d(cd);
            translate([ span/2, 0]) ring_2d(cds);
        }
        translate([-span/2, 0]) jaw_cut_2d(cd,   90);   // big jaw opens outward (-X)
        translate([ span/2, 0]) jaw_cut_2d(cds, -90);   // small jaw opens outward (+X)
        square([span * window, fh - 4 * frame_rail], center = true);
    }
}

linear_extrude(depth) clamp_2d(cable_d);
