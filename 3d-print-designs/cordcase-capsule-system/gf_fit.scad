// Does the adapter seat in the spec-exact Gridfinity baseplate already in the
// library, and does a capsule seat in the adapter?
use <gridfinity.scad>
use <gf_adapter.scad>
use <cordcase.scad>
test = "adapter_in_baseplate"; nudge = [0,0,0];
GF_FOOT = 4.75; PLATE_H = 4.75 + 0.6;

if (test == "adapter_in_baseplate")
  intersection() {
    gf_baseplate(1, 2);
    translate(nudge + [0, 0, PLATE_H - GF_FOOT]) gf_adapter(1, 2, 38, 63);
  }
else if (test == "capsule_in_adapter")
  intersection() {
    gf_adapter(1, 2, 38, 63);
    translate(nudge + [0, 0, 4.75 + 1.6 + 0.4]) body(38, 63, 101);
  }
else if (test == "adapter_tiles")
  intersection() {
    gf_adapter(1, 2, 38, 63);
    translate(nudge + [42, 0, 0]) gf_adapter(1, 2, 38, 63);
  }
