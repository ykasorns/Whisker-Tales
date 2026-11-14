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
            'shavinghog', 'clipbeetle', 'paperwolf',  # chapter 3
            'pincushionmole', 'buttonladybug', 'quiltbear',  # book 2 chapter 4
            'sockjelly', 'spoolfrog', 'thimbleturtle',       # chapter 5
            'woolpuff', 'tangleball', 'yarnyeti']             # chapter 6
for src in sorted(f for k in MONSTERS
                  for f in glob.glob(f'{ROOT}/assets/raw/frames/{k}/*.png')):
    name = os.path.basename(src)[:-4].replace('mon_', '').replace('boss_', '')
    shutil.copy(src, f'{OUT}/mon/{name}.png')
    m += 1
# Treat Dungeon (D-065): guardians draw only idle ×3, attack and defeated, so
# only those ship, at most 440 px wide (drawn at ~200 dp)
DUNGEON_BOSSES = ['cookiegolem', 'jellyking', 'cakedragon']
DUNGEON_FRAMES = ['idle_f1', 'idle_f2', 'idle_f3', 'attack', 'defeated']
for k in DUNGEON_BOSSES:
    for f in DUNGEON_FRAMES:
        src = f'{ROOT}/assets/raw/frames/{k}/boss_{k}_{f}.png'
        if not os.path.exists(src):
            continue
        im = Image.open(src).convert('RGBA')
        s = min(1, 440 / im.width)
        im.resize((round(im.width * s), round(im.height * s)), Image.LANCZOS).save(
            f'{OUT}/mon/{k}_{f}.png', optimize=True)
        m += 1
os.makedirs(f'{OUT}/dungeon', exist_ok=True)
for src in sorted(glob.glob(f'{ROOT}/assets/raw/frames/dungeon_v1/prizes/*.png')):
    shutil.copy(src, f'{OUT}/dungeon/{os.path.basename(src)}')
if os.path.exists(f'{ROOT}/assets/raw/frames/dungeon_v1/mode_dungeon.png'):
    im = Image.open(f'{ROOT}/assets/raw/frames/dungeon_v1/mode_dungeon.png').convert('RGBA')
    im.resize((192, 192), Image.LANCZOS).save(f'{OUT}/dungeon/mode_dungeon.png', optimize=True)
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
# Animated class-skill effects: eight chronological frames per skill.  The
# raw 256 px masters stay in assets/raw; 192 px is ample for their largest
# in-game draw size and keeps the mobile bundle compact.
os.makedirs(f'{OUT}/skill_fx', exist_ok=True)
skill_fx = 0
SKILL_FX_IDS = ['shield_bash', 'iron_wall', 'war_cry', 'twin_strike',
                'poison_blade', 'shadow_step', 'power_shot', 'arrow_rain',
                'eagle_eye', 'fireball', 'frost_nova', 'meteor']
for skill in SKILL_FX_IDS:
    for src in sorted(glob.glob(
            f'{ROOT}/assets/raw/frames/skill_fx/{skill}/{skill}_[0-9][0-9].png')):
        frame = os.path.basename(src).removeprefix(f'{skill}_')
        im = Image.open(src).convert('RGBA').resize((192, 192), Image.LANCZOS)
        im.save(f'{OUT}/skill_fx/{skill}_{frame}', optimize=True)
        skill_fx += 1
# Hand-painted bitmap combat digits. Variable widths are preserved so a "1"
# does not occupy the same horizontal space as an "8" when numbers compose.
os.makedirs(f'{OUT}/damage_numbers', exist_ok=True)
damage_glyphs = 0
for style in ('normal', 'skill', 'crit', 'hurt'):
    for src in sorted(glob.glob(
            f'{ROOT}/assets/raw/frames/damage_numbers/{style}/*.png')):
        im = Image.open(src).convert('RGBA')
        width = round(im.width * 128 / im.height)
        im.resize((width, 128), Image.LANCZOS).save(
            f'{OUT}/damage_numbers/{style}_{os.path.basename(src)}',
            optimize=True)
        damage_glyphs += 1
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
# D-069: UI kit v3 (GPT, assets/raw/ui_v3/widgets). Only pieces at their brief
# size are published (a raw oversized generation is skipped until it is
# redone); colours are reduced to 256 so the kit stays small.
# UI kit v3 (D-069). Every piece is cropped to its painted area: the files
# carry transparent margins (a button face is ~60% of its file's height), and
# a box decorated with an untrimmed piece shows a face smaller than the box,
# so labels sit outside it. Stretch pieces also get their slice (the part that
# stretches) written to app/lib/ui/kit_specs.g.dart, measured after the crop.
#   name: (file w, file h, kind, cap)   kind: 'nine' = corners `cap` px,
#   'pill' = round ends `cap` px wide, middle stretches both ways,
#   'fixed' = drawn whole.
KIT = {
    'ui_panel_card': (256, 256, 'nine', 56), 'ui_panel_tile': (128, 128, 'nine', 32),
    'ui_panel_dialog': (384, 384, 'nine', 88), 'ui_panel_sheet': (512, 256, 'nine', 72),
    'ui_panel_inset': (256, 128, 'nine', 44),
    'ui_tab_strip': (768, 128, 'pill', 56), 'ui_tab_on': (256, 128, 'pill', 40),
    'ui_tab_off': (256, 128, 'pill', 40),
    'ui_btn_green': (480, 160, 'pill', 80), 'ui_btn_yellow': (480, 160, 'pill', 80),
    'ui_btn_purple': (480, 160, 'pill', 80), 'ui_btn_coral': (480, 160, 'pill', 80),
    'ui_btn_disabled': (480, 160, 'pill', 80),
    'ui_bar_track': (480, 64, 'pill', 32), 'ui_bar_fill_green': (480, 48, 'pill', 24),
    'ui_bar_fill_teal': (480, 48, 'pill', 24), 'ui_bar_fill_coral': (480, 48, 'pill', 24),
    'ui_bar_fill_sun': (480, 48, 'pill', 24),
    'ui_toast_plate': (480, 120, 'pill', 60), 'ui_chip_pill': (320, 96, 'pill', 48),
    'ui_btn_round_red': (160, 160, 'fixed', 0), 'ui_btn_round_cream': (160, 160, 'fixed', 0),
    'ui_toggle_track_off': (192, 96, 'fixed', 0), 'ui_toggle_track_on': (192, 96, 'fixed', 0),
    'ui_toggle_knob': (80, 80, 'fixed', 0), 'ui_sheet_grabber': (128, 32, 'fixed', 0),
    'ui_spinner_yarn': (192, 192, 'fixed', 0), 'ui_section_mark': (256, 48, 'fixed', 0),
    'ui_divider_stitch': (512, 24, 'fixed', 0), 'ui_badge_count': (96, 96, 'fixed', 0),
    'ui_badge_dot': (64, 64, 'fixed', 0), 'ui_ribbon_new': (192, 96, 'fixed', 0),
    'ui_slot_empty': (160, 160, 'fixed', 0), 'ui_slot_filled': (160, 160, 'fixed', 0),
    'ui_slot_locked': (160, 160, 'fixed', 0), 'ui_slot_selected': (160, 160, 'fixed', 0),
    **{f'ui_rim_g{i}': (160, 160, 'fixed', 0) for i in range(6)},
}
os.makedirs(f'{OUT}/kit', exist_ok=True)
kit_specs = []
for name, (fw, fh, kind, cap) in KIT.items():
    src = f'{ROOT}/assets/raw/ui_v3/widgets/{name}.png'
    if not os.path.exists(src):
        continue
    im = Image.open(src).convert('RGBA')
    if im.size != (fw, fh):
        print(f'kit: skipped {name} (size {im.size}, wants {(fw, fh)})')
        continue
    box = im.split()[3].point(lambda a: 255 if a > 24 else 0).getbbox()
    if kind != 'fixed':  # whole pieces keep their canvas: rims sit on slots,
        im = im.crop(box)  # a knob is centred in its track, a spinner turns
    w, h = im.size  # about the canvas centre
    if kind != 'fixed':
        left = max(4, cap - box[0])
        right = w - max(4, cap - (fw - box[2]))
        if kind == 'nine':
            top = max(4, cap - box[1])
            bottom = h - max(4, cap - (fh - box[3]))
        else:  # pill: only a thin band in the middle stretches up and down
            top, bottom = h // 2 - 2, h // 2 + 2
        assert 0 < left < right < w and 0 < top < bottom < h, name
        kit_specs.append((name, w, h, left, top, right, bottom))
    else:
        kit_specs.append((name, w, h, 0, 0, w, h))
    im.quantize(256, method=Image.FASTOCTREE, dither=Image.NONE).save(
        f'{OUT}/kit/{name}.png', optimize=True)
if kit_specs:
    with open(f'{ROOT}/app/lib/ui/kit_specs.g.dart', 'w') as f:
        f.write('// GENERATED by tools/sync_sprites.py from assets/raw/ui_v3 — do not edit.\n'
                '// Size of every published UI-kit picture and the part of it that\n'
                '// stretches, in picture pixels (after the transparent margin is cut).\n\n'
                'class KitSpec {\n'
                '  const KitSpec(this.w, this.h, this.left, this.top, this.right, this.bottom);\n'
                '  final double w, h, left, top, right, bottom;\n'
                '}\n\n'
                'const kitSpecs = <String, KitSpec>{\n')
        for kit_name, *v in kit_specs:
            f.write(f"  '{kit_name}': KitSpec({', '.join(str(x) for x in v)}),\n")
        f.write('};\n')
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
# D-067: collectible-style Adventure pick cards. These are full portrait
# frames rather than nine-slice boxes, so publish them at the phone draw size
# and preserve the transparent silhouette around the raised crest.
for src in sorted(glob.glob(
        f'{ROOT}/assets/raw/frames/story_v2/cards/*.png')):
    os.makedirs(f'{OUT}/story/cards_v2', exist_ok=True)
    Image.open(src).convert('RGBA').resize((320, 480), Image.LANCZOS).save(
        f'{OUT}/story/cards_v2/{os.path.basename(src)}', optimize=True)
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
print(f'{len(FRAMES)} cat frames + {outfits} outfit frames + {n} gear + '
      f'{m} monster frames + {skill_fx} skill FX frames + '
      f'{damage_glyphs} damage glyphs + bg + ui → {OUT}')
