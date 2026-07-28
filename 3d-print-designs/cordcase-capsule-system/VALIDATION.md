# Validation print — first physical check

Everything in this project is verified geometrically. Nothing has been printed.
This one plate exercises **every fit in the system** using the smallest parts, so
you find out in about two hours instead of after a full set.

## The plate

| Part | What it proves |
|---|---|
| `cordcase_body_S_short_25x38x101` | the mouth the cap plugs into, and the label panel |
| `cordcase_cap_S_25x38` | cap friction fit — `cap_cl` 0.35 mm |
| `cordcase_label_short_usb-c` | label interference fit — `lab_cl` 0.15 mm |
| `cordcase_rack_S_4slot` ×2 | capsule lean, and the tile dovetail — `dt_cl` 0.35 mm |
| `cordcase_gfadapter_S_1x1` | Gridfinity foot against your real baseplates |
| `cordclip` | print-in-place clip — arms must thread their slots and ratchet |

Seven parts, about 208 cm² of a 225 cm² bed. One plate.

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

**5. Cable clip.** Coil a cable, thread each arm back through its slot and pull.
The teeth should click and hold; the arms should flex without whitening or
snapping at the root.

- Arm won't thread → raise `slot_cl` in `cableclip.scad` by 0.1
- Ratchet slips under load → raise `tooth` by 0.2
- Arm cracks at the root when flexed → raise `strap_t` by 0.2, or print it in PETG;
  PLA is stiff and this is the one part in the system that has to bend

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
