# GPT task — Book 2 scenery redo: layers must be TRANSPARENT above the art (D-067)

Regenerate **7 scenery layers** (plus 1 optional) as **RGBA PNGs with real transparency**. Read the whole file first. Do not edit Dart code, JSON or docs; Claude wires the art in. Reply to YK in Thai; file names and notes inside files in English.

## Why this redo is needed (the mistake)
The first Book 2 delivery made every layer a fully opaque rectangle (alpha 255 everywhere; the first brief wrongly said "opaque"). In the game the layers are stacked back to front:

```
L0 sky      (opaque, fills the whole scene)
L1 far      (drawn over the sky)
L2 mid      (drawn over far)
L3 ground   (drawn last, over everything)
```

Because the Book 2 mid layers carry their own painted blue sky and clouds, they hide the far layer and the shared sky behind them: the far hills are cut in half by a straight horizontal line. The Book 2 ground layer also paints bushes and a patchwork fence over everything above the path. Book 1 does it right: **far, mid and ground are transparent PNGs; only the real scenery (hills, trees, bushes, path) is painted, and everything above it is fully transparent** so the sky and the layers behind show through.

Measured on the Book 1 files (`assets/raw/backgrounds/bg_book1_*.png`, attach them as references):

| Layer | Top of the painted art (fraction of image height, from the top) | Bottom |
|---|---|---|
| `L3_ground` | starts at 0.51–0.63 (median 0.57); everything above is transparent | opaque to the bottom edge |
| `L1_far` | starts at 0.55–0.70 (median 0.60) | opaque to the bottom edge |
| `L2_mid` | starts at 0.23–0.70 (median 0.36–0.50): hills and trees of uneven height | opaque to ~0.93–0.97 |

Match this. A tall tree or giant button may rise above the median line; the sky between them must stay transparent.

## Format (the most important part)
- Output: **PNG, RGBA, true alpha**. The background above the art is transparent (alpha 0), never white, never blue, never magenta.
- If your image tool cannot write alpha directly: paint on a flat magenta `#FF00FF` background (no magenta inside the art), then key it out yourself with a script, with **edge despill** (no pink fringe or halo around the art at any zoom level; shrink the matte by 1 px and recolour edge pixels from their inner neighbours). Deliver the keyed RGBA file, not the magenta one.
- Keep the **exact pixel sizes of the first delivery** (below). Same filenames in `assets/raw/backgrounds/`; overwrite the opaque ones.
- **Tile seamlessly left ↔ right**, in colour **and in the alpha silhouette**: the height of the painted top edge at the far left column must equal the far right column, or a step will show where the image repeats.
- No characters, no text, no letters or numbers. Antialiased outline edges, no black or dark matte edge.

## Style (unchanged)
Match Book 1 and the first Book 2 pack: bold dark ink outline (#33291F), saturated colored-pencil fill with visible diagonal strokes, one flat shadow tone, no gradients or airbrush, bright playful palette (orange #F6A83C, coral #EE6352, teal #3FA7B8, lime #8CC152, sun yellow #F9D64E, plum #7A5E8C, cream #F6F0E1). Warm and cosy, not dark. **Keep the content and composition of the files you already made** (same hills, buttons, reeds, pom-poms, windmill, mountains), just remove the sky/clouds/background behind them and make the lower edge sit as described. Use the current files as the content reference and the matching Book 1 file as the layering/alpha reference.

## Files to deliver
| File | Size (exact) | Content and what must be transparent |
|---|---|---|
| `bg_book2_ch4_L1_far.png` | 1044×887 | far patchwork hills (pale quilted greens and pinks), distant spool-and-pinwheel windmill, stitched fences. **Art only in the bottom ~40%** (top edge median 0.60, range 0.55–0.68, wavy hill line). Above it fully transparent. Keep pale and low-contrast. |
| `bg_book2_ch4_L2_mid.png` | 1309×887 | nearer rolling patchwork hills, giant sewing buttons like boulders, thread-reel trees, flower-shaped buttons. **No sky, no clouds.** Hill line median 0.40, range 0.25–0.65; reel trees and buttons may poke above it. Above = transparent. Richer than far. |
| `bg_book2_ch5_L1_far.png` | 1258×887 | far river of teal and coral ribbons winding between hills, distant folded-ribbon bridge. Art in the bottom ~40% (median 0.60). Above transparent. |
| `bg_book2_ch5_L2_mid.png` | 1222×887 | nearer ribbon river banks, floating buttons as stepping stones, thread reeds, lace-edged lily pads. **No sky, no clouds** (the cattail reeds must stand against transparency). Median 0.45, range 0.30–0.70. |
| `bg_book2_ch6_L1_far.png` | 1249×887 | far snow-white mountains of piled wool balls, pale blue knitted slopes, tiny stitched pines. Art in the bottom ~40% (median 0.60). Above transparent. |
| `bg_book2_ch6_L2_mid.png` | 1150×887 | nearer knitted yarn mountains with chunky stitch texture, giant pom-poms, scarf-shaped winding trail. **No sky.** Median 0.40, range 0.25–0.65; the pom-poms may rise above the ridge. |
| `bg_book2_L3_ground.png` | 1840×667 | the walkable ground. **Top 51–60% fully transparent.** Painted art starts at 0.51–0.63 (median 0.57): the top fringe is thread-end grass and low bushes, below it the quilted patchwork path with visible stitching and button pebbles. **Remove the tall patchwork fence/bushes and any sky** that the first version painted above the path; they covered the chapter scenery. Opaque to the bottom edge. Must work under all three chapters. |
| *(optional)* `bg_book2_L0_sky.png` | 1633×887 | stays **opaque**. If you redo it: a smooth soft sky blue → peach, cream stitched clouds, a few floating buttons and ribbon streamers. **No hard horizontal colour bands** (the current one shows a flat peach stripe and a flat cyan stripe); transitions must be gradual painted strokes. Tileable left↔right. |

## Self-check (do this before delivering; report the numbers)
For every file run something equivalent to:

```python
from PIL import Image; import numpy as np
im = Image.open(path).convert("RGBA"); a = np.asarray(im)[:, :, 3]; H = a.shape[0]
top = [int(np.argmax(a[:, x] > 128)) / H for x in range(a.shape[1])]
print(im.size, "alpha min", a.min(), "top-of-art median", np.median(top),
      "range", min(top), max(top),
      "left/right column alpha diff", abs(a[:, 0].astype(int) - a[:, -1].astype(int)).mean())
```
Pass criteria: `alpha min == 0` for the six L1/L2 files and the ground; top-of-art median within the range of its row above; the left/right column alpha difference small (< 8); no pixel with a magenta tint (R>200, G<60, B>200) anywhere. Also composite each layer over a mid-grey and over a sky-blue background and look at the edges at 200% zoom: no halos, no pink fringe, no chewed outline.

## Delivery
Put the files exactly where the table says (overwrite). Update `assets/raw/sheets/book2_preview.png` and `assets/raw/sheets/BOOK2_DELIVERY.md` (real sizes plus the self-check numbers). Also save `assets/raw/sheets/book2_layers_preview.png`: for each chapter, a composite of sky + far + mid + ground stacked exactly as the game stacks them (far bottom ≈ 0.04 above the ground line, mid bottom ≈ 0.06, scene height 887), repeated twice side by side so the left↔right join is visible. Do not write anywhere else, do not commit, do not build an APK. Check with `ls` that all 7 (or 8) files exist.

## How Claude checks it afterwards
Claude renders pages 31, 41 and 51 in the real game and looks for: far hills visible down to the mid layer's hill line with no straight horizontal cut, the shared sky showing between the hills, no halo around the art, no step where the layers repeat.
