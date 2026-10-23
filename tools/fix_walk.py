"""Replace a class outfit's three walk frames with a redone walk cycle whose
legs really alternate (YK 2026-10-23: walk 1 and walk 3 had the same leg
forward).

    python3 -I tools/fix_walk.py novice assets/raw/sheets/sheet_walk_novice.png

The redone sheet is 3 columns × 1 row: walk 1, walk 2 (passing), walk 3.
Frames are sliced on a shared ground line, scaled so the passing pose is as
tall as the shipped one, and placed on the shipped canvas feet-down and
centred, so nothing else (ground line, anchors) changes.
"""
import glob
import os
import subprocess
import sys
import tempfile

from PIL import Image

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
def require_magenta(path: str) -> None:
    """Stop when the sheet's border is not the magenta key colour — a wrong
    file (e.g. something else picked up from Downloads) must never be sliced."""
    import numpy as np
    from PIL import Image
    rgb = np.asarray(Image.open(path).convert('RGB'))
    border = np.concatenate([rgb[:4].reshape(-1, 3), rgb[-4:].reshape(-1, 3),
                             rgb[:, :4].reshape(-1, 3), rgb[:, -4:].reshape(-1, 3)])
    r, g, b = np.median(border, axis=0)
    if not (r > 200 and b > 200 and g < 90):
        sys.exit(f'ERROR: {path} is not on a magenta background (border {int(r)},{int(g)},{int(b)}) — wrong file?')

cls, sheet = sys.argv[1], sys.argv[2]
require_magenta(sheet)
OUT = f'{ROOT}/assets/raw/frames/outfit/{cls}'

with tempfile.TemporaryDirectory() as tmp:
    r = subprocess.run(
        ['python3', '-I', f'{ROOT}/tools/sprite_slicer/slice_sheet.py', sheet,
         '--cols', '3', '--rows', '1', '--names', 'walk_f1,walk_f2,walk_f3',
         '--out', tmp, '--align', 'ground'], capture_output=True, text=True)
    print(r.stdout[-300:], r.stderr[-300:])
    if r.returncode:
        sys.exit(r.returncode)
    new = {n: Image.open(f'{tmp}/{n}.png').convert('RGBA')
           for n in ('walk_f1', 'walk_f2', 'walk_f3')}

old2 = Image.open(f'{OUT}/walk_f2.png').convert('RGBA')
cw, ch = old2.size
ob = old2.getbbox()
old_h, feet, cx = ob[3] - ob[1], ob[3], (ob[0] + ob[2]) / 2
nb = new['walk_f2'].getbbox()
s = old_h / (nb[3] - nb[1])
print(f'scale {s:.3f} (new passing pose {nb[3] - nb[1]} px → {old_h} px)')
# one centre for the whole cycle (the passing pose's), so the body does not drift
ncx = (nb[0] + nb[2]) / 2
for name, im in new.items():
    im = im.resize((round(im.width * s), round(im.height * s)), Image.LANCZOS)
    b = im.getbbox()
    out = Image.new('RGBA', (cw, ch), (0, 0, 0, 0))
    ox = round(cx - ncx * s)
    oy = round(feet - b[3])
    out.alpha_composite(im, (max(ox, -im.width), oy))
    out.save(f'{OUT}/{name}.png')
print('replaced', ', '.join(sorted(new)))
