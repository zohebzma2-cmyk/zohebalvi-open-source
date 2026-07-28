// =====================================================================
// CordCase - upright capsule cable storage
//
// An original take on the same idea as CableCap: one sealed, labelled,
// stand-up case per cable instead of an open bin. Built from scratch;
// dimensions chosen to match the same shelf/drawer use case.
//
// Sized for a FlashForge Adventurer 3C (150 x 150 x 150 mm). Note the
// 152 mm "tall" size in that product family does NOT fit a 150 mm bed -
// this system tops out at 145 mm so it prints upright without tricks.
//
//   openscad -o out.stl -D 'part="body"' -D fw=38 -D fd=63 -D h=127 cordcase.scad
// =====================================================================

/* [Part select] */
part = "body";       // body | cap | plate | label | rack
fw   = 38;           // footprint width
fd   = 63;           // footprint depth
h    = 127;          // overall height including the cap
nx   = 3;            // baseplate: sockets across

/* [Shell] */
wall     = 2.0;
floor_th = 1.6;
corner_r = 6.0;
foot_ch  = 1.0;      // 45 deg lead-in chamfer at the very bottom

/* [Cap] */
cap_h    = 16;       // how tall the contrasting cap stands
cap_wall = 2.0;
cap_skirt = 10;      // inner skirt that plugs down into the body
cap_cl   = 0.35;     // friction-fit clearance

/* [Ribs] */
// Vertical ribs cut into the long faces. Cut inward, so the footprint is
// unchanged and cases still stand shoulder to shoulder in a baseplate.
rib_d    = 0.8;
rib_r    = 2.6;
rib_gap  = 4.6;      // < chord width, so ribs run together into a fluted face

/* [Label plate] */
// A recessed panel down the front face. The printed plate drops in and is
// read bottom-to-top, the way a spine label is.
lab_w    = 13;       // plate width
lab_frac = 0.46;     // plate height as a fraction of body height
lab_deep = 1.4;      // recess depth
lab_t    = 1.0;      // plate thickness (prints this + 0.6 mm of text)
lab_cl   = 0.15;    // light interference: the plate friction-fits into the panel

/* [Drawer rack] */
// A toast-rack of leaning fins. Each capsule drops into a slot and tips back
// against the next fin, so a drawerful reads like a card index from above.
// Fins lean by rack_ang from vertical; keep that under 45 deg and every face
// stays self-supporting, so the rack prints flat on its base with no supports.
rack_ang  = 20;      // lean from vertical, degrees
rack_fin  = 2.2;     // fin thickness
rack_base = 3.0;     // base plate thickness
rack_cl   = 1.2;     // slot clearance on the capsule's across-slot dimension
rack_wall = 2.4;     // end walls
rack_fh   = 16;      // how far a divider stands above the ramp
rack_lip  = 9;       // retaining lip at the low end
slots     = 3;       // slots per tile

/* [Baseplate] */
plate_h  = 5.0;
sock_cl  = 0.4;
sock_d   = 3.0;      // how deep a case sits into the plate

$fn = 48;

// ------------------------------------------------------------ primitives

module rr(w, d, r, hh) {
    rr_ = max(min(r, w / 2 - 0.01, d / 2 - 0.01), 0.2);
    linear_extrude(hh) offset(r = rr_) square([w - 2 * rr_, d - 2 * rr_], center = true);
}

function body_h(hh) = hh - cap_h;          // the cap makes up the rest
function lab_h(hh) = body_h(hh) * lab_frac;

// Vertical fluting down the two long faces.
module ribs(w, d, z0, z1) {
    n = max(2, floor((d - 2 * corner_r) / rib_gap));
    span = d - 2 * corner_r;
    for (side = [-1, 1])
        for (i = [0:n])
            translate([side * (w / 2 + rib_r - rib_d), -span / 2 + i * span / n, z0])
                cylinder(r = rib_r, h = z1 - z0, $fn = 24);
}

// --------------------------------------------------------------- body

module body(w, d, hh) {
    bh = body_h(hh);
    lh = lab_h(hh);
    difference() {
        // outer shell with a chamfered foot
        union() {
            hull() {
                translate([0, 0, 0]) rr(w - 2 * foot_ch, d - 2 * foot_ch, corner_r - foot_ch, 0.01);
                translate([0, 0, foot_ch]) rr(w, d, corner_r, 0.01);
            }
            translate([0, 0, foot_ch]) rr(w, d, corner_r, bh - foot_ch);
        }
        // cavity, open at the top
        translate([0, 0, floor_th]) rr(w - 2 * wall, d - 2 * wall, corner_r - wall, bh);
        ribs(w, d, foot_ch + 2, bh - 2);
        // recessed label panel down the front face
        translate([-lab_w / 2, -d / 2 - 0.1, (bh - lh) / 2])
            cube([lab_w, lab_deep + 0.1, lh]);
    }
}

// ---------------------------------------------------------------- cap

module cap(w, d, hh) {
    skirt_o = w - 2 * wall - cap_cl;          // slides into the body mouth
    skirt_od = d - 2 * wall - cap_cl;
    difference() {
        union() {
            rr(w, d, corner_r, cap_h - 1.2);
            hull() {                          // softened crown
                translate([0, 0, cap_h - 1.2]) rr(w, d, corner_r, 0.01);
                translate([0, 0, cap_h]) rr(w - 2.4, d - 2.4, corner_r - 1.2, 0.01);
            }
            // skirt hangs below the shoulder; solid here so it welds to the crown
            translate([0, 0, -cap_skirt])
                rr(skirt_o, skirt_od, corner_r - wall, cap_skirt);
        }
        // one bore up through skirt and crown together
        translate([0, 0, -cap_skirt - 0.01])
            rr(skirt_o - 2 * cap_wall, skirt_od - 2 * cap_wall, corner_r - wall - cap_wall,
               cap_skirt + cap_h - cap_wall);
        ribs(w, d, 1.5, cap_h - 3);
    }
}

// -------------------------------------------------------------- label

// Printed flat, text raised. Reads bottom-to-top like a spine label.
module label(hh, txt) {
    lh = lab_h(hh) - lab_cl;
    lw = lab_w - lab_cl;
    tsize = (txt == "") ? 6 : min(8, (lw - 3), (lh - 6) / max(len(txt) * 0.62, 1) * 1.6);
    linear_extrude(lab_t) offset(r = 0.8) square([lw - 1.6, lh - 1.6], center = true);
    if (txt != "")
        translate([0, 0, lab_t]) linear_extrude(0.6) rotate([0, 0, 90])
            text(txt, size = tsize, halign = "center", valign = "center");
}

// ----------------------------------------------------------- baseplate

module plate(w, d, nx, ny) {
    W = nx * (w + 3) + 6;
    D = ny * (d + 3) + 6;
    difference() {
        rr(W, D, corner_r, plate_h);
        for (i = [0:nx - 1], j = [0:ny - 1])
            translate([(i - (nx - 1) / 2) * (w + 3), (j - (ny - 1) / 2) * (d + 3),
                       plate_h - sock_d])
                hull() {
                    rr(w - 2 * foot_ch + sock_cl, d - 2 * foot_ch + sock_cl,
                       corner_r - foot_ch, 0.01);
                    translate([0, 0, foot_ch])
                        rr(w + sock_cl, d + sock_cl, corner_r, sock_d);
                }
    }
}

// --------------------------------------------------------- drawer rack

// An inclined tray: the floor ramps up at rack_ang, vertical dividers run UP
// the slope, and a lip at the low end stops anything sliding out. Capsules lie
// back in the slots so their spine labels face up and out, the way a card index
// reads. The lean runs along the dividers, not across them, so slot pitch only
// has to clear the capsule's width.
//
// Every face is a ramp, a vertical wall or a 45 deg chamfer - prints flat on
// the base with no supports.
function rack_pitch(cw) = cw + rack_cl + rack_fin;
function rack_len(cw, n) = n * rack_pitch(cw) + rack_fin;
// A capsule sits square on the incline, so it leans rack_ang from vertical and
// the slope only has to be as long as its footprint - not its height.
function rack_run(cd, h) = cd + 2 * rack_wall;

module rack(cw, cd, n, h = 101) {
    L = rack_len(cw, n);
    R = rack_run(cd, h);
    rise = R * tan(rack_ang);
    difference() {
        union() {
            // ramp: a wedge rising toward the back
            hull() {
                translate([0, -R / 2 + 1, 0]) cube([L, 2, rack_base], center = true);
                translate([0, R / 2 - 1, rise / 2]) cube([L, 2, rack_base + rise], center = true);
            }
            // dividers, vertical, running up the slope
            for (i = [0:n])
                translate([-L / 2 + rack_fin / 2 + i * rack_pitch(cw), 0, 0])
                    hull() {
                        translate([0, -R / 2 + 1, 0])
                            cube([rack_fin, 2, rack_base + rack_fh * 0.45], center = true);
                        translate([0, R / 2 - 1, rise / 2])
                            cube([rack_fin, 2, rack_base + rise + rack_fh], center = true);
                    }
            // retaining lip at the low end
            translate([0, -R / 2 + rack_wall / 2, rack_base / 2 + rack_lip / 2])
                cube([L, rack_wall, rack_base + rack_lip], center = true);
        }
        translate([0, 0, -50]) cube([L * 4, R * 4, 100], center = true);
    }
}

// -------------------------------------------------------------- render

if (part == "body")       body(fw, fd, h);
else if (part == "cap")   cap(fw, fd, h);
else if (part == "plate") plate(fw, fd, nx, 1);
else if (part == "label") label(h, label_text == "" ? "USB-C" : label_text);
else if (part == "rack")  rack(fw, fd, slots, h);
