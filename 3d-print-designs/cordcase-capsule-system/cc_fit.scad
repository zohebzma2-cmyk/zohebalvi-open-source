// Assembly tests for CordCase. Empty intersection = no clash; nudged together
// it must become non-empty, or the joint is too loose to hold.
use <cordcase.scad>
test = "cap_on_body"; nudge = [0,0,0];
cap_h = 16; lab_deep = 1.4; lab_t = 1.0; lab_frac = 0.46;
function bh(h) = h - cap_h;
function lh(h) = bh(h) * lab_frac;

if (test == "cap_on_body")
  intersection() { body(38,63,127); translate(nudge+[0,0,bh(127)]) cap(38,63,127); }
else if (test == "cap_on_body_small")
  intersection() { body(25,38,101); translate(nudge+[0,0,bh(101)]) cap(25,38,101); }
else if (test == "cap_on_body_xl")
  intersection() { body(63,140,145); translate(nudge+[0,0,bh(145)]) cap(63,140,145); }
else if (test == "label_in_panel")
  intersection() {
    body(38,63,127);
    translate(nudge+[0, -63/2 + lab_deep, (bh(127)-lh(127))/2 + lh(127)/2])
      rotate([90,0,0]) label(127, "Lightning");
  }
else if (test == "body_in_plate")
  intersection() { plate(38,63,3,1); translate(nudge+[0,0,5-3]) body(38,63,127); }

rack_ang = 20; rack_base = 3.0; rack_cl = 1.2; rack_fin = 2.2;
if (test == "capsule_in_rack")
  intersection() {
    rack(38, 63, 3, 101);
    let (R = rack_run(63, 101), yc = 3.5)
      translate(nudge + [0, yc, rack_base + (yc + R/2)*tan(rack_ang) + 0.3])
        rotate([rack_ang, 0, 0]) body(38, 63, 101);
  }

else if (test == "capsule_in_dock")
  intersection() { plate(38,63,3,1); translate(nudge+[0,0,2]) body(38,63,101); }
