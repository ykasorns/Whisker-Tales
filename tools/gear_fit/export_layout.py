"""Exports the expected gear layout (D-012 render order) for every frame ×
class as JSON — the Dart avatar module (T-027) must match it exactly.

    python3 tools/gear_fit/export_layout.py packages/wt_core/test/avatar/layout_expected.json
"""
import json, os, sys
from PIL import Image

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
A = json.load(open(f'{ROOT}/design/art/anchors_mochi.json'))
FR, GS, RO = A['frames'], A['gear'], A['render_order']
W = json.load(open(f'{ROOT}/design/data/wardrobe.json'))

def size(name):  # trimmed gear image size, as the app bundles it
    im = Image.open(f'{ROOT}/assets/raw/frames/gear/gear_{name}.png')
    b = im.getbbox()
    return b[2] - b[0], b[3] - b[1]

def gear(name, x, y, deg=0, scale=1.0):
    base = name.rsplit('_', 1)[0]
    g = GS[base]; iw, ih = size(name)
    h = g['size'] * scale; w = iw / ih * h
    return {'op': 'gear', 'image': name, 'x': x, 'y': y, 'w': round(w, 3), 'h': round(h, 3),
            'gx': round(g['grip'][0] * w, 3), 'gy': round(g['grip'][1] * h, 3), 'deg': deg}

def layout(key, cls, tier=2):
    a = FR[key]; ops = []
    weapon = f"{W['weapon_art'][cls]}_{tier}"
    off = W['off_hand_art'].get(cls)
    back = a.get('back') or [a['head'][0] - 55, a['head'][1] + 150]
    ops.append(gear(f'bag_{tier}', back[0], back[1]))
    if off and a.get('bp'):
        deg = (a.get('bpDeg', a['fpDeg'])) if off == 'dagger' else 0
        ops.append(gear(f'{off}_{tier}', a['bp'][0], a['bp'][1], deg))
    if a.get('fp') and a.get('fpBehind'):
        ops.append(gear(weapon, a['fp'][0], a['fp'][1], a['fpDeg']))
    ops.append({'op': 'cat'})
    ops.append(gear(f'scarf_{tier}', a['neck'][0], a['neck'][1], 0, RO['scarf_scale']))
    (x1, y1), (x2, y2) = a['chin']
    ops.append({'op': 'restamp', 'poly': [[x1 - 200, y1 - 400], [x2 + 200, y2 - 400], [x2 + 200, y2], [x1 - 200, y1]]})
    for occ in a.get('occluders', []):
        ops.append({'op': 'restamp', 'poly': occ})
    ops.append(gear(f'hat_{tier}', a['head'][0] + a['hat'][0], a['head'][1] + a['hat'][1], a['hatDeg'], RO['hat_scale']))
    if a.get('fp') and not a.get('fpBehind'):
        ops.append(gear(weapon, a['fp'][0], a['fp'][1], a['fpDeg']))
        ops.append({'op': 'restamp', 'circle': [a['fp'][0], a['fp'][1], RO['paw_radius']]})
    return ops

out = {f'{k}|{c}': layout(k, c) for k in FR for c in ['warrior', 'rogue', 'archer', 'mage']}
os.makedirs(os.path.dirname(sys.argv[1]), exist_ok=True)
json.dump(out, open(sys.argv[1], 'w'), indent=0)
print(len(out), 'layouts')
