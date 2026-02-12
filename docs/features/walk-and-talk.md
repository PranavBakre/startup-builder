<!-- @version 0.1 -->
<!-- @systems movement rendering npc dialogue -->
<!-- @tags tile-map player-movement npc-interaction dialogue collision camera -->
# Walk & Talk

The player moves around a tile-based map, encounters NPCs, and discovers startup problems through conversation.

## Overview

- Grid-based player movement on a single-zone tile map with collision detection
- 3–5 stationary NPCs placed at fixed positions on the map
- Interact with NPCs by walking adjacent and pressing a key to open dialogue
- Each NPC delivers a unique dialogue sequence that surfaces a real-world startup problem
- 2.5D top-down perspective with sprite layering for depth

## Design

The player spawns on a small town-like map. They move tile-by-tile using arrow keys or WASD. The map has ground tiles, obstacle tiles (buildings, trees, fences), and NPC tiles. NPCs stand in fixed positions around the map — near a coffee shop, outside a building, sitting on a bench, etc.

When the player is adjacent to an NPC (one tile away, facing them), a prompt appears (e.g., "Press C to chat"). Pressing the interact key opens a dialogue overlay. The NPC speaks line by line — the player advances dialogue by pressing the interact key again or pressing Enter. The first layer of every NPC's dialogue reveals a problem they're experiencing with a digital product or a real-world pain point.

After reading all dialogue, the overlay closes and the player can continue exploring. There is no problem journal or selection mechanic yet — the player simply discovers problems by talking to people. That's v0.2.

### Map Layout

A single zone, roughly 20x15 tiles. Contains:
- Open ground (walkable)
- A few buildings (collision — the player walks around them, not into them)
- Simple props: trees, benches, lamp posts (collision)
- 3–5 NPCs scattered in interesting positions

No building interiors. No map transitions. Just one continuous outdoor zone.

### NPC Dialogue

Each NPC has:
- A name
- A fixed position on the map
- A dialogue array (ordered lines of text)
- A problem embedded in the dialogue (the core reason this NPC exists)

Dialogue is linear — the same lines play every time. No branching, no choices. The player reads and moves on.

### Camera

Top-down with a slight tilt to give depth (the "2.5D" feel). The camera follows the player, keeping them roughly centered. Sprite layering ensures objects "above" the player on screen (like a tree canopy) overlap correctly.

## Implementation Plan

### Iteration 0

**Goal:** Prove that tile-based movement, collision, NPC adjacency detection, and dialogue display work together.

**What it looks like:**
- A rendered grid in the browser (colored rectangles — no sprites yet)
- A player tile (distinct color) that moves with arrow keys, one tile per keypress
- Wall/obstacle tiles that block movement
- 2–3 NPC tiles (distinct color) at hardcoded positions
- Adjacency detection: when the player is next to an NPC, a text label appears
- Pressing the interact key prints the NPC's dialogue lines sequentially in a basic text box overlay
- No camera movement, no sprites, no 2.5D angle — flat grid, proof of concept

**Acceptance criteria for iteration 0:**
- [x] Grid renders in browser with distinct tile types (ground, wall, NPC)
- [x] Player moves one tile per keypress (arrow keys or WASD)
- [x] Player cannot move onto wall or NPC tiles
- [x] When adjacent to an NPC, a visual indicator appears
- [x] Pressing interact key (C) while adjacent to NPC opens dialogue
- [x] Dialogue displays line by line, advancing on keypress
- [x] Dialogue closes after the last line
- [x] At least 2 NPCs with different dialogue

**Status:** ✅ Complete (commit c56ea86)

---

### Iteration 1: Visual Foundation

**Goal:** Replace colored rectangles with actual tile-based visuals that show in the Godot editor.

**What we're building:**
Replace the `_draw()` approach with proper Godot nodes so the game looks real and is editable in the editor.

**Technical approach:**

1. **TileMap node with TileSet**
   - Create a TileSet resource with tile definitions
   - Use placeholder tile sprites (simple 16x16 or 32x32 pixel art)
   - Define ground, wall, and prop tiles with collision shapes
   - Replace the 2D array tile system with Godot's TileMap
   - Keep the same 20x15 map dimensions

2. **Player as Sprite2D**
   - Create a Player scene (Node2D with Sprite2D child)
   - Use a simple placeholder sprite (16x16 or 32x32)
   - Keep grid-based position tracking (convert to world position for rendering)
   - Movement still instant (no tweening yet — that's iteration 2)

3. **NPCs as Sprite2D**
   - Create an NPC scene (Area2D with Sprite2D and CollisionShape2D)
   - Each NPC is an instance with distinct sprite
   - Position them on the grid like before
   - Keep the same dialogue data structure

4. **Scene structure visible in editor**
   - Main scene: World (Node2D)
     - TileMap (ground, walls, props)
     - Player (instanced scene)
     - NPCs (instanced scenes)
     - UI layer (CanvasLayer with dialogue box)
   - Everything visible and editable in editor 2D view

**What stays the same:**
- Grid-based movement logic (still one tile per keypress)
- Collision detection (but uses TileMap collision instead of array checks)
- Adjacency detection and dialogue system
- Input handling
- No camera movement yet (iteration 2)

**What changes:**
- Visual representation (sprites instead of colored rectangles)
- Scene structure (proper node hierarchy)
- Map data (TileMap instead of 2D array)
- Editability (everything visible in editor)

**Placeholder art approach:**
- Keep it minimal — solid-colored squares or very simple pixel art
- Focus: structure and systems, not visual polish
- Can use Godot's built-in colored tiles or generate simple sprites
- Real art comes in iteration 3

**Acceptance criteria for iteration 1:**
- [ ] TileMap renders in both editor and game with distinct tile types
- [ ] Player appears as a sprite (not colored rectangle)
- [ ] 2 NPCs appear as sprites with different visuals
- [ ] Player moves one tile per keypress (same as iteration 0)
- [ ] Collision detection works with TileMap collision layers
- [ ] Adjacency detection still works with new sprite-based NPCs
- [ ] Dialogue system works identically to iteration 0
- [ ] All game objects visible in Godot editor 2D view
- [ ] Scene structure is clean and organized

**Files to create/modify:**
- `scenes/world.tscn` (main game scene, replaces iteration_0.tscn)
- `scenes/player.tscn` (player character scene)
- `scenes/npc.tscn` (NPC base scene)
- `scripts/world.gd` (main game logic, refactored from iteration_0.gd)
- `scripts/player.gd` (player movement logic)
- `scripts/npc.gd` (NPC behavior and dialogue)
- `resources/tiles.tres` (TileSet resource)
- `assets/tiles/` (tile sprites)
- `assets/characters/` (player and NPC sprites)

**Deferred to iteration 2:**
- Smooth movement tweening
- Camera following
- 4-directional player sprites
- Sprite layering / Y-sort for depth

**Deferred to iteration 3:**
- Additional NPCs (3-5 total)
- Better quality sprites
- Map design polish
- Dialogue visual effects

---

### Full Implementation

**Step 1 — Tile map system**
- Define a tile map data structure (2D array of tile types)
- Load or define the map layout (hardcoded is fine for v0.1)
- Render tiles with placeholder sprites or colored tiles
- Define tile types: ground (walkable), wall (blocking), NPC (blocking), prop (blocking)

**Step 2 — Player movement**
- Player entity with grid position (x, y)
- Keyboard input handler (arrow keys + WASD)
- Move one tile per keypress in the input direction
- Collision check before moving: reject move if target tile is blocking
- Smooth visual transition between tiles (lerp/tween over ~100–150ms)

**Step 3 — Camera**
- Camera follows the player, centered on their position
- Slight top-down tilt for 2.5D feel (achieved through sprite art and layering, not 3D projection)
- Sprite draw order: sort by Y position so objects lower on screen render on top
- Objects "above" the player (trees, building tops) overlap the player sprite

**Step 4 — NPC placement and adjacency**
- NPCs defined as entities with: name, grid position, dialogue array
- NPCs placed at hardcoded map positions
- Adjacency detection: check if player is exactly 1 tile away (cardinal directions only) from an NPC
- When adjacent, show interaction prompt ("Press C to chat")

**Step 5 — Dialogue system**
- Dialogue overlay UI: a box at the bottom of the screen (RPG-style)
- Shows NPC name and current dialogue line
- Advance to next line on keypress (C or Enter)
- Close overlay after last line
- While dialogue is open, player movement is disabled

**Step 6 — Content: NPCs and their problems**
- 3–5 NPCs, each with a name and a dialogue sequence
- Each dialogue naturally surfaces a problem (a pain point with a digital product or a real-world inefficiency)
- Problems should feel grounded and realistic — the kind of thing a real person would complain about

Example NPCs (placeholder — final content TBD):

| NPC | Location hint | Problem |
|---|---|---|
| Alex | Near coffee shop | Frustrated with expense tracking apps that are too complex for freelancers |
| Jordan | Outside library | Can't find a good way to organize and share research notes with a team |
| Sam | Sitting on bench | Local small businesses have no easy way to set up online ordering |

**Step 7 — Polish (only if core is solid)**
- Player sprite (simple character, 4 directional frames)
- NPC sprites (distinct characters)
- Tile sprites (grass, path, building walls, trees)
- Interaction prompt animation (subtle bounce or fade-in)
- Dialogue text typewriter effect (characters appear one by one)

## Deferred / Cut

| Item | Reason | Where it lives |
|---|---|---|
| Problem journal (collecting problems) | That's v0.2's core mechanic | v0.2 roadmap |
| Problem selection / company founding | v0.2 | v0.2 roadmap |
| NPC walking or pathfinding | Not needed — NPCs are stationary | Maybe v2+ |
| Multiple map zones | One zone is enough for v0.1 | Later versions |
| Building interiors | v0.5 mechanic | v0.5 roadmap |
| Day/night cycle | v0.3 mechanic | v0.3 roadmap |
| Sound effects | Polish, not core | Later |
| Save/load | v0.3 mechanic | v0.3 roadmap |
| Branching dialogue or choices | Not needed — linear dialogue only | Maybe v0.2+ |
| NPC memory (remembering past conversations) | Design brief mentions it but it's not v0.1 | v1.0 roadmap |
| Animated NPC idle behavior | Polish, not core | Later |

## Game Data

```
// Tile types
GROUND = 0   // walkable
WALL = 1     // blocking (buildings, fences)
PROP = 2     // blocking (trees, benches, lamp posts)

// Map: 2D array of tile type integers
// NPC positions stored separately (they occupy ground tiles but block movement)

// NPC structure
{
  id: string,
  name: string,
  position: { x: number, y: number },
  dialogue: string[],          // ordered lines of text
  problem: {
    description: string,       // one-line summary of the problem
    category: string           // e.g., "productivity", "local-business", "education"
  }
}

// Player structure
{
  position: { x: number, y: number },
  facing: "up" | "down" | "left" | "right"
}
```

## Dependencies

- **Uses**: None (this is the foundation — first thing built)
- **Used by**: v0.2 (The Idea) builds on this map, movement, and NPC system. Every subsequent version builds on these systems.

## Acceptance Criteria (Full v0.1)

- [ ] A single-zone tile map renders in the browser with ground, walls, and props
- [ ] Player moves tile-by-tile with arrow keys or WASD
- [ ] Collision prevents walking through walls, props, and NPCs
- [ ] Smooth visual movement between tiles (not instant snapping)
- [ ] Camera follows the player
- [ ] Sprite layering gives a 2.5D depth feel (objects overlap correctly)
- [ ] 3–5 NPCs are visible on the map at fixed positions
- [ ] Walking adjacent to an NPC shows an interaction prompt
- [ ] Pressing C while adjacent opens a dialogue overlay
- [ ] Dialogue shows NPC name and text, advances line by line
- [ ] Each NPC's dialogue surfaces a distinct, realistic startup problem
- [ ] Dialogue closes after the last line and returns control to the player
- [ ] The game runs in a browser

## Status

- [x] Iteration 0 complete (2026-02-12, commit c56ea86)
- [ ] Iteration 1 complete
- [ ] Iteration 2 complete
- [ ] Iteration 3 complete (full v0.1)
- [ ] Playtested
- [ ] Doc finalized with code index

## Changes

- 2026-02-12: Initial documentation (pre-build)
- 2026-02-12: Iteration 0 complete - colored grid prototype with movement, collision, adjacency, and dialogue
- 2026-02-12: Added iteration 1 specification - visual foundation with TileMap and sprites
