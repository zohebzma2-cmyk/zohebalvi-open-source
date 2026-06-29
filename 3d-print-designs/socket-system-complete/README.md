# Socket Organizer — print guide

Parametric, friction-post socket rails for a FlashForge. One post size holds every
socket of a drive; rails auto-split to fit your bed; each rail is stamped with the
drive size and every post with its socket size.

## Files
- `socket_rail.scad` — the parametric model (edit the top block)
- `rail_1-4_metric.stl`, `rail_3-8_metric.stl`, `rail_1-2_metric.stl` — ready to slice

## First: set your bed size
Open `socket_rail.scad`, set **`bed_max`** to the longest rail your printer can lay down:
| FlashForge | bed | `bed_max` |
|---|---|---|
| Adventurer 3 | 150 mm | `140` |
| Adventurer 4 / 5M / 5M Pro | 220 mm | `210` |
| Creator 3 / Pro | 300 mm | `290` |

Rails longer than that split automatically into multiple rails laid out together.

## Dial in the fit (do this once)
The post is `drive − clearance`. Default `clearance = 0.45 mm`.
- Sockets too **tight** → raise clearance (e.g. 0.55).
- Too **loose / fall off** → lower it (e.g. 0.35).
Print *one* rail first and test before committing to all of them.

## Export more (CLI)
```bash
# any drive, metric or SAE
openscad -o rail_3-8_sae.stl -D 'drive="3/8"' -D 'system="sae"' socket_rail.scad
openscad -o rail_1-2_metric.stl -D 'drive="1/2"' socket_rail.scad
```
Or just edit `drive` / `system` at the top of the file and File ▸ Export ▸ STL.

## Connecting the parts (dovetail)
Every part has a dovetail **tail** on the right end and a **socket** on the left, all at
the shared 5 mm base height — so the auto-split rails rejoin into long rails, and the bit
holder clips onto the end of any rail. Slide the next piece **down** over the tail.

### Print order (do the tolerance test FIRST)
1. Print **`tolerance_test.stl`** (~10 min). Slide each male into its female.
2. Whichever gap clicks together firm-but-removable is your number.
3. Set `joint_gap` to that value in `socket_rail.scad` **and** `bit_holder.scad`
   (default is 0.30), then re-export. If 0.30 already fits, you're done — no re-export.

## "All on the bed" — let FlashPrint pack it
This set is ~17 sub-rails + the bit holder — far more than one 150×150 plate. Don't lay it
out by hand: **drag all the STLs into FlashPrint and hit Auto-Arrange.** It nests as many
as fit per plate; print that plate, load the rest, repeat. Rails are sized (`bed_max=140`)
so each fits the Adventurer 3 bed.

## Slicer (FlashPrint) settings
- **Orientation:** base flat on the bed (as exported). Posts tilt back 12° for wall-mount — no supports needed.
- **Layer height:** 0.2 mm · **Walls:** 3 perimeters · **Infill:** 20–30% (these take real grip force)
- **Material:** PLA or PETG both fine; PETG if the rack lives in a hot garage.
- **Supports:** none.

## Mounting (wall_mount = true)
Two **keyhole slots** near the back edge — drop over two screws set to your stud/pegboard
spacing. Set `wall_mount = false` for flat-in-a-drawer with countersunk screw holes instead.

## Customize the socket sets
Edit the `metric_*` / `sae_*` lists at the top. Use `""` for a blank/spare post.
Change `spacing` if big ½″ sockets crowd each other.
