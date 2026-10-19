"""Gear-fit preview (D-012): draws Mochi frames with gear on the anchors in
design/art/anchors_mochi.json, using the render order there (chin / paw /
occluder re-stamps), into one contact sheet — for measuring anchors of new
frames or skins.

    python3 tools/gear_fit/render.py out.png [overrides.json]
"""
import json, sys
from PIL import Image, ImageDraw

import os
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
A = json.load(open(f'{ROOT}/design/art/anchors_mochi.json'))
FR, GS = A['frames'], A['gear']
CLASS_GEAR = {'novice': {}, 'warrior': {'fp': 'sword', 'bp': 'shield'}, 'rogue': {'fp': 'dagger', 'bp': 'dagger'},
              'archer': {'fp': 'bow'}, 'mage': {'fp': 'staff'}}

def gear_img(name, tier):
    im = Image.open(f'{ROOT}/assets/raw/frames/gear/gear_{name}_{tier}.png').convert('RGBA')
    return im.crop(im.getbbox())

def paste_gear(canvas, name, tier, x, y, deg=0, scale=1.0):
    im = gear_img(name, tier); g = GS[name]
    h = g['size'] * scale; w = im.width / im.height * h
    im = im.resize((max(1, round(w)), max(1, round(h))), Image.LANCZOS)
    gx, gy = g['grip'][0] * w, g['grip'][1] * h
    # rotate around grip: pad so grip is centre
    pad = int(max(w, h) * 2)
    big = Image.new('RGBA', (pad, pad), (0, 0, 0, 0))
    ox, oy = round(pad / 2 - gx), round(pad / 2 - gy)
    big.alpha_composite(im, (ox, oy))
    big = big.rotate(-deg, resample=Image.BICUBIC, center=(pad / 2, pad / 2))
    canvas.alpha_composite(big, (round(x - pad / 2), round(y - pad / 2)))

def restamp(canvas, cat, off, mask):
    """Draw the cat again over gear, only where mask is set."""
    layer = Image.new('RGBA', canvas.size, (0, 0, 0, 0))
    layer.alpha_composite(cat, off)
    m = Image.new('L', canvas.size, 0)
    mask(ImageDraw.Draw(m))
    canvas.paste(layer, (0, 0), Image.composite(layer, Image.new('RGBA', canvas.size, (0,0,0,0)), m).getchannel('A'))

def render(key, cls, tier=2, look=('hat', 'scarf', 'bag'), fix=None):
    a = FR[key]
    cat = Image.open(f'{ROOT}/assets/raw/frames/mochi2/cat_mochi_{key}.png').convert('RGBA')
    P = 120
    W, H = cat.width + 2 * P, cat.height + 2 * P
    c = Image.new('RGBA', (W, H), (235, 230, 215, 255))
    off = (P, P)
    def at(p, d=(0, 0)): return (p[0] + d[0] + P, p[1] + d[1] + P)
    cg = CLASS_GEAR[cls]
    f = fix or {}
    hx, hy = a['head']
    # behind body
    if 'bag' in look:
        bk = f.get('back', {}).get(key)
        bx, by = at(bk) if bk else at(a['head'], (-55, 150))
        paste_gear(c, 'bag', tier, bx, by)
    if cg.get('bp') == 'dagger' and a.get('bp'):
        x, y = at(a['bp']); paste_gear(c, 'dagger', tier, x, y, a.get('bpDeg', a['fpDeg']))
    if f.get('shield_behind') and cg.get('bp') == 'shield' and a.get('bp'):
        x, y = at(a['bp']); paste_gear(c, 'shield', tier, x, y)
    behind = key in f.get('fp_behind', [])
    if behind and cg.get('fp') and a.get('fp'):
        x, y = at(a['fp']); paste_gear(c, cg['fp'], tier, x, y, a['fpDeg'])
    c.alpha_composite(cat, off)
    if 'scarf' in look:
        n = f.get('neck', {}).get(key)
        sx, sy = at(a['head'], (20, 125)) if not n else at(n['p'])
        paste_gear(c, 'scarf', tier, sx, sy, n.get('deg', 0) if n else 0, n.get('s', 1) if n else 1)
        if n and 'chin' in n:
            # cat pixels above the chin line come back on top of the scarf
            (x1, y1), (x2, y2) = n['chin']
            poly = [at((x1 - 200, y1 - 400)), at((x2 + 200, y2 - 400)), at((x2 + 200, y2)), at((x1 - 200, y1))]
            restamp(c, cat, off, lambda d: d.polygon(poly, fill=255))
        for occ in f.get('occluders', {}).get(key, []):
            pts = [at(q) for q in occ]
            restamp(c, cat, off, lambda d, pts=pts: d.polygon(pts, fill=255))
    if 'hat' in look:
        hd = f.get('hat', {}).get(key, {})
        x, y = at(a['head'], hd.get('d', (0, 20)))
        paste_gear(c, 'hat', tier, x, y, hd.get('deg', 0), hd.get('s', 1))
    if not f.get('shield_behind') and cg.get('bp') == 'shield' and a.get('bp'):
        x, y = at(a['bp']); paste_gear(c, 'shield', tier, x, y)
    if not behind and cg.get('fp') and a.get('fp'):
        x, y = at(a['fp']); paste_gear(c, cg['fp'], tier, x, y, a['fpDeg'])
        paw = f.get('paw', {}).get(key)
        if paw:
            cx, cy = at(paw['c']); r = paw['r']
            restamp(c, cat, off, lambda d: d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=255))
    return c

def sheet(items, out, cols=4, scale=0.6):
    ims = [render(*it[:2], **(it[2] if len(it) > 2 else {})) for it in items]
    w = max(i.width for i in ims); h = max(i.height for i in ims)
    rows = (len(ims) + cols - 1) // cols
    S = Image.new('RGBA', (w * cols, h * rows), (255, 255, 255, 255))
    for i, im in enumerate(ims):
        S.alpha_composite(im, ((i % cols) * w, (i // cols) * h))
    S = S.resize((round(S.width * scale), round(S.height * scale)), Image.LANCZOS)
    S.convert('RGB').save(out)

if __name__ == '__main__':
    fix = json.load(open(sys.argv[2])) if len(sys.argv) > 2 else {
        'neck': {k: {'p': v['neck'], 'chin': v['chin'], 's': A['render_order']['scarf_scale']} for k, v in FR.items()},
        'paw': {k: {'c': v['fp'], 'r': A['render_order']['paw_radius']} for k, v in FR.items() if v.get('fp')},
        'hat': {k: {'d': v['hat'], 'deg': v['hatDeg'], 's': A['render_order']['hat_scale']} for k, v in FR.items()},
        'back': {k: v['back'] for k, v in FR.items() if 'back' in v},
        'fp_behind': [k for k, v in FR.items() if v.get('fpBehind')],
        'occluders': {k: v['occluders'] for k, v in FR.items() if 'occluders' in v},
        'shield_behind': True}
    keys = [('idle', 'warrior'), ('walk_f1', 'warrior'), ('walk_f2', 'rogue'), ('walk_f3', 'archer'),
            ('bare_warrior', 'warrior'), ('bare_rogue', 'rogue'), ('bare_archer', 'archer'), ('bare_mage', 'mage'),
            ('bare_novice', 'novice'), ('dodge', 'mage'), ('hurt', 'rogue'), ('victory', 'warrior')]
    sheet([(k, c, {'fix': fix}) for k, c in keys], sys.argv[1])
