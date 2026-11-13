# GPT task — UI kit v3 + missing icons: make the whole game one theme (D-069)

You are generating **image assets** for the Flutter game *Whisker Tales* (Android, kids/families, hand-painted colored-pencil storybook look). Read this whole file before drawing anything. Do not edit Dart code, JSON or docs; Claude wires the art in. Reply to YK in Thai; file names and notes inside files in English.

## 0. Where this comes from (audit by Claude, 2026-11-13)

Screens were captured from the real game (`app/test/goldens/**`). The painted pieces (HUD frames, bottom dock, wood action buttons, story cards, boss faces, 84 icons, gear, skill effects, damage numbers) already match each other. What breaks the theme is everything the **code draws itself**: flat pastel gradient rectangles, Material switches, flat progress bars, stock tab bars, flat green/yellow/purple buttons, system fonts glyphs. That is what this brief replaces.

| Surface in the game | Today | Decision |
|---|---|---|
| Top HUD frames (profile, currency, chapter), dock, wood "action" button plate | painted (frames v2) | **KEEP** (style anchor) |
| 84 icons (`app/assets/game/icon`, 128×128), 36 gear pictures, story cards v2, boss faces, home basket/yarn, pets, skill FX, damage numbers | painted | **KEEP** (style anchor; do not redraw) |
| List cards, stat tiles, settings rows, pet / library / shop / craft panels (49 `Card(` uses) | flat pastel gradient | **NEW** paper panels, section A1 |
| Dialogs and the bottom craft sheet | flat panel | **NEW** dialog + sheet panels, A1 |
| Character / pets / wardrobe / library page tabs | stock Material `TabBar` | **NEW** tab kit, A2 |
| "Watch ad" green, yellow, purple and coral pill buttons (shop, dungeon result, story result) | flat coloured rectangles | **NEW** pill buttons + round plates, A3 |
| Settings switches (2) | Material `Switch` | **NEW** toggle, A4 |
| Progress bars (library, research, XP, story HP, loading) | flat `LinearProgressIndicator` | **NEW** bar track + fills, A5 |
| Wardrobe grid cells, locked "?" cells, item grade borders | flat rounded squares | **NEW** slots + grade rims, A6 |
| Stat chips, red dash section marks, cooldown count, "new" tags, dividers, toasts, spinner | flat shapes / Material | **NEW** small parts, A7 |
| 24 stat attributes (armor pierce, thorns, lifesteal …) | **text only, no icon** (only evade, crit, skill damage have icons) | **NEW** stat icon sheets, B1 |
| `▶` speed button text, pet attack emoji 🧀 🥕 🌈 (system emoji in the pet cards) | system glyphs | **NEW** 4 icons on the second stat sheet, B1 |
| Adaptive launcher icon, store art | exists | out of scope |

Scope choice (YK, please note): the 84 existing icons and every painted frame stay as they are. Redrawing them would change nothing visible and force a round of screenshot-test updates. New pieces must **look like they came from the same hand** as these anchors: attach them (section 2).

## 1. Style block — paste VERBATIM at the top of every generation

```
STYLE: the same hand-painted colored-pencil storybook style as the reference images: bold dark ink outlines (#33291F, about 2.5% of the shortest side of the piece), vibrant saturated colored pencil strokes clearly visible at a diagonal angle (top-left to bottom-right), a single flat shadow tone, light coming from the TOP-LEFT (highlight on the top and left edges, shadow on the bottom and right edges, same on every piece), bright playful palette limited to warm orange #F6A83C, coral #EE6352, teal #3FA7B8, lime #8CC152, sun yellow #F9D64E, shadow plum #7A5E8C and cream #F6F0E1, plus honey-wood browns #8A552D and #57351F and paper cream #FFFBF2, no digital gradients, no airbrush, no glow, no drop shadow outside the piece, child-friendly. No text, letters or numbers inside any piece (the game draws Thai and English text itself).
```

Interface pieces additionally follow these rules:
- Wood is the same honey-brown wood as `ui_frame_action.png`: slim rim, no leaves, no vines, no knobs, no flowers. At most one tiny flat rivet per piece, only where this brief says so.
- Paper is flat warm cream. **The middle of every stretchable piece is plain flat paper**: no drawings, no texture strong enough to show when stretched, no gradient across the middle.
- Edges are painted with the same dark ink outline as the anchors; corners slightly hand-drawn, not geometric-perfect.

## 2. Reference images — attach ALL of these to every generation

1. `app/assets/game/ui/ui_frame_action.png` (wood plate, rim weight)
2. `app/assets/game/ui/ui_frame_currency.png` (rim + paper)
3. `app/assets/game/ui/ui_frame_nav_dock.png` (slots on wood)
4. `app/assets/game/story/cards_v2/card_relic_common.png` (paper card with painted border)
5. `assets/raw/sheets/sheet_gear_icons.png` (object icon style)
6. `assets/raw/sheets/sheet_icons_1_hud.png` (chunky icon style)

## 3. How the game uses each piece (so you draw it right)

- **9-slice panels**: Flutter stretches the centre of the image and keeps the four corners and four edges at their size. So: the **corners hold all the detail**, the edges are a uniform strip, the centre is flat. A cut through the middle column and the middle row must be identical along its whole length.
- **3-slice horizontal pieces** (pills, bars, tabs): the left and right caps keep their shape, only the middle stretches horizontally. The middle must be identical column by column. Height never changes.
- **Fixed pieces** are drawn at their size and never stretched (icons, knob, dot, rim, spinner).
- Do **not** give rect numbers: Claude measures the finished PNGs (flood fill) and writes the slice data. Draw what the table says; Claude measures what you drew.
- **Output format for interface pieces: PNG, RGBA, true alpha, transparent background** (no magenta, no checkerboard, no shadow outside the piece). If your tool cannot write alpha, paint on flat magenta `#FF00FF` (none inside the art) and key it out yourself with despill (no pink fringe at any zoom). Deliver the keyed file.
- **Icon sheets (section B)**: flat magenta `#FF00FF` background, exactly as the existing icon sheets; Claude slices them.

## 4. A — UI kit pieces (transparent PNGs)

Sizes are exact pixels at 2× design size. Keep them exactly; the middle zone must be stretchable as described.

### A1 — Panels (9-slice)
| File | Size | Corner / edge zone | What it is |
|---|---|---|---|
| `ui_panel_card.png` | 256×256 | 56 px | Standard list card (library, shop, pets, settings rows). Cream paper `#FFFBF2` with a slim darker-cream hand-drawn border and a small soft shadow tone on the bottom-right inside edge. **Near-white paper, because the game tints it pink, mint, lilac or sky by multiplying a colour over it.** No wood. |
| `ui_panel_tile.png` | 128×128 | 32 px | Small tile for stat cells, wardrobe cells, chips-with-icon: same paper family as the card, thinner border, smaller radius. |
| `ui_panel_dialog.png` | 384×384 | 88 px | Pop-up panel (welcome back, confirmations, age check): slim honey-wood rim (same as the action plate) around flat cream paper; one tiny rivet in each corner is allowed. |
| `ui_panel_sheet.png` | 512×256 | top 72, left/right 56, bottom 24 | Bottom sheet (craft sheet): wood rim along the top and sides with rounded **top** corners; the bottom edge is cut flat with no rim (it sits at the screen edge). |
| `ui_sheet_grabber.png` | 128×32 | fixed | The little drag handle that sits at the top centre of the sheet: a short rounded wooden bar. |
| `ui_panel_inset.png` | 256×128 | 40 px | Sunken tray / shelf (the equipment row under the craft sheet): slightly darker cream, inner shadow on the top and left edges, thin outline. |

### A2 — Tabs (3-slice horizontal)
| File | Size | Caps | What it is |
|---|---|---|---|
| `ui_tab_strip.png` | 768×128 | 56 | The track behind the page tabs: a long slim wooden groove with a darker cream inside. |
| `ui_tab_on.png` | 256×128 | 40 | Selected tab: a raised cream paper tab with warm-orange tint and a visible bottom lip; looks lifted out of the strip. |
| `ui_tab_off.png` | 256×128 | 40 | Unselected tab: flat, slightly darker cream, no lip, sits inside the groove. Same silhouette as `ui_tab_on`. |

### A3 — Buttons (3-slice horizontal pills; the text area is a flat face)
| File | Size | Caps | What it is |
|---|---|---|---|
| `ui_btn_green.png` | 480×160 | 80 | Primary "confirm / watch" button: lime `#8CC152` flat face, dark ink outline, a lighter highlight stroke along the top-left, a thicker bottom lip in a darker green. |
| `ui_btn_yellow.png` | 480×160 | 80 | Same construction, sun yellow `#F9D64E`, lip in orange. |
| `ui_btn_purple.png` | 480×160 | 80 | Same construction, plum `#7A5E8C` face, lighter plum highlight (text on it is cream). |
| `ui_btn_coral.png` | 480×160 | 80 | Same construction, coral `#EE6352`. |
| `ui_btn_disabled.png` | 480×160 | 80 | Same construction, flat beige-grey `#B9AE9C`, lip darker beige. |
| `ui_btn_round_red.png` | 160×160 | fixed | Round close-button plate, coral face, no glyph (the game draws the cross icon). |
| `ui_btn_round_cream.png` | 160×160 | fixed | Round plate, cream face, wood rim, no glyph (info / back). |

All five pills keep an **empty face of at least 60% of the height** for text and an icon. Every pill has the same lip thickness (the game moves the label up 4 px when pressed).

### A4 — Toggle
| File | Size | What it is |
|---|---|---|
| `ui_toggle_track_off.png` | 192×96 | Capsule track, beige-grey, dark outline, empty. |
| `ui_toggle_track_on.png` | 192×96 | Same capsule, teal `#3FA7B8` with a lighter top-left stroke. |
| `ui_toggle_knob.png` | 80×80 | Round cream knob with outline and a soft bottom-right shadow tone, fixed size, no glyph. |

### A5 — Progress bars (3-slice horizontal)
| File | Size | Caps | What it is |
|---|---|---|---|
| `ui_bar_track.png` | 480×64 | 32 | Empty groove: sunken cream capsule with an inner shadow on the top edge and a dark outline. |
| `ui_bar_fill_green.png` | 480×48 | 24 | Fill: lime capsule with round ends, lighter top stroke, thin dark outline; the game draws it at the progress width (never less than two caps). Also used for HP. |
| `ui_bar_fill_teal.png` | 480×48 | 24 | Same, teal (research, loading). |
| `ui_bar_fill_coral.png` | 480×48 | 24 | Same, coral (low health, boss). |
| `ui_bar_fill_sun.png` | 480×48 | 24 | Same, sun yellow (XP). |

### A6 — Slots and grade rims (fixed 160×160; the 160×160 slot is also 9-slice with 40 px corners)
| File | What it is |
|---|---|
| `ui_slot_empty.png` | Square paper cell for an unowned or empty item slot: pale cream, dashed hand-drawn inner outline, no icon. |
| `ui_slot_filled.png` | The same cell for an owned item: warmer cream, solid thin outline, a soft bottom-right shadow tone. |
| `ui_slot_selected.png` | Same as filled with a thicker honey-wood rim and a tiny sun-yellow corner mark (no glow). |
| `ui_slot_locked.png` | Same silhouette, grey-beige, a faint diagonal pencil hatch, no lock drawn (the game draws the lock icon). |
| `ui_rim_g0.png` … `ui_rim_g5.png` | **Six transparent-centre rings** laid over an item picture to show its grade: same outer silhouette as the slots, a hand-drawn outline 12 px wide in the grade colour — g0 `#B9AE9C` grey, g1 `#8CC152` lime, g2 `#3FA7B8` teal, g3 `#7A5E8C` plum, g4 `#F9D64E` sun yellow, g5 `#EE6352` coral — with a darker ink edge on both sides of the ring. The inside is fully transparent. |

### A7 — Small parts
| File | Size | Type | What it is |
|---|---|---|---|
| `ui_chip_pill.png` | 320×96 | 3-slice, caps 48 | Stat / tag chip: small cream capsule with a slim outline (replaces the code-drawn chip). |
| `ui_badge_dot.png` | 64×64 | fixed | Notification dot: coral disc with a cream ring, empty. |
| `ui_badge_count.png` | 96×96 | fixed | Round coral count badge with a cream ring, empty (the game draws the number). |
| `ui_ribbon_new.png` | 192×96 | fixed | Small cloth ribbon tag with a swallow-tail, sun yellow, empty (the game draws "NEW"). |
| `ui_divider_stitch.png` | 512×24 | tiles horizontally | A hand-stitched dashed line in dark brown thread on transparent; the left and right ends join so it can repeat. |
| `ui_section_mark.png` | 256×48 | 3-slice, caps 16 | The short painted pencil underline that sits under section titles (replaces a flat red dash): coral, rough-edged brush stroke. |
| `ui_toast_plate.png` | 480×120 | 3-slice, caps 60 | Floating message plate: cream paper capsule with a slim wood rim. |
| `ui_spinner_yarn.png` | 192×192 | fixed | A single ball of coral yarn with one loose thread curling out to one side (asymmetric so rotation is visible), on transparent. |

Total budget: the game ships in an APK that is already 35.4 MB. Keep every piece **simple**: flat fills, minimal hatching. Target ≤ 40 KB each after Claude's optimisation, ≤ 600 KB for the whole kit.

## 5. B — Missing icons (two sheets, magenta background)

Use the exact **STYLE** and **SHEET LAYOUT** paragraphs of `design/art/icon_prompts.md` (5 columns × 3 rows, 15 cells, flat magenta `#FF00FF`, one icon per cell about 60% of the cell, wide padding, no text). Each icon is a chunky object icon that stays readable at 20 px. Attach `sheet_icons_1_hud.png` and `sheet_icons_2_ui.png` as references. One short generation per sheet.

### `assets/raw/ui_v3/sheets/sheet_icons_7_stats_1.png` — 5 × 3
Order, left→right, top→bottom (ids in brackets; do not draw the ids):
1. `stat_crit_dmg` — a spiky orange-yellow starburst with a small upward arrow
2. `stat_crit_res` — a round wooden shield with a small starburst deflected on its face
3. `stat_crit_dmg_res` — a shield with a crossed-out starburst and a padded rim
4. `stat_combo` — two small crossed wooden swords with a little coral "chain" ring
5. `stat_combo_res` — a round teal ring broken in the middle (a chain link snapping)
6. `stat_counter` — two curved coral arrows chasing each other (return strike)
7. `stat_counter_res` — a teal shield with two small curved arrows bouncing off
8. `stat_stun` — a sun-yellow dizzy swirl with three little stars circling
9. `stat_stun_res` — a plum helmet-shaped cap with a swirl bouncing off
10. `stat_accuracy` — a round target with a lime arrow in the middle
11. `stat_lifesteal` — a coral heart with a small teal droplet flowing into it (no teeth, no blood, cartoon-soft)
12. `stat_lifesteal_res` — a heart with a small teal shield in front
13. `stat_regen` — a lime heart with a small green leaf and a sparkle
14. `stat_attack_speed` — a wooden sword with three teal speed lines
15. `stat_boss_dmg` — a small sun-yellow crown with a crack and a little sword stuck in the top

### `assets/raw/ui_v3/sheets/sheet_icons_8_stats_2.png` — 5 × 3
1. `stat_pet_dmg` — a coral paw print with a tiny starburst
2. `stat_cdr` — a cream stopwatch with a teal rim and a curved arrow pointing back
3. `stat_yarn_find` — a coral yarn ball with a small magnifying glass
4. `stat_fish_find` — an orange goldfish with a small magnifying glass
5. `stat_exp_find` — a sun-yellow star with a small upward arrow
6. `stat_craft_luck` — a lime four-leaf clover on a small wooden knitting needle
7. `stat_armor_pierce` — a round shield with a lime arrow passing clean through it, round-tipped
8. `stat_dmg_reduction` — a teal shield with three small down-pointing arrows
9. `stat_thorns` — a green leafy ball with blunt round thorns, soft and cute, not sharp
10. `stat_execute` — a cream skull-free tombstone-shaped badge with a golden star on it (no skull, no blood)
11. `stat_opening_shield` — a sun-yellow shield with a sparkle and a tiny stopwatch
12. `speed_play` — a chunky teal right-pointing play triangle on a small cream round plate
13. `pet_cheese` — a wedge of yellow cheese with holes
14. `pet_carrot` — an orange carrot with two lime leaves
15. `pet_rainbow` — a small bright rainbow arc with two cream clouds

## 6. Where to put the files — separate staging folder

Create and use **only** `/Users/kolupy/whisker_tales/assets/raw/ui_v3/`:

```
assets/raw/ui_v3/
  widgets/        # every file in section 4, flat, exact names
  sheets/         # sheet_icons_7_stats_1.png, sheet_icons_8_stats_2.png
  preview_kit.png
  DELIVERY.md
```

**Never** write, overwrite or delete anything else. Specifically do not touch: `assets/raw/backgrounds/` and any `bg_book*` file (the Book 2 scenery redo is running in parallel), monsters, bosses, boss faces, Mochi, pets, `skill_fx`, `damage_numbers`, `story/cards_v2`, `assets/raw/frames/`, `assets/raw/ui/`, `assets/raw/sheets/` (except new files in your own `ui_v3/sheets`), `app/`, `tools/`, `design/`. No git commit or push, no APK build.

## 7. Order of work (so Claude can start wiring early)

1. **Batch 1** (the most visible mismatch): A1 panels, A2 tabs, A3 buttons, A4 toggle, A5 bars. When it is saved, run the self-check and write `DELIVERY.md` for these, and tell YK so Claude can start wiring.
2. **Batch 2**: A6 slots and rims, A7 small parts. Append to `DELIVERY.md`.
3. **Batch 3**: the two icon sheets (section 5). Append to `DELIVERY.md`.

## 8. Self-check before each batch is delivered (report the numbers)

Run something equivalent to this for every PNG in `widgets/`:

```python
from PIL import Image; import numpy as np, sys
def check(path, w, h, caps=None, nine=None):
    im = Image.open(path).convert("RGBA"); a = np.asarray(im).astype(int)
    assert im.size == (w, h), f"{path}: size {im.size} != {(w, h)}"
    alpha = a[:, :, 3]
    assert alpha.min() == 0, f"{path}: no transparent pixel at all (opaque background?)"
    magenta = ((a[:, :, 0] > 200) & (a[:, :, 1] < 60) & (a[:, :, 2] > 200) & (alpha > 0)).sum()
    assert magenta == 0, f"{path}: {magenta} magenta-tinted pixels (fringe)"
    border = np.concatenate([alpha[0], alpha[-1], alpha[:, 0], alpha[:, -1]])
    print(path, im.size, "alpha ok", "border transparent %.0f%%" % (100 * (border == 0).mean()))
    if caps:  # 3-slice: columns inside the caps must be identical
        mid = a[:, caps:w - caps, :]
        d = np.abs(mid[:, 1:, :] - mid[:, :-1, :]).mean()
        assert d < 6, f"{path}: middle is not uniform (column step {d:.1f})"
    if nine:  # 9-slice: the middle band along both axes must be uniform
        c = nine
        row = a[h // 2 - 4:h // 2 + 4, c:w - c, :]; col = a[c:h - c, w // 2 - 4:w // 2 + 4, :]
        assert np.abs(row[:, 1:] - row[:, :-1]).mean() < 6, f"{path}: middle row not uniform"
        assert np.abs(col[1:] - col[:-1]).mean() < 6, f"{path}: middle column not uniform"
```
Pass criteria: size exact; transparent border; no magenta tint; 3-slice and 9-slice middles uniform (step < 6). Also composite every piece over cream `#F6F0E1` and over mid-grey and look at the edges at 200%: no halo, no dark matte line, no chewed outline. For the sheets: 5×3 grid, every cell the same size, every icon inside its cell with ≥ 15% padding, no magenta inside an icon.

## 9. Delivery notes and preview

- `assets/raw/ui_v3/DELIVERY.md`: one table row per file with the **real pixel size** measured from the file, the self-check result, and anything that did not match this brief (say so plainly).
- `assets/raw/ui_v3/preview_kit.png`: a mock screen (about 1080×1920) on cream paper showing the new parts in use **next to the anchors** (an existing `ui_frame_action.png`, `ui_frame_currency.png`, a `card_relic_common.png`, a few existing icons): a page tab strip with one tab selected, three cards with different tints holding an icon, a toggle on and off, a progress bar at 30% and 80%, the five buttons, a 4×3 slot grid with all four states and the six rims, a dialog, a sheet with its grabber, chips, badges and the divider. Labels go **outside** the artwork. This is how YK and Claude judge that new and old pieces look like one set.
- Check with `ls -R /Users/kolupy/whisker_tales/assets/raw/ui_v3` that every file named in this brief exists (4 panels + grabber + inset = 6, tabs 3, buttons 7, toggle 3, bars 5, slots 4 + rims 6, small parts 8, sheets 2, preview, DELIVERY.md).

## 10. How Claude checks it afterwards

Claude measures every piece with a flood fill, writes the slice data, replaces the code-drawn cards, tabs, buttons, switches, bars, slots and chips, slices the icon sheets, runs the screenshot tests and looks at every screen again. If something does not stretch cleanly Claude lists the file and the reason, and you redraw only that piece.
