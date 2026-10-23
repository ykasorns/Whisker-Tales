"""Slice one icon sheet from design/art/icon_sheets.json into
assets/raw/frames/icon/icon_<id>.png (D-037).

    python3 -I tools/slice_icon_sheet.py sheet_icons_2_ui
"""
import json
import os
import subprocess
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
name = sys.argv[1]
v = json.load(open(f'{ROOT}/design/art/icon_sheets.json'))[name]
r = subprocess.run(
    ['python3', '-I', f'{ROOT}/tools/sprite_slicer/slice_sheet.py',
     f'{ROOT}/assets/raw/sheets/{name}.png', '--cols', str(v['cols']),
     '--rows', str(v['rows']), '--names', ','.join('icon_' + i for i in v['ids']),
     '--out', f'{ROOT}/assets/raw/frames/icon', '--align', 'center',
     '--spill-start', '110', '--last-row-cols', str(len(v['ids']) - v['cols'] * (v['rows'] - 1))],
    capture_output=True, text=True)
print(r.stdout[-600:], r.stderr[-400:])
sys.exit(r.returncode)
