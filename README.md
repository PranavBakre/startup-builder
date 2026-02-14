# Startup Simulator 🚀

An HD-2D top-down game where you build a startup from scratch — discover problems, hire a team, build a product, pitch investors, and grow to a $1B valuation.

**Stardew Valley meets startup culture**, set in Indiranagar, Bangalore.

![Status](https://img.shields.io/badge/status-v0.1%20complete-green) ![Engine](https://img.shields.io/badge/engine-Godot%204-blue) ![License](https://img.shields.io/badge/license-private-lightgrey)

## The Game

You start with $100,000 and a map full of people with problems. Walk around, talk to NPCs, discover real-world pain points, and choose one to build a company around. Then hire, build, launch, fundraise, and survive market cycles — all while managing burn rate and keeping your startup alive.

**Win condition:** $1B valuation.
**Lose condition:** Bankruptcy without recovery.

### Visual Style

HD-2D — 2D sprite art in a 3D-lit world, inspired by Octopath Traveler. Warm, grounded, inviting. Think cozy neighborhood with startup energy.

## Current Status

| Version | Name | Status |
|---------|------|--------|
| v0.1 | Walk & Talk | ✅ Complete |
| v0.2 | The Idea | 🔨 Up next |
| v0.3–v1.0 | [See roadmap](docs/version-roadmap.md) | — |

**v0.1** delivers: tile-based movement on a 60×50 Indiranagar map, 5 NPCs with dialogue, camera zoom, and problem discovery.

## Getting Started

### Prerequisites

- [Godot 4.x](https://godotengine.org/download)
- [uv](https://github.com/astral-sh/uv) (for Python tooling, optional)

### Run the Game

```bash
# Open in Godot editor
open game/project.godot

# Or run from CLI
godot --path game
```

### Generate Sprites (optional)

```bash
cd tools
uv sync
uv run python generate_sprites.py              # Google Imagen + Gemini
uv run python generate_sprites.py --provider openai  # OpenAI GPT Image
```

Requires `GOOGLE_API_KEY` or `OPENAI_API_KEY` in environment.

## Documentation

| Doc | What it covers |
|-----|---------------|
| [CLAUDE.md](CLAUDE.md) | Project rules, workflow, version scope |
| [KNOWLEDGE.md](KNOWLEDGE.md) | Technical reference — architecture, code anatomy |
| [Game Brief](docs/startup-simulator-game-brief.md) | Full game vision (the dream) |
| [Version Roadmap](docs/version-roadmap.md) | v0.1→v1.0 breakdown |
| [Changelog](CHANGELOG.md) | What changed and when |

## Built With

- **[Godot 4](https://godotengine.org/)** — Game engine
- **GDScript** — Game logic
- **[OpenClaw](https://github.com/openclaw/openclaw)** — AI agent framework powering the dev squad
- **Google Imagen 4 / Gemini Flash / OpenAI GPT Image** — Sprite generation
