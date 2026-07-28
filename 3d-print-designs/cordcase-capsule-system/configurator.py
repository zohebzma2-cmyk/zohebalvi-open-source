#!/usr/bin/env python3
"""
CordCase configurator — a local web app that generates any case, cap or label
on demand and verifies it before handing you the STL.

    python3 configurator.py          # then open http://127.0.0.1:8770

Stdlib only. It shells out to OpenSCAD for geometry, runs the same manifold and
build-volume checks the batch build uses, and caches results by parameter hash
so re-picking a configuration is instant.
"""

import hashlib
import html
import json
import os
import re
import struct
import subprocess
import threading
import urllib.parse
import zipfile
import io
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

HERE = os.path.dirname(os.path.abspath(__file__))
SCAD = os.path.join(HERE, "cordcase.scad")
CACHE = os.path.join(HERE, ".configurator-cache")
BED = (150.0, 150.0, 150.0)
MARGIN = 5.0
PORT = 8770

PRESETS = [
    ("Small", 25, 38), ("Medium", 38, 63), ("Wide", 25, 89),
    ("Large", 63, 89), ("X-Large", 63, 140),
]
HEIGHTS = [("Short", 101), ("Standard", 127), ("Tall", 145)]

# Values are interpolated into openscad -D flags, so they are validated hard.
SAFE_TEXT = re.compile(r"^[A-Za-z0-9 ._+/&()-]{0,22}$")
_locks = {}
_locks_guard = threading.Lock()


def key_lock(key):
    """One lock per configuration, so different parts build in parallel while
    two requests for the same part still can't race on the same output file."""
    with _locks_guard:
        return _locks.setdefault(key, threading.Lock())


def clamp(v, lo, hi, default):
    try:
        f = float(v)
    except (TypeError, ValueError):
        return default
    return max(lo, min(hi, f))


def check_mesh(path):
    """Returns (size_tuple, None) or (None, reason). Same checks as the batch build."""
    data = open(path, "rb").read()
    if len(data) < 84:
        return None, "empty STL"
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
        return None, "mesh has duplicate directed edges"
    if any((b, a) not in edges for a, b in edges):
        return None, "mesh is not watertight"
    xs = [v[0] for v in verts]
    ys = [v[1] for v in verts]
    zs = [v[2] for v in verts]
    size = (max(xs) - min(xs), max(ys) - min(ys), max(zs) - min(zs))
    over = [ax for ax, s, b in zip("XYZ", size, BED) if s > b - MARGIN]
    if over:
        return None, f"{size[0]:.0f} x {size[1]:.0f} x {size[2]:.0f} mm overruns the bed on {'/'.join(over)}"
    return size, None


def generate(part, w, d, h, text, nx):
    key = hashlib.sha256(f"{part}|{w}|{d}|{h}|{text}|{nx}".encode()).hexdigest()[:16]
    stl = os.path.join(CACHE, f"{key}.stl")
    png = os.path.join(CACHE, f"{key}.png")
    meta = os.path.join(CACHE, f"{key}.json")
    cached = None
    if os.path.exists(meta):
        try:
            cached = json.load(open(meta))
        except (ValueError, OSError):
            cached = None
    # A cached success is only good if the artefacts are still on disk; a cached
    # failure is kept so a bad configuration doesn't re-run OpenSCAD every keystroke.
    if cached and (not cached.get("ok") or os.path.exists(stl)):
        return cached

    with key_lock(key):
        defs = ["-D", f'part="{part}"', "-D", f"fw={w}", "-D", f"fd={d}",
                "-D", f"h={h}", "-D", f"nx={int(nx)}", "-D", f'label_text="{text}"']
        r = subprocess.run(["openscad", "--export-format", "binstl", "-o", stl, *defs, SCAD],
                           capture_output=True, text=True)
        log = r.stderr + r.stdout
        def fail(msg):
            out = {"ok": False, "error": msg}
            try:
                json.dump(out, open(meta, "w"))
            except OSError:
                pass
            return out

        if r.returncode != 0 or "ERROR" in log:
            return fail("OpenSCAD could not build that configuration")
        simple = re.search(r"Simple:\s+(\w+)", log)
        volumes = re.search(r"Volumes:\s+(\d+)", log)
        if simple and simple.group(1) != "yes":
            return fail("geometry is not a simple solid")
        if volumes and volumes.group(1) != "2":
            return fail(f"produced {int(volumes.group(1)) - 1} separate bodies")

        size, err = check_mesh(stl)
        if err:
            return fail(err)

        dist = max(size) * 3.4 + 90
        subprocess.run(["openscad", "--render", "-o", png, "--imgsize=760,560",
                        f"--camera=0,0,{size[2] / 2:.0f},68,0,22,{dist:.0f}",
                        "--colorscheme=Tomorrow Night", *defs, SCAD],
                       capture_output=True, text=True)

        inner = (w - 4.0, d - 4.0, max(h - 16 - 1.6, 0))   # wall 2.0, cap 16, floor 1.6
        out = {"ok": True, "key": key,
               "inner": [round(v, 1) for v in inner] if part == "body" else None,
               "size": [round(v, 1) for v in size],
               "triangles": struct.unpack("<I", open(stl, "rb").read(84)[80:84])[0],
               "bytes": os.path.getsize(stl)}
        json.dump(out, open(meta, "w"))
        return out


PAGE = """<!doctype html><html><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover">
<title>CordCase Configurator</title><style>
:root{color-scheme:dark}
*{box-sizing:border-box}
body{margin:0;background:#0f1113;color:#e8e8ea;
 font:15px/1.55 -apple-system,BlinkMacSystemFont,"SF Pro Text","Segoe UI",Inter,sans-serif;
 -webkit-tap-highlight-color:transparent;overscroll-behavior-y:none}
.wrap{max-width:1040px;margin:0 auto;padding:2.2rem 1.25rem calc(4rem + env(safe-area-inset-bottom))}
h1{font-size:1.55rem;margin:0 0 .2rem;letter-spacing:-.02em}
.sub{color:#8b9199;margin:0 0 1.6rem;font-size:.92rem;max-width:60ch}
.grid{display:grid;grid-template-columns:330px 1fr;gap:1.5rem;align-items:start}
@media(max-width:780px){.grid{grid-template-columns:1fr}}
.card{background:#16191d;border:1px solid #23272d;border-radius:14px;padding:1.15rem}
.lb{font-size:.7rem;text-transform:uppercase;letter-spacing:.08em;color:#8b9199;margin:1.15rem 0 .45rem}
.lb:first-child{margin-top:0}
.seg{display:grid;grid-template-columns:repeat(2,1fr);gap:.4rem}
.seg.h3{grid-template-columns:repeat(3,1fr)}
.seg button{margin:0;min-height:44px;background:#0f1113;color:#c9ced6;border:1px solid #2a2f36;
 border-radius:9px;font:inherit;font-size:.85rem;cursor:pointer;padding:.4rem .3rem}
.seg button.on{background:#e8e8ea;color:#0f1113;border-color:#e8e8ea;font-weight:650}
.seg button small{display:block;font-size:.68rem;opacity:.62;font-weight:400}
input{width:100%;background:#0f1113;color:#e8e8ea;border:1px solid #2a2f36;border-radius:9px;
 padding:.6rem .7rem;font:inherit;font-size:.92rem;min-height:44px}
.row{display:flex;gap:.55rem}
.out{min-height:460px;display:flex;flex-direction:column;align-items:center;justify-content:center;
 text-align:center;color:#8b9199}
.out img{max-width:100%;border-radius:10px;border:1px solid #23272d}
.stats{display:flex;gap:1.5rem;flex-wrap:wrap;justify-content:center;margin:1rem 0 .1rem;
 font-variant-numeric:tabular-nums lining-nums}
.stats div{font-size:.74rem;color:#8b9199}
.stats b{display:block;color:#e8e8ea;font-size:1.02rem;font-weight:650}
.acts{display:flex;gap:.6rem;flex-wrap:wrap;justify-content:center;margin-top:1.1rem}
.acts a{display:inline-flex;align-items:center;min-height:44px;padding:.6rem 1.15rem;
 border-radius:10px;text-decoration:none;font-weight:600;font-size:.9rem}
.primary{background:#2f6fd0;color:#fff}
.ghost{background:transparent;color:#c9ced6;border:1px solid #2a2f36}
.err{color:#ff6b6b;max-width:44ch}
.spin{color:#6f767f;font-size:.9rem}
.note{font-size:.78rem;color:#6f767f;margin-top:1.2rem;line-height:1.65;max-width:72ch}
@media (prefers-reduced-motion:reduce){*{transition:none!important;animation:none!important}}
</style></head><body><div class="wrap">
<h1>CordCase Configurator</h1>
<p class="sub">Change anything and it rebuilds itself &mdash; no Generate button. Every part is
checked watertight and inside the 150&nbsp;mm bed before a download is offered.</p>
<div class="grid">
<div class="card">
  <div class="lb">Part</div>
  <div class="seg h3" id="part">
    <button data-v="body" class="on">Body</button>
    <button data-v="cap">Cap</button>
    <button data-v="label">Label</button>
  </div>
  <div class="lb">Size</div>
  <div class="seg" id="size">__PRESETS__<button data-v="custom">Custom<small>set below</small></button></div>
  <div class="row" id="custom" style="display:none;margin-top:.55rem">
    <div style="flex:1"><div class="lb">Width</div><input id="w" type="number" value="38" min="18" max="140"></div>
    <div style="flex:1"><div class="lb">Depth</div><input id="d" type="number" value="63" min="18" max="140"></div>
  </div>
  <div class="lb">Height</div>
  <div class="seg h3" id="height">__HEIGHTS__</div>
  <div class="lb">Label text</div>
  <input id="text" value="USB-C" maxlength="22" placeholder="blank for a plain plate">
</div>
<div class="card out" id="out"><span class="spin">Building&hellip;</span></div>
</div>
<p class="note">The cap is the same whatever the body height, so you print one cap per size and it
fits all three. Print it in a contrasting filament &mdash; that is what makes a labelled row
readable at a glance. The 152&nbsp;mm size some cable-case systems use will not fit a 150&nbsp;mm
bed, so this stops at 145&nbsp;mm and everything prints upright without splitting.</p>
</div>
<script>
const $=s=>document.querySelector(s), $$=s=>[...document.querySelectorAll(s)];
const st={part:'body',w:38,d:63,h:127,text:'USB-C',size:'38x63'};
try{Object.assign(st,JSON.parse(localStorage.cordcase||'{}'));}catch(e){}

function paint(){
  $$('#part button').forEach(b=>b.classList.toggle('on',b.dataset.v===st.part));
  $$('#size button').forEach(b=>b.classList.toggle('on',b.dataset.v===st.size));
  $$('#height button').forEach(b=>b.classList.toggle('on',+b.dataset.v===+st.h));
  $('#custom').style.display = st.size==='custom' ? 'flex':'none';
  $('#w').value=st.w; $('#d').value=st.d; $('#text').value=st.text;
  localStorage.cordcase=JSON.stringify(st);
}
function seg(sel,key,cast){
  $$(sel+' button').forEach(b=>b.onclick=()=>{
    const v=b.dataset.v;
    if(key==='size'){ st.size=v; if(v!=='custom'){const p=v.split('x');st.w=+p[0];st.d=+p[1];} }
    else st[key]=cast?cast(v):v;
    paint(); run();
  });
}
seg('#part','part'); seg('#size','size'); seg('#height','h',Number);
['#w','#d','#text'].forEach(id=>$(id).oninput=()=>{
  st.w=+$('#w').value; st.d=+$('#d').value; st.text=$('#text').value; paint(); run();
});

let timer, seq=0;
function run(){ clearTimeout(timer); timer=setTimeout(go,420); }
async function go(){
  const my=++seq;
  $('#out').innerHTML='<span class="spin">Building and checking&hellip;</span>';
  const q=new URLSearchParams({part:st.part,w:st.w,d:st.d,h:st.h,text:st.text,nx:3});
  try{
    const j=await (await fetch('/generate?'+q)).json();
    if(my!==seq) return;                     // a newer request already won
    if(!j.ok){ $('#out').innerHTML='<span class="err">'+j.error+'</span>'; return; }
    const cap = j.inner ? '<div><b>'+j.inner[0]+' × '+j.inner[1]+' × '+j.inner[2]+'</b>usable inside</div>' : '';
    $('#out').innerHTML='<img src="/png/'+j.key+'.png" alt="preview">'
      +'<div class="stats"><div><b>'+j.size.join(' × ')+'</b>mm outside</div>'+cap
      +'<div><b>'+(j.bytes/1024).toFixed(0)+' KB</b>watertight</div></div>'
      +'<div class="acts"><a class="primary" href="/set?'+q+'">Download complete case (zip)</a>'
      +'<a class="ghost" href="/stl/'+j.key+'.stl" download>Just this part</a></div>';
  }catch(e){ if(my===seq) $('#out').innerHTML='<span class="err">'+e+'</span>'; }
}
paint(); go();
</script></body></html>"""


class Handler(BaseHTTPRequestHandler):
    def log_message(self, *a):
        pass

    def _send(self, code, body, ctype, extra=None):
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(body)))
        for k, v in (extra or {}).items():
            self.send_header(k, v)
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        u = urllib.parse.urlparse(self.path)
        q = urllib.parse.parse_qs(u.query)

        if u.path == "/":
            presets = "".join(
                f'<button data-v="{w}x{d}">{html.escape(n)}<small>{w} × {d}</small></button>'
                for n, w, d in PRESETS)
            heights = "".join(
                f'<button data-v="{v}">{html.escape(n)}<small>{v} mm</small></button>'
                for n, v in HEIGHTS)
            page = PAGE.replace("__PRESETS__", presets).replace("__HEIGHTS__", heights)
            return self._send(200, page.encode(), "text/html; charset=utf-8")

        if u.path == "/generate":
            part = q.get("part", ["body"])[0]
            if part not in ("body", "cap", "label", "plate"):
                return self._send(400, b'{"ok":false,"error":"unknown part"}', "application/json")
            text = q.get("text", [""])[0]
            if not SAFE_TEXT.match(text):
                return self._send(200, json.dumps({
                    "ok": False,
                    "error": "Label text: letters, digits and . _ + / & ( ) - only, 22 max"
                }).encode(), "application/json")
            w = clamp(q.get("w", [38])[0], 18, 140, 38)
            d = clamp(q.get("d", [63])[0], 18, 140, 63)
            h = clamp(q.get("h", [127])[0], 60, 145, 127)
            nx = clamp(q.get("nx", [3])[0], 1, 5, 3)
            return self._send(200, json.dumps(generate(part, w, d, h, text, nx)).encode(),
                              "application/json")

        if u.path == "/set":
            text = q.get("text", [""])[0]
            if not SAFE_TEXT.match(text):
                return self._send(400, b"bad label text", "text/plain")
            w = clamp(q.get("w", [38])[0], 18, 140, 38)
            d = clamp(q.get("d", [63])[0], 18, 140, 63)
            h = clamp(q.get("h", [127])[0], 60, 145, 127)
            wanted = [("body", text), ("cap", ""), ("label", text)]
            buf = io.BytesIO()
            with zipfile.ZipFile(buf, "w", zipfile.ZIP_DEFLATED) as z:
                for part, t in wanted:
                    res = generate(part, w, d, h, t, 3)
                    if not res.get("ok"):
                        return self._send(409, res.get("error", "failed").encode(), "text/plain")
                    src = os.path.join(CACHE, f"{res['key']}.stl")
                    slug = re.sub(r"[^A-Za-z0-9]+", "-", text).strip("-").lower() or "blank"
                    # the cap fits every height, so its filename must not imply one
                    name = {"body": f"cordcase_body_{w:.0f}x{d:.0f}x{h:.0f}.stl",
                            "cap": f"cordcase_cap_{w:.0f}x{d:.0f}_fits-all-heights.stl",
                            "label": f"cordcase_label_{h:.0f}_{slug}.stl"}[part]
                    z.write(src, name)
                z.writestr("PRINT-ME.txt",
                           "CordCase - one complete case\n"
                           "===========================\n\n"
                           f"Body   {w:.0f} x {d:.0f} x {h:.0f} mm  (prints upright, no supports)\n"
                           f"Cap    print in a CONTRASTING filament\n"
                           f"Label  1 mm thin - lay flat, 100%% infill\n\n"
                           "FlashForge Adventurer 3C: pick the 'Adventurer 3 Series 0.4 nozzle'\n"
                           "profile, 0.2 mm layers, 4 walls, 15%% infill, SUPPORTS OFF, RAFT OFF.\n")
            data = buf.getvalue()
            return self._send(200, data, "application/zip",
                              {"Content-Disposition": 'attachment; filename="cordcase-set.zip"'})

        m = re.fullmatch(r"/(stl|png)/([0-9a-f]{16})\.(stl|png)", u.path)
        if m and m.group(1) == m.group(3):
            path = os.path.join(CACHE, f"{m.group(2)}.{m.group(3)}")
            if os.path.exists(path):
                ctype = "model/stl" if m.group(3) == "stl" else "image/png"
                extra = ({"Content-Disposition":
                          f'attachment; filename="cordcase_{m.group(2)}.stl"'}
                         if m.group(3) == "stl" else None)
                return self._send(200, open(path, "rb").read(), ctype, extra)

        self._send(404, b"not found", "text/plain")


if __name__ == "__main__":
    os.makedirs(CACHE, exist_ok=True)
    print(f"CordCase configurator on http://127.0.0.1:{PORT}")
    ThreadingHTTPServer(("127.0.0.1", PORT), Handler).serve_forever()
