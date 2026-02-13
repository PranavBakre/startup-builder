# Changelog

All notable changes to this project are documented here. Entries use `@features` tags for searchability.

---

## 2026-02-12

### Added

- **v0.1 feature doc created** — Walk & Talk feature doc with ideation process, iteration 0 definition, full implementation plan, and acceptance criteria. @features walk-and-talk
  - Files changed: `docs/features/walk-and-talk.md`

### Design

- **Visual style decision — HD-2D** — Settled on Octopath Traveler-inspired HD-2D: 2D sprite art in a 3D-lit world with real-time shadows, depth of field, bloom, and atmospheric lighting. Warm and grounded, not dark/dramatic. This rules out browser-only engines and makes Godot the strong frontrunner. @features visual-style
  - Files changed: `docs/startup-simulator-game-brief.md`

- **Navigation model decision** — Hybrid walk + fast-travel. Walking is the primary mechanic early, shifts to secondary as management scales. Fast-travel unlocks for discovered locations. Walking remains the idea engine throughout — NPCs are always the source of product direction. @features navigation-model
  - Files changed: `docs/startup-simulator-game-brief.md`

- **Project documentation structure established** — Created CLAUDE.md (project entry point), docs/documentation-guide.md (doc system conventions), docs/version-roadmap.md (v0.1–v1.0 breakdown), and CHANGELOG.md. The full game brief has been decomposed into 10 incremental sub-versions, each with scope, iteration 0, and acceptance criteria. @features documentation-setup
  - Files changed: `CLAUDE.md`, `docs/documentation-guide.md`, `docs/version-roadmap.md`, `CHANGELOG.md`

---

## 2026-02-13

### Added

- **Indiranagar map rework** — Replaced 200×150 generic grid with 60×50 Indiranagar, Bangalore street layout. Authentic road grid: 100 Feet Road (E-W), CMH Road (N-S), 12th Main, 80 Feet Road, numbered cross streets and main roads. Zone-based building placement (commercial brick near 100 Feet Road/12th Main, residential wood elsewhere). 3 hand-placed parks with fountains, benches, and flowers. Tree-lined streets on both sides of every road. @features walk-and-talk map indiranagar
  - Files changed: `scripts/world.gd`

- **5 NPCs with safe spawning** — Added Sam (barber) and Priya (teacher) to existing Alex, Jordan, Maya. All NPCs placed at road intersections for easy access. Added `_find_nearest_walkable()` fallback so NPCs and player never spawn inside buildings. @features walk-and-talk npc
  - Files changed: `scripts/world.gd`

- **Camera zoom controls** — Trackpad pinch, mouse scroll wheel, Cmd+/-, Cmd+0 (reset). Smooth zoom interpolation with lerp. Zoom range 0.05–2.0, default 0.5. @features walk-and-talk camera
  - Files changed: `scripts/world.gd`, `scenes/world.tscn`

- **Movement speed scaling** — Movement speed now scales with zoom level: `max(1, round(0.5 / current_zoom))`. At default zoom (0.5) = 1 tile per step; zoomed out = up to ~10 tiles per step. @features walk-and-talk movement
  - Files changed: `scripts/world.gd`

- **Bangalore-themed sprites** — Regenerated all 25 sprites (19 tiles + 6 characters) with Indiranagar visual theme. Laterite soil, tropical rain trees, ashoka trees, bougainvillea, marigolds, compound walls, Indian post boxes, green dustbins. Indian characters with brown skin, kurta, salwar kameez, saree. @features walk-and-talk sprites
  - Files changed: `assets/tiles/*.png`, `assets/characters/*.png`

- **Dual-engine sprite generation** — Imagen 4 for tiles/props, Gemini Flash for characters (handles people better). Magenta background removal for transparency. @features sprite-generation
  - Files changed: `startup-game-tools/generate_sprites.py`

### Fixed

- **Integer division warning** — Changed `TILE_SIZE / 2` to `TILE_SIZE / 2.0` in interact prompt positioning to avoid Godot integer division warnings. @features walk-and-talk
  - Files changed: `scripts/world.gd`

### Changed

- **Tile size 32→320** — 10× larger sprites for HD-2D quality at the new map scale. @features walk-and-talk
  - Files changed: `scripts/world.gd`, `scripts/player.gd`, `scripts/npc.gd`, `scenes/player.tscn`

- **19 tile types** — Expanded from basic set to 19 types: 4 ground variants, 4 building variants, and 11 props (tree, ashoka tree, bougainvillea, marigolds, bench, lamp post, compound wall, fountain, post box, dustbin, shop sign). @features walk-and-talk tiles
  - Files changed: `scripts/world.gd`

### Docs

- **Walk & Talk feature doc rewritten** — Complete rewrite of walk-and-talk.md to reflect Indiranagar rework: updated map layout, NPC table, camera section, movement section, sprite generation docs, code index, iteration 4 documentation. All acceptance criteria checked. @features walk-and-talk documentation
  - Files changed: `docs/features/walk-and-talk.md`
