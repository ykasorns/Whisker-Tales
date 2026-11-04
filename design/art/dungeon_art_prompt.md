# GPT task — Treat Dungeon art pack (D-065) for Whisker Tales

Generate **image assets** only. Read the whole file first. Do not edit Dart code, JSON or docs; Claude will wire the art in. Reply to YK in Thai; file names and notes inside files in English.

## Why
The new **Treat Dungeon** (ถ้ำขนมแมว, Adventure tab) is a 30-second fight against ONE boss; the more damage Mochi deals, the more pet treats (🍪) are paid out in five tiers. Boss level 1–30 rises in strength. Today it borrows the three chapter bosses (Eraser King, Sharpener Crab, Paper Wolf) as **interim** stand-ins. This pack replaces them with dungeon-only guardians, a cave backdrop and prize art. Rule D-057: new designs must be real generated artwork.

## Style (same for everything)
Pencil-and-crayon storybook look, warm palette, soft dark-brown outline — match `app/assets/game/mon/*`, `app/assets/game/cat/*` and `app/assets/game/bg/*`. Kid-safe and friendly (a boss may look grumpy or puffed-up, never scary, no blood, no weapons that look real). No text or letters inside any image. Original characters only — nothing from other games.
- Characters: **magenta `#FF00FF` flat background** (the repo's slicer keys it out; no magenta inside the art), one character per cell, feet on the same baseline, no drop shadow, no glow outside the outline. Cell size **1024×680** (3:2, the game shows them at 511×340).
- Backgrounds: opaque, painted, tile seamlessly left↔right.

## 1. Three guardians — one sheet each (4 columns × 2 rows = 8 cells)
Cell order, left→right, top→bottom: `idle_f1`, `idle_f2`, `idle_f3`, `hurt`, `telegraph_f1`, `telegraph_f2`, `attack`, `defeated`.
`idle` = a gentle 3-frame breathing/bobbing loop, same pose. `hurt` = squinting, leaning back a little. `telegraph_f1/f2` = winding up (the game flashes a warning: puffing up, raising arms, glowing cheeks). `attack` = the strike frame, leaning toward the left (toward Mochi). `defeated` = flopped over, dizzy swirls for eyes, smiling a little (it is a game, nobody is hurt).

Characters sit on the SAME scale: the boss is about **2.2× Mochi's height**. Save sheets to `assets/raw/sheets/` as `sheet_dungeon_<id>.png`.

| Sheet | Levels | Character prompt |
|---|---|---|
| `sheet_dungeon_cookiegolem.png` | 1–10 | `CHARACTER: "Cookie Golem", a big round chocolate-chip cookie body with stubby arms and legs, a wide grumpy-but-cute mouth made of icing, three chip-shaped bumps for a crown, crumbs falling when it moves. Warm biscuit-brown and cream palette.` |
| `sheet_dungeon_jellyking.png` | 11–20 | `CHARACTER: "Jelly King", a tall wobbly strawberry-jelly dome with a gummy crown, tiny fruit pieces floating inside like a snow globe, wide puffed chest, little stubby gummy arms. Translucent raspberry-red and gold, still drawn in coloured pencil.` |
| `sheet_dungeon_cakedragon.png` | 21–30 | `CHARACTER: "Layer-Cake Dragon", a plump friendly dragon whose body is a three-layer sponge cake with cream frosting, candle-shaped horns with tiny flames, wings made of wafer biscuits, sprinkles on its tail. Cream, pink and blueberry palette.` |

Keep each boss clearly different in silhouette (round / tall dome / long winged body).

## 2. Cave backdrop — 4 tiling layers, 400 px high
Same layering as the farm scenery: `bg_dungeon_L0_back.png` (736×400, glowing cave ceiling and far wall, soft crayon-blue light shafts), `bg_dungeon_L1_far.png` (~560×400, far cookie-crumb rock pillars and jars), `bg_dungeon_L2_mid.png` (~560×400, nearer candy-stone arches, hanging lollipop crystals), `bg_dungeon_L3_ground.png` (1103×400, sandy-biscuit floor with sugar-crystal pebbles; the top 30 % is the walkable ground). Warm lantern light, cosy not dark. Save to `assets/raw/backgrounds/`.

## 3. Reward tier prizes (5) — 192×192, transparent
One treat jar that grows with each tier, drawn from the same viewpoint: `prize_t1.png` a small glass jar with 3 cookies, `prize_t2.png` a jar with a few more, `prize_t3.png` a full jar with a ribbon, `prize_t4.png` a big jar with a ribbon and a sparkle, `prize_t5.png` a golden overflowing treasure jar with a crown lid and stars. Real alpha (PNG-32), tight crop, no text. Save to `assets/raw/frames/dungeon_v1/prizes/`.

## 4. Adventure menu card art — 256×256, transparent
`mode_dungeon.png`: Mochi (the orange cat) peeking into a glowing cave mouth shaped like a giant cookie, a few crumbs floating. Matches the size and crop of `mode_story`. Save to `assets/raw/frames/dungeon_v1/`.

## 5. Timer and damage-bar frame (optional, 2 pieces)
`ui_dungeon_timer.png` (240×104, a round stopwatch plate on a wooden rim with an EMPTY face, no digits) and `ui_dungeon_bar.png` (960×96, a long horizontal wooden trough with an EMPTY inner groove and five small empty notches along the top at 20/40/60/80/100 %). Same calm honey-wood rim as `assets/raw/frames/ui_v2/`. For each give the empty rectangle `[x1,y1,x2,y2]` measured on the final file.

## Delivery
Put everything where each section says. Also save `assets/raw/frames/dungeon_v1/preview_sheet.png` (all pieces on mid-grey, labels outside the artwork) and `assets/raw/frames/dungeon_v1/DELIVERY.md` with each file's real pixel size and the measured rectangles. Do not write anywhere else, do not commit, do not build an APK. Check with `ls -R` that every file exists: 3 sheets, 4 backgrounds, 5 prizes, 1 card, 2 UI.
