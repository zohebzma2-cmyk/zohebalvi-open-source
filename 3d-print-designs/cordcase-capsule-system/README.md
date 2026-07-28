# CoilCap — a complete modular cable-storage system for the FlashForge Adventurer 3C

Five widths, three heights, interlocking baseplates, swappable printed labels,
wall mounts and drawer trays. Every part is generated from one parametric source,
sized for a 150 × 150 × 150 mm bed, and machine-verified before it is written.

Nothing in the system needs support material.

## What's here

| | |
|---|---|
| `stl/` | Every part, ready to slice |
| `coilcap_system.scad` | The parametric source. Change a number, re-run, get a new system |
| `build_all.py` | Renders and verifies the whole set |
| `fitcheck.scad` / `fitcheck.py` | Assembly tests — proves mating parts fit *and* engage |
| `generate_stl.py` | Standalone pure-Python generator for the simple first-gen box (no CAD install) |

## The system

**Grid.** 25 mm pitch. Every box is 75 mm deep (3 units) and 1–5 units wide.

| Size | Footprint | Interior width |
|---|---|---|
| S | 25 × 75 | 19.4 mm |
| M | 50 × 75 | 44.4 mm |
| W | 75 × 75 | 69.4 mm |
| L | 100 × 75 | 94.4 mm |
| XL | 125 × 75 | 119.4 mm |

Interior depth is 67.8 mm on all of them. Three heights — 25 (short), 40 (standard),
55 (tall) — give interior depths of 21.2 / 36.2 / 51.2 mm. All 15 combinations exist.

**Feet and stacking.** Each 25 mm cell has its own foot: a 1.2 mm straight section
inset 1.0 mm, then a 1.0 mm chamfer out to full width. The straight part locates in
a baseplate bore; the gaps between feet are what the baseplate's webs sit in, so a
5-wide box drops flat onto a grid. Stacked box-on-box, the outer foot perimeter lands
on the rim below with 1.0 mm of lateral engagement and the mouth chamfer centres it.

**Labels.** The front wall is 4.4 mm thick and carries a 2.0 mm pocket, open at the
front and at the top. A 1.0 mm card slides down into it and is held by 2.0 mm lips at
each edge, leaving the middle exposed so you can read it and thumb it back out. Cards
print flat with 0.6 mm raised text. 28 cards included, in three widths.

**Baseplates.** 1×3 through 5×3, 5 mm thick, dovetailed on two edges so they tile into
any grid you like. Also a wall-mount version with a screw flange (M4 countersunk) and
a drawer tray with a 12 mm rim.

## Verification

`build_all.py` refuses to write a part it cannot vouch for. Per part it checks that
CGAL reports a single closed manifold body, that the mesh is watertight with
consistent winding, and that the bounding box clears the Adventurer 3C's envelope
with 5 mm to spare.

`fitcheck.py` goes further and tests the *assemblies*. For each pair of mating parts
it renders their intersection in the assembled position and measures its volume:

- **clearance** — nominal position must produce zero overlap, or the parts won't go together
- **engagement** — pushed 0.4–0.5 mm the overlap must become non-zero, or the joint is
  so loose it never touches

Both directions matter. The clearance test alone would happily pass a dovetail that
is 3 mm too small. Running it caught three real bugs during design: baseplate webs
colliding with multi-cell box bodies, dovetail slots cut facing the wrong way, and
label text on the small card running underneath the retaining lips.

```
python3 build_all.py     # render + verify every part
python3 fitcheck.py      # assembly tests
```

## FlashPrint settings (Adventurer 3C)

150 × 150 × 150 mm, 0.4 mm nozzle, 240 °C max hot end, 100 °C max bed, enclosed.

| Setting | Value | Why |
|---|---|---|
| Material | PLA | PETG works at 235/70 but 240 °C max leaves no headroom. Skip ABS. |
| Nozzle / bed | 210 °C / 50 °C | FlashForge PLA defaults. |
| Layer height | 0.2 mm | 0.3 mm on the tall boxes cuts roughly a third of the time. |
| Perimeters | 4 | Makes the 2.8 mm walls solid, so infill never touches them. |
| Top / bottom | 4 layers | |
| Infill | 15 % | Only the floor slab uses it. |
| Supports | **Off** | Nothing overhangs past 45°. |
| Raft | **Off** | FlashPrint defaults it on. Use a brim instead if a corner lifts. |
| Cooling | 100 % | Leave the front door open for PLA; the enclosure traps heat. |
| Speed | 60 mm/s, first layer 20 | |

The label cards are 1.0 mm thick — print those at 0.2 mm layers with 100 % infill, and
lay several on the plate at once.

**Print order.** Start with one `box_M_50x75x40`, one `baseplate_2x3`, and one
`label_M_usb-c`. That is the whole system in miniature: it proves the foot fits the
socket, the card fits the pocket, and your printer's tolerances agree with the model.
Adjust `socket_cl` (socket fit) or `lab_card` (card thickness) by 0.1 mm if anything is
tight, re-run `build_all.py`, and then commit to a full set.

Because these are flat, wide first layers, bed levelling and Z-offset matter more than
usual. Level before a long batch.

If you prefer OrcaSlicer or Cura, both ship FlashForge Adventurer 3 profiles; export
plain `.gcode` rather than FlashPrint's `.gx`.

## Customising

Everything is driven by the constants at the top of `coilcap_system.scad` — grid pitch,
wall thickness, foot geometry, label pocket, dovetails. Change one and re-run
`build_all.py`; the fit tests will tell you if you broke a joint.

Any label text, any size:

```
openscad --export-format binstl -o stl/label_M_thunderbolt.stl \
  -D 'part="label"' -D ux=2 -D 'label_text="Thunderbolt"' coilcap_system.scad
```

Two-tone labels on a single-extruder machine: the text starts exactly 1.0 mm up, so
insert a filament change at that layer in FlashPrint.

## On the original

This is an original design, not a copy. CableCap by 3D Printing Builds is a paid
product (Kickstarter-funded; about US$40 for the complete library on Cults3D) and its
actual geometry is not something I can or should reproduce — so this is built from
scratch to cover the same ground: 5 widths, 3 heights, 15 boxes, an interlocking base
system, printable labels, wall-mounted grids and trays.

Things their bundle has that this does not: Gridfinity-compatible plates (this uses its
own 25 mm grid, not Gridfinity's 42 mm), a shelf system, angled display stands, and
premade multi-colour label sheets. If you want those, buy theirs.

---

# CordCase — the upright capsule system

A second, separate system in this repo. Where CoilCap is an open tray you look
down into, CordCase is a sealed stand-up case you pull off a shelf like a book:
a fluted body, a contrasting snap-on cap, and a spine label read bottom-to-top.

| | |
|---|---|
| `cordcase.scad` | the parametric source |
| `build_cordcase.py` | renders and verifies all 57 parts |
| `cc_fit.scad` + `fitcheck_generic.py` | assembly tests for the cap and label joints |
| `configurator.py` | local web app that generates any configuration on demand |
| `stl_cordcase/` | the built parts |

**57 parts**: 15 bodies (5 footprints x 3 heights), 5 caps, 33 spine labels,
4 baseplates.

| Size | Footprint | | Height | |
|---|---|---|---|---|
| Small | 25 x 38 mm | | Short | 101 mm |
| Medium | 38 x 63 mm | | Standard | 127 mm |
| Wide | 25 x 89 mm | | Tall | 145 mm |
| Large | 63 x 89 mm | | | |
| X-Large | 63 x 140 mm | | | |

The cap is height-independent — print one per footprint and it fits all three
heights. Print it in a contrasting filament; that is what makes a labelled row
readable at a glance.

**Two limits worth knowing.** Cable-case systems of this shape often list a
152 mm tall size; that does not fit a 150 mm bed, so this tops out at 145 mm and
every size prints upright with no splitting. And X-Large has no baseplate — at
140 mm deep, a plate to hold it overruns the bed. The build and the configurator
both refuse to emit a part that does not fit, rather than handing you a bad file.

## The configurator

```
./run_configurator.sh        # http://127.0.0.1:8770
```

Change anything and it rebuilds — no Generate button. It runs the same checks
the batch build does (single closed manifold body, watertight mesh, inside the
build volume) and will not offer a download for anything that fails. One click
gets a complete working case as a zip: body, cap, label, and a print-settings
note. Results cache by parameter hash.

## Not yet printed

Everything here is verified geometrically, not physically. The cap friction fit
(0.35 mm) and the label plate fit (0.15 mm interference) are reasoned and
tested in CAD, but no part has come off a printer yet. Print one Medium case
first and adjust `cap_cl` / `lab_cl` before committing to a full set.
