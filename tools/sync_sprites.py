"""Copies game sprites into the app bundle (T-027, D-024): Mochi's base
frames and class outfit frames as-is, gear slot icons trimmed to their
bounding box and scaled to at most 220 px.

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
# class outfits (D-024): Mochi drawn in each class's outfit, one file per
# frame; classes without a folder yet fall back to the frames above
outfits = 0
for src in sorted(glob.glob(f'{ROOT}/assets/raw/frames/outfit/*/*.png')):
    cls = os.path.basename(os.path.dirname(src))
    shutil.copy(src, f'{OUT}/cat/outfit_{cls}_{os.path.basename(src)}')
    outfits += 1
# gear: slot icons only (D-024: gear is never drawn on the cat)
n = 0
for src in sorted(glob.glob(f'{ROOT}/assets/raw/frames/gear/*.png')):
    name = os.path.basename(src)[:-4].replace('gear_', '', 1)
    im = Image.open(src)
    im = im.crop(im.getbbox())
    # drawn at ≤ ~150 px on a phone: 220 px keeps it crisp and the APK small
    s = min(1, 220 / max(im.size))
    im.resize((round(im.width * s), round(im.height * s)), Image.LANCZOS).save(
        f'{OUT}/gear/{name}.png', optimize=True)
    n += 1
# monsters + bosses (feet-aligned frames, as sliced)
os.makedirs(f'{OUT}/mon', exist_ok=True)
m = 0
for src in sorted(glob.glob(f'{ROOT}/assets/raw/frames/eraserslime/*.png') +
                  glob.glob(f'{ROOT}/assets/raw/frames/acorn/*.png') +
                  glob.glob(f'{ROOT}/assets/raw/frames/eraserking/*.png')):
    name = os.path.basename(src)[:-4].replace('mon_', '').replace('boss_', '')
    shutil.copy(src, f'{OUT}/mon/{name}.png')
    m += 1
# parallax layers, scaled down to a phone-sized height
os.makedirs(f'{OUT}/bg', exist_ok=True)
for src in sorted(glob.glob(f'{ROOT}/assets/raw/backgrounds/*.png')):
    im = Image.open(src)
    s = 400 / im.height
    im.resize((round(im.width * s), 400), Image.LANCZOS).save(
        f'{OUT}/bg/{os.path.basename(src)}', optimize=True)
# boss faces for the challenge button
os.makedirs(f'{OUT}/ui', exist_ok=True)
for src in sorted(glob.glob(f'{ROOT}/assets/raw/frames/ui/*.png')):
    shutil.copy(src, f'{OUT}/ui/{os.path.basename(src)}')
print(f'{len(FRAMES)} cat frames + {outfits} outfit frames + {n} gear + {m} monster frames + bg + ui → {OUT}')
