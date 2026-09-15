#!/usr/bin/env python3
"""Make near-white slide-logo backgrounds transparent and crop to the artwork.

Flood-fills only from light pixels on the image border, so white that belongs
to the drawing (knotwork, manuscript parchment, cathedral windows) is kept.
"""

from __future__ import annotations

import argparse
from collections import deque
from pathlib import Path

import numpy as np
from PIL import Image

LOGO_DIR = Path(__file__).resolve().parent
IMAGE_EXTS = {".png", ".jpg", ".jpeg", ".webp"}
SKIP = {"remove_background.py"}


def light_border_background(rgb: np.ndarray) -> np.ndarray:
    """Median colour of light pixels along the frame, used as the paper colour."""
    border = np.concatenate(
        [rgb[0], rgb[-1], rgb[:, 0], rgb[:, -1]],
        axis=0,
    )
    light = border[border.mean(axis=1) >= 200]
    if len(light) == 0:
        light = border
    return np.median(light, axis=0)


def is_paper(pix: np.ndarray, paper: np.ndarray, tol: float) -> np.ndarray:
    return np.all(np.abs(pix.astype(np.int16) - paper) <= tol, axis=-1)


def flood_paper(rgba: np.ndarray, paper: np.ndarray, tol: float) -> np.ndarray:
    h, w = rgba.shape[:2]
    rgb = rgba[:, :, :3]
    paper_mask = is_paper(rgb, paper, tol)
    start = np.zeros((h, w), dtype=bool)
    start[0] |= paper_mask[0]
    start[-1] |= paper_mask[-1]
    start[:, 0] |= paper_mask[:, 0]
    start[:, -1] |= paper_mask[:, -1]

    seen = np.zeros((h, w), dtype=bool)
    queue = deque(zip(*np.nonzero(start)))
    while queue:
        y, x = queue.popleft()
        if seen[y, x]:
            continue
        seen[y, x] = True
        if not paper_mask[y, x]:
            continue
        rgba[y, x, 3] = 0
        for ny, nx in ((y - 1, x), (y + 1, x), (y, x - 1), (y, x + 1)):
            if 0 <= ny < h and 0 <= nx < w and not seen[ny, nx]:
                queue.append((ny, nx))
    return rgba


def crop_to_alpha(image: Image.Image, pad: int) -> Image.Image:
    bbox = image.getbbox()
    if bbox is None:
        return image
    left, top, right, bottom = bbox
    left = max(0, left - pad)
    top = max(0, top - pad)
    right = min(image.width, right + pad)
    bottom = min(image.height, bottom + pad)
    return image.crop((left, top, right, bottom))


def process(path: Path, tol: float, pad: int) -> Path:
    src = Image.open(path).convert("RGBA")
    arr = np.array(src)
    dest = path.with_suffix(".png")
    if (arr[:, :, 3] < 255).mean() > 0.05:
        print(f"{path.name}: already has transparency, skip")
        return dest
    paper = light_border_background(arr[:, :, :3])
    out = flood_paper(np.array(src), paper, tol)
    image = crop_to_alpha(Image.fromarray(out), pad)
    dest = path.with_suffix(".png")
    image.save(dest)
    print(f"{path.name}: paper RGB {tuple(paper.round().astype(int))} -> {dest.name} {image.size}")
    return dest


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "paths",
        nargs="*",
        type=Path,
        help="Images to process (default: all images in this directory)",
    )
    parser.add_argument("--tol", type=float, default=28, help="Max per-channel distance from paper")
    parser.add_argument("--pad", type=int, default=6, help="Pixels kept around the cropped artwork")
    args = parser.parse_args()

    paths = args.paths or [
        p
        for p in sorted(LOGO_DIR.iterdir())
        if p.suffix.lower() in IMAGE_EXTS and p.name not in SKIP
    ]
    if not paths:
        raise SystemExit("No images found")
    for path in paths:
        process(path, args.tol, args.pad)


if __name__ == "__main__":
    main()
