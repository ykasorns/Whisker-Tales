# Treat Dungeon Art Pack — Delivery

Generated as original raster artwork with the built-in ImageGen workflow. Existing Whisker Tales monster, cat, background, and UI-frame assets were used only as style references.

## Shared prompt direction

- Pencil-and-crayon children's storybook rendering
- Warm, friendly palette with soft dark-brown outlines
- Kid-safe original characters and scenery
- No text or letters inside production art
- Guardian sheets use a flat `#FF00FF` keyed background
- Prize, mode-card, timer, and damage-bar assets use real transparent alpha
- No exterior drop shadows or glow

## Guardian animation sheets

Each sheet is 4096×1360 and contains eight 1024×680 cells in this order: `idle_f1`, `idle_f2`, `idle_f3`, `hurt`, `telegraph_f1`, `telegraph_f2`, `attack`, `defeated`.

| File | Pixel size | Alpha | Prompt subject |
|---|---:|---|---|
| `../../sheets/sheet_dungeon_cookiegolem.png` | 4096×1360 | No | Round chocolate-chip Cookie Golem with icing face, chip crown, and crumbs |
| `../../sheets/sheet_dungeon_jellyking.png` | 4096×1360 | No | Tall raspberry Jelly King with gummy crown and suspended fruit pieces |
| `../../sheets/sheet_dungeon_cakedragon.png` | 4096×1360 | No | Layer-Cake Dragon with frosting layers, candle horns, wafer wings, and sprinkled tail |

## Cave backgrounds

All four backgrounds are opaque, horizontally repeating storybook cave layers.

| File | Pixel size | Alpha | Layer content |
|---|---:|---|---|
| `../../backgrounds/bg_dungeon_L0_back.png` | 736×400 | No | Glowing cave ceiling, far wall, blue light shafts |
| `../../backgrounds/bg_dungeon_L1_far.png` | 560×400 | No | Distant cookie-rock pillars and treat jars |
| `../../backgrounds/bg_dungeon_L2_mid.png` | 560×400 | No | Candy-stone arches and hanging candy crystals |
| `../../backgrounds/bg_dungeon_L3_ground.png` | 1103×400 | No | Sandy biscuit walkable floor and sugar-crystal pebbles |

## Reward prizes

All prize icons use the same gentle three-quarter jar viewpoint.

| File | Pixel size | Alpha | Tier treatment |
|---|---:|---|---|
| `prizes/prize_t1.png` | 192×192 | Yes | Small jar with three cat cookies |
| `prizes/prize_t2.png` | 192×192 | Yes | Jar with a few more cookies |
| `prizes/prize_t3.png` | 192×192 | Yes | Full jar with teal ribbon |
| `prizes/prize_t4.png` | 192×192 | Yes | Larger full jar, teal-gold ribbon, one sparkle |
| `prizes/prize_t5.png` | 192×192 | Yes | Golden overflowing jar with crown lid and stars |

## Mode and UI

Rectangle coordinates use `[x1,y1,x2,y2]` with the lower-right edge exclusive. These are conservative fully empty face/groove rectangles measured from the final production pixels.

| File | Pixel size | Alpha | Empty rectangle |
|---|---:|---|---|
| `mode_dungeon.png` | 256×256 | Yes | — |
| `ui_dungeon_timer.png` | 240×104 | Yes | `[95,33,144,83]` |
| `ui_dungeon_bar.png` | 960×96 | Yes | `[94,32,867,72]` |

`mode_dungeon.png` depicts Mochi peeking into a warmly glowing giant-cookie cave. The timer is an empty wooden stopwatch plate. The damage bar is an empty honey-wood trough with five top markers.

## Preview and validation

- `preview_sheet.png`: 1800×2680, mid-grey preview background with labels outside the production art
- Confirmed file count: 3 guardian sheets, 4 backgrounds, 5 prizes, 1 mode card, and 2 UI pieces
- Confirmed all requested pixel sizes and expected alpha modes

No Dart, JSON, gameplay documentation, APK, or commit was created or changed for this delivery.
