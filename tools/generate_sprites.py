#!/usr/bin/env python3
"""
Sprite Generator for Startup Simulator
Uses Google Imagen 4 + Gemini Flash to generate game sprites.

Art style: Photorealistic aerial drone photography (satellite/bird's eye view).
Reference: wall_bungalow.png — warm natural sunlight, lush green grass, tropical
vegetation, Indian residential neighborhood seen from directly above.

All assets target this consistent look:
- Ground tiles: seamless tileable aerial photo textures
- Building tiles: complete structures with surrounding landscaping (Google Earth style)
- Props: individual objects seen from above, magenta bg for transparency keying
- Characters: realistic illustrated figures, magenta bg for transparency keying
- Provider: Supports Google (Imagen/Gemini) and OpenAI (GPT Image 1)
"""

import os
import sys
from pathlib import Path

try:
    from google import genai
    from google.genai import types
    from dotenv import load_dotenv
    from PIL import Image
    import io
    import argparse
    import requests
    import base64
except ImportError as e:
    print(f"ERROR: Missing required package: {e}")
    print("\nInstall dependencies with:")
    print("  pip install google-genai pillow python-dotenv requests")
    sys.exit(1)

try:
    from openai import OpenAI
except ImportError:
    OpenAI = None

# Load environment variables from .env file
load_dotenv()

TILE_SIZE = 320

# =============================================================================
# STYLE SYSTEM
# =============================================================================
# Target: photorealistic aerial drone photography, matching wall_bungalow.png
# - Top-down bird's eye perspective looking straight down
# - Warm natural sunlight with soft realistic shadows
# - Indian / Bangalore / Indiranagar neighborhood aesthetic
# - Lush tropical vegetation (coconut palms, bougainvillea, rain trees)
#
# Category-specific approaches:
# - Ground tiles: seamless tileable aerial photo textures
# - Buildings: complete structures with surrounding landscaping (Google Earth)
# - Props: individual objects from above, magenta bg for transparency keying
# - Characters: realistic illustrated figures, magenta bg for transparency
#
# Key constraints:
# - Ground: soft smooth textures, NOT high-frequency detail (noisy at zoom-out)
# - Buildings: centered with wide plain grass border, nothing cut off at edges
# - Props/Characters: object centered, clean magenta bg, no scene context
# =============================================================================

# Per-category style prefixes
STYLE_GROUND = (
    "photorealistic aerial drone photograph, top-down bird's eye view looking "
    "straight down, warm natural sunlight, soft smooth texture with gentle "
    "color variation, minimal fine grain detail, low frequency pattern"
)
STYLE_BUILDING = (
    "photorealistic aerial drone photograph, top-down bird's eye view looking "
    "straight down at a single building, warm natural sunlight with soft shadows, "
    "building centered in frame with wide plain green grass border on all four "
    "sides, nothing cut off at the edges of the image, no neighboring buildings "
    "visible, clean edges that blend with grass, Bangalore India"
)
STYLE_PROP = (
    "photorealistic aerial drone photograph, top-down bird's eye view looking "
    "straight down, warm natural sunlight, soft shadow cast on ground"
)
STYLE_CHARACTER = (
    "photorealistic digital illustration, 3/4 front-facing view, warm natural "
    "lighting, detailed realistic rendering, Indian person from Bangalore"
)

# Shared prompt fragments
BG_MAGENTA = "isolated on solid flat uniform bright magenta (#FF00FF) background"
BG_TRANSPARENT = "isolated on a transparent background"
NO_TEXT = "no text, no numbers, no labels, no watermarks, no UI elements"

# Sprite definitions with prompts
SPRITES = {
    "tiles": {
        # --- Ground tiles (seamless tileable aerial textures, soft/smooth to avoid noise at zoom-out) ---
        "ground.png": {
            "prompt": f"{STYLE_GROUND}, dark gray asphalt road surface, smooth uniform texture with a few subtle cracks, seamless tileable, flat even lighting, {NO_TEXT}",
            "aspect_ratio": "1:1"
        },
        "ground_grass.png": {
            "prompt": f"{STYLE_GROUND}, lush green tropical grass lawn seen from above, soft uniform green with gentle color variation, no individual blades visible, seamless tileable, matte finish, {NO_TEXT}",
            "aspect_ratio": "1:1"
        },
        "ground_dirt.png": {
            "prompt": f"{STYLE_GROUND}, reddish brown Indian laterite soil path, smooth compacted earth with subtle tone variation, seamless tileable, warm red-earth tones, {NO_TEXT}",
            "aspect_ratio": "1:1"
        },
        "ground_sand.png": {
            "prompt": f"{STYLE_GROUND}, light beige sandy walkway surface, smooth fine sand with soft tonal shifts, seamless tileable, warm muted tones, {NO_TEXT}",
            "aspect_ratio": "1:1"
        },

        # --- Building tiles (centered structure, wide grass border, clean edges) ---
        "wall.png": {
            "prompt": f"{STYLE_BUILDING}, small Indian apartment building with flat gray concrete roof and water tank, rectangular shape, {NO_TEXT}",
            "aspect_ratio": "1:1"
        },
        "wall_brick.png": {
            "prompt": f"{STYLE_BUILDING}, traditional Indian house with red-brown terracotta flat roof and small inner courtyard, warm earthy tones, {NO_TEXT}",
            "aspect_ratio": "1:1"
        },
        "wall_wood.png": {
            "prompt": f"{STYLE_BUILDING}, ochre-yellow painted Indian shophouse with corrugated metal roof, narrow rectangular shape, warm golden tones, {NO_TEXT}",
            "aspect_ratio": "1:1"
        },
        "roof.png": {
            "prompt": f"{STYLE_BUILDING}, Indian residential house with dark gray Mangalore clay tile pitched roof, hip roof shape visible from above, {NO_TEXT}",
            "aspect_ratio": "1:1"
        },
        "wall_school.png": {
            "prompt": f"{STYLE_BUILDING}, Indian school with cream-yellow walls and flat concrete roof, L-shaped layout with open courtyard, {NO_TEXT}",
            "aspect_ratio": "1:1"
        },
        "wall_office.png": {
            "prompt": f"{STYLE_BUILDING}, modern office building with flat gray roof and rooftop AC units, rectangular shape, glass and concrete, {NO_TEXT}",
            "aspect_ratio": "1:1"
        },
        "wall_bungalow.png": {
            "prompt": f"{STYLE_BUILDING}, cozy Indian bungalow with warm terracotta orange-red clay tile pitched roof, a few coconut palms nearby, {NO_TEXT}",
            "aspect_ratio": "1:1"
        },
        "park_ground.png": {
            "prompt": f"{STYLE_GROUND}, manicured park lawn, bright soft green grass with a faint worn dirt footpath, smooth uniform texture, seamless tileable, {NO_TEXT}",
            "aspect_ratio": "1:1"
        },

        # --- Props (individual objects seen from directly above, magenta bg) ---
        "tree.png": {
            "prompt": f"{STYLE_PROP}, single large tropical rain tree with wide spreading dense green canopy seen from directly above, round organic leaf mass, small dark shadow beneath on ground, centered in frame, {BG_MAGENTA}, {NO_TEXT}",
            "aspect_ratio": "1:1"
        },
        "tree_pine.png": {
            "prompt": f"{STYLE_PROP}, single tall ashoka tree with narrow dark green columnar canopy seen from directly above, elongated oval leaf mass, small dark shadow beneath, centered in frame, {BG_MAGENTA}, {NO_TEXT}",
            "aspect_ratio": "1:1"
        },
        "bush.png": {
            "prompt": f"{STYLE_PROP}, small bougainvillea bush with bright pink flowers and green leaves seen from directly above, low rounded organic shape, centered in frame, {BG_MAGENTA}, {NO_TEXT}",
            "aspect_ratio": "1:1"
        },
        "flowers.png": {
            "prompt": f"{STYLE_PROP}, small circular garden bed with bright orange marigolds and white jasmine flowers seen from directly above, neat round flower patch, centered in frame, {BG_MAGENTA}, {NO_TEXT}",
            "aspect_ratio": "1:1"
        },
        "bench.png": {
            "prompt": f"{STYLE_PROP}, green painted park bench seen from directly above, rectangular shape with visible wooden slat pattern, small shadow on one side, centered in frame, {BG_MAGENTA}, {NO_TEXT}",
            "aspect_ratio": "1:1"
        },
        "lamp_post.png": {
            "prompt": f"{STYLE_PROP}, modern silver street lamp post seen from directly above, circular lamp head at top with thin pole visible below, small round shadow on ground, centered in frame, {BG_MAGENTA}, {NO_TEXT}",
            "aspect_ratio": "1:1"
        },
        "fence.png": {
            "prompt": f"{STYLE_PROP}, section of low concrete compound wall with iron railing on top seen from directly above, straight horizontal line with narrow shadow on one side, centered in frame, {BG_MAGENTA}, {NO_TEXT}",
            "aspect_ratio": "1:1"
        },
        "fountain.png": {
            "prompt": f"{STYLE_PROP}, small round stone park fountain with clear blue water seen from directly above, circular shape with concentric stone rings and central spout, centered in frame, {BG_MAGENTA}, {NO_TEXT}",
            "aspect_ratio": "1:1"
        },
        "mailbox.png": {
            "prompt": f"{STYLE_PROP}, red cylindrical Indian post box seen from directly above, small round shape with domed top, tiny shadow on ground, centered in frame, {BG_MAGENTA}, {NO_TEXT}",
            "aspect_ratio": "1:1"
        },
        "trash_can.png": {
            "prompt": f"{STYLE_PROP}, green municipal dustbin with round lid seen from directly above, small circular shape, tiny shadow on ground, centered in frame, {BG_MAGENTA}, {NO_TEXT}",
            "aspect_ratio": "1:1"
        },
        "sign_shop.png": {
            "prompt": f"{STYLE_PROP}, colorful rectangular shop signboard on a post seen from directly above, bright painted sign with shadow on ground, centered in frame, {BG_MAGENTA}, {NO_TEXT}",
            "aspect_ratio": "1:1"
        },
    },
    "characters": {
        "player.png": {
            "prompt": f"{STYLE_CHARACTER}, young Indian male entrepreneur in his 20s wearing a casual light blue button-up shirt and dark jeans with sneakers, brown skin, friendly confident smile, standing pose facing forward, full body visible head to feet, single person centered in frame, {BG_MAGENTA}, {NO_TEXT}",
            "aspect_ratio": "1:1",
            "gender": "male"
        },
        "npc_alex.png": {
            "prompt": f"{STYLE_CHARACTER}, Indian male freelance developer in his late 20s wearing a blue hoodie and carrying a laptop bag slung over shoulder, brown skin, glasses, casual friendly expression, standing pose facing forward, full body visible head to feet, single person centered in frame, {BG_MAGENTA}, {NO_TEXT}",
            "aspect_ratio": "1:1",
            "gender": "male"
        },
        "npc_jordan.png": {
            "prompt": f"{STYLE_CHARACTER}, Indian male college student in his early 20s wearing wire-frame glasses and a green cotton kurta with jeans, brown skin, curious intelligent expression, standing pose facing forward, full body visible head to feet, single person centered in frame, {BG_MAGENTA}, {NO_TEXT}",
            "aspect_ratio": "1:1",
            "gender": "male"
        },
        "npc_maya.png": {
            "prompt": f"{STYLE_CHARACTER}, Indian female baker in her 30s wearing a flour-dusted white apron over a deep red salwar kameez, brown skin, warm welcoming smile, standing pose facing forward, full body visible head to feet, single person centered in frame, {BG_MAGENTA}, {NO_TEXT}",
            "aspect_ratio": "1:1",
            "gender": "female"
        },
        "npc_sam.png": {
            "prompt": f"{STYLE_CHARACTER}, Indian male barber in his 30s with short stylish hair and trimmed beard wearing a black vest over white t-shirt, brown skin, confident friendly expression, standing pose facing forward, full body visible head to feet, single person centered in frame, {BG_MAGENTA}, {NO_TEXT}",
            "aspect_ratio": "1:1",
            "gender": "male"
        },
        "npc_priya.png": {
            "prompt": f"{STYLE_CHARACTER}, Indian female school teacher in her 40s wearing a colorful cotton saree in teal and gold, carrying a notebook under one arm, brown skin, kind warm expression, standing pose facing forward, full body visible head to feet, single person centered in frame, {BG_MAGENTA}, {NO_TEXT}",
            "aspect_ratio": "1:1",
            "gender": "female"
        },
    }
}


def _process_transparency(image, prompt):
    """Remove magenta background and make it transparent."""
    from PIL import Image as PILImage

    if "background" not in prompt.lower():
        return image

    print(f"  Processing transparency...")
    image = image.convert("RGBA")
    datas = image.getdata()

    # Assume background color is the top-left pixel
    bg_color = datas[0]

    new_data = []
    for item in datas:
        if (abs(item[0] - bg_color[0]) < 10 and
            abs(item[1] - bg_color[1]) < 10 and
            abs(item[2] - bg_color[2]) < 10):
            new_data.append((255, 255, 255, 0))
        else:
            new_data.append(item)

    image.putdata(new_data)
    return image


def _generate_with_imagen(client, prompt: str, aspect_ratio: str):
    """Generate image using Imagen 4 API (tiles and props)."""
    config = types.GenerateImagesConfig(
        number_of_images=1,
        aspect_ratio=aspect_ratio,
    )

    response = client.models.generate_images(
        model='imagen-4.0-ultra-generate-001',
        prompt=prompt,
        config=config,
    )

    if not response.generated_images:
        return None

    return response.generated_images[0].image.image_bytes


def _generate_with_gemini(client, prompt: str):
    """Generate image using Gemini Flash (characters — handles people better)."""
    response = client.models.generate_content(
        model='gemini-2.5-flash-image',
        contents=prompt,
        config=types.GenerateContentConfig(
            response_modalities=["IMAGE"],
        ),
    )

    if not response.candidates or not response.candidates[0].content.parts:
        return None

    for part in response.candidates[0].content.parts:
        if part.inline_data is not None:
            return part.inline_data.data

    return None


def _generate_with_dalle(client, prompt: str):
    """Generate image using OpenAI GPT Image 1.5."""
    # Note: 'background' and 'output_format' are passed via extra_body 
    # as they are new parameters not yet in all SDK versions.
    # 'response_format' is omitted as gpt-image-1.5 defaults to b64_json and rejects the param.
    response = client.images.generate(
        model="gpt-image-1.5",
        prompt=prompt,
        size="1024x1024",
        quality="high",
        n=1,
        extra_body={
            "background": "transparent",
            "output_format": "png",
        }
    )
    
    image_b64 = response.data[0].b64_json
    if image_b64:
        return base64.b64decode(image_b64)
    
    # Fallback to URL if somehow returned
    image_url = getattr(response.data[0], 'url', None)
    if image_url:
        image_response = requests.get(image_url)
        if image_response.status_code == 200:
            return image_response.content
            
    return None


def generate_sprite(client, sprite_name: str, prompt: str, aspect_ratio: str, output_path: Path, is_character: bool = False, provider: str = "google"):
    """Generate a single sprite. Uses selected provider's engines."""
    print(f"Generating {sprite_name}...")
    print(f"  Prompt: {prompt[:80]}...")
    
    if provider == "openai":
        engine_name = "GPT Image"
    else:
        engine_name = 'Gemini Flash' if is_character else 'Imagen 4'
    
    print(f"  Engine: {engine_name}")

    try:
        if provider == "openai":
            image_bytes = _generate_with_dalle(client, prompt)
        else:
            if is_character:
                image_bytes = _generate_with_gemini(client, prompt)
            else:
                image_bytes = _generate_with_imagen(client, prompt, aspect_ratio)

        if image_bytes is None:
            print(f"  ✗ Failed - no image data returned")
            return False

        image = Image.open(io.BytesIO(image_bytes))
        
        # Only process manual transparency for non-OpenAI providers 
        # (OpenAI uses native background="transparent" via gpt-image-1.5)
        if provider != "openai":
            image = _process_transparency(image, prompt)

        # Ensure output directory exists
        output_path.parent.mkdir(parents=True, exist_ok=True)

        # Save image
        image.save(output_path, 'PNG')
        print(f"  ✓ Saved {image.size[0]}x{image.size[1]} to {output_path}")
        return True

    except Exception as e:
        print(f"  ✗ Error: {e}")
        return False


def main():
    parser = argparse.ArgumentParser(description="Generate sprites for Startup Simulator")
    parser.add_argument("--provider", choices=["google", "openai"], default="google", 
                        help="Image generation provider (default: google)")
    args = parser.parse_args()

    if args.provider == "google":
        # Get Google API key from environment
        api_key = os.environ.get('GOOGLE_API_KEY') or os.environ.get('GEMINI_API_KEY')
        if not api_key:
            print("ERROR: No Google API key found")
            print("\nSet your API key:")
            print("  export GOOGLE_API_KEY=your_api_key_here")
            sys.exit(1)
        client = genai.Client(api_key=api_key)
        engine_desc = "Imagen 4 (tiles/props) + Gemini Flash (characters)"
    else:
        # OpenAI Provider
        if OpenAI is None:
            print("ERROR: OpenAI package not installed")
            print("  pip install openai")
            sys.exit(1)
            
        api_key = os.environ.get('OPENAI_API_KEY')
        if not api_key:
            print("ERROR: No OPENAI_API_KEY found in environment")
            print("  export OPENAI_API_KEY=your_api_key_here")
            sys.exit(1)
        client = OpenAI(api_key=api_key)
        engine_desc = "OpenAI GPT Image 1"

    print("=" * 70)
    print("Startup Simulator - Sprite Generator")
    print(f"Using: {engine_desc}")
    print("=" * 70)
    print()

    # Determine output path (game repo's assets folder)
    tools_root = Path(__file__).parent
    game_root = tools_root.parent / "startup-game"

    if not game_root.exists():
        print(f"WARNING: Game directory not found at {game_root}")
        print("Saving to local output/ directory instead")
        game_root = tools_root / "output"

    total = sum(len(sprites) for sprites in SPRITES.values())
    generated = 0
    failed = 0

    # Generate all sprites
    for category, sprites in SPRITES.items():
        print(f"\n--- Generating {category} ---")
        print("-" * 70)

        is_character = (category == "characters")

        for filename, config in sprites.items():
            output_path = game_root / "assets" / category / filename

            # Adjust prompt based on provider
            prompt = config["prompt"]
            if args.provider == "openai":
                # Use native transparency instead of magenta keying
                prompt = prompt.replace(BG_MAGENTA, BG_TRANSPARENT)

            success = generate_sprite(
                client=client,
                sprite_name=filename,
                prompt=prompt,
                aspect_ratio=config["aspect_ratio"],
                output_path=output_path,
                is_character=is_character,
                provider=args.provider
            )

            if success:
                generated += 1
            else:
                failed += 1

            print()

    # Summary
    print("=" * 70)
    print(f"Generation complete!")
    print(f"  ✓ Generated: {generated}/{total}")
    if failed > 0:
        print(f"  ✗ Failed: {failed}/{total}")
    print(f"\nAssets saved to: {game_root / 'assets'}")
    print("=" * 70)

    if failed > 0:
        sys.exit(1)


if __name__ == "__main__":
    main()
