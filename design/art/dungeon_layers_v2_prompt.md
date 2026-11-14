# GPT task — Treat Dungeon scenery redo: far / mid / ground must be TRANSPARENT above the art

Regenerate **3 dungeon scenery layers** as **RGBA PNGs with real transparency**, keep `L0_back` opaque. Read the whole file first. Do not edit Dart code, JSON or docs; Claude wires the art in. Reply to YK in Thai; file names and notes inside files in English.

## Why
The dungeon files (`assets/raw/backgrounds/bg_dungeon_L0_back / L1_far / L2_mid / L3_ground.png`) are all fully opaque rectangles (alpha 255 everywhere). In the boss fight they are stacked back to front, so the far, mid and ground rectangles show up as three hard horizontal bands with different walls/skies, which looks like messy overlapping pictures:

```
L0_back    (opaque, fills the whole scene)
L1_far     (drawn over L0)
L2_mid     (drawn over far)
L3_ground  (drawn last)
```

Fix: only the real scenery (far arches/pillars, nearer props, floor) is painted; **everything above it is fully transparent** so the layer behind shows through. Use the Book 1 files (`assets/raw/backgrounds/bg_book1_L1_far / L2_mid / L3_ground.png`) as the alpha/layering reference: ground art starts at ~0.57 of its height, far at ~0.60, mid at ~0.40 (uneven props may rise higher).

## Format
- PNG, RGBA, true alpha; transparent area is alpha 0, never white/black/magenta.
- If you can't write alpha: paint on flat magenta `#FF00FF`, key it out with edge despill (no pink fringe, shrink matte 1 px, recolour edge pixels from inner neighbours). Deliver the keyed file.
- **Keep the exact pixel sizes of the current files** and the same filenames in `assets/raw/backgrounds/` (overwrite).
- **Tile seamlessly left ↔ right** in colour **and** in the alpha silhouette (painted top edge at the far-left column equals far-right column).
- No characters, text, letters or numbers. Antialiased outline edges, no dark matte edge.

## Content and style
Keep the content and composition of the existing dungeon files (same arches, pillars, props, floor), just remove the wall/sky/background behind them. Match the project style: bold dark ink outline (#33291F), colored-pencil fill with visible diagonal strokes, one flat shadow tone, no gradients/airbrush, bright cosy palette, not dark or scary (Kids/Families).

| File | Painted region | Transparent |
|---|---|---|
| `bg_dungeon_L1_far.png` | distant arches / pillars / banners; art only in the bottom ~40% (top edge median 0.60, wavy/arched line). Pale, low contrast. | everything above the art |
| `bg_dungeon_L2_mid.png` | nearer pillars, crates, torches, props; top edge median ~0.40 (range 0.25–0.65), tall props may poke higher; opaque down to ~0.95. Richer than far. **No wall backdrop** between the props. | gaps between props and everything above |
| `bg_dungeon_L3_ground.png` | the walkable floor; **top ~55% fully transparent**; art starts at 0.51–0.63 (median 0.57) with a small fringe of floor edge/rubble, then the floor tiles to the bottom edge, opaque to the bottom. | top ~55% |
| `bg_dungeon_L0_back.png` | stays **opaque**; a smooth back wall / ambient scene with no hard horizontal colour bands; tileable left↔right. Only redo if it shows hard bands. | — |

## Self-check (report the numbers)
```python
from PIL import Image; import numpy as np
im = Image.open(path).convert("RGBA"); a = np.asarray(im)[:, :, 3]; H = a.shape[0]
top = [int(np.argmax(a[:, x] > 128)) / H for x in range(a.shape[1])]
print(im.size, "alpha min", a.min(), "top median", np.median(top), "range", min(top), max(top),
      "L/R alpha diff", abs(a[:, 0].astype(int) - a[:, -1].astype(int)).mean())
```
Pass: `alpha min == 0` for L1/L2/L3; top-of-art medians within the ranges above; L/R alpha diff < 8; no magenta-tinted pixels (R>200, G<60, B>200). Composite each layer over mid-grey and sky-blue and check edges at 200% zoom: no halos or pink fringe.
