# Validation print — first physical check

Everything in this project is verified geometrically. Nothing has been printed.
This one plate exercises **every fit in the system** using the smallest parts, so
you find out in about two hours instead of after a full set.

## Starter plate — one of everything

`CordCase-PETG-STARTER.3mf` is the one to print first: a complete Small system
plus all three useful jaw sizes, on a single plate.

| | Part | Proves |
|---|---|---|
| 1 | Drawer rack, 4 slots | capsule lean, tile dovetail |
| 2 | Stand (dock), 4 sockets | capsule stands upright |
| 3 | Box (body, short) | the mouth and the label panel |
| 4 | Lid (cap) | the 0.35 mm friction fit |
| 5 | Jaw, 6 mm | the snap fit at the design size |
| 6 | Jaw, 4 mm | the smallest jaw, thinnest section |
| 7 | Jaw, 8 mm | the largest jaw that still fits beside the rest |

Seven objects, no overlaps, everything sitting at z=0 inside the bed. The lid is
already flipped crown-down so nothing overhangs.

## Ready-made project files

Two plates, already positioned, with the printer, process and a PETG profile
baked in. Open either and press Slice.

| File | Contents | Bed used |
|---|---|---|
| `CordCase-PETG-plate1.3mf` | 2 rack tiles + 4 cord clamps | 70 % |
| `CordCase-PETG-plate2.3mf` | body, cap, label, Gridfinity adapter | 26 % |

Two plates rather than one because all seven parts came to 208 cm2 of a 225 cm2
bed - too tight for the slicer to arrange with skirt clearance.

**Do not open the STLs by selecting them all in Finder.** macOS hands them to
OrcaSlicer as one multi-file open and it merges them into a single object named
after the first file - it will report the body as 128 x 42.8 x 95 mm. Use the
3MFs, or import STLs one at a time.

The mesh positions are baked into these files rather than left to auto-arrange,
which was placing objects off the bed on this machine.

## The plate

| Part | What it proves |
|---|---|
| `cordcase_body_S_short_25x38x101` | the mouth the cap plugs into, and the label panel |
| `cordcase_cap_S_25x38` | cap friction fit — `cap_cl` 0.35 mm |
| `cordcase_label_short_usb-c` | label interference fit — `lab_cl` 0.15 mm |
| `cordcase_rack_S_4slot` ×2 | capsule lean, and the tile dovetail — `dt_cl` 0.35 mm |
| `cordcase_gfadapter_S_1x1` | Gridfinity foot against your real baseplates |
| `cordclamp` ×4 | double-ended snap clip — jaw must spring open and retain |

Seven parts, about 208 cm² of a 225 cm² bed. One plate.

## A note on the cap's orientation

The cap is modelled with its plug-in skirt hanging below the shoulder. Printed
that way up the shoulder is an unsupported ledge, so in the supplied plate the
cap is **flipped crown-down**. That puts the crown's 45 deg taper on the bed and
makes the shoulder step inward as it rises, so nothing overhangs. If you ever
import the cap STL yourself, rotate it 180 deg about X before slicing.

## Settings — PETG on an Adventurer 3C

**Read this first: the Adventurer 3C's hot end tops out at 240 °C.** PETG is often
quoted as 230–250; the top of that range is above what this machine will do. Use
**235 °C** and do not try to set 250 — it will either clamp or refuse.

| | |
|---|---|
| Nozzle | **235 °C** (240 max — do not exceed) |
| Bed | **80 °C** |
| Layer | 0.2 mm |
| Walls | 4 |
| Infill | 15 % |
| Speed | **40–50 mm/s** — slower than PLA |
| Cooling | **40 %** — not 100 %. Too much fan ruins PETG layer bonding |
| Enclosure door | **CLOSED** — the opposite of the PLA advice |
| Supports | OFF |
| Raft | OFF |

The label is 1 mm thin — 100 % infill, laid flat.

### PETG changes what you are measuring

PETG oozes more and squishes wider than PLA, so **expect every press fit to come
out tighter**, not looser. If the cap or the label will not go in, that is the
expected direction of error — raise the clearance, do not assume the model is
wrong. Reference values were reasoned for PLA:

- `cap_cl` 0.35 → try 0.45 if the cap binds
- `lab_cl` 0.15 → try 0.25 if the label will not seat
- `dt_cl` 0.35 → try 0.45 if the tiles will not slide

Also give the bed a moment to cool before removing parts. PETG grips a hot plate
hard enough to pull flakes out of it; on a cold plate the parts release cleanly.

## What to check, and what to change

Work through these in order. Each maps to exactly one constant.

**1. Cap onto body.** Should push on with light thumb pressure and stay put when
you lift the case by the cap. Nothing to change if so.

- Too tight / won't seat → raise `cap_cl` in `cordcase.scad` by 0.1
- Falls off / rattles → lower `cap_cl` by 0.1

**2. Label into the panel.** Should press in flush and not fall out when the case
is turned over.

- Won't go in, or bows → raise `lab_cl` by 0.1
- Drops out → lower `lab_cl` by 0.05 (this one is a light interference fit; small steps)

**3. Rack tile to rack tile.** The dovetail should slide together by hand and
resist being pulled apart sideways.

- Won't slide → raise `dt_cl` by 0.1
- Loose / falls apart → lower `dt_cl` by 0.1

**4. Capsule in a rack slot.** Should drop in and lean back without binding on
the dividers.

- Binds → raise `rack_cl` by 0.4
- Rattles badly → lower `rack_cl` by 0.4

**5. Cord clamp.** Push a cable into a jaw. It should spring open, take the
cable, and close behind it so the cable will not fall back out.

- Won't take the cable → raise `mouth` in `cableclip.scad` from 0.72 toward 0.8
- Cable falls out → lower `mouth` toward 0.65
- Jaw cracks instead of springing → raise `jaw_wall`, or print in PETG; this is
  the one part in the system that has to flex, and PLA is brittle in that duty
- Sized for a 6 mm cable by default; change `cable_d` for thicker runs

`mouth` is the FINAL opening as a fraction of the cable, lips included — 0.72
means the gap really is 72 % of `cable_d`. Analysis before printing: each jaw
tip deflects 0.84 mm to admit a 6 mm cable, about 0.66 % surface strain against
PETG's ~4-5 % yield, so it should spring rather than crack. The part prints flat,
so the jaw flexes within a layer instead of across layer bonds — that is the
whole reason for the orientation. In PLA the same geometry is far more likely to
snap; this is the part that most wants PETG.

**6. Gridfinity adapter into your baseplate.** This is the one I could only
verify against the spec-exact plate in your own library, not real hardware.

- Won't seat → raise `socket_clr` where `gf_foot_1u()` is called, in 0.05 steps
- Sloppy → lower it

## After any change

```
python3 build_cordcase.py     # rebuild + re-verify all 57 parts
python3 fitcheck_generic.py   # re-run the assembly tests
```

The fit harness will tell you immediately if a tolerance change broke a different
joint. Then republish and the site picks it up.

## Record what you measure

Worth writing the actual numbers down — calipers on the printed cap opening vs
the modelled 21.0 mm, for instance. A single real measurement replaces every
assumption in this file.
