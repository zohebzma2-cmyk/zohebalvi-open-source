// =====================================================================
//  WORKSHOP & PEGBOARD PACK  — print the part you need
//  part = "peg_hook" | "peg_bin" | "headphone_stand" | "drawer_divider"
//  Units mm. Pegboard pitch 25.4mm (1"), 1/4" holes. No supports.
// =====================================================================
part = "peg_hook";
$fn = 48;

PITCH = 25.4; PRONG_R = 2.7; PRONG_L = 11; PLATE_T = 4;

// shared pegboard mount: back plate + two prongs (insert into adjacent holes)
module peg_back(pw = 30, ph = 38) {
  cube([pw, PLATE_T, ph]);                                  // plate (x=width, y=thin, z=height)
  z0 = (ph - PITCH) / 2;
  for (z = [z0, z0 + PITCH])
    translate([pw/2, PLATE_T, z]) rotate([-90,0,0]) cylinder(h = PRONG_L, r = PRONG_R);
}

module peg_hook() {
  peg_back(28, 36);
  // J-hook off the front (-Y), then up
  translate([28/2, 0, 6]) rotate([0,0,0]) {
    rotate([90,0,0]) cylinder(h = 34, r = 4);               // arm out (-Y)
    translate([0, -34, 0]) sphere(r = 5);                   // up-turn tip
  }
}

module peg_bin() {
  peg_back(46, 30);
  // a small open bin hanging off the front
  bw = 46; bd = 34; bh = 34; w = 2.4;
  translate([0, -bd, 0]) difference() {
    cube([bw, bd, bh]);
    translate([w, w, w]) cube([bw - 2*w, bd - w, bh]);      // hollow (open top + open back to plate)
  }
}

module headphone_stand() {
  // weighted base + post + T-cradle
  cube([90, 70, 6]);                                         // base
  translate([45 - 6, 35 - 6, 6]) cube([12, 12, 150]);        // post
  translate([45, 41, 156]) rotate([90,0,0]) cylinder(h = 30, r = 22, $fn = 6); // hex cradle bar
}

module drawer_divider() {
  // interlocking divider strip: slots at the top so strips cross perpendicular
  L = 120; H = 40; t = 3; slots = 3;
  difference() {
    cube([L, t, H]);
    for (i = [1:slots])
      translate([L*i/(slots+1) - (t+0.4)/2, -1, H/2]) cube([t + 0.4, t + 2, H]);  // top half slots
  }
}

if (part == "peg_hook")            peg_hook();
else if (part == "peg_bin")        peg_bin();
else if (part == "headphone_stand") headphone_stand();
else if (part == "drawer_divider") drawer_divider();
