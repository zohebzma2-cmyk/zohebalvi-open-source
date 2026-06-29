// =====================================================================
//  DESK & CABLE ORGANIZER PACK  — print the part you need
//  Set `part`, hit F6, export STL. Units: mm. No supports.
// =====================================================================
part = "cable_comb";   // "cable_comb" | "headphone_hook" | "phone_stand"
$fn = 48;

// ---- 1. Cable comb: drop cables into the U-notches; screws to a desk edge
module cable_comb(slots = 5) {
  L = slots*10 + 8; W = 18; wallH = 12; baseT = 4; wallT = 5;
  difference() {
    union() {
      cube([L, W, baseT]);                 // base
      cube([L, wallT, wallH]);             // upright wall
    }
    // U-notches along the top of the wall
    for (i = [0:slots-1])
      translate([8 + i*10, -1, wallH]) rotate([-90,0,0]) cylinder(h = wallT+2, r = 3);
    // countersunk screw holes in the base
    for (x = [5, L-5]) translate([x, W-6, -1]) {
      cylinder(h = baseT+2, r = 1.9);
      translate([0,0,baseT-1.6]) cylinder(h = 1.8, r1 = 1.9, r2 = 3.6);
    }
  }
}

// ---- 2. Headphone hook: screws under a desk; band rests in the up-turn
module headphone_hook() {
  w = 28;
  pts = [[0,0],[0,42],[6,42],[6,6],[78,6],[78,22],[70,22],[70,0]];
  rotate([90,0,90]) linear_extrude(w) polygon(pts);   // L-profile arm, extruded to width
  // mount screw holes (through the vertical plate)
  for (z = [12, 32]) translate([w/2, 3, z]) rotate([90,0,0]) cylinder(h = 8, r = 2, center=true);
}

// ---- 3. Phone stand: base + back-leaning support + front lip + cable slot
module phone_stand() {
  w = 78; baseT = 6;
  difference() {
    union() {
      cube([w, 90, baseT]);                                  // base
      translate([0, 50, baseT]) rotate([14,0,0]) cube([w, 8, 70]); // support, leans back 14°
      translate([0, 22, baseT]) cube([w, 7, 18]);            // front lip (catches phone's bottom edge)
    }
    // cable pass-through under where the phone sits
    translate([w/2, 40, baseT]) rotate([0,90,0]) cylinder(h = w+2, r = 6, center=true);
  }
}

if (part == "cable_comb")     cable_comb();
else if (part == "headphone_hook") headphone_hook();
else if (part == "phone_stand")    phone_stand();
