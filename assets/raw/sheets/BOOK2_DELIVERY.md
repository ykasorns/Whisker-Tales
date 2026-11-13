# Book 2 — Craft Room Art Delivery

Generated from `design/art/book2_art_prompt.md` and corrected by `design/art/book2_layers_v2_prompt.md` using the built-in image generation workflow, with the matching Book 1 asset type supplied as a style and alpha-layer reference.

## Character sprite sheets

| File | Pixel size |
|---|---:|
| `sheet_mon_pincushionmole.png` | 1774 × 887 |
| `sheet_mon_buttonladybug.png` | 1774 × 887 |
| `sheet_mon_sockjelly.png` | 1774 × 887 |
| `sheet_mon_spoolfrog.png` | 1774 × 887 |
| `sheet_mon_woolpuff.png` | 1774 × 887 |
| `sheet_mon_tangleball.png` | 1774 × 887 |
| `sheet_boss_quiltbear.png` | 1774 × 887 |
| `sheet_boss_thimbleturtle.png` | 1774 × 887 |
| `sheet_boss_yarnyeti.png` | 1774 × 887 |

## Boss challenge icon sheets

| File | Pixel size |
|---|---:|
| `sheet_icon_boss_ch4.png` | 2000 × 667 |
| `sheet_icon_boss_ch5.png` | 2000 × 667 |
| `sheet_icon_boss_ch6.png` | 2000 × 667 |

## Background layers — v2 alpha delivery

| File | Pixel size | Alpha min | Top-of-art median | Range | L/R alpha diff | Magenta pixels |
|---|---:|---:|---:|---:|---:|---:|
| `bg_book2_L0_sky.png` | 1633 × 887 | 255 | 0.000 | 0.000–0.000 | 0.00 | 0 |
| `bg_book2_L3_ground.png` | 1840 × 667 | 0 | 0.580 | 0.525–0.639 | 0.00 | 0 |
| `bg_book2_ch4_L1_far.png` | 1044 × 887 | 0 | 0.608 | 0.489–0.665 | 0.00 | 0 |
| `bg_book2_ch4_L2_mid.png` | 1309 × 887 | 0 | 0.638 | 0.427–0.716 | 0.00 | 0 |
| `bg_book2_ch5_L1_far.png` | 1258 × 887 | 0 | 0.609 | 0.584–0.636 | 0.00 | 0 |
| `bg_book2_ch5_L2_mid.png` | 1222 × 887 | 0 | 0.536 | 0.365–0.690 | 0.00 | 0 |
| `bg_book2_ch6_L1_far.png` | 1249 × 887 | 0 | 0.610 | 0.514–0.673 | 0.00 | 0 |
| `bg_book2_ch6_L2_mid.png` | 1150 × 887 | 0 | 0.468 | 0.294–0.617 | 0.00 | 0 |

## Preview

| File | Pixel size |
|---|---:|
| `book2_preview.png` | 1680 × 1300 |
| `book2_layers_preview.png` | 3266 × 2661 |

## Quality notes

- All 20 requested production images are present at the requested final dimensions.
- Character sheets use the required 4 × 2 grid; icon sheets use the required 3 × 1 grid.
- Character and icon backgrounds use flat key magenta. The shared sky is opaque; all six L1/L2 layers and the shared ground now use true RGBA transparency above the painted scenery.
- The first background pass produced black areas and overly panoramic compositions in several layers. Those files were rejected and regenerated at the Book 1 layer proportions before delivery.
- The v2 pass removes the painted sky/cloud backdrops from L1/L2 and removes the tall fence from L3, so stacked layers no longer cover each other with rectangular backgrounds.
- Alpha edges were despilled after resizing. Every delivered layer contains zero magenta-tint pixels, and the exact left/right alpha columns match (`0.00` mean difference).
- `book2_layers_preview.png` composites the layers with the same scene-height, ground-line and bottom offsets as the game, repeated twice horizontally for seam review.
