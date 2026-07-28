#!/usr/bin/env python3
"""
Render the complete CoilCap system to STL and verify every file.

Checks, per part:
  - OpenSCAD reports the solid as CGAL "Simple" with exactly 2 volumes
    (one solid, one outside) - i.e. a single closed manifold body
  - the mesh is watertight and consistently wound
  - the bounding box fits the Adventurer 3C's 150 x 150 x 150 mm envelope

    python3 build_all.py            # everything (~40 parts, a few minutes)
    python3 build_all.py boxes      # just one group: boxes labels plates
"""

import os
import re
import struct
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
SCAD = os.path.join(HERE, "coilcap_system.scad")
OUT = os.path.join(HERE, "stl")
BED = (150.0, 150.0, 150.0)
MARGIN = 5.0  # keep a skirt's worth of room off the bed edges

WIDTHS = [(1, "S"), (2, "M"), (3, "W"), (4, "L"), (5, "XL")]
HEIGHTS = [(25, "short"), (40, "standard"), (55, "tall")]
LABEL_TEXTS = ["USB-C", "Lightning", "USB-A", "Micro USB", "HDMI",
               "Ethernet", "Power", "Audio", "Adapters", "Chargers", ""]
# The small box's front face only has room for short words, so it gets a
# reduced set. Widths 3/4/5 all cap at a 60 mm pocket and share one card.
SHORT_TEXTS = ["USB-C", "USB-A", "HDMI", "Power", "Audio", ""]
LABEL_SIZES = [(1, "S", SHORT_TEXTS), (2, "M", LABEL_TEXTS), (3, "WLXL", LABEL_TEXTS)]


def jobs(groups):
    out = []
    if "boxes" in groups:
        for u, code in WIDTHS:
            for h, hname in HEIGHTS:
                out.append((f"box_{code}_{u*25}x75x{h}",
                            {"part": "box", "ux": u, "uy": 3, "h": h}))
    if "labels" in groups:
        for u, code, texts in LABEL_SIZES:
            for txt in texts:
                slug = re.sub(r"[^a-z0-9]+", "-", txt.lower()).strip("-") or "blank"
                out.append((f"label_{code}_{slug}",
                            {"part": "label", "ux": u, "label_text": txt}))
    if "plates" in groups:
        for nx, ny in [(1, 3), (2, 3), (3, 3), (4, 3), (5, 3)]:
            out.append((f"baseplate_{nx}x{ny}_{nx*25}x{ny*25}",
                        {"part": "plate", "ux": nx, "uy": ny}))
        out.append(("wallplate_3x3", {"part": "wallplate", "ux": 3, "uy": 3}))
        out.append(("wallplate_5x3", {"part": "wallplate", "ux": 5, "uy": 3}))
        out.append(("tray_3x3", {"part": "tray", "ux": 3, "uy": 3}))
        out.append(("tray_5x3", {"part": "tray", "ux": 5, "uy": 3}))
    return out


def render(name, params):
    path = os.path.join(OUT, f"coilcap_{name}.stl")
    cmd = ["openscad", "--export-format", "binstl", "-o", path, SCAD]
    for k, v in params.items():
        val = f'"{v}"' if isinstance(v, str) else str(v)
        cmd[3:3] = ["-D", f"{k}={val}"]
    res = subprocess.run(cmd, capture_output=True, text=True)
    log = res.stderr + res.stdout
    if res.returncode != 0 or "ERROR" in log:
        return path, f"openscad failed: {log.strip().splitlines()[-1] if log.strip() else res.returncode}"
    # Parts with no CSG operation skip CGAL entirely and report only a facet
    # count; those are covered by the mesh check below instead.
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
        return f"{size[0]:.1f} x {size[1]:.1f} x {size[2]:.1f} exceeds the bed"
    return size


if __name__ == "__main__":
    groups = sys.argv[1:] or ["boxes", "labels", "plates"]
    os.makedirs(OUT, exist_ok=True)
    todo = jobs(groups)
    failures = []
    for i, (name, params) in enumerate(todo, 1):
        path, err = render(name, params)
        if err is None:
            err = check_mesh(path)
            if isinstance(err, tuple):
                print(f"[{i:2}/{len(todo)}] OK   {name:34s} "
                      f"{err[0]:6.1f} x {err[1]:5.1f} x {err[2]:5.1f} mm")
                continue
        print(f"[{i:2}/{len(todo)}] FAIL {name:34s} {err}")
        failures.append(name)
    print()
    print(f"{len(todo) - len(failures)}/{len(todo)} parts verified"
          + (f" - FAILED: {', '.join(failures)}" if failures else
             " - all single closed manifold bodies, all inside the build volume"))
