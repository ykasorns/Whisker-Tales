"""Turn an AI-generated parallax layer into a seamless, transparent strip.

Layer sheets follow design/art/character_prompts.md: scenery on a flat
magenta sky. The magenta is keyed out the same way slice_sheet.py keys
sprites, then the right edge is cross-faded into the left edge over
--overlap of the width and cut off, so the strip tiles left/right without a
visible seam (the game scrolls it endlessly).

Usage:
  python3 -I tools/sprite_slicer/tile_background.py SHEET.png OUT.png [--overlap 0.08] [--gaps]
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


def pick_gaps(rgba: np.ndarray, overlap: int, upper: float = 0.6, maxlose: float = 0.2):
    """Crop columns [s, e) so the cross-fade window at each end sits on a gap
    in the scenery above the ground clutter. Cross-fading two different trees
    leaves a ghost of both (orange/green smear at every seam); over a gap only
    low ground plants blend, which hides fine. Returns None when no gap exists
    near the ends (the strip is continuous)."""
    h, w = rgba.shape[:2]
    top = rgba[: int(h * upper), :, 3].astype(np.float32) / 255
    col = top.sum(axis=0)
    csum = np.concatenate([[0.0], np.cumsum(col)])
    win = csum[overlap:] - csum[:-overlap]  # alpha mass of each window
    limit = 0.004 * top.shape[0] * overlap  # almost empty
    span = int(w * maxlose)
    starts = [i for i in range(0, span) if win[i] <= limit]
    ends = [i for i in range(w - span - overlap, w - overlap + 1) if win[i] <= limit]
    if not starts or not ends:
        return None
    s = starts[-1]  # the gap closest to the middle keeps the most scenery
    e = ends[0] + overlap
    return (s, e) if e - s > w * 0.6 else None


def pick_match(rgba: np.ndarray, overlap: int, maxlose: float = 0.2):
    """No gap anywhere (dense scenery): crop where the two cross-faded ends
    look most alike, so the blend shows the least ghost."""
    h, w = rgba.shape[:2]
    pm = rgba.astype(np.float32)
    pm[..., :3] *= pm[..., 3:] / 255
    pm = pm[::2]  # half the rows: plenty to compare
    span = int(w * maxlose)
    best = None
    for s0 in range(0, span, 6):
        a = pm[:, s0: s0 + overlap]
        for e0 in range(w - span, w - overlap + 1, 6):
            b = pm[:, e0: e0 + overlap]
            cost = float(np.abs(a - b).mean())
            if best is None or cost < best[0]:
                best = (cost, s0, e0 + overlap)
    return (best[1], best[2]) if best and best[2] - best[1] > w * 0.6 else None


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("sheet")
    p.add_argument("out")
    p.add_argument("--overlap", type=float, default=0.08, help="share of the width")
    p.add_argument("--gaps", action="store_true",
                   help="place the seam where the scenery above the ground has a gap")
    args = p.parse_args()

    rgb = np.asarray(Image.open(args.sheet).convert("RGB"))
    rgba = remove_background(rgb, estimate_background(rgb))
    overlap = round(rgb.shape[1] * args.overlap)
    # a narrow window fits into the gap between two trees; ground plants
    # still blend over it
    narrow = min(overlap, round(rgb.shape[1] * 0.03))
    gaps = None
    if args.gaps:
        gaps = pick_gaps(rgba, narrow) or pick_match(rgba, narrow)
    if gaps:
        overlap = min(overlap, round(rgb.shape[1] * 0.03))
    if gaps:
        rgba = rgba[:, gaps[0]: gaps[1]]
        print(f"cross-fade on scenery gaps: kept columns {gaps[0]}..{gaps[1]}")
    out = make_seamless(rgba, overlap)
    Image.fromarray(out, "RGBA").save(args.out, optimize=True)
    print(f"done: {args.out} {out.shape[1]}x{out.shape[0]}")


if __name__ == "__main__":
    main()
