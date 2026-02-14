# Art Direction Spec — Startup Simulator

> Oracle / 2026-02-14 · Addresses: baked shadows, building stretching, visual cohesion, character style

---

## 1. Current Problems & Root Causes

### Baked Shadows
AI image generators (Imagen, GPT Image) produce images with lighting baked in — each sprite has its own light source direction, shadow length, and ambient occlusion. When placed on a shared map:
- Shadow directions conflict (one building lit from top-left, another from bottom-right)
- Objects can't be rotated without the shadow facing the wrong way
- Time-of-day lighting becomes impossible — the shadows never change

**Root cause:** We're asking a generative model to produce *lit scenes* instead of *flat assets*.

### Building Stretching
Buildings are generated as single 1024×1024 textures and scaled to fit arbitrary footprints (2×3, 3×4, 4×4, etc.). A square image stretched to a rectangle looks distorted — windows warp, proportions break, bricks stretch.

**Root cause:** One texture per building, regardless of footprint dimensions. No modular composition system.

### No Visual Cohesion
Each asset is generated in its own prompt call. AI models have no memory of previous outputs — colors shift, texture density varies, lighting style differs. Tiles placed side-by-side look like collaged magazine clippings.

**Root cause:** No shared style anchor. Each generation is independent with no color/style constraints enforced at the prompt level.

### Character Style
Current photorealistic NPCs hit the uncanny valley — detailed enough to notice they're wrong, not detailed enough to pass as real. For a cozy Stardew-meets-startup tone, photorealism is the wrong register entirely.

**Root cause:** Style mismatch between game tone (warm, playful) and asset style (attempted photorealism).

---

## 2. Recommended Art Style by Category

The HD-2D approach means: **2D sprites rendered in a 3D-lit environment**. Sprites should be flat art that looks good *under* Godot's 2D lighting system, not art that tries to fake its own lighting.

### Ground Tiles
**Style:** Hand-painted-look flat textures. Muted, warm tones. Think watercolor-ish terrain.
- Seamless tiling. Every ground tile must tile in all 4 directions without visible seams.
- No baked shadows, no baked highlights. Flat diffuse color + subtle texture variation.
- Palette-restricted: all ground tiles share the same warm base palette (see §5).

### Buildings
**Style:** Flat isometric/top-down illustration. Clean lines, warm colors, simplified detail.
- NOT photorealistic. Illustrated/painterly — think Stardew Valley buildings but from a top-down/slight-iso perspective.
- Modular construction (see §4). No single-image scaling.
- Shadowless — Godot provides all shadows via `Light2D` / `CanvasModulate`.

### Props (trees, benches, lamps, etc.)
**Style:** Illustrated, consistent with building style. Flat color with minimal hand-painted texture.
- All props on transparent background with NO shadow and NO ground contact shadow.
- Consistent outline weight (1–2px at 320px tile size) — or no outlines if we go fully painterly.
- Trees should feel tropical: coconut palms, gulmohar, rain trees. Indiranagar-specific.

### Characters (NPCs + Player)
**Style:** Stylized illustrated — see §6 for full recommendation.

---

## 3. Shadow Strategy

**Approach: Shadow-free sprites + Godot 2D lighting.**

### Why
- Eliminates baked-shadow conflicts entirely
- Enables time-of-day cycle (v0.3+ has an in-game clock)
- Assets become rotatable and reusable
- Consistent visual feel across the entire map

### Implementation

1. **All sprites generated shadowless.** Prompt engineering: explicitly request "flat lighting, no shadows, no cast shadows, no ambient occlusion, evenly lit, studio lighting from directly above."

2. **Godot `Light2D` nodes** for dynamic lighting:
   - One directional `Light2D` for sun — rotates with time of day
   - `CanvasModulate` for ambient color shifts (warm morning, neutral midday, orange evening)
   - Point `Light2D` for lamps, shop signs, etc.

3. **`LightOccluder2D`** on buildings and tall props to cast real-time 2D shadows. These are geometric (polygonal), not texture-based — they'll be consistent and dynamic.

4. **Normal maps** (stretch goal): AI-generated normal maps or simple auto-generated ones can give sprites a pseudo-3D response to light. This is the HD-2D secret sauce. Not required for v0.2 but should be planned for.

### Prompt Template for Shadowless Assets
```
[asset description], flat lighting, no shadows, no cast shadows, 
evenly lit from above, transparent background, 2D game asset, 
top-down perspective, illustrated style, warm color palette
```

---

## 4. Building System — Modular Footprints

### The Problem
A 2×3 building ≠ a stretched 4×4 building. Single-texture scaling doesn't work.

### Solution: Modular Tile Composition

Buildings are composed from **tile-sized pieces** (320×320px each) that snap together:

```
┌──────┬──────┬──────┐
│ TL   │ TM   │ TR   │   TL = top-left corner
├──────┼──────┼──────┤   TM = top-middle edge
│ ML   │ MM   │ MR   │   MM = middle fill (repeatable)
├──────┼──────┼──────┤   BL = bottom-left corner
│ BL   │ BM   │ BR   │   etc.
└──────┴──────┴──────┘
```

**9-slice approach per building type:**
- 4 corners (TL, TR, BL, BR)
- 4 edges (TM, BM, ML, MR) — tileable/repeatable
- 1 fill (MM) — tileable in both directions

**For a 2×3 building:**
```
┌──┬──┐
│TL│TR│
├──┼──┤
│ML│MR│
├──┼──┤
│BL│BR│
└──┴──┘
```
(No middle column needed — edges connect directly.)

**For a 4×4 building:**
```
┌──┬──┬──┬──┐
│TL│TM│TM│TR│
├──┼──┼──┼──┤
│ML│MM│MM│MR│
├──┼──┼──┼──┤
│ML│MM│MM│MR│
├──┼──┼──┼──┤
│BL│BM│BM│BR│
└──┴──┴──┘──┘
```

### Building Types Needed (from KNOWLEDGE.md)
Each type gets its own 9-slice set:

| Type | Zone | Visual |
|------|------|--------|
| WALL_BRICK | Commercial | Red/brown brick, shop fronts |
| WALL_OFFICE | Commercial | Modern glass/concrete, startup office |
| WALL_WOOD | Residential | Traditional wood/painted walls |
| WALL_BUNGALOW | Residential | Bangalore bungalow — terracotta + white |
| WALL_SCHOOL | Institutional | Institutional, gated |
| WALL | Generic | Default wall fill |
| ROOF | All | Terracotta/flat roof tops |

That's 7 types × 9 pieces = **63 building tiles**. Eva generates these as a batch with strict style/color consistency.

### Rendering Change in `world.gd`
Replace the current single-sprite-per-building approach in `_render_tiles()` with per-tile rendering using the 9-slice lookup. Each tile within a building footprint gets the correct piece based on its position relative to the building bounds.

---

## 5. Color Palette & Visual Cohesion

### Master Palette

Indiranagar, Bangalore — warm, tropical, slightly dusty. Not neon. Not cold.

**Ground tones:**
- Warm grey asphalt: `#8C8478`
- Dusty path: `#C4A882`
- Grass (lush): `#5A8C3C`
- Grass (dry): `#8FA858`
- Sand/dirt: `#D4B896`

**Building tones:**
- Terracotta: `#C45C3E`
- Whitewash: `#F0E8D8`
- Brick red: `#9C4A3A`
- Concrete grey: `#B8AFA0`
- Wood brown: `#7A5C40`
- Startup-office blue-grey: `#6E7B8B`

**Foliage:**
- Deep canopy: `#2E5E1A`
- Mid green: `#4A7A2E`
- Light leaf: `#7AAA4A`
- Gulmohar orange: `#E86830`
- Bougainvillea pink: `#D44880`

**Accent:**
- Autorickshaw yellow: `#E8C840`
- Shop sign teal: `#2A8B7A`
- Warm lamp glow: `#FFD080`

### Cohesion Rules

1. **Color reference image.** Generate ONE establishing image of an Indiranagar street scene. Use it as a style reference in every subsequent generation prompt (Gemini supports image references).

2. **Palette enforcement.** Every prompt includes: "Use only warm earth tones. Color palette: terracotta, whitewash, brick red, warm grey, dusty brown, lush green. No cold blues, no neon, no saturated primaries."

3. **Batch generation.** Generate related assets together (all ground tiles in one session, all WALL_BRICK pieces in one session) to maximize internal consistency.

4. **Post-processing pass.** After AI generation, run a color-correction script that:
   - Maps output colors to the nearest palette color (quantization)
   - Adjusts white balance to a consistent warm tone
   - Normalizes brightness/contrast across all assets
   - This can be a Python script in `tools/` — automated, not manual.

---

## 6. Character Style Recommendation

### Recommended: **Stylized Illustrated** (not pixel art, not chibi, not photorealistic)

Think: **Ghibli-adjacent character illustration meets indie game.** Proportional bodies (not chibi), soft features, warm colors, slightly simplified anatomy. Expressive but not cartoonish.

**Why this over alternatives:**

| Style | Pros | Cons | Verdict |
|-------|------|------|---------|
| Pixel art | Easy consistency, retro charm | Doesn't match HD-2D vision, feels retro not modern | ❌ |
| Chibi | Cute, forgiving | Too juvenile for startup theme | ❌ |
| Photorealistic | Immersive | Uncanny valley, AI artifacts obvious, wrong tone | ❌ |
| Flat vector | Clean, consistent | Too corporate, no warmth | ❌ |
| **Stylized illustrated** | Warm, expressive, scalable, AI-achievable | Needs prompt discipline | ✅ |

### Character Specs
- **View:** 3/4 top-down (matching tile perspective)
- **Size:** ~256px tall within a 320×320 tile, centered
- **Detail level:** Clear facial features, identifiable clothing, but not photographic. Painterly skin tones, simple hair shapes.
- **Diversity:** Indiranagar is diverse — skin tones, clothing styles (kurtas, t-shirts, business casual), ages
- **Poses:** 4 directional sprites (down, up, left, right) per character. Left/right can mirror if asymmetric detail is minimal.
- **Animation:** Not in scope for v0.2. Static sprites with horizontal flip for movement (current approach).
- **No shadows on character sprites.** Godot handles it.

### Prompt Template for Characters
```
[character description], stylized illustrated game character, 
3/4 top-down view, warm painterly style, soft features, 
proportional body, flat lighting, no shadow, transparent background,
Bangalore Indian neighborhood setting, 2D game sprite
```

---

## 7. Practical AI Generation Approach

### What Eva Can Generate with AI Tools

| Asset | AI Achievable? | Tool | Notes |
|-------|---------------|------|-------|
| Ground tiles (seamless) | ✅ Yes | Gemini / GPT Image | Need post-processing for seamless tiling. Generate large texture, crop tiles. |
| Building 9-slice pieces | ⚠️ Partially | Gemini / GPT Image | Corners/edges need strict alignment. Generate full building face, slice programmatically. |
| Props (trees, benches, etc.) | ✅ Yes | Gemini / GPT Image | Individual items on transparent bg. Batch with style reference. |
| Characters | ✅ Yes | Gemini / GPT Image | Style consistency is the challenge. Use detailed prompt templates. |
| Normal maps | ❌ No | Tool-generated | Auto-generate from diffuse sprites using tools like Laigter or SpriteIlluminator. |
| Seamless tile correction | ❌ Script | Python (PIL) | Mirror/blend edges for seamless tiling. |
| Color quantization | ❌ Script | Python (PIL) | Palette enforcement post-generation. |

### Generation Workflow

1. **Create style reference image.** One hero image of an Indiranagar street in the target style. Use as reference for all subsequent prompts.

2. **Generate by category in batches:**
   - Session 1: All ground tiles (5 types)
   - Session 2: Building type 1 — full face renders → slice into 9 pieces
   - Session 3: Building type 2 — repeat
   - ...
   - Session N: All props
   - Session N+1: All characters

3. **Post-process pipeline** (`tools/process_sprites.py`):
   ```
   AI output → remove background → color correct → 
   palette quantize → seamless tile fix (if tile) → 
   resize to 320px → export PNG
   ```

4. **Manual touch-up budget:** Expect 10-20% of assets need manual fixes (seam issues, weird AI artifacts, color outliers). Flag these for human review.

### What Needs Human/Tool Work (Not AI)

- **9-slice slicing logic** — Script to cut a full building facade into the 9 pieces
- **Seamless tile processing** — Edge-blending script for ground tiles  
- **Normal map generation** — Laigter or similar tool, automated
- **Color palette enforcement** — Python script with PIL
- **LightOccluder2D polygons** — Manual or auto-traced in Godot from sprite silhouettes
- **Sprite atlas packing** — Godot's built-in import system handles this

---

## 8. Migration Plan

Iterative migration — each iteration adds one layer, is testable on its own, and builds on the previous.

### Iteration 0 — Single Tile Proof of Pipeline
**The smallest proof that the new art pipeline works end-to-end.**

- [ ] Generate ONE `GROUND` tile in the new illustrated/shadowless style using updated prompt templates
- [ ] Run it through a minimal `tools/process_sprites.py` (background removal + resize to 320px — skip color quantization for now)
- [ ] Replace the existing `GROUND` sprite in `game/` with the new one
- [ ] Add a basic `CanvasModulate` node to the scene tree (neutral white — just proves the node works)
- [ ] Launch the game in Godot. Verify: tile renders, tiles seamlessly, lighting node active, nothing broken

**Deliverables:** 1 new ground tile PNG, skeleton `process_sprites.py`, `CanvasModulate` in scene tree.
**Verify:** Screenshot the map — new tile visible, no seams, game runs.

### Iteration 1 — Full Ground Layer
**All 5 ground tile types in new style, with color pipeline.**

- [ ] Create the master style reference image (one Indiranagar street scene in target style)
- [ ] Generate all 5 ground types (`GROUND`, `GROUND_GRASS`, `GROUND_DIRT`, `GROUND_SAND`, `PARK_GROUND`) using style reference
- [ ] Add color correction + palette quantization to `process_sprites.py` (§5 palette)
- [ ] Process all 5 tiles through full pipeline (bg removal → color correct → seamless tile fix → resize)
- [ ] Replace all ground sprites in game
- [ ] Add one directional `Light2D` node (sun) — verify ground responds to it

**Deliverables:** 5 ground tile PNGs, complete `process_sprites.py` with color pipeline, `Light2D` sun node.
**Verify:** Full map ground looks cohesive. Changing `Light2D` angle visibly affects ground tiles. No seams.

### Iteration 2 — One Building Type (9-Slice)
**Prove modular building composition works with one building type.**

- [ ] Pick one building type (`WALL_BRICK` — most common in commercial zones)
- [ ] Generate full building facade in new style → slice into 9 pieces programmatically (add slicing to `process_sprites.py`)
- [ ] Refactor `_render_tiles()` in `world.gd` to support 9-slice rendering for `WALL_BRICK` (keep old single-sprite path for other types)
- [ ] Add `LightOccluder2D` to one `WALL_BRICK` building (manual polygon, proves shadow casting)
- [ ] Test with at least 2 different footprint sizes (e.g., 2×3 and 4×4)

**Deliverables:** 9 `WALL_BRICK` tile PNGs, 9-slice rendering code in `world.gd`, one `LightOccluder2D` shadow.
**Verify:** Brick buildings render at multiple footprint sizes without stretching. Sun casts shadow behind the occluded building.

### Iteration 3 — All Building Types
**Extend 9-slice system to remaining 6 building types.**

- [ ] Generate 9-slice sets for: `WALL_OFFICE`, `WALL_WOOD`, `WALL_BUNGALOW`, `WALL_SCHOOL`, `WALL`, `ROOF` (6 × 9 = 54 tiles)
- [ ] Process through pipeline with palette enforcement
- [ ] Remove old single-sprite building path from `_render_tiles()` — all buildings now use 9-slice
- [ ] Auto-generate `LightOccluder2D` polygons from building bounds (script or helper function, not manual)
- [ ] Test across all zone types (commercial, residential, institutional)

**Deliverables:** 54 building tile PNGs, auto-occluder generation, old building rendering code removed.
**Verify:** Walk the full map. Every building renders correctly. No stretching. Shadows cast from all buildings.

### Iteration 4 — Props
**Replace all 11 prop types in new illustrated style.**

- [ ] Generate all 11 props (`TREE`, `TREE_PINE`, `BUSH`, `FLOWERS`, `BENCH`, `LAMP_POST`, `FENCE`, `FOUNTAIN`, `MAILBOX`, `TRASH_CAN`, `SIGN_SHOP`) — shadowless, consistent palette, transparent background
- [ ] Process through pipeline
- [ ] Add `LightOccluder2D` to tall props (trees, lamp posts, fountain)
- [ ] Add point `Light2D` to `LAMP_POST` and `SIGN_SHOP` (warm glow, §5 palette `#FFD080`)

**Deliverables:** 11 prop PNGs, occluders on tall props, point lights on lamps/signs.
**Verify:** Props match building/ground style. Lamp posts glow. Trees cast shadows.

### Iteration 5 — Characters
**Replace player + 5 NPCs with stylized illustrated sprites.**

- [ ] Generate player sprite: 4 directions (down, up, left, right) in stylized illustrated style (§6)
- [ ] Generate 5 NPC sprites: at minimum down-facing + horizontal flip (match §6 specs — diverse, Indiranagar-appropriate)
- [ ] Process through pipeline (bg removal, color correction, resize)
- [ ] Drop into game, test with existing dialogue system

**Deliverables:** 4 player direction PNGs, 5+ NPC PNGs.
**Verify:** Characters match world style. Dialogue still works. No uncanny valley.

### Iteration 6 — Lighting Polish & HD-2D Depth
**Tune the lighting system and add HD-2D depth effects.**

- [ ] Add `CanvasModulate` time-of-day color presets (warm morning, neutral midday, orange evening) — wire to a debug toggle for now (time-of-day system is v0.3)
- [ ] Tune `Light2D` parameters: sun intensity, shadow softness, lamp glow radius
- [ ] Generate normal maps for buildings and characters using Laigter or SpriteIlluminator
- [ ] Apply normal maps — verify pseudo-3D light response
- [ ] Full map playtest: walk every zone, check visual consistency

**Deliverables:** Time-of-day presets (debug-togglable), tuned light params, normal maps for key assets.
**Verify:** Toggle through morning/midday/evening — map looks distinct in each. Normal maps create visible depth under directional light.

### Timeline Estimate
- Iteration 0: < 1 session (proof of pipeline)
- Iteration 1: 1 session (ground layer)
- Iteration 2: 1 session (one building type + 9-slice refactor)
- Iteration 3: 1–2 sessions (remaining buildings)
- Iteration 4: 1 session (props)
- Iteration 5: 1 session (characters)
- Iteration 6: 1 session (lighting polish)

**Total: ~7–8 working sessions across Eva (assets) and Cortana (code changes).**

---

## Status

- [ ] Iteration 0 — Single tile proof of pipeline
- [ ] Iteration 1 — Full ground layer
- [ ] Iteration 2 — One building type (9-slice)
- [ ] Iteration 3 — All building types
- [ ] Iteration 4 — Props
- [ ] Iteration 5 — Characters
- [ ] Iteration 6 — Lighting polish & HD-2D depth

## Changes

- 2026-02-14: Rewrote migration plan — replaced 6 vague phases with 7 numbered iterations (iteration 0–6), each with specific deliverables and verification steps. Added Status and Changes sections.
- 2026-02-14: Initial spec — sections 1–7 (problems, style recommendations, shadow strategy, building system, color palette, character style, AI generation approach)

---

## Appendix: Prompt Engineering Notes

### Key Phrases That Work for Shadowless Assets
- "flat lighting, no shadows, no cast shadows"
- "evenly lit from directly above"
- "studio lighting, no directional light"
- "2D game asset, flat color"

### Key Phrases for Style Consistency
- "warm illustrated style, painterly"
- "Bangalore neighborhood, Indian tropical"  
- "earth tones, terracotta, whitewash"
- "Stardew Valley aesthetic, cozy, warm"

### Key Phrases to AVOID
- "photorealistic" (triggers baked lighting)
- "3D render" (triggers shadows and perspective)
- "dramatic lighting" (triggers strong directional shadows)
- "HDR" (triggers high-contrast lighting)
