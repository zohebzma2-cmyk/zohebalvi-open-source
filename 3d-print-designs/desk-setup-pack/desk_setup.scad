// =====================================================================
//  DESK SETUP PACK  — part = "earbuds_stand" | "key_mail" | "cable_drop"
//  Units mm. No supports.
// =====================================================================
part = "earbuds_stand";
$fn = 48;

// 1. Earbuds / AirPods / small-device stand
module earbuds_stand() {
  cube([42, 46, 5]);                                    // base
  translate([0, 30, 5]) rotate([14,0,0]) cube([42, 5, 42]);  // back support (leans 14°)
  translate([0, 13, 5]) cube([42, 5, 14]);              // front lip
  // cable pass-through
  translate([21, 24, 5]) rotate([0,90,0]) cylinder(h = 44, r = 5, center = true);
}

// 2. Wall key + mail organizer: back plate + mail pocket + 3 key pegs
module key_mail() {
  W = 110; plateH = 95; t = 4;
  difference() {
    cube([W, t, plateH]);                               // back plate
    for (z = [plateH-12, 12]) translate([W/2, -1, z]) rotate([-90,0,0]) cylinder(h = t+2, r = 2);  // screw holes
  }
  // mail pocket (open top), front of plate
  pocketH = 48; pocketD = 38; w = 3;
  translate([0, t, 28]) difference() {
    cube([W, pocketD, pocketH]);
    translate([w, w, w]) cube([W - 2*w, pocketD, pocketH]);   // hollow + open top
  }
  // 3 key pegs below the pocket
  for (x = [W*0.2, W*0.5, W*0.8])
    translate([x, t, 14]) rotate([-90,0,0]) { cylinder(h = 16, r = 3); translate([0,0,16]) sphere(r = 4.5); }
}

// 3. Desk-edge cable drop clip: clamps over a desktop edge; cable drops into the top notch
module cable_drop() {
  w = 24; gap = 22; arm = 6; depth = 40; H = gap + 2*arm;   // gap = desktop thickness
  difference() {
    cube([w, depth, H]);
    translate([-1, 0, arm]) cube([w + 2, depth - 3, gap]);          // mouth (opens at front, grips desk edge)
    translate([w/2, 0, H]) rotate([0,90,0]) cylinder(h = w + 2, r = 3.5, center = true);  // cable U-notch on top front
  }
}

if (part == "earbuds_stand")    earbuds_stand();
else if (part == "key_mail")    key_mail();
else if (part == "cable_drop")  cable_drop();
