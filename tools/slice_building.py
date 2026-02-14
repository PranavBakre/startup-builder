#!/usr/bin/env python3
"""
9-Slice Building Slicer for Startup Simulator.

Takes a full building facade image and slices it into 9 tiles for flexible
rendering in the tile-based game engine.

Output layout (each piece 320×320):
  TL  TM  TR
  ML  MM  MR
  BL  BM  BR

For inputs larger than 960×960, edges are extracted from borders and
the fill (MM) is taken from the center. This allows buildings of any
size to be represented with a fixed 3×3 tile footprint.

Usage:
  uv run python slice_building.py <input_image> <building_type>
  uv run python slice_building.py facade.png office
  # → game/assets/buildings/office/tl.png ... br.png
"""

import argparse
import sys
from pathlib import Path
from PIL import Image

TILE_SIZE = 320
MIN_INPUT = TILE_SIZE * 3  # 960

SLICE_NAMES = [
    ("tl", 0, 0), ("tm", 1, 0), ("tr", 2, 0),
    ("ml", 0, 1), ("mm", 1, 1), ("mr", 2, 1),
    ("bl", 0, 2), ("bm", 1, 2), ("br", 2, 2),
]


def slice_building(input_path: Path, building_type: str, output_root: Path | None = None) -> None:
    """Slice a building facade into 9 tiles."""
    image = Image.open(input_path).convert("RGBA")
    w, h = image.size

    if w < MIN_INPUT or h < MIN_INPUT:
        print(f"ERROR: Input must be at least {MIN_INPUT}×{MIN_INPUT}px, got {w}×{h}")
        sys.exit(1)

    # Determine output directory
    if output_root is None:
        output_root = Path(__file__).parent.parent / "game" / "assets" / "buildings"
    out_dir = output_root / building_type
    out_dir.mkdir(parents=True, exist_ok=True)

    # For images exactly 960×960, simple 3×3 grid cut
    # For larger images, extract edges from borders, center from middle
    t = TILE_SIZE  # alias

    # Source regions: (left, upper, right, lower)
    # Columns: left edge [0..t], center [mid-t/2..mid+t/2], right edge [w-t..w]
    # Rows:    top edge  [0..t], center [mid-t/2..mid+t/2], bottom edge [h-t..h]
    cx = w // 2
    cy = h // 2

    col_ranges = [
        (0, t),                         # left
        (cx - t // 2, cx + t // 2),     # center
        (w - t, w),                     # right
    ]
    row_ranges = [
        (0, t),                         # top
        (cy - t // 2, cy + t // 2),     # center
        (h - t, h),                     # bottom
    ]

    print(f"Slicing {input_path.name} ({w}×{h}) → {out_dir}/")

    for name, col, row in SLICE_NAMES:
        x1, x2 = col_ranges[col]
        y1, y2 = row_ranges[row]
        tile = image.crop((x1, y1, x2, y2))

        # Ensure exact tile size (handles odd-dimension rounding)
        if tile.size != (t, t):
            tile = tile.resize((t, t), Image.LANCZOS)

        out_path = out_dir / f"{name}.png"
        tile.save(out_path, "PNG")
        print(f"  ✓ {name}.png  ({x1},{y1})→({x2},{y2})")

    print(f"\nDone! 9 tiles saved to {out_dir}/")


def main():
    parser = argparse.ArgumentParser(description="Slice a building facade into 9 tiles")
    parser.add_argument("input", help="Input building facade image (≥960×960)")
    parser.add_argument("building_type", help="Building type name (e.g. office, bungalow)")
    parser.add_argument("--output-dir", help="Override output root directory")
    args = parser.parse_args()

    input_path = Path(args.input)
    if not input_path.exists():
        print(f"ERROR: {input_path} not found")
        sys.exit(1)

    output_root = Path(args.output_dir) if args.output_dir else None
    slice_building(input_path, args.building_type, output_root)


if __name__ == "__main__":
    main()
