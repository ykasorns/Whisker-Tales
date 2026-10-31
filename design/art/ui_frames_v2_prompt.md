# GPT task — UI frame set v2 (calmer frames) for Whisker Tales

> **QUICK SUMMARY — where everything goes**
> Repo root: `/Users/kolupy/whisker_tales` (all paths below are relative to it; absolute form = root + path).
> Save every generated file under **`/Users/kolupy/whisker_tales/assets/raw/frames/ui_v2/`** (create the folder if missing). Exact file list in section 5.
> Never write into `assets/raw/frames/ui/`, `assets/raw/ui/`, `app/` or `tools/`. No git commit/push, no APK.
> Finish by writing `assets/raw/frames/ui_v2/DELIVERY.md` and `preview_sheet.png` in the same folder.


You are generating **image assets** for the Flutter game *Whisker Tales* (Android, kids/families, storybook look). Read this whole file first. Do not edit any Dart code, `design/art/ui_frames.json`, `DECISIONS.md` or `_dispatch/HANDOFF.md` — Claude will wire the new art into the game after you deliver it. Your job is only: generate the PNGs listed below, put them in the folder named in "Where to put the files", and write the short delivery note.

Reply to YK in Thai; file names, code and notes inside files in English.

## 1. Why this task exists

YK's phone review (2026-10-31, D-059) showed the current UI frames are **too busy**: every wood frame has big leaves, knobs and vines at the corners, so the home screen looks cluttered and the text areas are small. The layout code is now fixed (frames are drawn at their true aspect ratio, only the middle stretches). What is still missing is **calmer art**. Hard rule D-057: new designs must be real generated artwork, not code approximations.

Read for context (do not change): `app/lib/ui/frames.dart`, `design/art/ui_frames.json` (how the current frames are measured), `DECISIONS.md` entries D-057 and D-059, and look at the current frames in `app/assets/game/ui/ui_frame_*.png` to match the palette and line style.

## 2. Style (must match the current game)

- Hand-painted storybook / children's picture-book look: warm wood (honey-brown), cream paper panels, soft dark-brown outline, gentle shading. Same palette and outline weight as the existing `ui_frame_*.png`.
- **Calmer than v1:** NO big leaves, NO vines, NO flowers, NO dangling knobs at the corners. At most one small, flat accent (a tiny rivet/nail or a single small leaf) per frame, and only where listed below. Edges should be a clean, slim wooden rim.
- Large, clean, **flat cream paper area** in the middle of each frame (no texture noise, no drawings, no text) — live game text is drawn on top of it.
- Transparent background (real alpha, PNG-32). No drop shadow outside the frame, no glow, no background color, no checkerboard baked into the image.
- No text, no numbers, no letters anywhere in the artwork (the game draws text itself, in Thai and English).
- Kids/Families safe: nothing scary, no weapons, no brand or character from other games (no Legend of Mushroom content).

## 3. Technical rules for every frame (very important)

The game draws each frame as a **3-slice**: left cap, stretchable middle, right cap. The middle is stretched horizontally, so:

1. The **middle part of the frame must be horizontally uniform** — a strip of wood rim top and bottom with plain paper between. No decoration, knot, nail or shading that changes along x between the caps; otherwise it will visibly stretch.
2. Anything that must keep its shape (a medallion, a plus button, the ribbon ends) sits only inside the **caps** (the first `cap_l` px and last `cap_r` px).
3. Crop each file **tight** to the frame: no empty margin around it (a few px of anti-aliased transparent edge is fine).
4. Exact pixel size and cap widths are given per frame below. Keep these **exactly**, so Claude can reuse the same measurements. If you cannot hit the size exactly, say so in the delivery note and give the real size.
5. Also write, per frame, the **paper content rectangle** you actually painted: `[x1, y1, x2, y2]` in pixels, measured in the final PNG — the largest rectangle that is fully clean cream paper. For the dock also give the 5 slot rectangles. Put these numbers in the delivery note (section 6). Measure them for real (open the PNG, check pixels), do not estimate by eye.

## 4. Frames to generate

Use the same names as v1 plus the suffix `_v2`. Sizes are in pixels.

| File | Size (w×h) | cap_l / cap_r | What it is |
|---|---|---|---|
| `ui_frame_profile_v2.png` | 620×320 | 275 / 40 | Top-left player card. Left cap holds a round **empty medallion** (cream disc, ~106×86 px area, centered vertically, x≈112–218) with a slim wood ring — the game draws the level number inside it. Right part is one long cream paper strip for the name/XP bar. |
| `ui_frame_currency_v2.png` | 960×209 | 40 / 175 | Resource tag (coins/yarn/gems). Left cap is just the rounded end. **Right cap holds an empty round "+" button** (plain round wood button, **no plus sign drawn**, the game draws it). Middle is one long paper strip. |
| `ui_frame_chapter_v2.png` | 561×251 | 105 / 85 | Chapter/wave banner under the profile. Slim ribbon-style end pieces (flat, no leaves). Paper in the middle. |
| `ui_frame_action_v2.png` | 590×254 | 92 / 90 | Wide button plate for toggles (AUTO, Better: wear now, Auto-knit). Rounded wood plate, paper face, no icons. |
| `ui_frame_nav_dock_v2.png` | 891×275 | 65 / 75 | Bottom navigation dock holding **5 equal paper slots** in a row. Slim wood rim, **no leaves**. Slots must be the same size, evenly spaced, each a clean cream rounded rectangle about 122×106 px, vertical span y≈80–186, and **tall enough for an emoji icon (about 40px) plus a one-line label below it**. The wood between slots is a thin divider (≈25 px). The top area above the slots (y 0–80) may be plain thin rim or empty transparent — nothing decorative that overlaps slots. |
| `ui_frame_nav_selected_v2.png` | 309×348 | 0 / 0 | The "selected tab" **bookmark ribbon** hung behind the active slot's icon: a small cloth ribbon/bookmark shape with a swallow-tail bottom, a flat color (soft warm red or teal), no text. Not stretched; drawn at its natural ratio. |

### New pieces (not in v1)

| File | Size | Notes |
|---|---|---|
| `ui_badge_cooldown_v2.png` | 128×128 | Small round badge, cream disc with slim wood ring, **empty** (no number). The game draws the cooldown seconds on top, at the bottom-right corner of a skill/pet icon. Must be readable at 28×28 dp. |
| `ui_label_plate_v2.png` | 240×96 | Small horizontal paper plate (cream, slim rim, rounded) that sits behind a one-line tab label so dark text stays readable on busy art. Uniform middle (3-slice, caps 30/30). |
| `ui_dock_icons_v2/` (folder) | each 192×192, transparent | Five bigger, bolder tab icons in the same storybook style, one file each: `nav_character.png` (cat head with small hat), `nav_adventure.png` (open book / map), `nav_home.png` (cozy house), `nav_events.png` (gift box), `nav_shop.png` (basket/shop stall). They must fill most of the square (the current emoji icons look tiny inside the slots). No text. Same outline and palette as the frames. |

## 5. Where to put the files

Put everything in a **new folder** so nothing existing is overwritten. Absolute path: `/Users/kolupy/whisker_tales/assets/raw/frames/ui_v2/` (create it, and the sub-folder `ui_dock_icons_v2/`, if they do not exist). Save each file directly with exactly the name shown; do not leave copies in your working/output folder or anywhere else in the repo:

```
assets/raw/frames/ui_v2/
  ui_frame_profile_v2.png
  ui_frame_currency_v2.png
  ui_frame_chapter_v2.png
  ui_frame_action_v2.png
  ui_frame_nav_dock_v2.png
  ui_frame_nav_selected_v2.png
  ui_badge_cooldown_v2.png
  ui_label_plate_v2.png
  ui_dock_icons_v2/nav_character.png
  ui_dock_icons_v2/nav_adventure.png
  ui_dock_icons_v2/nav_home.png
  ui_dock_icons_v2/nav_events.png
  ui_dock_icons_v2/nav_shop.png
  DELIVERY.md
```

Do **not** touch `assets/raw/frames/ui/`, `assets/raw/ui/`, `app/assets/` or `tools/sync_sprites.py`. Do not commit or push; YK will ask Claude to review and commit. Do not build an APK.

Also keep one preview sheet for review: `assets/raw/frames/ui_v2/preview_sheet.png` (all frames on a mid-gray background, labelled outside the artwork, not inside the PNGs).

After saving, run `ls -R /Users/kolupy/whisker_tales/assets/raw/frames/ui_v2` and check that all 14 items (11 PNGs incl. 5 icons, `preview_sheet.png`, `DELIVERY.md`) are there; fix any missing or misnamed file.

## 6. Delivery note (`assets/raw/frames/ui_v2/DELIVERY.md`)

Write it in English, with a table per frame: file name, **real pixel size**, `cap_l`, `cap_r`, **content rect** `[x1,y1,x2,y2]`, and extra rects (`medallion` for the profile; the 5 `slots` for the dock; the "+" button circle rect for currency). Then list anything that did not match this brief (size off, extra decoration kept, etc.). Claude will turn these numbers into `design/art/ui_frames.json`.

## 7. Self-check before you finish

- Open every PNG: alpha is real (no baked background), no text/numbers, no leaves at corners.
- Cover the caps in your head: is the middle of each frame identical column by column? If not, redo it.
- The five dock slots are equal width and evenly spaced.
- File names and folder exactly as in section 5.
- Numbers in DELIVERY.md were measured from the final files.

When done, tell YK (in Thai) the folder path and that Claude should now review the art, wire it in, and run the tests.
