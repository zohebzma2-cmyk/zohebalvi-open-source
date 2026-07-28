use <cordcase.scad>
cap_h = 16; scene = "family";
module unit(w,d,h,x,y=0){ translate([x,y,0]){ body(w,d,h); translate([0,0,h-cap_h]) cap(w,d,h); } }
if (scene == "family") {
  // all five footprints, standard height, front row
  unit(25, 38,127,-118);
  unit(38, 63,127, -72);
  unit(25, 89,127, -22);
  unit(63, 89,127,  30);
  unit(63,140,127, 110);
}
else if (scene == "heights") {
  unit(38,63,101,-52); unit(38,63,127,0); unit(38,63,145,52);
}
else if (scene == "open") {
  translate([-30,0,0]){ body(38,63,127); translate([0,0,127-cap_h]) cap(38,63,127); }
  translate([ 30,0,0]){ body(38,63,127); translate([0,0,127-cap_h+34]) cap(38,63,127); }
}
else if (scene == "plate") {
  plate(38,63,3,1);
  for (i=[-1:1]) translate([i*41,0,2]) { body(38,63,101); translate([0,0,101-cap_h]) cap(38,63,101); }
}
