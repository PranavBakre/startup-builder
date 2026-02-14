#!/usr/bin/env python3
"""
Sprite Post-Processing Pipeline for Startup Simulator.

Steps:
  1. Background removal (magenta keying with anti-aliased edge cleanup)
  2. Palette quantization (map to master palette)
  3. Seamless tile edge-blending (ground tiles only)
  4. Resize to 320×320 output
  5. Export as PNG with transparency

Usage:
  uv run python process_sprites.py <input> [--output <output>] [--tile] [--size 320]
  uv run python process_sprites.py --batch <dir> [--output-dir <dir>] [--size 320]
"""

import argparse
import math
import sys
from pathlib import Path
from PIL import Image, ImageFilter

# ===========================================================================
# Master Palette — warm illustrated Bangalore aesthetic
# Derived from the game's tile types and visual identity.
# ===========================================================================
MASTER_PALETTE = [
    # Greens (grass, vegetation)
    (74, 140, 58),    # dark grass
    (106, 176, 76),   # mid grass
    (140, 200, 96),   # light grass
    (56, 100, 46),    # deep foliage
    (168, 212, 120),  # pale lawn

    # Earth tones (dirt, sand, paths)
    (160, 100, 60),   # laterite red-brown
    (192, 140, 90),   # warm dirt
    (210, 180, 140),  # sandy beige
    (140, 80, 50),    # dark earth
    (225, 200, 160),  # pale sand

    # Grays (asphalt, concrete, roofs)
    (80, 80, 90),     # dark asphalt
    (120, 120, 125),  # mid gray
    (170, 170, 175),  # light concrete
    (55, 55, 60),     # deep shadow
    (200, 200, 200),  # pale gray

    # Warm building tones (terracotta, brick, wood, paint)
    (180, 90, 50),    # terracotta
    (200, 120, 70),   # warm brick
    (220, 180, 100),  # ochre/yellow paint
    (240, 220, 180),  # cream wall
    (150, 70, 45),    # dark brick

    # Blues (water, sky accents)
    (80, 140, 200),   # water blue
    (120, 180, 220),  # light water
    (60, 100, 160),   # deep blue

    # Accent colors (flowers, signs, details)
    (220, 60, 80),    # marigold red
    (240, 160, 50),   # marigold orange
    (200, 80, 160),   # bougainvillea pink
    (255, 240, 200),  # warm highlight
    (40, 40, 45),     # near-black outlines

    # Whites
    (245, 245, 240),  # off-white
    (255, 255, 255),  # pure white
]


def _nearest_palette_color(r: int, g: int, b: int) -> tuple[int, int, int]:
    """Find the closest color in the master palette (Euclidean distance in RGB)."""
    best = MASTER_PALETTE[0]
    best_dist = float("inf")
    for pr, pg, pb in MASTER_PALETTE:
        d = (r - pr) ** 2 + (g - pg) ** 2 + (b - pb) ** 2
        if d < best_dist:
            best_dist = d
            best = (pr, pg, pb)
    return best


# ===========================================================================
# Step 1: Background Removal (magenta keying)
# ===========================================================================

def remove_magenta_bg(image: Image.Image, threshold: int = 60) -> Image.Image:
    """
    Remove magenta (#FF00FF) background with anti-aliased soft edges.
    
    Uses a two-pass approach:
      1. Hard key: pixels close to magenta become fully transparent.
      2. Soft edge: border pixels get partial alpha based on color distance.
    """
    image = image.convert("RGBA")
    pixels = image.load()
    w, h = image.size

    for y in range(h):
        for x in range(w):
            r, g, b, a = pixels[x, y]
            # Magenta distance: high R, low G, high B
            mag_dist = math.sqrt(
                (r - 255) ** 2 + g ** 2 + (b - 255) ** 2
            )
            if mag_dist < threshold:
                pixels[x, y] = (0, 0, 0, 0)
            elif mag_dist < threshold * 1.5:
                # Soft edge — partial alpha
                alpha_factor = (mag_dist - threshold) / (threshold * 0.5)
                new_alpha = int(min(a, 255 * alpha_factor))
                pixels[x, y] = (r, g, b, new_alpha)

    return image


# ===========================================================================
# Step 2: Palette Quantization
# ===========================================================================

def quantize_to_palette(image: Image.Image) -> Image.Image:
    """Map every opaque pixel to the nearest master palette color."""
    image = image.convert("RGBA")
    pixels = image.load()
    w, h = image.size

    for y in range(h):
        for x in range(w):
            r, g, b, a = pixels[x, y]
            if a < 10:
                continue  # skip transparent
            nr, ng, nb = _nearest_palette_color(r, g, b)
            pixels[x, y] = (nr, ng, nb, a)

    return image


# ===========================================================================
# Step 3: Seamless Tile Edge-Blending
# ===========================================================================

def blend_tile_edges(image: Image.Image, margin: int = 16) -> Image.Image:
    """
    Make a tile seamless by blending opposite edges.
    
    For each edge strip of `margin` pixels, cross-fade with the opposite edge
    so the tile wraps without visible seams.
    """
    image = image.convert("RGBA")
    w, h = image.size
    result = image.copy()
    src = image.load()
    dst = result.load()

    # Horizontal wrap (left ↔ right)
    for y in range(h):
        for i in range(margin):
            t = i / margin  # 0 at edge → 1 at margin
            # Left edge: blend with right side
            lr, lg, lb, la = src[i, y]
            rr, rg, rb, ra = src[w - margin + i, y]
            blended = (
                int(lr * t + rr * (1 - t)),
                int(lg * t + rg * (1 - t)),
                int(lb * t + rb * (1 - t)),
                int(la * t + ra * (1 - t)),
            )
            dst[i, y] = blended
            dst[w - margin + i, y] = (
                int(rr * t + lr * (1 - t)),
                int(rg * t + lg * (1 - t)),
                int(rb * t + lb * (1 - t)),
                int(ra * t + la * (1 - t)),
            )

    # Vertical wrap (top ↔ bottom)
    src = result.load()  # re-read after horizontal pass
    for x in range(w):
        for i in range(margin):
            t = i / margin
            tr, tg, tb, ta = src[x, i]
            br, bg, bb, ba = src[x, h - margin + i]
            blended = (
                int(tr * t + br * (1 - t)),
                int(tg * t + bg * (1 - t)),
                int(tb * t + bb * (1 - t)),
                int(ta * t + ba * (1 - t)),
            )
            dst[x, i] = blended
            dst[x, h - margin + i] = (
                int(br * t + tr * (1 - t)),
                int(bg * t + tg * (1 - t)),
                int(bb * t + tb * (1 - t)),
                int(ba * t + ta * (1 - t)),
            )

    return result


# ===========================================================================
# Step 4 & 5: Resize + Export
# ===========================================================================

def resize_sprite(image: Image.Image, size: int = 320) -> Image.Image:
    """Resize to size×size using high-quality Lanczos resampling."""
    return image.resize((size, size), Image.LANCZOS)


# ===========================================================================
# Full Pipeline
# ===========================================================================

def process_sprite(
    input_path: Path,
    output_path: Path,
    is_tile: bool = False,
    target_size: int = 320,
    quantize: bool = True,
) -> None:
    """Run the full post-processing pipeline on a single sprite."""
    print(f"Processing {input_path.name}...")

    image = Image.open(input_path)

    # 1. Background removal
    image = remove_magenta_bg(image)
    print("  ✓ Background removed")

    # 2. Palette quantization
    if quantize:
        image = quantize_to_palette(image)
        print("  ✓ Palette quantized")

    # 3. Seamless edge blending (ground tiles only)
    if is_tile:
        image = blend_tile_edges(image)
        print("  ✓ Tile edges blended")

    # 4. Resize
    image = resize_sprite(image, target_size)
    print(f"  ✓ Resized to {target_size}×{target_size}")

    # 5. Export
    output_path.parent.mkdir(parents=True, exist_ok=True)
    image.save(output_path, "PNG")
    print(f"  ✓ Saved to {output_path}")


# Ground tile filenames (these get edge-blending)
GROUND_TILES = {
    "ground.png", "ground_grass.png", "ground_dirt.png",
    "ground_sand.png", "park_ground.png",
}


def _is_ground_tile(path: Path) -> bool:
    return path.name in GROUND_TILES


def main():
    parser = argparse.ArgumentParser(description="Post-process game sprites")
    parser.add_argument("input", nargs="?", help="Input image file")
    parser.add_argument("--output", "-o", help="Output file path")
    parser.add_argument("--tile", action="store_true", help="Apply seamless tile blending")
    parser.add_argument("--size", type=int, default=320, help="Output size in pixels (default: 320)")
    parser.add_argument("--no-quantize", action="store_true", help="Skip palette quantization")
    parser.add_argument("--batch", help="Process all PNGs in directory")
    parser.add_argument("--output-dir", help="Output directory for batch mode")
    args = parser.parse_args()

    if args.batch:
        batch_dir = Path(args.batch)
        out_dir = Path(args.output_dir) if args.output_dir else batch_dir / "processed"
        if not batch_dir.is_dir():
            print(f"ERROR: {batch_dir} is not a directory")
            sys.exit(1)

        pngs = sorted(batch_dir.glob("*.png"))
        if not pngs:
            print(f"No PNG files found in {batch_dir}")
            sys.exit(0)

        print(f"Processing {len(pngs)} sprites from {batch_dir}...\n")
        for p in pngs:
            is_tile = args.tile or _is_ground_tile(p)
            process_sprite(p, out_dir / p.name, is_tile=is_tile,
                           target_size=args.size, quantize=not args.no_quantize)
            print()
        print("Done!")

    elif args.input:
        inp = Path(args.input)
        if not inp.exists():
            print(f"ERROR: {inp} not found")
            sys.exit(1)
        out = Path(args.output) if args.output else inp.parent / f"{inp.stem}_processed.png"
        is_tile = args.tile or _is_ground_tile(inp)
        process_sprite(inp, out, is_tile=is_tile, target_size=args.size,
                       quantize=not args.no_quantize)
    else:
        parser.print_help()
        sys.exit(1)


if __name__ == "__main__":
    main()
