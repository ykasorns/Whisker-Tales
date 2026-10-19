"""Copies game sprites into the app bundle (T-027): Mochi full-body frames
as-is (anchors are in their pixels) and gear art trimmed to its bounding box
(gear grips in anchors_mochi.json are fractions of the trimmed image).

    python3 tools/sync_sprites.py
"""
import glob, os, shutil
from PIL import Image

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
OUT = f'{ROOT}/app/assets/game'
FRAMES = ['idle', 'walk_f1', 'walk_f2', 'walk_f3', 'dodge', 'hurt', 'victory', 'sleep',
          'bare_novice', 'bare_warrior', 'bare_rogue', 'bare_archer', 'bare_mage']

shutil.rmtree(OUT, ignore_errors=True)
os.makedirs(f'{OUT}/cat', exist_ok=True)
os.makedirs(f'{OUT}/gear', exist_ok=True)
for f in FRAMES:
    shutil.copy(f'{ROOT}/assets/raw/frames/mochi2/cat_mochi_{f}.png', f'{OUT}/cat/{f}.png')
n = 0
for src in sorted(glob.glob(f'{ROOT}/assets/raw/frames/gear/*.png')):
    name = os.path.basename(src)[:-4].replace('gear_', '', 1)
    im = Image.open(src)
    im.crop(im.getbbox()).save(f'{OUT}/gear/{name}.png', optimize=True)
    n += 1
print(f'{len(FRAMES)} cat frames + {n} gear images → {OUT}')
