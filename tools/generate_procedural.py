#!/usr/bin/env python3
"""
Procedural Sprite Generator for Startup Simulator
No AI/API — pure Pillow drawing. Generates all game assets programmatically.

Style: Illustrated top-down, warm Indiranagar palette, shadowless.
All props/characters have transparent backgrounds.
Ground tiles are seamless-tileable.
Buildings are top-down roof views.
"""

import os
import sys
import math
import random
from pathlib import Path

try:
    from PIL import Image, ImageDraw, ImageFont, ImageFilter
except ImportError:
    print("ERROR: pip install pillow")
    sys.exit(1)

# ─── Palette (from art-direction.md) ───
PAL = {
    "terracotta":   (196, 92, 62),
    "brick":        (156, 74, 58),
    "brick_light":  (180, 100, 72),
    "cream":        (245, 235, 220),
    "sand":         (210, 190, 160),
    "grass":        (90, 140, 60),
    "grass_light":  (110, 160, 75),
    "grass_dark":   (70, 120, 48),
    "park_green":   (80, 150, 55),
    "park_light":   (100, 170, 70),
    "asphalt":      (140, 132, 120),
    "asphalt_dark": (120, 112, 100),
    "dirt":         (160, 120, 80),
    "dirt_dark":    (140, 100, 65),
    "wood":         (160, 120, 70),
    "wood_dark":    (130, 95, 55),
    "roof_tile":    (180, 90, 55),
    "roof_dark":    (155, 75, 45),
    "concrete":     (185, 180, 172),
    "concrete_dk":  (165, 160, 152),
    "blue_glass":   (140, 170, 200),
    "blue_glass_dk":(120, 150, 180),
    "yellow":       (220, 190, 80),
    "white":        (250, 248, 245),
    "dark":         (60, 55, 50),
    "skin":         (180, 140, 110),
    "skin_dark":    (160, 120, 90),
    "hair_black":   (45, 35, 30),
    "shirt_blue":   (100, 140, 190),
    "shirt_red":    (190, 70, 60),
    "shirt_green":  (70, 140, 80),
    "shirt_teal":   (60, 150, 140),
    "jeans":        (80, 90, 120),
    "metal_grey":   (160, 165, 170),
    "green_bench":  (60, 120, 70),
    "water_blue":   (130, 180, 210),
    "water_light":  (170, 210, 235),
    "flower_orange":(230, 150, 50),
    "flower_pink":  (220, 100, 130),
    "flower_white": (245, 240, 235),
    "leaf_green":   (80, 140, 55),
    "leaf_dark":    (55, 100, 40),
    "trunk_brown":  (110, 80, 50),
}

TILE = 320
CHAR_SIZE = 320
SEED = 42

random.seed(SEED)


# ─── Utility ───

def noise_fill(draw, x0, y0, x1, y1, base_color, variance=10, density=1.0):
    """Fill a region with noisy color variation for texture."""
    r, g, b = base_color
    for y in range(y0, y1, 2):
        for x in range(x0, x1, 2):
            if density < 1.0 and random.random() > density:
                continue
            dr = random.randint(-variance, variance)
            c = (max(0, min(255, r+dr)), max(0, min(255, g+dr)), max(0, min(255, b+dr)))
            draw.rectangle([x, y, x+1, y+1], fill=c)


def draw_ellipse_aa(img, bbox, fill):
    """Draw a slightly softer ellipse."""
    overlay = Image.new("RGBA", img.size, (0,0,0,0))
    d = ImageDraw.Draw(overlay)
    d.ellipse(bbox, fill=fill)
    # slight blur for anti-alias
    overlay = overlay.filter(ImageFilter.GaussianBlur(1))
    img.paste(Image.alpha_composite(Image.new("RGBA", img.size, (0,0,0,0)), overlay), (0,0), overlay)
    return img


# ═══════════════════════════════════════════════════════════════
# GROUND TILES (seamless tileable)
# ═══════════════════════════════════════════════════════════════

def gen_ground():
    """Asphalt road tile."""
    img = Image.new("RGBA", (TILE, TILE), PAL["asphalt"])
    draw = ImageDraw.Draw(img)
    noise_fill(draw, 0, 0, TILE, TILE, PAL["asphalt"], variance=8)
    # subtle cracks
    for _ in range(3):
        x = random.randint(20, TILE-20)
        y = random.randint(20, TILE-20)
        pts = [(x, y)]
        for _ in range(random.randint(4, 8)):
            x += random.randint(-15, 15)
            y += random.randint(5, 20)
            pts.append((x, y))
        draw.line(pts, fill=PAL["asphalt_dark"], width=1)
    return img

def gen_grass():
    """Green grass tile."""
    img = Image.new("RGBA", (TILE, TILE), PAL["grass"])
    draw = ImageDraw.Draw(img)
    noise_fill(draw, 0, 0, TILE, TILE, PAL["grass"], variance=12)
    # grass blade strokes
    for _ in range(200):
        x = random.randint(0, TILE-1)
        y = random.randint(0, TILE-1)
        l = random.randint(4, 10)
        c = random.choice([PAL["grass_light"], PAL["grass_dark"]])
        draw.line([(x, y), (x+random.randint(-2,2), y-l)], fill=c, width=1)
    return img

def gen_dirt():
    """Dirt/laterite path tile."""
    img = Image.new("RGBA", (TILE, TILE), PAL["dirt"])
    draw = ImageDraw.Draw(img)
    noise_fill(draw, 0, 0, TILE, TILE, PAL["dirt"], variance=15)
    # pebbles
    for _ in range(30):
        x, y = random.randint(5, TILE-5), random.randint(5, TILE-5)
        r = random.randint(2, 5)
        draw.ellipse([x-r, y-r, x+r, y+r], fill=PAL["dirt_dark"])
    return img

def gen_sand():
    """Sandy walkway tile."""
    img = Image.new("RGBA", (TILE, TILE), PAL["sand"])
    draw = ImageDraw.Draw(img)
    noise_fill(draw, 0, 0, TILE, TILE, PAL["sand"], variance=10)
    return img

def gen_park_ground():
    """Park grass — distinct from regular grass: lighter, with clover patches."""
    img = Image.new("RGBA", (TILE, TILE), PAL["park_green"])
    draw = ImageDraw.Draw(img)
    noise_fill(draw, 0, 0, TILE, TILE, PAL["park_green"], variance=12)
    # clover/flower patches to distinguish from plain grass
    for _ in range(8):
        cx, cy = random.randint(20, TILE-20), random.randint(20, TILE-20)
        r = random.randint(8, 18)
        draw.ellipse([cx-r, cy-r, cx+r, cy+r], fill=PAL["park_light"])
        # tiny flowers
        for _ in range(3):
            fx = cx + random.randint(-r+3, r-3)
            fy = cy + random.randint(-r+3, r-3)
            draw.ellipse([fx-2, fy-2, fx+2, fy+2], fill=PAL["flower_white"])
    # worn footpath suggestion
    for y in range(0, TILE, 3):
        x_off = int(8 * math.sin(y / 40))
        cx = TILE // 2 + x_off
        draw.line([(cx-12, y), (cx+12, y)], fill=PAL["dirt"], width=1)
    return img


# ═══════════════════════════════════════════════════════════════
# BUILDINGS (top-down roof views, transparent bg)
# ═══════════════════════════════════════════════════════════════

def _draw_roof_tiles(draw, x0, y0, x1, y1, color, dark_color, tile_h=12):
    """Draw terracotta-style roof tile pattern."""
    for row_y in range(y0, y1, tile_h):
        offset = (tile_h // 2) if ((row_y - y0) // tile_h) % 2 else 0
        for col_x in range(x0 - tile_h, x1 + tile_h, tile_h):
            tx = col_x + offset
            if tx < x0 - tile_h or tx > x1 + tile_h:
                continue
            c = color if random.random() > 0.3 else dark_color
            draw.arc([tx, row_y, tx + tile_h, row_y + tile_h], 0, 180, fill=c, width=1)
            draw.line([(tx, row_y + tile_h//2), (tx + tile_h, row_y + tile_h//2)], fill=dark_color, width=1)

def _building_base(w, h, roof_color, roof_dark, edge_color, roof_style="flat"):
    """Create a building footprint with roof, transparent bg."""
    pad = 40
    img = Image.new("RGBA", (TILE, TILE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    cx, cy = TILE // 2, TILE // 2
    x0, y0 = cx - w//2, cy - h//2
    x1, y1 = cx + w//2, cy + h//2
    
    # Building outline/edge (walls visible at edges from top-down)
    draw.rectangle([x0-3, y0-3, x1+3, y1+3], fill=edge_color)
    
    if roof_style == "tiled":
        draw.rectangle([x0, y0, x1, y1], fill=roof_color)
        _draw_roof_tiles(draw, x0, y0, x1, y1, roof_color, roof_dark)
    elif roof_style == "pitched":
        draw.rectangle([x0, y0, x1, y1], fill=roof_color)
        _draw_roof_tiles(draw, x0, y0, x1, y1, roof_color, roof_dark)
        # ridge line
        draw.line([(cx, y0+10), (cx, y1-10)], fill=roof_dark, width=3)
    elif roof_style == "flat":
        draw.rectangle([x0, y0, x1, y1], fill=roof_color)
        noise_fill(draw, x0, y0, x1, y1, roof_color, variance=6)
        # flat roof edge lip
        draw.rectangle([x0, y0, x1, y0+4], fill=edge_color)
        draw.rectangle([x0, y1-4, x1, y1], fill=edge_color)
        draw.rectangle([x0, y0, x0+4, y1], fill=edge_color)
        draw.rectangle([x1-4, y0, x1, y1], fill=edge_color)
    elif roof_style == "glass":
        draw.rectangle([x0, y0, x1, y1], fill=roof_color)
        # glass panel grid
        for gx in range(x0+8, x1-8, 24):
            draw.line([(gx, y0), (gx, y1)], fill=edge_color, width=2)
        for gy in range(y0+8, y1-8, 24):
            draw.line([(x0, gy), (x1, gy)], fill=edge_color, width=2)
        # slight variation in panels
        for gx in range(x0+8, x1-8, 24):
            for gy in range(y0+8, y1-8, 24):
                if random.random() > 0.6:
                    draw.rectangle([gx+1, gy+1, gx+22, gy+22], fill=PAL["blue_glass_dk"])
    
    return img, draw, (x0, y0, x1, y1)

def gen_wall():
    """Apartment — flat concrete roof with water tank."""
    img, draw, (x0, y0, x1, y1) = _building_base(200, 180, PAL["concrete"], PAL["concrete_dk"], PAL["asphalt_dark"], "flat")
    # water tank
    tx, ty = x1 - 40, y0 + 20
    draw.rectangle([tx, ty, tx+30, ty+25], fill=PAL["concrete_dk"])
    draw.rectangle([tx+2, ty+2, tx+28, ty+23], fill=PAL["blue_glass"])
    return img

def gen_wall_brick():
    """Traditional house — terracotta tiled roof."""
    img, draw, _ = _building_base(180, 160, PAL["roof_tile"], PAL["roof_dark"], PAL["brick"], "tiled")
    return img

def gen_wall_wood():
    """Shophouse — corrugated metal roof."""
    img, draw, (x0, y0, x1, y1) = _building_base(160, 120, PAL["metal_grey"], PAL["asphalt_dark"], PAL["wood_dark"], "flat")
    # corrugation lines
    for gy in range(y0+5, y1-5, 6):
        draw.line([(x0+5, gy), (x1-5, gy)], fill=PAL["concrete_dk"], width=1)
    return img

def gen_roof():
    """Residential — pitched tile roof."""
    img, draw, _ = _building_base(190, 170, PAL["roof_tile"], PAL["roof_dark"], PAL["brick"], "pitched")
    return img

def gen_wall_school():
    """School — L-shaped flat roof."""
    img = Image.new("RGBA", (TILE, TILE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = TILE//2, TILE//2
    # L-shape: horizontal bar + vertical bar
    # horizontal
    hx0, hy0 = cx-110, cy-80
    hx1, hy1 = cx+110, cy+10
    draw.rectangle([hx0-3, hy0-3, hx1+3, hy1+3], fill=PAL["sand"])
    draw.rectangle([hx0, hy0, hx1, hy1], fill=PAL["cream"])
    noise_fill(draw, hx0, hy0, hx1, hy1, PAL["cream"], variance=5)
    # vertical
    vx0, vy0 = cx-110, cy+10
    vx1, vy1 = cx-30, cy+90
    draw.rectangle([vx0-3, vy0-3, vx1+3, vy1+3], fill=PAL["sand"])
    draw.rectangle([vx0, vy0, vx1, vy1], fill=PAL["cream"])
    noise_fill(draw, vx0, vy0, vx1, vy1, PAL["cream"], variance=5)
    # edge lips
    for rect in [(hx0, hy0, hx1, hy1), (vx0, vy0, vx1, vy1)]:
        draw.rectangle([rect[0], rect[1], rect[2], rect[1]+3], fill=PAL["sand"])
        draw.rectangle([rect[0], rect[3]-3, rect[2], rect[3]], fill=PAL["sand"])
    return img

def gen_wall_office():
    """Office — glass/steel flat roof."""
    img, draw, (x0, y0, x1, y1) = _building_base(220, 200, PAL["blue_glass"], PAL["blue_glass_dk"], PAL["concrete_dk"], "glass")
    # AC units
    for i in range(3):
        ax = x0 + 20 + i * 60
        ay = y0 + 15
        draw.rectangle([ax, ay, ax+25, ay+18], fill=PAL["concrete_dk"])
        draw.ellipse([ax+8, ay+4, ax+18, ay+14], fill=PAL["asphalt_dark"])
    return img

def gen_wall_bungalow():
    """Bungalow — warm tiled pitched roof."""
    img, draw, (x0, y0, x1, y1) = _building_base(200, 170, PAL["terracotta"], PAL["brick"], PAL["cream"], "pitched")
    # small porch overhang at bottom
    px0, py0 = TILE//2-30, y1+3
    draw.rectangle([px0, py0, px0+60, py0+15], fill=PAL["wood"])
    draw.rectangle([px0+2, py0+2, px0+58, py0+13], fill=PAL["wood_dark"])
    return img


# ═══════════════════════════════════════════════════════════════
# PROPS (transparent bg, top-down view)
# ═══════════════════════════════════════════════════════════════

def gen_tree():
    """Large spreading tree canopy — top-down."""
    img = Image.new("RGBA", (TILE, TILE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = TILE//2, TILE//2
    # canopy blobs
    for _ in range(12):
        ox = cx + random.randint(-50, 50)
        oy = cy + random.randint(-50, 50)
        r = random.randint(35, 65)
        c = random.choice([PAL["leaf_green"], PAL["leaf_dark"], PAL["grass"]])
        draw.ellipse([ox-r, oy-r, ox+r, oy+r], fill=c)
    # trunk hint at center
    draw.ellipse([cx-8, cy-8, cx+8, cy+8], fill=PAL["trunk_brown"])
    return img

def gen_tree_pine():
    """Narrow columnar tree (ashoka/cypress) — top-down."""
    img = Image.new("RGBA", (TILE, TILE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = TILE//2, TILE//2
    # elongated canopy
    draw.ellipse([cx-25, cy-70, cx+25, cy+70], fill=PAL["leaf_dark"])
    draw.ellipse([cx-20, cy-60, cx+20, cy+60], fill=PAL["leaf_green"])
    # trunk
    draw.ellipse([cx-5, cy-5, cx+5, cy+5], fill=PAL["trunk_brown"])
    return img

def gen_bush():
    """Bougainvillea bush — top-down."""
    img = Image.new("RGBA", (TILE, TILE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = TILE//2, TILE//2
    # green base
    draw.ellipse([cx-40, cy-35, cx+40, cy+35], fill=PAL["leaf_green"])
    draw.ellipse([cx-35, cy-30, cx+35, cy+30], fill=PAL["leaf_dark"])
    # pink flower clusters
    for _ in range(15):
        fx = cx + random.randint(-30, 30)
        fy = cy + random.randint(-25, 25)
        draw.ellipse([fx-5, fy-5, fx+5, fy+5], fill=PAL["flower_pink"])
    return img

def gen_flowers():
    """Marigold/jasmine flower bed — top-down."""
    img = Image.new("RGBA", (TILE, TILE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = TILE//2, TILE//2
    # soil circle
    draw.ellipse([cx-45, cy-45, cx+45, cy+45], fill=PAL["dirt"])
    # green leaves
    draw.ellipse([cx-40, cy-40, cx+40, cy+40], fill=PAL["leaf_green"])
    # flowers
    for _ in range(25):
        fx = cx + random.randint(-32, 32)
        fy = cy + random.randint(-32, 32)
        if (fx-cx)**2 + (fy-cy)**2 > 35**2:
            continue
        c = random.choice([PAL["flower_orange"], PAL["flower_white"], PAL["yellow"]])
        r = random.randint(3, 6)
        draw.ellipse([fx-r, fy-r, fx+r, fy+r], fill=c)
    return img

def gen_bench():
    """Park bench — top-down."""
    img = Image.new("RGBA", (TILE, TILE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = TILE//2, TILE//2
    # bench body
    bw, bh = 70, 25
    draw.rectangle([cx-bw, cy-bh, cx+bw, cy+bh], fill=PAL["green_bench"])
    # slats
    for sy in range(cy-bh+4, cy+bh-4, 8):
        draw.line([(cx-bw+5, sy), (cx+bw-5, sy)], fill=(50, 100, 55), width=2)
    # legs
    for lx in [cx-bw+10, cx+bw-10]:
        for ly in [cy-bh+5, cy+bh-5]:
            draw.rectangle([lx-3, ly-3, lx+3, ly+3], fill=PAL["dark"])
    return img

def gen_lamp_post():
    """Street lamp — top-down (circle head + thin pole shadow)."""
    img = Image.new("RGBA", (TILE, TILE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = TILE//2, TILE//2
    # pole
    draw.line([(cx, cy-30), (cx, cy+30)], fill=PAL["metal_grey"], width=3)
    # lamp head
    draw.ellipse([cx-15, cy-15, cx+15, cy+15], fill=PAL["metal_grey"])
    draw.ellipse([cx-10, cy-10, cx+10, cy+10], fill=PAL["yellow"])
    return img

def gen_fence():
    """Compound wall section — top-down."""
    img = Image.new("RGBA", (TILE, TILE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = TILE//2, TILE//2
    # horizontal wall
    draw.rectangle([cx-120, cy-8, cx+120, cy+8], fill=PAL["concrete"])
    draw.rectangle([cx-120, cy-6, cx+120, cy+6], fill=PAL["cream"])
    # posts
    for px in range(cx-120, cx+121, 40):
        draw.rectangle([px-5, cy-10, px+5, cy+10], fill=PAL["concrete_dk"])
    # iron railing dots on top
    for px in range(cx-115, cx+116, 10):
        draw.ellipse([px-2, cy-4, px+2, cy+4], fill=PAL["dark"])
    return img

def gen_fountain():
    """Park fountain — top-down."""
    img = Image.new("RGBA", (TILE, TILE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = TILE//2, TILE//2
    # outer stone ring
    draw.ellipse([cx-60, cy-60, cx+60, cy+60], fill=PAL["concrete"])
    # water
    draw.ellipse([cx-52, cy-52, cx+52, cy+52], fill=PAL["water_blue"])
    draw.ellipse([cx-35, cy-35, cx+35, cy+35], fill=PAL["water_light"])
    # inner ring
    draw.ellipse([cx-20, cy-20, cx+20, cy+20], fill=PAL["concrete_dk"])
    # center spout
    draw.ellipse([cx-6, cy-6, cx+6, cy+6], fill=PAL["water_light"])
    # ripples
    for r in [25, 40, 50]:
        draw.ellipse([cx-r, cy-r, cx+r, cy+r], outline=(150, 195, 225, 100), width=1)
    return img

def gen_mailbox():
    """Red post box — top-down."""
    img = Image.new("RGBA", (TILE, TILE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = TILE//2, TILE//2
    # cylindrical top
    draw.ellipse([cx-18, cy-18, cx+18, cy+18], fill=(200, 55, 45))
    draw.ellipse([cx-14, cy-14, cx+14, cy+14], fill=(220, 70, 55))
    # dome highlight
    draw.ellipse([cx-6, cy-8, cx+4, cy-2], fill=(240, 110, 90))
    return img

def gen_trash_can():
    """Dustbin — top-down."""
    img = Image.new("RGBA", (TILE, TILE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = TILE//2, TILE//2
    draw.ellipse([cx-20, cy-20, cx+20, cy+20], fill=PAL["green_bench"])
    draw.ellipse([cx-16, cy-16, cx+16, cy+16], fill=(70, 130, 80))
    # lid handle
    draw.rectangle([cx-8, cy-2, cx+8, cy+2], fill=PAL["dark"])
    return img

def gen_sign_shop():
    """Shop signboard — top-down (rectangular sign on pole)."""
    img = Image.new("RGBA", (TILE, TILE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = TILE//2, TILE//2
    # pole
    draw.rectangle([cx-2, cy-40, cx+2, cy+40], fill=PAL["metal_grey"])
    # sign
    draw.rectangle([cx-35, cy-15, cx+35, cy+15], fill=PAL["yellow"])
    draw.rectangle([cx-33, cy-13, cx+33, cy+13], fill=PAL["terracotta"])
    return img


# ═══════════════════════════════════════════════════════════════
# CHARACTERS (3/4 front view, transparent bg)
# ═══════════════════════════════════════════════════════════════

def _draw_character(img, draw, skin, hair_color, shirt_color, pant_color, 
                    has_glasses=False, accessory=None, hair_style="short"):
    """Draw a stylized chibi-ish character, full body."""
    cx, cy_head = TILE//2, 75
    
    # Head
    head_r = 35
    draw.ellipse([cx-head_r, cy_head-head_r, cx+head_r, cy_head+head_r], fill=skin)
    
    # Hair
    if hair_style == "short":
        draw.ellipse([cx-head_r-2, cy_head-head_r-5, cx+head_r+2, cy_head-5], fill=hair_color)
    elif hair_style == "long":
        draw.ellipse([cx-head_r-2, cy_head-head_r-5, cx+head_r+2, cy_head+5], fill=hair_color)
        # hair sides falling down
        draw.rectangle([cx-head_r-2, cy_head, cx-head_r+10, cy_head+50], fill=hair_color)
        draw.rectangle([cx+head_r-10, cy_head, cx+head_r+2, cy_head+50], fill=hair_color)
    elif hair_style == "bun":
        draw.ellipse([cx-head_r-2, cy_head-head_r-5, cx+head_r+2, cy_head-5], fill=hair_color)
        draw.ellipse([cx-12, cy_head-head_r-15, cx+12, cy_head-head_r+5], fill=hair_color)
    
    # Eyes
    ey = cy_head - 5
    for ex in [cx-12, cx+12]:
        draw.ellipse([ex-5, ey-4, ex+5, ey+4], fill=PAL["white"])
        draw.ellipse([ex-3, ey-3, ex+3, ey+3], fill=PAL["dark"])
    
    # Glasses
    if has_glasses:
        draw.rectangle([cx-20, ey-6, cx+20, ey+6], outline=PAL["dark"], width=2)
        draw.line([(cx-2, ey), (cx+2, ey)], fill=PAL["dark"], width=2)
    
    # Mouth
    draw.arc([cx-8, cy_head+5, cx+8, cy_head+18], 0, 180, fill=PAL["dark"], width=2)
    
    # Neck
    neck_top = cy_head + head_r - 5
    draw.rectangle([cx-8, neck_top, cx+8, neck_top+12], fill=skin)
    
    # Torso
    torso_top = neck_top + 10
    torso_bot = torso_top + 80
    # shirt body
    pts_torso = [
        (cx-35, torso_top+10), (cx-8, torso_top),
        (cx+8, torso_top), (cx+35, torso_top+10),
        (cx+30, torso_bot), (cx-30, torso_bot)
    ]
    draw.polygon(pts_torso, fill=shirt_color)
    
    # Arms
    for side in [-1, 1]:
        ax = cx + side * 35
        draw.rectangle([ax-8, torso_top+10, ax+8, torso_top+65], fill=shirt_color)
        # hands
        draw.ellipse([ax-7, torso_top+60, ax+7, torso_top+75], fill=skin)
    
    # Accessory
    if accessory == "apron":
        draw.rectangle([cx-25, torso_top+20, cx+25, torso_bot-5], fill=PAL["white"])
        draw.rectangle([cx-25, torso_top+20, cx+25, torso_top+25], fill=PAL["cream"])
    elif accessory == "laptop_bag":
        draw.line([(cx-30, torso_top+5), (cx+20, torso_bot-10)], fill=PAL["dark"], width=4)
        draw.rectangle([cx+10, torso_bot-20, cx+35, torso_bot+5], fill=PAL["dark"])
    elif accessory == "notebook":
        draw.rectangle([cx+28, torso_top+30, cx+45, torso_top+55], fill=PAL["cream"])
    elif accessory == "saree_drape":
        # pallu draping over shoulder
        draw.polygon([(cx-35, torso_top+10), (cx-20, torso_top),
                       (cx+10, torso_bot), (cx-10, torso_bot)],
                      fill=(*shirt_color[:2], max(0, shirt_color[2]-30)))
    
    # Legs
    leg_top = torso_bot - 5
    leg_bot = leg_top + 70
    for side in [-1, 1]:
        lx = cx + side * 12
        draw.rectangle([lx-10, leg_top, lx+10, leg_bot], fill=pant_color)
    
    # Shoes
    for side in [-1, 1]:
        sx = cx + side * 12
        draw.ellipse([sx-12, leg_bot-5, sx+12, leg_bot+8], fill=PAL["dark"])
    
    return img

def gen_player():
    img = Image.new("RGBA", (CHAR_SIZE, CHAR_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    return _draw_character(img, draw, PAL["skin"], PAL["hair_black"], 
                          PAL["shirt_blue"], PAL["jeans"])

def gen_npc_alex():
    img = Image.new("RGBA", (CHAR_SIZE, CHAR_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    return _draw_character(img, draw, PAL["skin"], PAL["hair_black"],
                          (70, 100, 160), PAL["jeans"],  # hoodie blue
                          has_glasses=True, accessory="laptop_bag")

def gen_npc_jordan():
    img = Image.new("RGBA", (CHAR_SIZE, CHAR_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    return _draw_character(img, draw, PAL["skin"], PAL["hair_black"],
                          PAL["shirt_green"], PAL["jeans"],
                          has_glasses=True)

def gen_npc_maya():
    img = Image.new("RGBA", (CHAR_SIZE, CHAR_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    return _draw_character(img, draw, PAL["skin_dark"], PAL["hair_black"],
                          PAL["shirt_red"], PAL["shirt_red"],
                          hair_style="long", accessory="apron")

def gen_npc_sam():
    img = Image.new("RGBA", (CHAR_SIZE, CHAR_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    return _draw_character(img, draw, PAL["skin"], PAL["hair_black"],
                          PAL["dark"], PAL["jeans"],  # black vest
                          hair_style="short")

def gen_npc_priya():
    img = Image.new("RGBA", (CHAR_SIZE, CHAR_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    return _draw_character(img, draw, PAL["skin_dark"], PAL["hair_black"],
                          PAL["shirt_teal"], PAL["shirt_teal"],
                          hair_style="bun", accessory="saree_drape")


# ═══════════════════════════════════════════════════════════════
# MANIFEST & MAIN
# ═══════════════════════════════════════════════════════════════

MANIFEST = {
    # Ground tiles
    "tiles/ground.png": gen_ground,
    "tiles/ground_grass.png": gen_grass,
    "tiles/ground_dirt.png": gen_dirt,
    "tiles/ground_sand.png": gen_sand,
    "tiles/park_ground.png": gen_park_ground,
    # Building roofs
    "tiles/wall.png": gen_wall,
    "tiles/wall_brick.png": gen_wall_brick,
    "tiles/wall_wood.png": gen_wall_wood,
    "tiles/roof.png": gen_roof,
    "tiles/wall_school.png": gen_wall_school,
    "tiles/wall_office.png": gen_wall_office,
    "tiles/wall_bungalow.png": gen_wall_bungalow,
    # Props
    "tiles/tree.png": gen_tree,
    "tiles/tree_pine.png": gen_tree_pine,
    "tiles/bush.png": gen_bush,
    "tiles/flowers.png": gen_flowers,
    "tiles/bench.png": gen_bench,
    "tiles/lamp_post.png": gen_lamp_post,
    "tiles/fence.png": gen_fence,
    "tiles/fountain.png": gen_fountain,
    "tiles/mailbox.png": gen_mailbox,
    "tiles/trash_can.png": gen_trash_can,
    "tiles/sign_shop.png": gen_sign_shop,
    # Characters
    "characters/player.png": gen_player,
    "characters/npc_alex.png": gen_npc_alex,
    "characters/npc_jordan.png": gen_npc_jordan,
    "characters/npc_maya.png": gen_npc_maya,
    "characters/npc_sam.png": gen_npc_sam,
    "characters/npc_priya.png": gen_npc_priya,
}


def main():
    import argparse
    parser = argparse.ArgumentParser(description="Procedural sprite generator — no AI")
    parser.add_argument("--output", "-o", default=None, help="Output root (default: game/assets/ in repo)")
    parser.add_argument("--only", nargs="*", help="Generate only these (e.g. tiles/tree.png characters/player.png)")
    args = parser.parse_args()

    if args.output:
        out_root = Path(args.output)
    else:
        out_root = Path(__file__).parent.parent / "game" / "assets"

    print("=" * 60)
    print("Procedural Sprite Generator — Startup Simulator")
    print(f"Output: {out_root}")
    print("=" * 60)

    targets = MANIFEST
    if args.only:
        targets = {k: v for k, v in MANIFEST.items() if k in args.only}

    ok, fail = 0, 0
    for rel_path, gen_fn in targets.items():
        out_path = out_root / rel_path
        out_path.parent.mkdir(parents=True, exist_ok=True)
        try:
            img = gen_fn()
            img.save(str(out_path), "PNG")
            print(f"  ✓ {rel_path} ({img.size[0]}×{img.size[1]})")
            ok += 1
        except Exception as e:
            print(f"  ✗ {rel_path}: {e}")
            fail += 1

    print(f"\nDone: {ok} generated, {fail} failed")
    if fail:
        sys.exit(1)


if __name__ == "__main__":
    main()
