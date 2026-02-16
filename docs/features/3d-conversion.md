<!-- @version pre-v0.3 -->
<!-- @systems rendering camera movement asset-pipeline lighting -->
<!-- @tags 3d-conversion node3d glb models ai-generation cel-shaded -->
# 3D Conversion

Replace all 2D sprite assets with AI-generated 3D models (.glb) and convert the engine layer from Node2D to Node3D.

## Overview

- Convert the entire rendering layer from Godot's 2D engine (Node2D, Sprite2D, Camera2D) to 3D (Node3D, MeshInstance3D, Camera3D)
- Replace all 30 PNG sprite assets with AI-generated .glb 3D models
- Add real-time 3D lighting (DirectionalLight3D sun, OmniLight3D lamps, WorldEnvironment)
- Preserve all game logic: grid movement, NPC interaction, dialogue, journal, HUD, company founding
- Style target: cel-shaded/stylized 3D (A Short Hike, Spiritfarer) — NOT photorealistic

## Design

### What is untouched (zero changes)

- `map_generator.gd` (324 lines) — pure data computation, no rendering
- `dialogue_manager.gd` (74 lines) — pure CanvasLayer UI logic
- All game state in world.gd — problems, journal, founding, HUD (~400 lines)
- NPC data structures, grid coordinate system

### Coordinate mapping

The 2D system uses the XY plane with Y-down. The 3D system uses the XZ plane with Y-up.

```
2D:  position = Vector2(grid.x * 320 + 160, grid.y * 320 + 160)
3D:  position = Vector3(grid.x * TILE_SIZE, 0.0, grid.y * TILE_SIZE)
```

`TILE_SIZE` changes from 320 (pixels) to 2.0 (meters). This gives a 120m × 100m map — a reasonable neighborhood block scale.

### Camera

Orthographic Camera3D replaces Camera2D:
- Projection: orthogonal (preserves the grid-based feel, no perspective distortion)
- Ortho `size` replaces zoom (smaller = more zoomed in)
- Rotation: ~50° pitch looking down, 0° yaw
- Offset from player: (0, 25, 20) — above and behind
- Starting size: 30.0 (~15 tiles visible across)

### Buildings in 3D

Each building type gets one .glb model normalized to a 1×1 tile footprint. The model is then scaled to match the actual footprint dimensions:

```gdscript
instance.scale = Vector3(b.w, 1.0, b.h)  # stretch to footprint
```

This is simpler than the current 2D system — 3D models naturally have height, eliminating z-index layering hacks.

### Character facing

Sprite flip_h is replaced by rotating the 3D model node:

```gdscript
model.rotation.y = atan2(-direction.x, -direction.y)
```

### Interact prompt positioning

Canvas transform is replaced by Camera3D.unproject_position():

```gdscript
var screen_pos = camera.unproject_position(npc.global_position + Vector3(0, 2, 0))
```

### Performance strategy

The 60×50 map = 3000 ground tiles. Individual MeshInstance3D per tile is too expensive. Use `MultiMeshInstance3D` to batch all ground tiles of the same type into one draw call (5 multimeshes instead of ~2000 nodes). Props (~200) and buildings (~80) stay as individual nodes. Frustum culling is automatic in Godot 3D.

### 3D model generation

New tool `tools/generate_models.py` mirrors `generate_sprites.py` architecture:
- API backend: Hunyuan3D (Tencent) for text-to-3D generation
- Prompt strategy: cel-shaded, stylized, low-poly, warm Indiranagar palette
- Post-processing: scale normalization, material palette enforcement, center on origin
- Output: `.glb` files to `game/assets/models/{category}/{name}.glb`

### Lighting

| Node | Purpose | Settings |
|---|---|---|
| DirectionalLight3D | Sun | rotation=(-45, -30, 0), shadow_enabled, color=(1.0, 0.95, 0.85), energy=1.2 |
| WorldEnvironment | Ambient + tonemap | ambient_color=(0.4, 0.45, 0.5), energy=0.3, tonemap=ACES |
| OmniLight3D (per lamp) | Street lamp glow | color=#FFD080, range=8, energy=2.0 |

---

## Approach: Parallel 3D scenes

Create new `_3d` versions of scenes and scripts alongside the existing 2D ones. The 2D game stays functional as a fallback until the final cutover (iteration 6). Work on a `feature/3d-conversion` branch.

---

## Iterations

### Iteration 0 — Minimal 3D proof

The smallest proof that 3D works: a colored box on a flat plane with grid movement and camera follow.

**Create:**
| File | Purpose |
|---|---|
| `game/scenes/world_3d.tscn` | Node3D root + Camera3D + CanvasLayer |
| `game/scripts/world_3d.gd` | Minimal orchestrator: map gen, one green plane, player box, one NPC box, grid movement, camera follow (~100 lines) |
| `game/scenes/player_3d.tscn` | Node3D + MeshInstance3D (blue BoxMesh) |
| `game/scripts/player_3d.gd` | Grid movement on XZ plane with tween animation (~60 lines) |
| `game/scripts/camera_controller_3d.gd` | Camera3D, orthographic, smooth follow, zoom via ortho size (~50 lines) |

**Modify:**
| File | Change |
|---|---|
| `game/project.godot` | main_scene → world_3d.tscn, renderer → forward_plus |

**Verify:** Blue box on green plane. Arrow keys move one grid step. Camera follows smoothly. Red box (NPC) blocks movement.

### Iteration 1 — Full tile grid with colored meshes

Render the actual 60×50 map from MapGenerator with different colored shapes per tile type.

**Create:**
| File | Purpose |
|---|---|
| `game/scripts/tile_renderer_3d.gd` | Static class. Ground: colored PlaneMesh batched via MultiMeshInstance3D per type. Buildings: BoxMesh with height. Props: small boxes/cylinders. (~130 lines) |

**Modify:**
| File | Change |
|---|---|
| `game/scripts/world_3d.gd` | Replace single-plane with TileRenderer3D.render() call |

**Verify:** Full Indiranagar map as colored-block city. Buildings have height. Roads dark gray, grass green. Walk around, collision works against buildings.

### Iteration 2 — Full game logic port

Port all v0.2 features so the 3D version is feature-complete.

**Create:**
| File | Purpose |
|---|---|
| `game/scenes/npc_3d.tscn` | Area3D + MeshInstance3D (colored BoxMesh) + CollisionShape3D |
| `game/scripts/npc_3d.gd` | Port of npc.gd for 3D (~65 lines) |

**Modify:**
| File | Change |
|---|---|
| `game/scripts/world_3d.gd` | Add all game state, journal, HUD, NPC proximity detection, dialogue integration, founding flow (~400 lines from world.gd, mostly CanvasLayer UI copy-paste) |

**Verify:** Walk to NPC, prompt appears, dialogue works, Tab opens journal, found company, HUD shows, checkmarks on NPCs. Fully playable.

### Iteration 3 — Lighting and environment

The visual payoff of 3D.

**Create:**
| File | Purpose |
|---|---|
| `game/resources/default_environment.tres` | Environment resource (ambient, tonemap, SSAO) |

**Modify:**
| File | Change |
|---|---|
| `game/scenes/world_3d.tscn` | Add DirectionalLight3D, WorldEnvironment nodes |
| `game/scripts/tile_renderer_3d.gd` | Add OmniLight3D at lamp_post positions |

**Verify:** Building shadows fall consistently. Warm ambient lighting. Lamp posts glow. Block city looks good with proper lighting.

### Iteration 4 — 3D model generation tool + first models

Build the AI pipeline and replace placeholder boxes for ground + trees.

**Create:**
| File | Purpose |
|---|---|
| `tools/generate_models.py` | Python script calling Hunyuan3D API. Prompt defs, post-processing. Mirrors generate_sprites.py. (~300 lines) |
| `game/assets/models/ground/*.glb` | 5 ground tile models |
| `game/assets/models/props/tree.glb` | First prop model |

**Modify:**
| File | Change |
|---|---|
| `game/scripts/tile_renderer_3d.gd` | Load .glb files with fallback to procedural mesh |
| `tools/pyproject.toml` | Add dependencies for 3D API client |

**Verify:** Ground tiles and trees render as real 3D models. Other assets still colored boxes. Performance acceptable.

### Iteration 5 — All 3D models

Generate and integrate every remaining model.

**Create:**
| File | Purpose |
|---|---|
| `game/assets/models/buildings/*.glb` | 7 building type models |
| `game/assets/models/props/*.glb` | 10 remaining prop models |
| `game/assets/models/characters/*.glb` | Player + 5 NPC models |

**Modify:**
| File | Change |
|---|---|
| `game/scripts/player_3d.gd` | Load .glb scene, rotate model on direction change |
| `game/scripts/npc_3d.gd` | Load character-specific .glb by NPC ID |

**Verify:** Full map with 3D models. Characters recognizable. Buildings have detail. Walk every zone.

### Iteration 6 — Cutover and cleanup

Delete all 2D code. Rename `_3d` files to replace originals.

**Rename (drop `_3d` suffix):**
- `world_3d.tscn/gd` → `world.tscn/gd`
- `player_3d.tscn/gd` → `player.tscn/gd`
- `npc_3d.tscn/gd` → `npc.tscn/gd`
- `camera_controller_3d.gd` → `camera_controller.gd`
- `tile_renderer_3d.gd` → `tile_renderer.gd`

**Delete:**
- Old 2D scripts/scenes
- `game/assets/tiles/*.png`, `game/assets/characters/*.png`
- `game/resources/tiles.tres`
- `game/scenes/iteration_0.tscn`, `game/scripts/iteration_0.gd`

**Update docs:**
- `KNOWLEDGE.md` — new scene tree, architecture, 3D constants
- `CHANGELOG.md` — record the conversion
- `docs/art-direction.md` — mark §9 transition as complete

**Verify:** Game launches cleanly. All features work. No 2D remnants.

---

## Branching Strategy

```
main (stable 2D game)
  └── feature/3d-conversion
        ├── commit: iter-0 — minimal 3D proof
        ├── commit: iter-1 — full tile grid
        ├── commit: iter-2 — game logic ported
        ├── commit: iter-3 — lighting
        ├── commit: iter-4 — first .glb models
        ├── commit: iter-5 — all models
        └── commit: iter-6 — cleanup/cutover → merge to main
```

---

## Risks

| Risk | Mitigation |
|---|---|
| Performance (3000 tiles) | MultiMeshInstance3D from iter 1; frustum culling automatic |
| AI 3D model quality | Iter 0-3 work with colored boxes regardless; fallback to procedural geometry |
| Camera feel wrong | Experiment in iter 0 (ortho vs perspective, angle) |
| CanvasLayer UI breaks | CanvasLayer is camera-independent; only prompt needs unproject_position() |
| .glb import issues | Godot 4 has excellent glTF support; test one model manually before building pipeline |

---

## Deferred / Cut

| Item | Reason | Where it lives |
|---|---|---|
| Skeletal animation for characters | Adds complexity, not needed for static grid movement | v0.4+ |
| LOD levels on models | Orthographic camera keeps everything at same visual distance | Later if perf needed |
| Normal maps | 3D geometry replaces the need for normal maps | N/A |
| 9-slice building system | 3D models with scale replace modular tile composition | N/A (art-direction.md §4 deprecated) |
| Perspective camera option | Orthographic matches grid gameplay better | Maybe user preference later |

---

## Acceptance Criteria

- [ ] Game runs entirely on Node3D (no Node2D rendering)
- [ ] All 30 sprite assets replaced with .glb 3D models
- [ ] Grid-based movement works identically on XZ plane
- [ ] All v0.2 features work: NPC dialogue, problem collection, journal, HUD, company founding
- [ ] Camera provides clear top-down/isometric view with zoom
- [ ] DirectionalLight3D casts real-time shadows from buildings and props
- [ ] OmniLight3D on lamp posts provides warm glow
- [ ] WorldEnvironment provides ambient lighting and tonemap
- [ ] AI model generation tool exists in tools/generate_models.py
- [ ] Performance: stable 60fps on desktop
- [ ] No 2D rendering remnants in the codebase
- [ ] KNOWLEDGE.md and CHANGELOG.md updated

## Changes

- 2026-02-17: Initial feature doc (pre-build)
