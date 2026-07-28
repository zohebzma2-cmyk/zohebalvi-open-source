#!/usr/bin/env python3
"""
Assembly tests for the CoilCap system.

For every pair of mating parts, two things are checked:

  clearance  - assembled in their nominal position the parts must not overlap
               at all (an empty intersection). Anything above TOL is a clash
               that would stop them going together.
  engagement - pushed together by a fraction of a millimetre they MUST overlap.
               This catches the opposite failure: a joint with so much slack
               that the parts never actually touch, which no clearance test
               would ever notice.

    python3 fitcheck.py
"""

import json
import os
import re
import struct
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
SCAD_FILE = os.environ.get("FIT_SCAD", "fitcheck.scad")
TOL = 0.01          # mm^3 - below this is surface contact, not a clash

# name, description, nudge that should push the joint into engagement
TESTS = json.loads(os.environ["FIT_TESTS"]) if "FIT_TESTS" in os.environ else [
    ("box_in_plate", "box seated in a baseplate", [0, 0, -0.4]),
]


def read_stl(path):
    data = open(path, "rb").read()
    if data[:5] == b"solid" and b"facet" in data[:2048]:
        pts = [tuple(float(c) for c in p)
               for p in re.findall(rb"vertex\s+(\S+)\s+(\S+)\s+(\S+)", data)]
        return [tuple(pts[i:i + 3]) for i in range(0, len(pts), 3)]
    n = struct.unpack("<I", data[80:84])[0]
    return [tuple(struct.unpack("<3f", data[84 + i * 50 + 12 + k * 12:
                                            84 + i * 50 + 24 + k * 12]) for k in range(3))
            for i in range(n)]


def volume(tris):
    v = 0.0
    for a, b, c in tris:
        v += (a[0] * (b[1] * c[2] - b[2] * c[1])
              - a[1] * (b[0] * c[2] - b[2] * c[0])
              + a[2] * (b[0] * c[1] - b[1] * c[0])) / 6.0
    return abs(v)


def overlap(test, nudge):
    """mm^3 of shared volume between the two parts, or None on a render error."""
    out = f"/tmp/fit_{test}_{'n' if any(nudge) else '0'}.stl"
    if os.path.exists(out):
        os.remove(out)
    r = subprocess.run(["openscad", "--export-format", "binstl", "-o", out,
                        "-D", f'test="{test}"',
                        "-D", f"nudge=[{nudge[0]},{nudge[1]},{nudge[2]}]",
                        os.path.join(HERE, SCAD_FILE)],
                       capture_output=True, text=True)
    log = r.stderr + r.stdout
    if "ERROR" in log:
        return None
    if "top level object is empty" in log or not os.path.exists(out):
        return 0.0
    return volume(read_stl(out))


if __name__ == "__main__":
    failures = []
    for name, desc, nudge in TESTS:
        clear = overlap(name, [0, 0, 0])
        eng = overlap(name, nudge)
        if clear is None or eng is None:
            print(f"FAIL  {name:24s} openscad error")
            failures.append(name)
        elif clear > TOL:
            print(f"FAIL  {name:24s} {desc}: {clear:.2f} mm^3 clash when assembled")
            failures.append(name)
        elif eng <= TOL:
            print(f"FAIL  {name:24s} {desc}: no contact even when pushed "
                  f"{max(abs(n) for n in nudge)} mm - joint is too loose")
            failures.append(name)
        else:
            print(f"PASS  {name:24s} {desc:34s} clears, engages within "
                  f"{max(abs(n) for n in nudge)} mm")
    print()
    print("every joint in the system assembles and engages" if not failures
          else f"FAILED: {', '.join(failures)}")
    sys.exit(1 if failures else 0)
