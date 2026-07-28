// =====================================================================
// CoilCap - complete modular cable storage system
// Original clean-room design. Sized for FlashForge Adventurer 3C
// (150 x 150 x 150 mm build volume, 0.4 mm nozzle).
//
// Every feature is self-supporting: no overhang shallower than 45 deg,
// so nothing in this system needs support material.
//
// Render one part:
//   openscad -o out.stl -D 'part="box"' -D ux=2 -D h=40 coilcap_system.scad
// =====================================================================

/* [Part select] */
part = "box";        // box | label | plate | wallplate | tray
ux   = 2;            // width in grid units (1..5)
uy   = 3;            // depth in grid units (3 = 75 mm, the standard)
h    = 40;           // box height: 25 short, 40 standard, 55 tall
label_text = "";     // text for part="label"

/* [System geometry] */
pitch      = 25;     // grid pitch
wall       = 2.8;    // side + back wall
front_wall = 4.4;    // front wall, thicker to host the flush label pocket
floor_th   = 1.6;    // floor
corner_r   = 4.0;    // outer corner radius
// Three-stage foot: a straight section that locates in the baseplate bore,
// then a 45 deg ramp out to full size. The gaps between the per-cell feet are
// what the baseplate's webs sit in, so a multi-cell box drops flat onto a grid.
foot_inset = 1.0;    // how far the foot is inset from the outer wall
foot_str   = 1.2;    // straight (vertical) section at the very bottom
foot_ramp  = 1.0;    // 45 deg ramp out to full width
mouth_ch   = 0.8;    // outward chamfer at the top of the wall

// stacking engagement = (wall - mouth_ch) - foot_inset = 1.0 mm

/* [Label pocket] */
// Pocket sunk into the thick front wall, open at the front and at the top.
// Two lips at the left and right edges retain the card; the middle of the
// card stays exposed so you can read it and slide it out with a fingertip.
lab_pocket = 2.0;    // pocket depth into the front wall
lab_card   = 1.0;    // card thickness (prints this thick + 0.6 mm of text)
lab_lip_w  = 2.0;    // retaining lip width at each edge
lab_lip_t  = 0.8;    // lip thickness = how far the card sits recessed
lab_h      = 18;     // pocket height
lab_margin = 4;      // side margin on the front face

/* [Baseplate] */
plate_h     = 5.0;   // >= foot_str + foot_ramp + a solid floor under the socket
socket_cl   = 0.25;  // fit clearance, total across the socket
dt_len  = 4;         // dovetail that joins plates edge to edge
dt_neck = 4;
dt_head = 6;
dt_cl   = 0.35;

/* [Tray / wall mount] */
tray_wall = 2.4;
tray_rim  = 12;
flange    = 14;      // wall-mount flange depth
screw_d   = 4.5;
screw_head = 8.6;

$fn = 48;

// ------------------------------------------------------------ primitives

module rr(w, d, r, hh) {
    rr_ = max(min(r, w / 2 - 0.01, d / 2 - 0.01), 0.2);
    linear_extrude(hh) offset(r = rr_) square([w - 2 * rr_, d - 2 * rr_], center = true);
}

module dovetail_2d(neck, head, len) {
    polygon([[0, -neck / 2], [len, -head / 2], [len, head / 2], [0, neck / 2]]);
}

// ------------------------------------------------------------------- box

foot_h = foot_str + foot_ramp;

module feet(nx, ny) {
    fw = pitch - 2 * foot_inset;
    for (i = [0:nx - 1], j = [0:ny - 1])
        translate([(i - (nx - 1) / 2) * pitch, (j - (ny - 1) / 2) * pitch, 0]) {
            rr(fw, fw, corner_r - foot_inset, foot_str);
            hull() {
                translate([0, 0, foot_str]) rr(fw, fw, corner_r - foot_inset, 0.01);
                translate([0, 0, foot_h]) rr(pitch, pitch, corner_r, 0.01);
            }
        }
}

function label_width(W) = min(W - 2 * lab_margin, 60);

module box(nx, ny, hh) {
    W = nx * pitch;
    D = ny * pitch;
    cav_d = D - wall - front_wall;          // cavity is pushed back off the front wall
    cav_y = (front_wall - wall) / 2;
    cav_z = foot_h + floor_th;              // floor sits on top of the feet, not through them
    lw = label_width(W);
    union() {
        difference() {
            union() {
                feet(nx, ny);
                translate([0, 0, foot_h]) rr(W, D, corner_r, hh - foot_h);
            }
            // cavity, with an outward chamfer at the mouth that catches the foot above
            hull() {
                translate([0, cav_y, cav_z])
                    rr(W - 2 * wall, cav_d, corner_r - wall, hh - cav_z - mouth_ch);
                translate([0, cav_y, hh - 0.01])
                    rr(W - 2 * wall + 2 * mouth_ch, cav_d + 2 * mouth_ch,
                       corner_r - wall + mouth_ch, 0.01);
            }
            // label pocket: sunk into the front wall, open at the front and top
            translate([-lw / 2, -D / 2 - 0.1, hh - lab_h])
                cube([lw, lab_pocket + 0.1, lab_h + 1]);
        }
        // retaining lips down each side of the pocket
        for (x = [-lw / 2, lw / 2 - lab_lip_w])
            translate([x, -D / 2, hh - lab_h]) cube([lab_lip_w, lab_lip_t, lab_h]);
    }
}

// ----------------------------------------------------------------- label

module label(nx, txt) {
    lw = label_width(nx * pitch) - 0.6;
    lh = lab_h - 0.4;
    t  = lab_card;
    // text has to stay clear of the retaining lips, which cover lab_lip_w
    // of the card at each end
    usable = lw - 2 * lab_lip_w - 3;
    tsize = (txt == "") ? 5 : min(6.5, usable / (len(txt) * 0.60), lh - 6);
    linear_extrude(t) offset(r = 1.0) square([lw - 2, lh - 2], center = true);
    if (txt != "")
        translate([0, 0, t])
            linear_extrude(0.6)
                text(txt, size = tsize, halign = "center", valign = "center");
}

// ------------------------------------------------------------- baseplate

// Negative of the foot: straight bore, then a chamfer that opens out to the
// plate's top surface, so nothing of the plate stands proud of the box body.
function foot_drop() = plate_h - foot_h;   // z at which a seated foot bottoms out

module socket() {
    bw = pitch - 2 * foot_inset + socket_cl;
    translate([0, 0, foot_drop()]) rr(bw, bw, corner_r - foot_inset, foot_str);
    hull() {
        translate([0, 0, plate_h - foot_ramp]) rr(bw, bw, corner_r - foot_inset, 0.01);
        translate([0, 0, plate_h - 0.01])
            rr(pitch + socket_cl, pitch + socket_cl, corner_r, 0.02);
    }
}

module plate_body(nx, ny, dt) {
    W = nx * pitch;
    D = ny * pitch;
    difference() {
        union() {
            rr(W, D, corner_r, plate_h);
            if (dt) {
                translate([W / 2, 0, 0])
                    linear_extrude(plate_h) dovetail_2d(dt_neck, dt_head, dt_len);
                translate([0, D / 2, 0]) rotate([0, 0, 90])
                    linear_extrude(plate_h) dovetail_2d(dt_neck, dt_head, dt_len);
            }
        }
        // matching slots, cut inward from the -X and -Y edges (same handedness
        // as the tails, so a neighbour's tail slides straight in)
        if (dt) {
            translate([-W / 2, 0, -0.5]) linear_extrude(plate_h + 1)
                dovetail_2d(dt_neck + dt_cl, dt_head + dt_cl, dt_len + dt_cl / 2);
            translate([0, -D / 2, -0.5]) rotate([0, 0, 90]) linear_extrude(plate_h + 1)
                dovetail_2d(dt_neck + dt_cl, dt_head + dt_cl, dt_len + dt_cl / 2);
        }
    }
}

module plate(nx, ny, dt = true) {
    difference() {
        plate_body(nx, ny, dt);
        for (i = [0:nx - 1], j = [0:ny - 1])
            translate([(i - (nx - 1) / 2) * pitch, (j - (ny - 1) / 2) * pitch, 0]) socket();
    }
}

module screw_hole() {
    translate([0, 0, -1]) cylinder(d = screw_d, h = plate_h + 2);
    translate([0, 0, plate_h - 2.2]) cylinder(d1 = screw_d, d2 = screw_head, h = 2.2);
    translate([0, 0, plate_h - 0.01]) cylinder(d = screw_head, h = 2);
}

module wallplate(nx, ny) {
    W = nx * pitch;
    D = ny * pitch;
    xs = (nx == 1) ? [0] : [-(W / 2 - screw_head), W / 2 - screw_head];
    difference() {
        union() {
            plate(nx, ny, false);
            for (s = [-1, 1])
                translate([0, s * (D + flange) / 2, 0]) rr(W, flange, corner_r, plate_h);
        }
        for (s = [-1, 1], x = xs)
            translate([x, s * (D + flange) / 2, 0]) screw_hole();
    }
}

// ------------------------------------------------------------------ tray

module tray(nx, ny) {
    W  = nx * pitch;
    D  = ny * pitch;
    ow = W + 2 * (tray_wall + 0.3);   // 0.3 mm slip clearance around the boxes
    od = D + 2 * (tray_wall + 0.3);
    difference() {
        rr(ow, od, corner_r + tray_wall, plate_h + tray_rim);
        translate([0, 0, plate_h]) rr(W + 0.6, D + 0.6, corner_r, tray_rim + 1);
        for (i = [0:nx - 1], j = [0:ny - 1])
            translate([(i - (nx - 1) / 2) * pitch, (j - (ny - 1) / 2) * pitch, 0]) socket();
    }
}

// ---------------------------------------------------------------- render

if (part == "box")            box(ux, uy, h);
else if (part == "label")     label(ux, label_text);
else if (part == "plate")     plate(ux, uy);
else if (part == "wallplate") wallplate(ux, uy);
else if (part == "tray")      tray(ux, uy);
