# KNOWLEDGE.md — Startup Simulator Knowledge Bank

Shared reference for all agents (Junior, Oracle, Cortana, Eva). Read this before starting any task.

---

## Project Summary

**Startup Simulator** — HD-2D top-down game where the player builds a startup from problem discovery to $1B valuation. Stardew Valley meets startup culture, set in Indiranagar, Bangalore.

- **Engine:** Godot 4.x / GDScript
- **Visual Style:** HD-2D — 2D sprites in 3D-lit world (Octopath Traveler-inspired). Currently using AI-generated photorealistic sprites; will transition to 3D models pre-v2.
- **Platforms:** Desktop + Mobile
- **Repo:** github.com/PranavBakre/startup-builder

---

## Status

- **v0.1 (Walk & Talk):** ✅ Complete
- **v0.2 (The Idea):** 📋 Documented, not yet built
- **Current Target:** v0.2

---

## Repo Structure

```
startup-game/
├── game/                    ← Godot 4 project
│   ├── project.godot
│   ├── scenes/              ← .tscn scene files
│   │   ├── world.tscn       ← Main scene (camera, tilemap, dialogue UI)
│   │   ├── player.tscn      ← Player scene
│   │   ├── npc.tscn         ← NPC template
│   │   └── iteration_0.tscn ← Original prototype (archived)
│   ├── scripts/             ← GDScript files
│   │   ├── world.gd         ← Map gen, tile rendering, NPCs, dialogue, camera, movement (~500 lines)
│   │   ├── player.gd        ← Grid movement, tween animation, sprite flipping
│   │   ├── npc.gd           ← NPC setup, sprite loading, positioning
│   │   └── iteration_0.gd   ← Original prototype (archived)
│   ├── assets/
│   │   ├── tiles/           ← 19 tile/prop sprites (1024x1024 PNG, scaled to 320px in game)
│   │   └── characters/      ← 6 character sprites (player + 5 NPCs)
│   └── resources/
│       └── tiles.tres        ← Tile resource
├── tools/                   ← Python tooling
│   ├── generate_sprites.py  ← Multi-provider sprite generator (Google Imagen/Gemini, OpenAI GPT Image)
│   ├── main.py
│   └── pyproject.toml       ← Python deps (uv)
├── docs/                    ← Design docs, feature docs, roadmap
│   ├── startup-simulator-game-brief.md  ← Full game vision (north star)
│   ├── version-roadmap.md   ← v0.1→v1.0 incremental breakdown
│   ├── documentation-guide.md ← Doc system conventions
│   ├── features/
│   │   ├── walk-and-talk.md  ← v0.1 feature doc (complete)
│   │   └── the-idea.md       ← v0.2 feature doc (pre-build)
│   └── rules/
│       └── ideation.md       ← Scoping process for each version
├── CLAUDE.md                ← Project entry point, rules, workflow
├── CHANGELOG.md             ← Change history with @features tags
└── KNOWLEDGE.md             ← This file
```

---

## Architecture (Current v0.1)

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
- **TILE_SIZE:** 320px
- **MAP_SIZE:** 60×50 tiles
- **ZOOM:** 0.05–2.0, default 0.5
- **CHAR_DELAY:** 0.03s (typewriter effect)
- **MOVE_DURATION:** 0.15s per tile, 0.2s diagonal

### Map: Indiranagar, Bangalore
- **Major roads (2 tiles wide):** 100 Feet Road (y=23-24), CMH Road (x=4-5)
- **Secondary roads (1 tile wide):** 12th Main (x=42), 80 Feet Road (y=40)
- **Cross streets:** y=7, 14, 19, 30, 36, 46
- **Main roads:** x=12, 20, 28, 35, 50, 56
- **Parks:** Indiranagar Park (6-11, 31-35), Defence Colony (51-55, 41-45), BDA Complex (6-11, 8-13)
- **Zones:** Commercial (brick/office) near 100ft Road & 12th Main; Residential (wood/bungalow) elsewhere
- **Buildings:** Procedurally placed in city blocks with 1-tile grass buffer
- **Trees:** Both sides of every road (major: every 2 tiles with lamp posts; minor: every 3 tiles)

### Tile Types (23 total)
**Walkable (5):** GROUND, GROUND_GRASS, GROUND_DIRT, GROUND_SAND, PARK_GROUND
**Buildings (7):** WALL, WALL_BRICK, WALL_WOOD, ROOF, WALL_SCHOOL, WALL_OFFICE, WALL_BUNGALOW
**Props (11):** TREE, TREE_PINE, BUSH, FLOWERS, BENCH, LAMP_POST, FENCE, FOUNTAIN, MAILBOX, TRASH_CAN, SIGN_SHOP

### NPCs
| ID | Name | Position | Problem | Category |
|----|------|----------|---------|----------|
| alex | Alex | (25,23) | Expense tracking too complex for freelancers | productivity |
| jordan | Jordan | (12,33) | No good way to share research notes | education |
| maya | Maya | (42,16) | Small bakery needs simple online ordering | local-business |
| sam | Sam | (50,36) | Affordable appointment booking for small businesses | local-business |
| priya | Priya | (28,46) | Teacher needs parent communication tool | education |

### Movement System
- Grid-based, one tile per step (scales with zoom: `max(1, round(0.5/zoom))`)
- Tween animation between tiles
- Collision: bounds check → tile walkability → NPC blocking
- Supports diagonal movement
- Continuous movement when holding keys

### Dialogue System
- Walk adjacent to NPC → bouncing "Press C" prompt
- C key opens dialogue overlay with typewriter effect
- Space/Enter advances dialogue or skips typewriter
- After last line, dialogue closes

### Sprite Generation (tools/generate_sprites.py)
- **Google provider (default):** Imagen 4 Ultra for tiles/props, Gemini Flash for characters
- **OpenAI provider:** GPT Image 1.5 for everything
- Photorealistic aerial drone photography style
- Magenta (#FF00FF) background removal for transparency (Google); native transparency (OpenAI)
- Output: 1024×1024 PNG, scaled to 320px in game

---

## What's Next: v0.2 — The Idea

**Core mechanic:** Problem collection + company founding

### New Features
1. **Problem journal** — Auto-collects problems from NPC dialogue. Tab to open.
2. **Company founding** — Select a problem, name the company, see "Founded!" moment
3. **HUD** — Company name + $100,000 cash (static, no economy tick yet)
4. **Multi-layer NPC dialogue** — First talk = problem, re-talk = follow-up, post-founding = acknowledgment
5. **Map indicators** — Checkmark above NPCs whose problem was collected

### New Data Fields (per NPC)
```gdscript
"follow_up": "Any luck with that expense tracking idea?",
"post_founding": "Nice, you started a company! Hope it works out."
```

### New Game State
```gdscript
var discovered_problems: Array = []
var company_name: String = ""
var company_cash: int = 100000
var selected_problem: Dictionary = {}
var talked_to: Dictionary = {}  # { npc_id: true }
```

### Design Decision Pending
- Extract game state from world.gd into a GameState autoload singleton? (Simplifies v0.3 save/load)

---

## Critical Rules

1. **Docs first, code second** — Feature doc before any code
2. **One version at a time** — Don't build future version mechanics
3. **Iteration 0 first** — Smallest working proof before full implementation
4. **Playable at every version** — No "infrastructure only" versions
5. **Checkpoint = commit** — Commit after every working increment
6. **Scope cuts > scope creep** — Cut ruthlessly
7. **Game brief = north star, not blueprint** — Roadmap is what we actually build

---

## Version Roadmap (Summary)

| Ver | Name | Core Mechanic | Status |
|-----|------|--------------|--------|
| v0.1 | Walk & Talk | Movement + NPC dialogue | ✅ Done |
| v0.2 | The Idea | Problem collection + founding | 📋 Next |
| v0.3 | Tick Tock | In-game clock + economy + save/load | — |
| v0.4 | The Team | Job board + hiring | — |
| v0.5 | Home Base | Office setup + interiors | — |
| v0.6 | Ship It | Product dev + features + revenue | — |
| v0.7 | Storefront | Website builder mini-game | — |
| v0.8 | Pitch Day | Valuation + funding rounds + LLM pitch eval | — |
| v0.9 | Rocket Ship | Launch event + market cycles | — |
| v1.0 | Full Game | Bankruptcy + pivot + idle + win/lose | — |
| Pre-v2 | Art Pass | Replace AI sprites with 3D models | — |

---

## Agent Reference

| Agent | Role | Workspace | Branch |
|-------|------|-----------|--------|
| 🤠 Junior | Squad lead, orchestrator | ~/.openclaw/workspace | main |
| 🔮 Oracle | Architect — specs, systems, data models | startup-game-architect | architect/specs |
| 💠 Cortana | Builder — Godot code, scenes, scripts | startup-game-builder | builder/dev |
| 🎨 Eva | Designer — sprites, style guide, assets | startup-game-designer | designer/assets |

### Workflow
1. Junior assigns task to Oracle → she writes the spec
2. Junior assigns spec to Cortana → she builds it
3. Junior sends Cortana's work to Oracle → she reviews
4. Oracle approves or requests changes → loop
5. Junior merges into main
