// =====================================================================
// CordClamp - double J-hook cable clip
//
// A large open hook at one end and a smaller opposed hook at the other, their
// centres offset so the part reads as an S, joined by a flat bar with two
// windows. You HOOK a cable over a jaw rather than snapping it through a narrow
// mouth: the crook takes the cable and the returned tip stops it lifting out.
//
// Extruded flat - every face vertical, no supports, and the layers stack
// through the thickness so a hook flexes within a layer, not across bonds.
// =====================================================================

cable_d   = 6.0;     // cable the big hook is sized for
small_f   = 0.62;    // small hook as a fraction of the big one
hook_wall = 2.4;     // hook wall thickness
open_ang  = 105;     // sector removed to form the mouth, degrees
tip_r     = 1.1;     // rounded tip of the crook
depth     = 8.0;     // extrusion
bar_w     = 5.0;     // connecting bar width
$fn = 96;

function r_i(cd) = cd/2 + 0.3;
function r_o(cd) = r_i(cd) + hook_wall;

// Solid disc for a hook; bore and mouth are cut after the bar is joined on,
// so the bar can never end up filling the bore.
module hook_solid(cd) circle(r = r_o(cd));

// Everything removed to turn that disc into an open crook.
module hook_cut(cd, ang) {
    ri = r_i(cd); ro = r_o(cd); rm = (ri + ro) / 2;
    rotate(ang) difference() {
        union() {
            circle(r = ri);                                   // bore
            polygon([[0,0],                                   // mouth sector
                     [ro*2*cos(-open_ang/2), ro*2*sin(-open_ang/2)],
                     [ro*2.4, 0],
                     [ro*2*cos(open_ang/2),  ro*2*sin(open_ang/2)]]);
        }
        for (s = [-1, 1])                                     // keep rounded tips
            translate([rm*cos(s*open_ang/2), rm*sin(s*open_ang/2)]) circle(r = hook_wall/2);
    }
}

module clamp_2d(cd) {
    cds  = cd * small_f;
    span = r_o(cd) + r_o(cds) + cd * 1.9;
    off  = r_o(cd) * 0.55;
    difference() {
        union() {
            hull() {
                translate([-span/2, -off]) circle(r = bar_w/2);
                translate([ span/2,  off]) circle(r = bar_w/2);
            }
            translate([-span/2, -off]) hook_solid(cd);
            translate([ span/2,  off]) hook_solid(cds);
        }
        translate([-span/2, -off]) hook_cut(cd,   90);   // big hook opens +Y
        translate([ span/2,  off]) hook_cut(cds, -90);   // small hook opens -Y
        for (s = [-1, 1])                                 // two windows in the bar
            translate([s * span * 0.15, s * off * 0.30])
                rotate(atan2(2*off, span))
                    square([span * 0.17, bar_w - 2.6], center = true);
    }
}

linear_extrude(depth) clamp_2d(cable_d);
