#!/usr/bin/env python3
"""
Render and verify the complete CordCase capsule system.

Same guarantees as the tray system's build: every part must come out of CGAL
as a single closed manifold body, the STL must be watertight with consistent
winding, and the bounding box must clear the Adventurer 3C's envelope.

    python3 build_cordcase.py
"""

import os
import re
import struct
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
SCAD = os.path.join(HERE, "cordcase.scad")
OUT = os.path.join(HERE, "stl_cordcase")
BED = (150.0, 150.0, 150.0)
MARGIN = 5.0

# name, width, depth — footprints matching the shelf/drawer use case
SIZES = [("S", 25, 38), ("M", 38, 63), ("W", 25, 89), ("L", 63, 89), ("XL", 63, 140)]
# The 152 mm size in this product family will not fit a 150 mm bed; 145 is the
# tallest that still prints upright with no tricks.
HEIGHTS = [("short", 101), ("standard", 127), ("tall", 145)]
TEXTS = ["USB-C", "Lightning", "USB-A", "Micro USB", "HDMI",
         "Ethernet", "Power", "Audio", "Charger", "Adapter", ""]
# One baseplate per footprint, sized to stay inside the bed. XL is 140 mm deep
# on its own, so a plate for it would overrun the plate — it is left out.
PLATES = [("S", 25, 38, 4), ("M", 38, 63, 3), ("W", 25, 89, 4), ("L", 63, 89, 2)]


def jobs():
    out = []
    for code, w, d in SIZES:
        for hname, h in HEIGHTS:
            out.append((f"body_{code}_{hname}_{w}x{d}x{h}",
                        {"part": "body", "fw": w, "fd": d, "h": h}))
        # the cap is the same whatever the body height, so one per footprint
        out.append((f"cap_{code}_{w}x{d}", {"part": "cap", "fw": w, "fd": d, "h": 127}))
    for hname, h in HEIGHTS:
        for t in TEXTS:
            slug = re.sub(r"[^a-z0-9]+", "-", t.lower()).strip("-") or "blank"
            out.append((f"label_{hname}_{slug}",
                        {"part": "label", "h": h, "label_text": t}))
    for code, w, d, nx in PLATES:
        out.append((f"baseplate_{code}_{nx}x1", {"part": "plate", "fw": w, "fd": d, "nx": nx}))
    return out


def render(name, params):
    path = os.path.join(OUT, f"cordcase_{name}.stl")
    cmd = ["openscad", "--export-format", "binstl", "-o", path, SCAD]
    for k, v in params.items():
        val = f'"{v}"' if isinstance(v, str) else str(v)
        cmd[3:3] = ["-D", f"{k}={val}"]
    r = subprocess.run(cmd, capture_output=True, text=True)
    log = r.stderr + r.stdout
    if r.returncode != 0 or "ERROR" in log:
        last = log.strip().splitlines()[-1] if log.strip() else r.returncode
        return path, f"openscad failed: {last}"
    simple = re.search(r"Simple:\s+(\w+)", log)
    volumes = re.search(r"Volumes:\s+(\d+)", log)
    if simple and simple.group(1) != "yes":
        return path, "CGAL reports the solid is not simple"
    if volumes and volumes.group(1) != "2":
        return path, f"expected 1 closed body, got {int(volumes.group(1)) - 1}"
    return path, None


def check_mesh(path):
    data = open(path, "rb").read()
    if data[:5] == b"solid" and b"facet" in data[:512]:
        return "ASCII STL (expected binary)"
    n = struct.unpack("<I", data[80:84])[0]
    verts, edges = [], {}
    for i in range(n):
        off = 84 + i * 50 + 12
        tri = [struct.unpack("<3f", data[off + k * 12: off + k * 12 + 12]) for k in range(3)]
        verts += tri
        for k in range(3):
            e = (tri[k], tri[(k + 1) % 3])
            edges[e] = edges.get(e, 0) + 1
    if any(c != 1 for c in edges.values()):
        return "duplicate directed edges (bad winding)"
    if any((b, a) not in edges for a, b in edges):
        return "open edges (not watertight)"
    xs = [v[0] for v in verts]
    ys = [v[1] for v in verts]
    zs = [v[2] for v in verts]
    size = (max(xs) - min(xs), max(ys) - min(ys), max(zs) - min(zs))
    if any(s > b - MARGIN for s, b in zip(size, BED)):
        return f"{size[0]:.0f} x {size[1]:.0f} x {size[2]:.0f} exceeds the bed"
    return size


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    todo = jobs()
    fails = []
    for i, (name, params) in enumerate(todo, 1):
        path, err = render(name, params)
        if err is None:
            err = check_mesh(path)
            if isinstance(err, tuple):
                print(f"[{i:2}/{len(todo)}] OK   {name:34s} "
                      f"{err[0]:5.1f} x {err[1]:5.1f} x {err[2]:6.1f} mm")
                continue
        print(f"[{i:2}/{len(todo)}] FAIL {name:34s} {err}")
        fails.append(name)
    print()
    print(f"{len(todo) - len(fails)}/{len(todo)} parts verified"
          + (f" - FAILED: {', '.join(fails)}" if fails else
             " - all single closed manifold bodies, all inside the build volume"))
    sys.exit(1 if fails else 0)
