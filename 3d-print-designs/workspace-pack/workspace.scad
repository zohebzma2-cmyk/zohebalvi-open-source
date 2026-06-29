// =====================================================================
//  WORKSPACE PACK  — part = "charger_dock" | "tool_rack" | "riser_leg"
//  Units mm. No supports. (riser_leg: print 2–4, lay your own board on top.)
// =====================================================================
part = "charger_dock";
$fn = 48;

// 1. Phone charging dock: leaning rest + front lip + cable channel up the back
module charger_dock() {
  cube([46, 54, 5]);                                  // base
  translate([0, 36, 5]) rotate([12,0,0]) cube([46, 6, 48]);  // back rest (leans 12°)
  translate([0, 15, 5]) cube([46, 6, 16]);            // front lip
  translate([23, 42, 18]) rotate([90,0,0]) cylinder(h = 26, r = 4.5, center = true);  // cable channel up the back
}

// 2. Wall tool / marker rack: back plate + shelf with holes
module tool_rack(n = 5) {
  W = n*16 + 12; D = 42; backH = 72; shelfT = 9; t = 4;
  difference() {
    cube([W, t, backH]);                              // back plate
    for (z = [11, backH-11]) translate([W/2, -1, z]) rotate([-90,0,0]) cylinder(h = t+2, r = 2);  // screw holes
  }
  translate([0, t, backH - shelfT - 18]) difference() {
    cube([W, D, shelfT]);
    for (i = [0:n-1]) translate([12 + i*16, D/2 + 2, -1]) cylinder(h = shelfT+2, r = 5.5);  // tool holes
  }
}

// 3. Modular monitor-riser leg (inverted-U arch): print 2–4, span with a board
module riser_leg() {
  W = 140; D = 72; H = 88; t = 12;
  difference() {
    cube([W, D, H]);
    translate([t, -1, -1]) cube([W - 2*t, D + 2, H - t]);     // hollow out the arch (open underneath)
    translate([W/2 - 30, -1, H - t - 30]) cube([60, D+2, 30]); // soften the inner top corners
  }
}

if (part == "charger_dock")   charger_dock();
else if (part == "tool_rack") tool_rack();
else if (part == "riser_leg") riser_leg();
