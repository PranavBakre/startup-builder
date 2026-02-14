#!/usr/bin/env python3
"""Generate all new art assets for the Startup Simulator using OpenAI gpt-image-1."""

import argparse
import base64
import json
import os
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

OPENAI_API_KEY = os.environ.get("OPENAI_API_KEY", "")
GEMINI_API_KEY = os.environ.get("GEMINI_API_KEY", "")

COMMON_STYLE = (
    "flat lighting, no shadows, no cast shadows, evenly lit from above, "
    "2D game asset, warm illustrated style, Bangalore Indian neighborhood"
)

def generate_openai(prompt: str, output_path: str, size="1024x1024", background="auto", quality="high"):
    """Generate image via OpenAI gpt-image-1."""
    Path(output_path).parent.mkdir(parents=True, exist_ok=True)
    
    body = {
        "model": "gpt-image-1",
        "prompt": prompt,
        "n": 1,
        "size": size,
        "quality": quality,
        "background": background,
        "output_format": "png",
    }
    
    data = json.dumps(body).encode()
    req = urllib.request.Request(
        "https://api.openai.com/v1/images/generations",
        data=data,
        headers={
            "Authorization": f"Bearer {OPENAI_API_KEY}",
            "Content-Type": "application/json",
        },
    )
    
    for attempt in range(3):
        try:
            with urllib.request.urlopen(req, timeout=120) as resp:
                result = json.loads(resp.read())
            b64 = result["data"][0]["b64_json"]
            img_bytes = base64.b64decode(b64)
            with open(output_path, "wb") as f:
                f.write(img_bytes)
            print(f"  ✅ Saved: {output_path} ({len(img_bytes)} bytes)")
            return True
        except urllib.error.HTTPError as e:
            body = e.read().decode() if hasattr(e, 'read') else str(e)
            print(f"  ⚠️ Attempt {attempt+1} failed: {e.code} {body[:200]}")
            if e.code == 429:
                time.sleep(15)
            else:
                time.sleep(3)
        except Exception as e:
            print(f"  ⚠️ Attempt {attempt+1} failed: {e}")
            time.sleep(3)
    
    print(f"  ❌ Failed after 3 attempts: {output_path}")
    return False


def generate_gemini(prompt: str, output_path: str):
    """Generate image via Gemini."""
    Path(output_path).parent.mkdir(parents=True, exist_ok=True)
    
    url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent?key={GEMINI_API_KEY}"
    body = {
        "contents": [{"parts": [{"text": prompt}]}],
        "generationConfig": {"responseModalities": ["TEXT", "IMAGE"]}
    }
    
    data = json.dumps(body).encode()
    req = urllib.request.Request(url, data=data, headers={"Content-Type": "application/json"})
    
    for attempt in range(3):
        try:
            with urllib.request.urlopen(req, timeout=120) as resp:
                result = json.loads(resp.read())
            
            for part in result.get("candidates", [{}])[0].get("content", {}).get("parts", []):
                if "inlineData" in part:
                    img_bytes = base64.b64decode(part["inlineData"]["data"])
                    with open(output_path, "wb") as f:
                        f.write(img_bytes)
                    print(f"  ✅ Saved: {output_path} ({len(img_bytes)} bytes)")
                    return True
            print(f"  ⚠️ No image in response")
            time.sleep(3)
        except Exception as e:
            print(f"  ⚠️ Attempt {attempt+1} failed: {e}")
            time.sleep(5)
    
    print(f"  ❌ Failed after 3 attempts: {output_path}")
    return False


# ============================================================================
# ASSET DEFINITIONS
# ============================================================================

GROUND_TILES = {
    "ground_grass.png": "lush green grass texture, color #5A8C3C, hand-painted watercolor look, seamless tileable pattern, warm muted tones, top-down view",
    "ground.png": "warm grey asphalt road texture, color #8C8478, hand-painted watercolor look, seamless tileable pattern, warm muted tones, top-down view",
    "ground_dirt.png": "laterite red-brown dirt path texture, color #C4A882, hand-painted watercolor look, seamless tileable pattern, warm muted tones, top-down view",
    "ground_sand.png": "sandy ground texture, color #D4B896, hand-painted watercolor look, seamless tileable pattern, warm muted tones, top-down view",
    "park_ground.png": "manicured park lawn texture, lush green well-maintained grass, hand-painted watercolor look, seamless tileable pattern, warm muted tones, top-down view",
}

PROPS = {
    "tree.png": "tropical rain tree seen from directly above, top-down view, lush green canopy, round shape, on transparent background, illustrated style, warm palette, no shadow",
    "tree_pine.png": "ashoka tree seen from directly above, top-down view, narrow columnar green canopy, on transparent background, illustrated style, warm palette, no shadow",
    "bush.png": "bougainvillea bush seen from directly above, top-down view, bright pink flowers with green leaves, on transparent background, illustrated style, warm palette, no shadow",
    "flowers.png": "cluster of marigolds and jasmine flowers seen from directly above, top-down view, orange and white flowers, on transparent background, illustrated style, warm palette, no shadow",
    "bench.png": "green park bench seen from directly above, top-down view, wooden slats with green metal frame, on transparent background, illustrated style, warm palette, no shadow",
    "lamp_post.png": "ornate street lamp seen from directly above, top-down view, black metal pole with warm glow bulb, on transparent background, illustrated style, warm palette, no shadow",
    "fence.png": "compound wall with metal railing seen from directly above, top-down view, whitewashed wall with iron railings, on transparent background, illustrated style, warm palette, no shadow",
    "fountain.png": "stone park fountain seen from directly above, top-down view, circular stone basin with water, on transparent background, illustrated style, warm palette, no shadow",
    "mailbox.png": "red Indian post box seen from directly above, top-down view, cylindrical red pillar box, on transparent background, illustrated style, warm palette, no shadow",
    "trash_can.png": "green dustbin seen from directly above, top-down view, cylindrical green bin with lid, on transparent background, illustrated style, warm palette, no shadow",
    "sign_shop.png": "colorful shop signboard seen from directly above, top-down view, rectangular sign with bright teal and yellow colors, on transparent background, illustrated style, warm palette, no shadow",
}

CHARACTERS = {
    "player.png": "young Indian male entrepreneur, casual clothes, confident expression, stylized illustrated game character, 3/4 front-facing view, warm painterly style, soft features, proportional body, Ghibli-adjacent style, NOT photorealistic, transparent background",
    "npc_alex.png": "Indian male freelancer wearing blue hoodie and glasses, stylized illustrated game character, 3/4 front-facing view, warm painterly style, soft features, proportional body, Ghibli-adjacent style, NOT photorealistic, transparent background",
    "npc_jordan.png": "Indian male student wearing green kurta, curious expression, stylized illustrated game character, 3/4 front-facing view, warm painterly style, soft features, proportional body, Ghibli-adjacent style, NOT photorealistic, transparent background",
    "npc_maya.png": "Indian female baker wearing red salwar kameez with flour-dusted apron, warm smile, stylized illustrated game character, 3/4 front-facing view, warm painterly style, soft features, proportional body, Ghibli-adjacent style, NOT photorealistic, transparent background",
    "npc_sam.png": "Indian male barber wearing black vest, stylish hair, confident look, stylized illustrated game character, 3/4 front-facing view, warm painterly style, soft features, proportional body, Ghibli-adjacent style, NOT photorealistic, transparent background",
    "npc_priya.png": "Indian female teacher wearing teal saree, warm expression, stylized illustrated game character, 3/4 front-facing view, warm painterly style, soft features, proportional body, Ghibli-adjacent style, NOT photorealistic, transparent background",
}

BUILDING_FACADES = {
    "wall_brick/wall_brick_facade.png": "commercial Indiranagar shop front building facade, red and brown brick walls, wooden shutters, shop signage, illustrated architectural facade, front elevation view, warm earth tones, detailed but illustrated style",
    "wall/wall_facade.png": "gray concrete building facade, simple commercial building, plain concrete walls, small windows, front elevation view, illustrated architectural facade, warm earth tones",
    "wall_wood/wall_wood_facade.png": "ochre painted traditional shophouse facade, warm yellow-brown painted walls, wooden doors and windows, front elevation view, illustrated architectural facade, Indian neighborhood style",
    "wall_office/wall_office_facade.png": "modern glass and concrete office building facade, startup office, blue-grey tinted windows, clean lines, front elevation view, illustrated architectural facade, warm earth tones",
    "wall_bungalow/wall_bungalow_facade.png": "Bangalore bungalow facade, terracotta roof tiles visible, whitewashed walls with terracotta accents, verandah, front elevation view, illustrated architectural facade, warm earth tones",
    "wall_school/wall_school_facade.png": "institutional school building facade, cream-yellow painted walls, large windows, front gate, front elevation view, illustrated architectural facade, warm earth tones",
    "roof/roof_facade.png": "Mangalore clay tile roof pattern, red-brown terracotta roof tiles arranged in rows, top-down view of roof surface, illustrated style, warm earth tones, seamless tileable",
}


def run_iteration(iteration: int, base_dir: str):
    base = Path(base_dir)
    tiles_dir = base / "game" / "assets" / "tiles"
    chars_dir = base / "game" / "assets" / "characters"
    bldg_dir = base / "game" / "assets" / "buildings"
    
    if iteration == 0:
        print("\n🎨 Iteration 0: Proof of concept — ground_grass.png")
        prompt = f"{GROUND_TILES['ground_grass.png']}, {COMMON_STYLE}"
        generate_openai(prompt, str(tiles_dir / "ground_grass.png"), background="opaque")
    
    elif iteration == 1:
        print("\n🎨 Iteration 1: All 5 ground tiles")
        for filename, desc in GROUND_TILES.items():
            print(f"\n  Generating {filename}...")
            prompt = f"{desc}, {COMMON_STYLE}"
            generate_openai(prompt, str(tiles_dir / filename), background="opaque")
            time.sleep(2)
    
    elif iteration == 2:
        print("\n🎨 Iteration 2: WALL_BRICK facade")
        desc = BUILDING_FACADES["wall_brick/wall_brick_facade.png"]
        prompt = f"{desc}, {COMMON_STYLE}, highly detailed, at least 960x960 pixels"
        generate_openai(prompt, str(bldg_dir / "wall_brick" / "wall_brick_facade.png"), background="opaque")
    
    elif iteration == 3:
        print("\n🎨 Iteration 3: All 11 prop sprites")
        for filename, desc in PROPS.items():
            print(f"\n  Generating {filename}...")
            prompt = f"{desc}, {COMMON_STYLE}"
            generate_openai(prompt, str(tiles_dir / filename), background="transparent")
            time.sleep(2)
    
    elif iteration == 4:
        print("\n🎨 Iteration 4: All 6 character sprites")
        for filename, desc in CHARACTERS.items():
            print(f"\n  Generating {filename}...")
            prompt = f"{desc}, {COMMON_STYLE}"
            generate_openai(prompt, str(chars_dir / filename), background="transparent")
            time.sleep(2)
    
    elif iteration == 5:
        print("\n🎨 Iteration 5: Remaining building facades")
        for rel_path, desc in BUILDING_FACADES.items():
            if rel_path == "wall_brick/wall_brick_facade.png":
                continue  # Already done in iteration 2
            print(f"\n  Generating {rel_path}...")
            prompt = f"{desc}, {COMMON_STYLE}, highly detailed"
            generate_openai(prompt, str(bldg_dir / rel_path), background="opaque")
            time.sleep(2)


def main():
    parser = argparse.ArgumentParser(description="Generate art assets for Startup Simulator")
    parser.add_argument("--iteration", "-i", type=int, required=True, help="Iteration number (0-5)")
    parser.add_argument("--base-dir", default=".", help="Base repo directory")
    args = parser.parse_args()
    
    if not OPENAI_API_KEY:
        print("ERROR: OPENAI_API_KEY not set")
        sys.exit(1)
    
    run_iteration(args.iteration, args.base_dir)
    print("\n✅ Done!")


if __name__ == "__main__":
    main()
