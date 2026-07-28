// Renders for documentation / the project page.
//   openscad -o hero.png --imgsize=1600,1000 --camera=0,0,0,55,0,25,520 \
//            -D 'scene="hero"' --colorscheme=Tomorrow preview.scad

use <coilcap_system.scad>

scene = "hero";
pitch = 25;
drop  = foot_drop();

module seated(u, hh, x) translate([x, 0, drop]) box(u, 3, hh);

if (scene == "hero") {
    // a 5-wide plate with a short, a standard and a tall box seated on it
    plate(5, 3);
    seated(1, 55, -2 * pitch);
    seated(2, 40, -0.5 * pitch);
    seated(2, 25, 1.5 * pitch);
}

else if (scene == "family") {
    // every width, standard height, lined up with 10 mm gaps
    xs = [-195, -147.5, -75, 22.5, 145];
    for (i = [0:4]) translate([xs[i], 0, 0]) box(i + 1, 3, 40);
}

else if (scene == "stack") {
    box(2, 3, 40);
    translate([0, 0, 40]) box(2, 3, 25);
    translate([0, 0, 65]) box(2, 3, 25);
}

else if (scene == "label") {
    box(2, 3, 40);
    translate([0, -3 * pitch / 2 + 2.0, 40 - 18 + 17.6 / 2])
        rotate([90, 0, 0]) label(2, "USB-C");
}

else if (scene == "angled") {
    // a straight bin beside an angled one, both seated on a 4-wide plate
    plate(4, 3);
    translate([-pitch, 0, drop]) box(2, 3, 40);
    translate([pitch, 0, drop]) box(2, 3, 40, true);
}

else if (scene == "plates") {
    plate(2, 3);
    translate([2 * pitch, 0, 0]) plate(2, 3);
}
