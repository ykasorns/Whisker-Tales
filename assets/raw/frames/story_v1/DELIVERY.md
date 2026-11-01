# Story Run Art v1 — Delivery

Generated as original raster artwork with the built-in ImageGen workflow. Current Whisker Tales cat, monster, and UI-frame assets were used only as style references.

## Shared art direction

- Pencil-and-crayon children's storybook rendering
- Warm palette with soft dark-brown outlines
- Friendly, kid-safe original characters
- No text or letters inside production artwork
- Real transparent alpha (PNG-32)
- No exterior drop shadow or glow
- Tight crop with safe transparent padding

## Production files

### Speaker portraits

| File | Pixel size | Alpha | Prompt subject |
|---|---:|---|---|
| `portraits/portrait_bobbin.png` | 256×256 | Yes | Cheerful teal thread spool with big eyes and a curled thread tail, facing slightly right |
| `portraits/portrait_hoot.png` | 256×256 | Yes | Sleepy-wise round owl with tiny round glasses and scholar cap, facing slightly right |
| `portraits/portrait_pip.png` | 256×256 | Yes | Worried but sweet grey mouse holding a blank upside-down wooden sign, facing slightly right |
| `portraits/portrait_crumb.png` | 256×256 | Yes | Plump hedgehog baker with flour-dusted apron and chef hat, facing slightly right |
| `portraits/portrait_inkie.png` | 256×256 | Yes | Friendly dark-blue dancing ink puddle with smiling face and arrow-shaped splash on top |
| `portraits/portrait_chesty.png` | 256×256 | Yes | Small wooden treasure chest with one mischievous face, tiny tongue and teeth along the lid |

### Card frames

Rectangle coordinates use `[x1,y1,x2,y2]` with the lower-right edge exclusive. The rectangle is a conservative, fully cream paper area measured from the final pixels.

| File | Pixel size | Alpha | Paper-face rectangle |
|---|---:|---|---|
| `cards/card_pick.png` | 200×280 | Yes | `[20,25,181,254]` |
| `cards/card_pick_selected.png` | 200×280 | Yes | `[27,30,174,249]` |
| `cards/card_shop.png` | 200×280 | Yes | `[20,22,180,241]` |

Card prompt set: portrait paper card, slim honey-wood rim, flat clean cream face, no leaves or vines; the selected version uses a warmer gold rim; the shop version includes a small blank bottom price tag.

### Combat FX

| File | Pixel size | Alpha | Prompt subject |
|---|---:|---|---|
| `fx/fx_hit_white.png` | 128×128 | Yes | Quick white crayon impact starburst |
| `fx/fx_hit_crit.png` | 128×128 | Yes | Larger gold impact starburst with small star shards |
| `fx/fx_hit_hurt.png` | 128×128 | Yes | Compact coral-red hurt puff |
| `fx/fx_dust.png` | 128×128 | Yes | Soft warm footstep dust puff |

## Preview

`preview_sheet.png` is 1600×1320. Its mid-grey background and labels are preview-only; all production assets retain transparent backgrounds and contain no text.

## Count note

The brief's explicit filename lists contain 13 production PNGs. With `preview_sheet.png`, this delivery therefore contains 14 PNGs, not the stated 17. No unnamed filler files were invented.

No Dart, JSON, game documentation, APK, or commit was created or changed for this delivery.
