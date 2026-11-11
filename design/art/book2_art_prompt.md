# GPT task — Book 2 "Craft Room" art pack (D-067) for Whisker Tales

Generate **image assets** only. Read the whole file first. Do not edit Dart code, JSON or docs; Claude will wire the art in. Reply to YK in Thai; file names and notes inside files in English.

## Why
Book 1 (pages 1–30: Crayon Meadow, Ink Lake, Paper Forest — a stationery world) is done. Pages 31+ currently replay Book 1's scenery and monsters. Book 2 is the **Craft Room**: a sewing-and-knitting world (fits Mochi's yarn theme). It has 3 chapters of 10 pages each (pages 31–60). Rule D-057: new designs must be real generated artwork.

## Style (same for everything)
Match the existing Book 1 art exactly (`assets/raw/sheets/sheet_mon_*.png`, `sheet_boss_*.png`, `assets/raw/backgrounds/bg_book1_*.png`): bold dark ink outline (#33291F), saturated colored-pencil fill with visible diagonal strokes, one flat shadow tone, no gradients or airbrush, bright playful palette (orange #F6A83C, coral #EE6352, teal #3FA7B8, lime #8CC152, sun yellow #F9D64E, plum #7A5E8C, cream #F6F0E1). Kid-safe: monsters are grumpy-cute, never scary, no blood, no sharp teeth, nothing that looks like a real weapon (pins and needles are drawn blunt and round-tipped). No text, letters or numbers inside any image. Original characters only. **Attach the Book 1 sheet of the same kind as a style reference every time** (a monster sheet for monsters, a boss sheet for bosses, a background layer for backgrounds).

Characters: **flat magenta `#FF00FF` background** (the repo's slicer keys it out; no magenta inside the art), one character per cell in an invisible grid of equal cells, feet on the same baseline in every cell, no drop shadow, no glow outside the outline, each character fully inside its cell with ≥10% padding. Monsters and bosses face **LEFT**.

## The three chapters
| Ch | Id | Name TH / EN | Monsters | Boss |
|---|---|---|---|---|
| 4 | `patch_meadow` | ทุ่งผ้าปะ / Patchwork Meadow | Pincushion Mole, Button Ladybug | Quilt Bear |
| 5 | `ribbon_river` | สายธารริบบิ้น / Ribbon River | Sock Jelly, Spool Frog | Thimble Turtle King |
| 6 | `yarn_peaks` | ภูเขาไหมพรม / Yarn Peaks | Wool Puff Sheep, Tangle Ball | Yarn Yeti |

## 1. Six regular monsters — `assets/raw/sheets/sheet_mon_<id>.png`, 4 columns × 2 rows (8 cells), aspect 2:1

Use this for every monster, changing only CHARACTER:

```
Create a sprite sheet of a cute cartoon craft-room monster in 8 frames, full body, side view facing LEFT. Mischievous but adorable, grumpy furrowed brows, coral and plum accents to show it is an enemy, never scary.

CHARACTER: <see table>

FRAMES, left to right, top to bottom:
Row 1: (1–3) idle, the same pose redrawn three times with slightly different hand-drawn line jitter (boiling-line frames), identical shape and position; (4) move, a small hop forward toward the left.
Row 2: (5) attack telegraph, wind-up pose 1, leaning back, clearly about to attack, no symbols or marks above the head; (6) attack telegraph, wind-up pose 2, even more stretched back; (7) attack, lunging forward to the left; (8) defeated, sitting dazed with swirly dizzy eyes, a little puff of colored-pencil smoke, no injuries.

SHEET LAYOUT: a clean sprite sheet on a perfectly flat solid magenta background (#FF00FF) filling the entire image, an invisible grid of 4 columns by 2 rows, every cell the same size, one pose per cell, centered, same character, same size and same ground line in every cell. No text, no numbers, no grid lines, no borders, no floor, no cast shadows, no background scenery.
```

| Sheet | CHARACTER |
|---|---|
| `sheet_mon_pincushionmole.png` | `"Pincushion Mole", a round plum-coloured mole whose back is a tomato-shaped pincushion stuck with blunt round-headed pins in bright colours, tiny round glasses made of two buttons, big digging paws, grumpy little face.` |
| `sheet_mon_buttonladybug.png` | `"Button Ladybug", a plump ladybug whose shell is one giant coral sewing button with four holes and a stitched rim, thread-like antennae, six short legs, huffy expression.` |
| `sheet_mon_sockjelly.png` | `"Sock Jelly", a floating jellyfish whose bell is a striped teal-and-cream knitted sock, tentacles are loose dangling yarn ends, hovers off the ground, sleepy-grumpy face.` |
| `sheet_mon_spoolfrog.png` | `"Spool Frog", a lime-green frog sitting on a wooden thread spool wound with sun-yellow thread, big round eyes, thread-end tongue curled like a ribbon, cranky face.` |
| `sheet_mon_woolpuff.png` | `"Wool Puff Sheep", a very round fluffy sheep made entirely of cream and pink wool curls, tiny hooves, a small knitted cap on its head, puffed-up proud face.` |
| `sheet_mon_tangleball.png` | `"Tangle Ball", a messy ball of tangled orange and plum yarn with two angry eyes peeking out, loose strands as tiny arms and legs, one knitting needle stub (round-tipped) held like a sword.` |

Output per monster (Claude slices them): `mon_<id>_idle_f1..3`, `_move`, `_telegraph_f1..2`, `_attack`, `_defeated`.

## 2. Three chapter bosses — `assets/raw/sheets/sheet_boss_<id>.png`, 4 columns × 2 rows, aspect 2:1

Each is about **1.6× the height of the regular monsters of its chapter**, still adorable.

```
Create a sprite sheet of a cute cartoon BOSS monster in 8 frames, full body, side view facing LEFT, larger and more impressive than a regular monster but still adorable and child-friendly, grumpy brows, coral and plum accents, never scary.

CHARACTER: <see table>

FRAMES, left to right, top to bottom:
Row 1: (1–3) idle, the same pose redrawn three times with slightly different hand-drawn line jitter (boiling-line frames), identical shape and position; (4) hurt, flinching backward, eyes squeezed, cartoon-funny not painful.
Row 2: (5) attack telegraph wind-up 1; (6) attack telegraph wind-up 2, exaggerated big wind-up so children can see the attack coming; (7) big attack, lunging forward to the left with three short curved motion lines; (8) defeated, sitting down dazed with swirly eyes and a puff of colored-pencil smoke, a little embarrassed.

SHEET LAYOUT: same as the monsters (flat #FF00FF background, 4 columns × 2 rows, equal cells, same size and ground line in every cell, no text, no borders, no shadows, no scenery).
```

| Sheet | CHARACTER |
|---|---|
| `sheet_boss_quiltbear.png` | `"Quilt Bear", a huge teddy bear sewn from mismatched patchwork squares in coral, teal, lime and yellow with visible stitches, one button eye and one embroidered eye, a lopsided crown made of a folded handkerchief, big puffed chest, very proud.` |
| `sheet_boss_thimbleturtle.png` | `"Thimble Turtle King", a big teal turtle whose shell is a giant silver sewing thimble with a dimpled pattern drawn as a harmless stripe, ribbon-wrapped flippers, a tiny crown made of a bent safety-pin (rounded, closed), cranky wise face.` |
| `sheet_boss_yarnyeti.png` | `"Yarn Yeti", a huge fluffy yeti made of thick cream and sky-blue knitted yarn with chunky stitch texture, a scarf of coral yarn trailing behind, round paws, a pom-pom on its head, grumpy furrowed brows.` |

Output per boss: `boss_<id>_idle_f1..3`, `_hurt`, `_telegraph_f1..2`, `_attack`, `_defeated`.

## 3. Boss-challenge icons — `assets/raw/sheets/sheet_icon_boss_ch4.png`, `_ch5.png`, `_ch6.png`, 3 columns × 1 row

Same job and layout as the Book 1 sheets (`sheet_icon_boss_ch1.png`). **Attach that sheet plus this chapter's two monster sheets and boss sheet as references.**

```
Create 3 round game UI portrait icons of the boss characters from the reference images, one per cell, for a "challenge the boss" button. Match the reference art style exactly (same line weight, colored pencil texture and palette).

ICONS left to right:
(1) <monster A> from the reference, wearing a small sun-yellow crown, grumpy determined face;
(2) <monster B> from the reference, wearing a small sun-yellow crown, grumpy determined face;
(3) <boss> from the reference, its crown, proud and grumpy face.

Each icon: head-and-shoulders close-up, three-quarter view looking slightly to the LEFT toward the viewer, face large and centered, everything important inside the central 80% of the cell so it survives a circular crop, readable at 64 px.

SHEET LAYOUT: flat #FF00FF background, 3 columns by 1 row, every cell the same square size, one icon per cell, wide magenta gaps. No circles, no frames, no borders, no text, no scenery.
```
- ch4: Pincushion Mole, Button Ladybug, Quilt Bear → `ui_bossface_pincushionmole|buttonladybug|quiltbear`
- ch5: Sock Jelly, Spool Frog, Thimble Turtle King → `ui_bossface_sockjelly|spoolfrog|thimbleturtle`
- ch6: Wool Puff Sheep, Tangle Ball, Yarn Yeti → `ui_bossface_woolpuff|tangleball|yarnyeti`

## 4. Scenery — 8 opaque painted layers, `assets/raw/backgrounds/`

Same layering and sizes as Book 1 (`bg_book1_*`): a sky and a ground shared by the whole book, plus a far layer and a mid layer per chapter. Every layer must **tile seamlessly left↔right** (the left edge continues into the right edge). Warm, cosy, not dark. Keep the far layers pale and low-contrast and the mid layers richer, so Mochi and the monsters stay readable in front. Do not paint any character.

| File | Size (match ±5%) | Content |
|---|---|---|
| `bg_book2_L0_sky.png` | 1633×887 | soft warm afternoon sky of cream-coloured stitched clouds, a few floating buttons and paper-thin ribbon streamers drifting, sky-blue to peach |
| `bg_book2_L3_ground.png` | 1840×667 | the walkable ground (top 30% is the path): a quilted path of patchwork squares with visible stitching, small button pebbles and thread-end grass; must work under all three chapters |
| `bg_book2_ch4_L1_far.png` | 1044×887 | far patchwork hills made of quilted fields in pale greens and pinks, a distant windmill made of a spool and pinwheel, stitched fences |
| `bg_book2_ch4_L2_mid.png` | 1309×887 | nearer rolling patchwork hills, giant sewing buttons sitting like boulders, thread-reel trees, bright flower-shaped buttons |
| `bg_book2_ch5_L1_far.png` | 1258×887 | far river of flowing teal and coral ribbons winding between hills, distant bridge made of a folded ribbon |
| `bg_book2_ch5_L2_mid.png` | 1222×887 | nearer ribbon river banks, big floating buttons as stepping stones, reeds made of thread, lace-edged lily pads |
| `bg_book2_ch6_L1_far.png` | 1249×887 | far snow-white mountains made of piled wool balls, pale blue knitted slopes, tiny stitched pine trees |
| `bg_book2_ch6_L2_mid.png` | 1150×887 | nearer knitted yarn mountains with chunky stitch texture, giant pom-poms, a scarf-shaped winding trail, cosy colours (cream, sky blue, coral) |

Chapters should differ clearly in dominant colour: ch4 green/pink, ch5 teal/coral, ch6 cream/sky-blue.

## Delivery
Put every file exactly where its section says. Also save `assets/raw/sheets/book2_preview.png` (all pieces on mid-grey, labels outside the artwork) and `assets/raw/sheets/BOOK2_DELIVERY.md` listing each file's real pixel size and any piece you were not happy with. Do not write anywhere else, do not commit, do not build an APK. Check with `ls` that every file exists: **6 monster sheets, 3 boss sheets, 3 icon sheets, 8 backgrounds = 20 images**.

## Suggested order
Do chapter 4 first (2 monsters, boss, icon sheet, its 2 scenery layers, sky and ground) so Claude can wire a first playable chapter while you make 5 and 6.
