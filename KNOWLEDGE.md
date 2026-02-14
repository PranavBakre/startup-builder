# KNOWLEDGE.md — Technical Reference

How the code works. For project rules, workflow, and version scope, see [CLAUDE.md](CLAUDE.md).

---

## Architecture (v0.1)

### Scene Tree
```
World (Node2D) — world.gd
├── TileMapLayer
├── Camera2D (follows player, zoom controls)
├── Player (Node2D) — player.gd
│   └── Sprite2D
├── NPC × 5 (Area2D) — npc.gd
│   └── Sprite2D
└── CanvasLayer
    ├── DialogueBox (Panel)
    │   └── MarginContainer/VBoxContainer
    │       ├── NPCName (Label)
    │       └── DialogueText (Label)
    └── InteractPrompt (Label)
```

### Key Constants
| Constant | Value | Location |
|----------|-------|----------|
| TILE_SIZE | 320px | world.gd, player.gd, npc.gd |
| MAP_SIZE | 60×50 tiles | world.gd |
| ZOOM_DEFAULT | 0.5 | world.gd |
| ZOOM_RANGE | 0.05–2.0 | world.gd |
| CHAR_DELAY | 0.03s | world.gd (typewriter) |
| MOVE_DURATION | 0.15s / 0.2s diagonal | player.gd |

---

## Map: Indiranagar, Bangalore

### Road Grid
- **Major roads (2 tiles wide):** 100 Feet Road (y=23-24), CMH Road (x=4-5)
- **Secondary (1 tile):** 12th Main (x=42), 80 Feet Road (y=40)
- **Cross streets:** y=7, 14, 19, 30, 36, 46
- **Main roads:** x=12, 20, 28, 35, 50, 56

### Zones
- **Commercial** (WALL_BRICK, WALL_OFFICE): blocks near 100ft Road (y=20-29) and 12th Main (x=36-49)
- **Residential** (WALL_WOOD, WALL_BUNGALOW): everywhere else

### Parks
1. Indiranagar Park (x=6-11, y=31-35) — fountain, benches, trees, flowers
2. Defence Colony Playground (x=51-55, y=41-45)
3. BDA Complex (x=6-11, y=8-13)

### Trees
Both sides of every road. Major: alternating trees/lamp posts every 2 tiles. Minor: trees every 3 tiles.

---

## Tile Types (23)

**Walkable (5):** GROUND, GROUND_GRASS, GROUND_DIRT, GROUND_SAND, PARK_GROUND

**Buildings (7):** WALL, WALL_BRICK, WALL_WOOD, ROOF, WALL_SCHOOL, WALL_OFFICE, WALL_BUNGALOW

**Props (11):** TREE, TREE_PINE, BUSH, FLOWERS, BENCH, LAMP_POST, FENCE, FOUNTAIN, MAILBOX, TRASH_CAN, SIGN_SHOP

---

## NPCs

| ID | Name | Position | Problem | Category |
|----|------|----------|---------|----------|
| alex | Alex | (25,23) | Expense tracking too complex for freelancers | productivity |
| jordan | Jordan | (12,33) | No good way to share research notes | education |
| maya | Maya | (42,16) | Small bakery needs simple online ordering | local-business |
| sam | Sam | (50,36) | Affordable appointment booking | local-business |
| priya | Priya | (28,46) | Teacher needs parent communication tool | education |

NPCs use `_find_nearest_walkable()` fallback to ensure walkable spawn positions.

---

## Systems

### Movement (player.gd)
- Grid-based, one tile per step (scales with zoom: `max(1, round(0.5/zoom))`)
- Tween animation between tiles (0.15s straight, 0.2s diagonal)
- Supports diagonal movement, continuous movement when holding keys
- Sprite flips horizontally for left/right

### Collision (world.gd → `_try_move()`)
Walk forward tile-by-tile up to step count, stopping at first obstacle:
1. Bounds check
2. Tile walkability check
3. NPC blocking check

### Dialogue (world.gd)
- Adjacent to NPC → bouncing "Press C" prompt
- C opens dialogue overlay with typewriter effect (0.03s/char)
- Space/Enter advances or skips typewriter
- After last line, closes and returns control

### Camera (world.gd)
- Follows player position with smoothing (speed 10.0)
- Zoom: trackpad pinch, mouse wheel, Cmd+/-, Cmd+0 (reset)
- Smooth zoom interpolation via lerp (speed 8.0)

### Map Generation (world.gd → `_generate_map()`)
Procedural with fixed seed (42):
1. Fill with grass
2. Lay road grid
3. Border walls
4. Place buildings in city blocks (zone-based wall types)
5. Hand-place parks with props
6. Tree-line all streets
7. Scatter street furniture, vegetation, dirt paths

### Tile Rendering (world.gd → `_render_tiles()`)
- Each tile → Sprite2D at `(x * TILE_SIZE + TILE_SIZE/2, y * TILE_SIZE + TILE_SIZE/2)`
- Props get grass rendered underneath (z_index -2)
- Buildings rendered as single sprite scaled to full footprint (not per-tile)

---

## Sprite Generation (tools/generate_sprites.py)

- **Google (default):** Imagen 4 Ultra (tiles/props) + Gemini Flash (characters)
- **OpenAI:** GPT Image 1.5 (everything)
- Style: photorealistic aerial drone photography, Indiranagar aesthetic
- Magenta bg removal for transparency (Google); native transparency (OpenAI)
- Output: 1024×1024 PNG → scaled to 320px in game
- Run: `cd tools && uv run python generate_sprites.py [--provider openai]`

---

## Code Health Notes

⚠️ **world.gd is monolithic (~500 lines)** — handles map gen, tile rendering, NPC spawning, dialogue, camera, input, and movement. Consider refactoring into separate systems before it grows further with v0.2+ features.

---

## Agent Reference

| Agent | Role | Workspace | Branch |
|-------|------|-----------|--------|
| 🤠 Junior | Squad lead | ~/.openclaw/workspace | main |
| 🔮 Oracle | Architect — specs, systems, data models | startup-game-architect | architect/specs |
| 💠 Cortana | Builder — Godot code, scenes, scripts | startup-game-builder | builder/dev |
| 🎨 Eva | Designer — sprites, style guide, assets | startup-game-designer | designer/assets |
