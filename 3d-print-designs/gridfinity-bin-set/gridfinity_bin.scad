// =====================================================================
//  GRIDFINITY BIN  — parametric storage bin (drops into any 42mm baseplate)
//  Spec-exact base, configurable size / height / compartments + label ledge.
//  Units: mm.  Export: F6 then File > Export > STL.
// =====================================================================
include <gridfinity.scad>

/* [Size] */
ux = 2;            // grid units wide  (x · 42mm each)
uy = 1;            // grid units deep  (y · 42mm each)
uz = 4;            // height units     (z · 7mm each → 28mm here)

/* [Inside] */
compartments = 2;  // equal x-divisions (1 = single open bin)
wall   = 1.2;      // wall + divider thickness
floorT = 1.4;      // bin floor thickness
label  = true;     // thin write-on label ledge at the top front

$fn = 48;
H        = uz * 7;
base_top = GF_FOOT + floorT;
OW = ux*GF - GF_CLR;
OD = uy*GF - GF_CLR;

echo(str("Gridfinity bin ", ux, "x", uy, "x", uz, "  (", OW, " x ", OD, " x ",
         H + base_top, " mm)  · ", compartments, " compartment(s)"));

// feet + floor
gf_base(ux, uy, floor = floorT);

// outer walls (hollow)
difference() {
  translate([0,0,base_top - 0.01]) linear_extrude(H) gf_rr(OW, OD, GF_R);
  translate([0,0,base_top + 0.01]) linear_extrude(H) gf_rr(OW - 2*wall, OD - 2*wall, max(1, GF_R - wall));
}

// dividers
if (compartments > 1)
  for (i = [1 : compartments-1])
    translate([-OW/2 + i*OW/compartments - wall/2, -(OD - 2*wall)/2, base_top])
      cube([wall, OD - 2*wall, H]);

// label ledge across the top front (write on it or stick a tag)
if (label)
  translate([-(OW - 2*wall)/2, -OD/2 + wall - 0.01, base_top + H - 6])
    cube([OW - 2*wall, 6, 1.2]);
