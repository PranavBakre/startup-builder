# CLAUDE.md — Startup Simulator

## Project Overview

Startup Simulator is an HD-2D top-down game where the player builds a digital product company from scratch — from discovering a real-world problem to scaling a billion-dollar business. 2D sprite art in a 3D-lit world (Octopath Traveler-inspired), tile-based navigation, NPC interactions, economic simulation, and startup lifecycle mechanics.

**Tone:** Serious but playful. Grounded and warm — not satirical. Stardew Valley meets startup culture.
**Visual Style:** HD-2D — 2D sprites with real-time 3D lighting, shadows, depth of field, and atmospheric effects.
**Platforms:** Desktop + Mobile (virtual joystick on mobile, keyboard on desktop)

**Status:** v0.1 complete, building v0.2
**Tech Stack:** Godot 4
**Current Target:** v0.2

## Documentation Index

| Document | Purpose |
|---|---|
| [docs/rules/ideation.md](docs/rules/ideation.md) | Ideation process — scoping, finding iteration 0, cutting ruthlessly before building |
| [docs/documentation-guide.md](docs/documentation-guide.md) | How the documentation system works — formats, workflows, conventions |
| [docs/version-roadmap.md](docs/version-roadmap.md) | Version breakdown from v0.1 to v1.0 — scope, goals, mechanics per version |
| [docs/startup-simulator-game-brief.md](docs/startup-simulator-game-brief.md) | Full game vision — the complete design brief (final-state scope) |
| [CHANGELOG.md](CHANGELOG.md) | Chronological record of changes |
| `docs/architecture.md` | System architecture — tech stack, modules, data flow *(created when building starts)* |
| `docs/workflows/building.md` | Build conventions — iteration model, coding patterns *(created when building starts)* |
| `docs/features/*.md` | Per-feature code indexes *(created as features are built)* |

## Game Scope

The [full game brief](docs/startup-simulator-game-brief.md) describes the complete vision. It encompasses 7 game phases, multiple mini-games, an economic simulation, LLM-powered mechanics, and idle systems.

**V1 is NOT the full vision.** The [version roadmap](docs/version-roadmap.md) breaks the brief into 10 incremental sub-versions (v0.1 → v1.0), each building on the last. Each sub-version is a playable, testable milestone.

### Version Summary

| Version | Codename | Core Delivery |
|---|---|---|
| v0.1 | Walk & Talk | Tile map + player movement + NPC chat + problem surfacing |
| v0.2 | The Idea | Problem collection + selection + company founding |
| v0.3 | Tick Tock | In-game clock + economy foundation + save/load |
| v0.4 | The Team | Job board + hiring flow + salary costs |
| v0.5 | Home Base | Office building + setup + employee placement |
| v0.6 | Ship It | Product development + feature building + revenue |
| v0.7 | Storefront | Website builder mini-game + customer acquisition |
| v0.8 | Pitch Day | Valuation + investor NPCs + funding rounds + equity |
| v0.9 | Rocket Ship | Launch event + market cycles + growth loop |
| v1.0 | The Full Game | Bankruptcy + pivot + idle mechanics + win/lose conditions |

## Critical Rules

1. **Docs first, code second** — Before building any feature, document it in `docs/features/<feature-name>.md`. Get alignment on approach, then implement.
2. **One version at a time** — Do not build mechanics from a later version. If tempted, note it in the roadmap and move on.
3. **Iteration 0 for each version** — Every sub-version starts with the smallest working proof of its core mechanic. For v0.1 this is a standalone console proof. For later versions, it's the new mechanic wired into the existing game at its simplest.
4. **Playable at every version** — Each sub-version must result in something a player can interact with. No "infrastructure only" versions.
5. **Feature-tagged documentation** — Every feature gets a doc in `docs/features/` with tags for grepability.
6. **Checkpoint = commit** — After every working increment, commit with a descriptive message. Git history is project history.
7. **Scope cuts over scope creep** — When in doubt, cut. A working v0.1 is worth more than a broken v0.5.
8. **Game brief is the north star, not the blueprint** — The brief describes the dream state. The version roadmap describes what we actually build and when.

## Quick Reference

| Question | Where to look |
|---|---|
| How do I scope before building? | [docs/rules/ideation.md](docs/rules/ideation.md) |
| What's the full game vision? | [docs/startup-simulator-game-brief.md](docs/startup-simulator-game-brief.md) |
| What's in each version? | [docs/version-roadmap.md](docs/version-roadmap.md) |
| How does the doc system work? | [docs/documentation-guide.md](docs/documentation-guide.md) |
| How was feature X built? | `docs/features/<feature-name>.md` |
| What changed recently? | [CHANGELOG.md](CHANGELOG.md) |
| System architecture & tech stack | `docs/architecture.md` *(after building starts)* |
| Build conventions & patterns | `docs/workflows/building.md` *(after building starts)* |

## Commands

```bash
# TBD — populated when tech stack is chosen and project is initialized
```

## Workflow

### Starting a New Version

Follow [docs/rules/ideation.md](docs/rules/ideation.md) before writing any code:

1. **Identify the core mechanic** — one sentence.
2. **Define iteration 0** — smallest working proof of the mechanic.
3. **Challenge scope** — cut anything non-essential from the version's roadmap entry.
4. **Write the feature doc(s)** — `docs/features/<feature-name>.md` with iteration 0, full plan, acceptance criteria.

### Building a Feature

1. **Check the roadmap** — Is this feature in the current target version? If not, stop.
2. **Build iteration 0** — Smallest working proof, testable in terminal or browser console.
3. **Build the feature** — Logic first, then UI, then polish.
4. **Test it** — Verify it works in the game context.
5. **Update docs** — Finalize the feature doc with actual code index.
6. **Append to CHANGELOG.md** — Record what was built.
7. **Commit** — Descriptive message following conventional commits (`feat:`, `fix:`, `wip:`).

### Advancing to the Next Version

1. **Verify current version is complete** — All features listed in the roadmap for the current version are built and working.
2. **Playtest** — The game is playable through the current version's content.
3. **Update CLAUDE.md** — Change "Current Target" to the next version.
4. **Start the next version's iteration 0** — Follow the building workflow above.

### Documenting Design Decisions

- Affects the game vision → update [docs/startup-simulator-game-brief.md](docs/startup-simulator-game-brief.md)
- Affects version scope → update [docs/version-roadmap.md](docs/version-roadmap.md)
- Affects how we build → update `docs/workflows/building.md`
- Affects architecture → update `docs/architecture.md`
