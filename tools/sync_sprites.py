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
# Generated sheets draw the cat a little larger than the base frames, so
# they are scaled to the same body size (×0.85 ≈ 291 px tall) and reduced to
# 256 colours to keep the APK under the 30 MB send limit.
OUTFIT_SCALE = 0.85
outfits = 0
for src in sorted(glob.glob(f'{ROOT}/assets/raw/frames/outfit/*/*.png')):
    cls = os.path.basename(os.path.dirname(src))
    name = os.path.basename(src)
    # The Warrior attacks with the sword in the left paw and the shield
    # strapped to the right forearm. Keep the original sheet slice as the
    # fallback source, but publish the corrected hand assignment as attack.
    if name == 'attack_right_shield.png':
        continue
    if cls == 'warrior' and name == 'attack.png':
        corrected = f'{os.path.dirname(src)}/attack_right_shield.png'
        if os.path.exists(corrected):
            src = corrected
    im = Image.open(src).convert('RGBA')
    im = im.resize((round(im.width * OUTFIT_SCALE), round(im.height * OUTFIT_SCALE)),
                   Image.LANCZOS)
    im = im.quantize(colors=256, method=Image.Quantize.FASTOCTREE)
    im.save(f'{OUT}/cat/outfit_{cls}_{name}', optimize=True)
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
MONSTERS = ['eraserslime', 'acorn', 'eraserking',   # book 1 chapter 1
            'inkbat', 'crayonsnail', 'sharpcrab',    # chapter 2
            'shavinghog', 'clipbeetle', 'paperwolf']  # chapter 3
for src in sorted(f for k in MONSTERS
                  for f in glob.glob(f'{ROOT}/assets/raw/frames/{k}/*.png')):
    name = os.path.basename(src)[:-4].replace('mon_', '').replace('boss_', '')
    shutil.copy(src, f'{OUT}/mon/{name}.png')
    m += 1
# parallax layers, scaled down to a phone-sized height
os.makedirs(f'{OUT}/bg', exist_ok=True)
for src in sorted(glob.glob(f'{ROOT}/assets/raw/backgrounds/*.png')):
    im = Image.open(src)
    s = 400 / im.height
    # painted layers: lossy WebP (≈ ⅓ of the PNG, no visible change) keeps
    # the APK under the 30 MB send limit with the ads SDK in (D-033)
    im.resize((round(im.width * s), 400), Image.LANCZOS).save(
        f'{OUT}/bg/{os.path.basename(src)[:-4]}.webp', quality=88, method=6)
# pets (T-038): idle + attack per pet, drawn small beside Mochi
os.makedirs(f'{OUT}/pet', exist_ok=True)
for src in sorted(glob.glob(f'{ROOT}/assets/raw/frames/pets/*.png')):
    im = Image.open(src)
    s = 200 / im.height
    im.resize((round(im.width * s), 200), Image.LANCZOS).save(
        f'{OUT}/pet/{os.path.basename(src)}', optimize=True)
# UI icons (D-037): painted replacements for the emoji — trimmed, ≤ 128 px
os.makedirs(f'{OUT}/icon', exist_ok=True)
for src in sorted(glob.glob(f'{ROOT}/assets/raw/frames/icon/*.png')):
    name = os.path.basename(src)[:-4].replace('icon_', '', 1)
    im = Image.open(src).convert('RGBA')
    im = im.crop(im.getbbox())
    pad = round(max(im.size) * 0.04)  # a hair of room so outlines are not cut
    sq = Image.new('RGBA', (max(im.size) + 2 * pad,) * 2, (0, 0, 0, 0))
    sq.alpha_composite(im, ((sq.width - im.width) // 2, (sq.height - im.height) // 2))
    s = min(1, 128 / sq.width)
    sq.resize((round(sq.width * s),) * 2, Image.LANCZOS).save(f'{OUT}/icon/{name}.png', optimize=True)
# home panel art (D-040): the yarn basket and its balls, bigger than the
# icons because they are drawn at ~190 dp
os.makedirs(f'{OUT}/home', exist_ok=True)
for src in sorted(glob.glob(f'{ROOT}/assets/raw/frames/home/*.png')):
    im = Image.open(src).convert('RGBA')
    im = im.crop(im.getbbox())
    cap = 720 if os.path.basename(src) == 'basket.png' else 256
    s = min(1, cap / max(im.size))
    im.resize((round(im.width * s), round(im.height * s)), Image.LANCZOS).save(
        f'{OUT}/home/{os.path.basename(src)}', optimize=True)
# boss faces for the challenge button
os.makedirs(f'{OUT}/ui', exist_ok=True)
for src in sorted(glob.glob(f'{ROOT}/assets/raw/frames/ui/*.png')):
    im = Image.open(src)
    im.thumbnail((160, 160), Image.LANCZOS)  # drawn at ~58 px
    im.save(f'{OUT}/ui/{os.path.basename(src)}', optimize=True)
# Full-size storybook surfaces are already optimized as WebP. Keep them in
# the source tree so a sprite sync cannot remove the live UI's background.
for src in sorted(glob.glob(f'{ROOT}/assets/raw/ui/*.webp')):
    shutil.copy(src, f'{OUT}/ui/{os.path.basename(src)}')
# Storybook UI kit generated from the approved D-054 mockup. Keep the full
# source atlas in assets/raw and publish tight transparent slices so Flutter
# lays live text and icons over painted frames rather than simulated boxes.
ui_kit = f'{ROOT}/assets/raw/ui/ui_storybook_kit.png'
if os.path.exists(ui_kit):
    atlas = Image.open(ui_kit).convert('RGBA')
    slices = {
        'ui_frame_profile.png': (30, 95, 650, 415),
        'ui_frame_chapter.png': (675, 135, 1254, 400),
        'ui_frame_currency.png': (35, 535, 650, 795),
        'ui_frame_action.png': (650, 540, 1254, 795),
        'ui_frame_nav_dock.png': (15, 885, 925, 1160),
        'ui_frame_nav_selected.png': (920, 820, 1240, 1230),
    }
    for name, box in slices.items():
        im = atlas.crop(box)
        if bbox := im.getbbox():
            im = im.crop(bbox)
        im.thumbnail((960, 480), Image.LANCZOS)
        im.save(f'{OUT}/ui/{name}', optimize=True)
# The phone pass found that the atlas currency plaque was too short and had
# to be stretched almost 2×. Publish a native 4.5:1 version instead so leaves,
# paper grain and the plus medallion keep their painted proportions.
currency_tag = f'{ROOT}/assets/raw/ui/ui_currency_tag_wide.png'
if os.path.exists(currency_tag):
    im = Image.open(currency_tag).convert('RGBA')
    # Image generation may leave almost-transparent specks in the empty
    # canvas. Ignore them or the nominal canvas stays tall and Flutter still
    # has to stretch the visible plaque.
    visible_alpha = im.getchannel('A').point(lambda a: 255 if a >= 24 else 0)
    if bbox := visible_alpha.getbbox():
        im = im.crop(bbox)
    im.thumbnail((960, 240), Image.LANCZOS)
    im.save(f'{OUT}/ui/ui_frame_currency.png', optimize=True)
# D-060: calmer UI frames (GPT, assets/raw/frames/ui_v2). They are generated at
# the exact size ui_frames.json was measured on, so they replace the atlas
# slices above under the same published names. Tab icons and the cooldown
# badge are new, small pieces.
v2 = f'{ROOT}/assets/raw/frames/ui_v2'
if os.path.isdir(v2):
    for name in ('profile', 'chapter', 'currency', 'action', 'nav_dock',
                 'nav_selected'):
        src = f'{v2}/ui_frame_{name}_v2.png'
        if os.path.exists(src):
            Image.open(src).convert('RGBA').save(
                f'{OUT}/ui/ui_frame_{name}.png', optimize=True)
    badge = f'{v2}/ui_badge_cooldown_v2.png'
    if os.path.exists(badge):
        Image.open(badge).convert('RGBA').save(
            f'{OUT}/ui/ui_badge_cooldown.png', optimize=True)
    for src in sorted(glob.glob(f'{v2}/ui_dock_icons_v2/nav_*.png')):
        Image.open(src).convert('RGBA').save(
            f'{OUT}/ui/{os.path.basename(src)}', optimize=True)
# D-062: Story Run art (GPT, assets/raw/frames/story_v1): speaker portraits,
# choice cards and combat hit sparks.
sv1 = f'{ROOT}/assets/raw/frames/story_v1'
for sub in ('portraits', 'cards', 'fx'):
    for src in sorted(glob.glob(f'{sv1}/{sub}/*.png')):
        os.makedirs(f'{OUT}/story/{sub}', exist_ok=True)
        Image.open(src).convert('RGBA').save(
            f'{OUT}/story/{sub}/{os.path.basename(src)}', optimize=True)
# 256 colours for every sprite (not the painted backgrounds, which band):
# the art is flat-shaded, so it looks the same and the APK stays under the
# 30 MB send limit (D-030)
for f in glob.glob(f'{OUT}/**/*.png', recursive=True):
    if f'{os.sep}bg{os.sep}' in f:
        continue
    im = Image.open(f)
    if im.mode != 'P':
        im.convert('RGBA').quantize(colors=256, method=Image.Quantize.FASTOCTREE) \
            .save(f, optimize=True)
print(f'{len(FRAMES)} cat frames + {outfits} outfit frames + {n} gear + {m} monster frames + bg + ui → {OUT}')
