"""Slice one icon sheet from design/art/icon_sheets.json into
assets/raw/frames/icon/icon_<id>.png (D-037).

    python3 -I tools/slice_icon_sheet.py sheet_icons_2_ui
"""
import json
import os
import subprocess
import sys

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

name = sys.argv[1]
require_magenta(f'{ROOT}/assets/raw/sheets/{name}.png')
v = json.load(open(f'{ROOT}/design/art/icon_sheets.json'))[name]
r = subprocess.run(
    ['python3', '-I', f'{ROOT}/tools/sprite_slicer/slice_sheet.py',
     f'{ROOT}/assets/raw/sheets/{name}.png', '--cols', str(v['cols']),
     '--rows', str(v['rows']), '--names', ','.join(v.get('prefix', 'icon_') + i for i in v['ids']),
     '--out', f"{ROOT}/assets/raw/frames/{v.get('out', 'icon')}", '--align', 'center',
     '--spill-start', '110', '--last-row-cols', str(len(v['ids']) - v['cols'] * (v['rows'] - 1))],
    capture_output=True, text=True)
print(r.stdout[-600:], r.stderr[-400:])
sys.exit(r.returncode)
