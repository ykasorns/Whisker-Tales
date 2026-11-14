# GPT task — UI kit v3, round 3: three small pieces to redraw (D-069)

Everything else in `assets/raw/ui_v3/` is accepted and in the game; do not touch it. Same STYLE block, references and delivery rules as `design/art/ui_kit_v3_prompt.md` (transparent PNG, true alpha, no magenta, no text, no git, no APK). Same folder, same file names, exact pixel sizes below. Reply to YK in Thai; notes in English.

How the game uses the art now (so you can judge your own result): every piece is cropped to its painted area by `tools/sync_sprites.py`, then drawn at 4 px = 1 dp. Stretch pieces keep their ends and stretch only the middle. A piece that is thinner than about 20 px in the file is thinner than 5 dp on the phone and reads as a hairline.

## 1. `widgets/ui_section_mark.png` — 256×48 — redraw (too thin to use)
The delivered file is a stroke only 8 px tall (2 dp on the phone), so the game still draws a plain coral bar beside headings ("Class", "Skills", "Looks knitted so far").
- One short hand-drawn **coral colored-pencil dash**, like a quick marker stroke: about **200 px wide × 30–34 px tall**, centred in the 256×48 canvas, slightly tilted (2–4° up to the right), rounded uneven ends, visible diagonal pencil strokes inside, a darker ink outline (#33291F at ~70%), one lighter streak along the top.
- Colour coral #EE6352 with a darker lip #C84B3D. No shadow, no glow.
- Fixed piece (never stretched). Check: painted area at least 28 px tall and 190 px wide.

## 2. `widgets/ui_divider_stitch.png` — 512×24 — redraw (only 116 px of it is painted)
The delivered stitch line covers x 198–314 only and is 2 px tall, so it cannot be used as a divider across a card.
- A **row of sewing stitches from edge to edge**: dashes about 22 px long × 6 px tall with 12 px gaps, honey-brown #B78755 with a darker ink edge, each dash very slightly uneven (hand-sewn), all on one straight line, centred vertically.
- It must **tile left ↔ right**: the pattern period divides 512 exactly (e.g. 16 dashes of 22 + 10 gap), half a gap at each end, so repeated copies join with an even rhythm.
- Check: painted pixels in every 40 px wide window across the whole width; painted height 5–8 px.

## 3. `widgets/ui_panel_dialog.png` — 384×384 — clean the lower rim only
On a dark game scene the bottom rim of the dialog sparkles: the pencil hatch in the lower lip has **holes in the alpha** (transparent specks between strokes), and the outer edge there is ragged. Keep the piece exactly as it is (rim width, rivets, cream paper, corner radius 88 px) but:
- make the whole rim **fully opaque** from its outer ink line to its inner ink line (hatch strokes are colour variation, never transparency);
- one clean continuous outer outline all the way round; no stray pixels outside it.
- Check: inside the outer silhouette, alpha is 255 everywhere (0 pixels with alpha < 250 after eroding the silhouette by 2 px); the centre 208×208 stays one flat cream.

## Self-check and delivery
Run the main brief's checks plus the three checks above and write the numbers into `assets/raw/ui_v3/DELIVERY.md`. Composite the three files over cream `#F6F0E1` **and over a dark blue `#2B3A55`** (the dialog must look clean on both) and save `assets/raw/ui_v3/preview_round3.png`. Do not change any other file.
