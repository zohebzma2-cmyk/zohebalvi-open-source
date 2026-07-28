// =====================================================================
// CordCase -> Gridfinity adapter
//
// Gridfinity feet underneath, CordCase sockets on top, so a capsule drops
// into any standard 42 mm Gridfinity baseplate. The foot comes from the
// spec-exact gf_foot_1u() in gridfinity.scad (0.8 / 1.8 / 2.15 = 4.75 mm),
// so this is consistent with the Gridfinity parts already in the library
// rather than a second, hand-rolled reading of the spec.
// =====================================================================
use <gridfinity.scad>
use <cordcase.scad>

GF = 42;
part = "adapter";
gx = 1;              // Gridfinity units across
gy = 2;              // Gridfinity units deep
fw = 38;             // capsule footprint
fd = 63;
sock_d = 4.0;        // how deep the capsule sits in
sock_cl = 0.5;
foot_ch = 1.0;
wall = 2.4;
corner_r = 6.0;

module rr(w, d, r, h) {
    r_ = max(min(r, w/2 - 0.01, d/2 - 0.01), 0.2);
    linear_extrude(h) offset(r = r_) square([w - 2*r_, d - 2*r_], center = true);
}

module gf_adapter(nx, ny, cw, cd) {
    W = nx * GF; D = ny * GF;
    H = 4.75 + sock_d + 1.6;                 // foot + socket + floor under it
    difference() {
        union() {
            translate([0, 0, 4.75]) rr(W, D, corner_r, H - 4.75);
            for (i = [0:nx-1], j = [0:ny-1])
                translate([(i-(nx-1)/2)*GF, (j-(ny-1)/2)*GF, 0]) gf_foot_1u(0);
        }
        // capsule socket, chamfered so it self-centres
        translate([0, 0, H - sock_d])
            hull() {
                // true offset: radius grows with the edge, so corners are no
                // looser than the flats
                rr(cw - 2*foot_ch + sock_cl, cd - 2*foot_ch + sock_cl,
                   corner_r - foot_ch + sock_cl/2, 0.01);
                translate([0, 0, foot_ch])
                    rr(cw + sock_cl, cd + sock_cl, corner_r + sock_cl/2, sock_d);
            }
    }
}

if (part == "adapter") gf_adapter(gx, gy, fw, fd);
