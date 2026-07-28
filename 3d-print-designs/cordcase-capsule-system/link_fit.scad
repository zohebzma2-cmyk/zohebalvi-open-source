use <cordcase.scad>
test = "rack_to_rack"; nudge = [0,0,0];
function rlen(cw,n) = n*(cw+1.2+2.2)+2.2;
if (test == "rack_to_rack")
  intersection() { rack(38,63,3,127); translate(nudge+[rlen(38,3),0,0]) rack(38,63,3,127); }
else if (test == "dock_to_dock")
  intersection() { plate(38,63,3,1); translate(nudge+[3*(38+3)+6,0,0]) plate(38,63,3,1); }
