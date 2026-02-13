<!-- @version 0.1 -->
<!-- @systems movement rendering npc dialogue camera sprite-generation -->
<!-- @tags tile-map player-movement npc-interaction dialogue collision camera zoom indiranagar -->
# Walk & Talk

The player moves around a tile-based map inspired by Indiranagar, Bangalore, encounters NPCs, and discovers startup problems through conversation.

## Overview

- Grid-based player movement on a 60x50 tile map with Indiranagar street layout
- 5 stationary NPCs placed at road intersections and landmarks
- Interact with NPCs by walking adjacent and pressing C to open dialogue
- Each NPC delivers a unique dialogue sequence that surfaces a real-world startup problem
- Photorealistic aerial drone photography style (top-down tiles/buildings/props, 3/4 view characters)
- Camera zoom (trackpad pinch, mouse wheel, Cmd+/-) with movement speed scaling

## Design

The player spawns at the 100 Feet Road × CMH Road intersection — the heart of Indiranagar. They move tile-by-tile using arrow keys. The map recreates Indiranagar's distinctive grid: tree-lined avenues, numbered cross streets and mains, commercial strips along 100 Feet Road and 12th Main, residential blocks with compound walls, and parks with fountains and benches.

When the player is adjacent to an NPC (one tile away), a bouncing prompt appears ("Press C to chat"). Pressing C opens a dialogue overlay with typewriter effect. Each NPC reveals a problem they're experiencing. After reading all dialogue, the overlay closes and the player continues exploring.

### Map Layout

60x50 tiles at 320px per tile. Indiranagar-inspired grid:

**Major roads (2 tiles wide):**
- 100 Feet Road — E-W artery at y=23-24
- CMH Road — N-S artery at x=4-5

**Secondary roads (1 tile wide):**
- 12th Main (cafe/commercial strip) at x=42
- 80 Feet Road at y=40
- 6 cross streets at y=7, 14, 19, 30, 36, 46
- 6 main roads at x=12, 20, 28, 35, 50, 56

**Zones:**
- Commercial (wall_brick) — blocks along 100 Feet Road and near 12th Main
- Residential (wall_wood) — all other blocks

**Parks:**
1. Indiranagar Park (x=6-11, y=31-35) — fountain, benches, trees, flowers
2. Defence Colony Playground (x=51-55, y=41-45)
3. BDA Complex / Metro green (x=6-11, y=8-13)

**Tree-lined streets** — Indiranagar's signature. Trees on both sides of every road:
- Major roads: alternating trees and lamp posts every 2 tiles
- Minor roads: trees every 3 tiles on both sides

**Tile types (19):**
| Type | Visual | Walkable |
|---|---|---|
| GROUND | Dark gray asphalt | Yes |
| GROUND_GRASS | Lush tropical green | Yes |
| GROUND_DIRT | Reddish laterite soil | Yes |
| GROUND_SAND | Sandy path | Yes |
| WALL | Gray concrete rooftop | No |
| WALL_BRICK | Terracotta rooftop | No |
| WALL_WOOD | Ochre painted rooftop | No |
| ROOF | Dark concrete rooftop | No |
| TREE | Tropical rain tree | No |
| TREE_PINE | Ashoka tree | No |
| BUSH | Bougainvillea | No |
| FLOWERS | Marigolds & jasmine | No |
| BENCH | Green cast iron bench | No |
| LAMP_POST | Modern street lamp | No |
| FENCE | Compound wall with railing | No |
| FOUNTAIN | Stone park fountain | No |
| MAILBOX | Red Indian post box | No |
| TRASH_CAN | Green municipal dustbin | No |
| SIGN_SHOP | Colorful shop signboard | No |

### NPCs

5 NPCs placed on roads/intersections for easy access:

| NPC | Position | Location | Problem |
|---|---|---|---|
| Alex | (25, 23) | 100 Feet Road | Expense tracking too complex for freelancers |
| Jordan | (12, 33) | Main road near park | No good way to share research notes |
| Maya | (42, 16) | 12th Main | Small bakery needs simple online ordering |
| Sam | (50, 36) | Road intersection east | Barber needs affordable appointment booking |
| Priya | (28, 46) | Southern cross road | Teacher needs parent communication tool |

NPCs use `_find_nearest_walkable()` fallback to ensure they spawn on walkable tiles.

### Camera

- Default zoom: 0.5
- Zoom range: 0.05 to 2.0
- Controls: trackpad pinch, mouse scroll wheel, Cmd+/-, Cmd+0 (reset)
- Smooth zoom interpolation (lerp, speed 8.0)
- Camera follows player with position smoothing (speed 10.0)

### Movement

- Grid-based, one tile per step at default zoom
- Movement speed scales with zoom level: `max(1, round(0.5 / current_zoom))`
- At default zoom (0.5) = 1 tile, zoomed out = up to ~10 tiles per step
- Tween animation: 0.15s per tile, 0.2s diagonal
- Continuous movement when holding keys

## Implementation Plan

### Iteration 0 — Grid Prototype
**Status:** ✅ Complete (2026-02-12, commit c56ea86)

Colored rectangle grid in Godot proving movement, collision, adjacency, and dialogue.

### Iteration 1 — Visual Foundation
**Status:** ✅ Complete (2026-02-12)

Replaced colored rectangles with Sprite2D nodes, proper scene structure (world.tscn, player.tscn, npc.tscn), and placeholder sprites.

### Iteration 2 — Movement & Camera Polish
**Status:** ✅ Complete (2026-02-12)

Smooth tween movement, Camera2D follow with smoothing, y_sort for depth.

### Iteration 3 — Tile Sprites & Content
**Status:** ✅ Complete (2026-02-12)

Programmatic tile sprite rendering, 3 NPCs, typewriter dialogue effect, interaction prompt animation.

### Iteration 4 — Indiranagar Rework
**Status:** ✅ Complete (2026-02-13)

Major overhaul to make the game look and feel like Indiranagar, Bangalore:

1. **Map redesign** — 200x150 generic grid → 60x50 Indiranagar street layout
   - Authentic road grid: 100 Feet Road, CMH Road, 12th Main, 80 Feet Road, numbered crosses/mains
   - Zone-based building placement (commercial brick, residential wood)
   - 3 hand-placed parks with fountains, benches, trees
   - Tree-lined streets on both sides of every road
   - Border walls

2. **Tile size 32→320** — 10x larger sprites for HD-2D quality

3. **5 NPCs** — Added Sam (barber) and Priya (teacher) to Alex, Jordan, Maya

4. **Camera zoom** — Trackpad pinch, mouse wheel, Cmd+/- with smooth interpolation

5. **Movement speed scaling** — Faster movement when zoomed out

6. **Sprite generation overhaul** (`startup-game-tools/generate_sprites.py`)
   - Multi-provider: Google (Imagen 4 + Gemini Flash) or OpenAI (GPT Image) via `--provider` flag
   - Art style: photorealistic aerial drone photography matching `wall_bungalow.png`
   - Indiranagar visual theme: laterite soil, rain trees, ashoka trees, bougainvillea, marigolds, compound walls, Indian post boxes, green dustbins
   - Indian characters: brown skin, kurta, salwar kameez, saree (realistic illustrated, not pixel art)
   - Magenta background removal for transparency

7. **NPC spawn safety** — `_find_nearest_walkable()` ensures NPCs/player never spawn inside buildings

## Sprite Generation

Located at `../startup-game-tools/generate_sprites.py`.

```bash
# Google provider (default): Imagen 4 for tiles/props, Gemini Flash for characters
uv run python generate_sprites.py

# OpenAI provider: GPT Image for all assets
uv run python generate_sprites.py --provider openai
```

**Providers:**
- **Google (default):** Imagen 4 (`imagen-4.0-fast-generate-001`) for tiles/props + Gemini Flash (`gemini-2.5-flash-image`) for characters
- **OpenAI:** GPT Image (`gpt-image-1.5`) for all assets

**Art style: Photorealistic aerial drone photography** (reference: `wall_bungalow.png`)
- Warm natural sunlight, soft realistic shadows
- Indian / Bangalore / Indiranagar neighborhood aesthetic
- Lush tropical vegetation (coconut palms, bougainvillea, rain trees)

**Style conventions by category:**
- **Ground tiles:** `photorealistic aerial drone photograph, top-down bird's eye view, seamless tileable texture`
- **Building tiles:** `photorealistic aerial drone photograph, top-down bird's eye view, lush green grass and tropical plants surrounding the structure` — complete buildings with landscaping (Google Earth style)
- **Props:** `photorealistic aerial drone photograph, top-down bird's eye view, isolated on solid magenta background` — individual objects seen from directly above
- **Characters:** `photorealistic digital illustration, 3/4 front-facing view, warm natural lighting, isolated on solid magenta background` — realistic illustrated figures (3/4 view for gameplay readability)
- All prompts include: `no text, no numbers, no labels, no watermarks, no UI elements`

**Transparency:** Props and characters use magenta (#FF00FF) background, removed in post-processing via top-left pixel color matching (10 RGB tolerance).

## Code Index

| File | Purpose |
|---|---|
| `scripts/world.gd` | Map generation, tile rendering, player/NPC spawning, dialogue, camera zoom, movement |
| `scripts/player.gd` | Grid-based movement with tween animation |
| `scripts/npc.gd` | NPC setup, sprite loading, dynamic scaling |
| `scenes/world.tscn` | Main game scene (Camera2D, TileMapLayer, CanvasLayer with dialogue UI) |
| `scenes/player.tscn` | Player scene (Sprite2D, scale 0.3125) |
| `scenes/npc.tscn` | NPC scene template |
| `assets/tiles/*.png` | 19 tile/prop sprites (1024x1024, scaled to 320x320 in game) |
| `assets/characters/*.png` | 6 character sprites (player + 5 NPCs) |

## Deferred / Cut

| Item | Reason | Where it lives |
|---|---|---|
| Problem journal | v0.2 core mechanic | v0.2 roadmap |
| Company founding | v0.2 | v0.2 roadmap |
| NPC walking/pathfinding | Not needed — stationary NPCs | Maybe v2+ |
| Multiple map zones | One zone is enough for v0.1 | Later versions |
| Building interiors | v0.5 mechanic | v0.5 roadmap |
| Day/night cycle | v0.3 mechanic | v0.3 roadmap |
| Save/load | v0.3 mechanic | v0.3 roadmap |
| Branching dialogue | Not needed — linear only | Maybe v0.2+ |
| 4-directional player sprites | Only left/right flip currently | Polish pass |
| Sound effects | Not core | Later |
| 3D model assets | AI-generated images have baked shadows (inconsistent direction/intensity) and inter-tile variance (roads/grass don't seamlessly match). Replace with 3D models for consistent renderer-driven lighting and deterministic tileable textures. | Pre-v2 art pass |

## Acceptance Criteria (Full v0.1)

- [x] Tile map renders with ground, walls, props, and tree-lined streets
- [x] Player moves tile-by-tile with arrow keys
- [x] Collision prevents walking through walls, props, and NPCs
- [x] Smooth visual movement between tiles (tween, 0.15s per tile)
- [x] Camera follows the player with zoom controls
- [x] Sprite layering gives depth feel (y_sort_enabled, z-index)
- [x] 5 NPCs visible on the map at road positions
- [x] Walking adjacent to an NPC shows an animated interaction prompt
- [x] Pressing C while adjacent opens a dialogue overlay
- [x] Dialogue shows NPC name and text with typewriter effect
- [x] Each NPC's dialogue surfaces a distinct, realistic startup problem
- [x] Dialogue closes after the last line and returns control to the player
- [x] Map resembles Indiranagar, Bangalore (road grid, tree-lined streets, parks)
- [x] Visual theme reflects Indian neighborhood (laterite soil, tropical trees, Indian characters)
- [x] The game runs in Godot

## Changes

- 2026-02-12: Initial documentation (pre-build)
- 2026-02-12: Iteration 0 complete — colored grid prototype
- 2026-02-12: Iteration 1 complete — visual foundation with sprites
- 2026-02-12: Iteration 2 complete — smooth movement, camera follow
- 2026-02-12: Iteration 3 complete — tile sprites, 3 NPCs, typewriter effect
- 2026-02-13: Iteration 4 complete — Indiranagar rework (60x50 map, 5 NPCs, 19 tile types, zoom controls, movement scaling, Bangalore-themed sprites, dual-engine sprite generation)
