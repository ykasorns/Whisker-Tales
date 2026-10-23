"""Turn an AI-generated parallax layer into a seamless, transparent strip.

Layer sheets follow design/art/character_prompts.md: scenery on a flat
magenta sky. The magenta is keyed out the same way slice_sheet.py keys
sprites, then the right edge is cross-faded into the left edge over
--overlap of the width and cut off, so the strip tiles left/right without a
visible seam (the game scrolls it endlessly).

Usage:
  python3 -I tools/sprite_slicer/tile_background.py SHEET.png OUT.png [--overlap 0.08]
"""

import argparse
import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from slice_sheet import estimate_background, remove_background  # noqa: E402


def make_seamless(rgba: np.ndarray, overlap: int) -> np.ndarray:
    """Width − overlap; the first `overlap` columns fade from the cut-off
    right edge into the original left edge (premultiplied, so transparent
    sky does not darken the blend)."""
    w = rgba.shape[1]
    out = rgba[:, : w - overlap].astype(np.float32)
    tail = rgba[:, w - overlap:].astype(np.float32)
    head = out[:, :overlap]
    t = np.linspace(0.0, 1.0, overlap, dtype=np.float32)[None, :, None]
    a_head, a_tail = head[..., 3:] / 255, tail[..., 3:] / 255
    a = a_tail * (1 - t) + a_head * t
    rgb = (tail[..., :3] * a_tail * (1 - t) + head[..., :3] * a_head * t) / np.maximum(a, 1e-3)
    out[:, :overlap] = np.dstack([rgb, a * 255])
    return np.clip(out, 0, 255).astype(np.uint8)


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("sheet")
    p.add_argument("out")
    p.add_argument("--overlap", type=float, default=0.08, help="share of the width")
    args = p.parse_args()

    rgb = np.asarray(Image.open(args.sheet).convert("RGB"))
    rgba = remove_background(rgb, estimate_background(rgb))
    out = make_seamless(rgba, round(rgb.shape[1] * args.overlap))
    Image.fromarray(out, "RGBA").save(args.out, optimize=True)
    print(f"done: {args.out} {out.shape[1]}x{out.shape[0]}")


if __name__ == "__main__":
    main()
