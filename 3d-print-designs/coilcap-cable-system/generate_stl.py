#!/usr/bin/env python3
"""
CoilCap - a modular, stackable cable-storage box.

Pure-Python binary STL generator. No dependencies, no CAD install needed.
Sized for a FlashForge Adventurer 3C (150 x 150 x 150 mm build volume).

Geometry is built as a loft: a stack of z-levels, each holding an outer and
(optionally) an inner rounded-rectangle profile with the same vertex count, so
consecutive levels can be stitched into a watertight, manifold shell.

    run:  python3 generate_stl.py
    out:  ./stl/*.stl
"""

import math
import struct
import os

# ---------------------------------------------------------------- parameters

PITCH = 50.0        # grid pitch, mm. A module is N x M pitches.
WALL = 2.8          # side wall thickness (7 lines @ 0.4 nozzle)
FLOOR = 1.6         # floor thickness (8 layers @ 0.2)
RADIUS = 4.0        # outer corner radius
FOOT_INSET = 1.2    # how far the foot is inset from the outer wall
FOOT_RAMP = 1.2     # 45 deg self-supporting ramp height of the foot
MOUTH_CHAMFER = 0.8  # top-of-wall inner chamfer, funnels the foot above in
SEG = 8             # arc segments per corner (32 points per profile)

# stacking engagement = (WALL - MOUTH_CHAMFER) - FOOT_INSET = 0.8 mm

# ------------------------------------------------------------------ profiles


def rounded_rect(width, depth, radius, inset, z):
    """CCW (seen from +z) rounded rectangle, shrunk inward by `inset`."""
    a = width / 2.0 - inset
    b = depth / 2.0 - inset
    r = max(radius - inset, 0.2)
    r = min(r, a, b)
    pts = []
    for cx, cy, start in ((a - r, b - r, 0.0),
                          (-(a - r), b - r, 90.0),
                          (-(a - r), -(b - r), 180.0),
                          (a - r, -(b - r), 270.0)):
        for j in range(SEG):
            ang = math.radians(start + 90.0 * j / (SEG - 1))
            pts.append((cx + r * math.cos(ang), cy + r * math.sin(ang), z))
    return pts


# ------------------------------------------------------------------ meshing

def cap_up(poly):
    """Fill a convex polygon, normal +z."""
    return [(poly[0], poly[i], poly[i + 1]) for i in range(1, len(poly) - 1)]


def cap_down(poly):
    """Fill a convex polygon, normal -z."""
    return [(poly[0], poly[i + 1], poly[i]) for i in range(1, len(poly) - 1)]


def stitch(lower, upper, flip=False):
    """Wall band between two equal-length loops. flip=True points normals in."""
    tris = []
    n = len(lower)
    for i in range(n):
        j = (i + 1) % n
        a, b, c, d = lower[i], lower[j], upper[j], upper[i]
        quad = [(a, b, c), (a, c, d)]
        tris += [t[::-1] for t in quad] if flip else quad
    return tris


def ring(outer, inner):
    """Flat annulus between two equal-length loops at the same z, normal +z."""
    tris = []
    n = len(outer)
    for i in range(n):
        j = (i + 1) % n
        tris += [(outer[i], outer[j], inner[j]), (outer[i], inner[j], inner[i])]
    return tris


def build_box(width, depth, height):
    """Open-top tray with a chamfered stacking foot and a funnelled mouth."""
    assert height >= FLOOR + MOUTH_CHAMFER + 2.0, "height too small"

    # outer skin: foot chamfer, then straight to the top
    outer_levels = [
        rounded_rect(width, depth, RADIUS, FOOT_INSET, 0.0),
        rounded_rect(width, depth, RADIUS, 0.0, FOOT_RAMP),
        rounded_rect(width, depth, RADIUS, 0.0, height),
    ]
    # cavity: straight, then chamfered outward at the very top
    inner_levels = [
        rounded_rect(width, depth, RADIUS, WALL, FLOOR),
        rounded_rect(width, depth, RADIUS, WALL, height - MOUTH_CHAMFER),
        rounded_rect(width, depth, RADIUS, WALL - MOUTH_CHAMFER, height),
    ]

    tris = cap_down(outer_levels[0])
    for lo, up in zip(outer_levels, outer_levels[1:]):
        tris += stitch(lo, up)
    tris += cap_up(inner_levels[0])
    for lo, up in zip(inner_levels, inner_levels[1:]):
        tris += stitch(lo, up, flip=True)
    tris += ring(outer_levels[-1], inner_levels[-1])
    return tris


# ---------------------------------------------------------------- validation

def validate(tris, name):
    """Watertight + consistently wound: every directed edge used exactly once,
    and its reverse used exactly once."""
    edges = {}
    degenerate = 0
    for tri in tris:
        for i in range(3):
            e = (tri[i], tri[(i + 1) % 3])
            if e[0] == e[1]:
                degenerate += 1
            edges[e] = edges.get(e, 0) + 1
    bad = [e for e, c in edges.items() if c != 1]
    unmatched = [e for e in edges if (e[1], e[0]) not in edges]
    ok = not bad and not unmatched and not degenerate
    print(f"  {'OK  ' if ok else 'FAIL'} {name}: {len(tris)} triangles, "
          f"{len(edges)} edges, dup={len(bad)} open={len(unmatched)} "
          f"degenerate={degenerate}")
    return ok


# -------------------------------------------------------------------- output

def write_stl(tris, path):
    with open(path, "wb") as f:
        f.write(b"CoilCap".ljust(80, b"\0"))
        f.write(struct.pack("<I", len(tris)))
        for a, b, c in tris:
            ux, uy, uz = (b[0] - a[0], b[1] - a[1], b[2] - a[2])
            vx, vy, vz = (c[0] - a[0], c[1] - a[1], c[2] - a[2])
            nx, ny, nz = (uy * vz - uz * vy, uz * vx - ux * vz, ux * vy - uy * vx)
            ln = math.sqrt(nx * nx + ny * ny + nz * nz) or 1.0
            f.write(struct.pack("<3f", nx / ln, ny / ln, nz / ln))
            for p in (a, b, c):
                f.write(struct.pack("<3f", *p))
            f.write(struct.pack("<H", 0))


PARTS = [
    # (name,               width,     depth,     height)
    ("1x1_lid",            PITCH,     PITCH,      8.0),
    ("1x1_short",          PITCH,     PITCH,     25.0),
    ("1x1_standard",       PITCH,     PITCH,     40.0),
    ("1x1_tall",           PITCH,     PITCH,     55.0),
    ("1x2_lid",            PITCH,     PITCH * 2,  8.0),
    ("1x2_short",          PITCH,     PITCH * 2, 25.0),
    ("1x2_standard",       PITCH,     PITCH * 2, 40.0),
    ("2x2_lid",            PITCH * 2, PITCH * 2,  8.0),
    ("2x2_standard",       PITCH * 2, PITCH * 2, 40.0),
    ("2x2_tall",           PITCH * 2, PITCH * 2, 55.0),
]

BUILD_VOLUME = (150.0, 150.0, 150.0)

if __name__ == "__main__":
    out = os.path.join(os.path.dirname(os.path.abspath(__file__)), "stl")
    os.makedirs(out, exist_ok=True)
    all_ok = True
    for name, w, d, h in PARTS:
        tris = build_box(w, d, h)
        all_ok &= validate(tris, name)
        assert w <= BUILD_VOLUME[0] and d <= BUILD_VOLUME[1] and h <= BUILD_VOLUME[2], \
            f"{name} exceeds the Adventurer 3C build volume"
        path = os.path.join(out, f"coilcap_{name}_{w:.0f}x{d:.0f}x{h:.0f}.stl")
        write_stl(tris, path)
    print("\nall meshes watertight" if all_ok else "\nMESH ERRORS - do not print")
