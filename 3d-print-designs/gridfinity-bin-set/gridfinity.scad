// =====================================================================
//  GRIDFINITY core — spec-exact foot + baseplate (42mm grid)
//  Reusable: `use <gridfinity.scad>` then call gf_base()/gf_baseplate().
//  Profile: 0.8 chamfer / 1.8 straight / 2.15 chamfer = 4.75mm foot.
// =====================================================================

GF      = 42;        // grid pitch
GF_CLR  = 0.5;       // bin footprint = GF*u - GF_CLR  (0.25 per side)
GF_R    = 4;         // outer corner radius
F1 = 0.8; F2 = 1.8; F3 = 2.15;        // chamfer / straight / chamfer
GF_FOOT = F1 + F2 + F3;               // 4.75
$fn = 40;

// rounded square, centered
module gf_rr(w, d, r) offset(r=max(0.4, r)) square([max(0.2, w-2*r), max(0.2, d-2*r)], center=true);

// one 1x1 foot (solid), optional `clr` enlarges it (used to cut baseplate sockets)
module gf_foot_1u(clr=0) {
  w  = GF - GF_CLR + 2*clr;
  wt = w - 2*F3;            // straight-section width
  wb = wt - 2*F1;          // bottom width
  rt = GF_R + clr;
  // bottom chamfer
  hull() {
    linear_extrude(0.01) gf_rr(wb, wb, rt-F3-F1);
    translate([0,0,F1]) linear_extrude(0.01) gf_rr(wt, wt, rt-F3);
  }
  // straight
  translate([0,0,F1]) linear_extrude(F2) gf_rr(wt, wt, rt-F3);
  // top chamfer
  hull() {
    translate([0,0,F1+F2])   linear_extrude(0.01) gf_rr(wt, wt, rt-F3);
    translate([0,0,GF_FOOT]) linear_extrude(0.01) gf_rr(w,  w,  rt);
  }
}

// bin BASE for a ux x uy bin: the feet + the floor plate they join into.
// Build your bin body on top, starting at z = GF_FOOT.
module gf_base(ux, uy, floor=1.2) {
  for (i=[0:ux-1], j=[0:uy-1])
    translate([(i-(ux-1)/2)*GF, (j-(uy-1)/2)*GF, 0]) gf_foot_1u();
  // floor plate joining the feet
  translate([0,0,GF_FOOT-0.01])
    linear_extrude(floor+0.01) gf_rr(ux*GF-GF_CLR, uy*GF-GF_CLR, GF_R);
}

// BASEPLATE of nx x ny cells (sockets the feet drop into). socket_clr = fit gap.
module gf_baseplate(nx, ny, socket_clr=0.25, wall=1.6) {
  H = GF_FOOT + 0.6;
  difference() {
    linear_extrude(H) gf_rr(nx*GF, ny*GF, GF_R);     // full-pitch slab (tiles butt together)
    for (i=[0:nx-1], j=[0:ny-1])
      translate([(i-(nx-1)/2)*GF, (j-(ny-1)/2)*GF, H-GF_FOOT])
        gf_foot_1u(socket_clr);
  }
}
