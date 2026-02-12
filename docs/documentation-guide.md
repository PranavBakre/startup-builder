# Documentation Guide

How the Startup Simulator documentation system works — structure, formats, workflows, conventions, and search patterns.

## Documentation Structure

```
CLAUDE.md                              # Entry point — project overview, version summary, rules, workflow
CHANGELOG.md                           # Chronological record of changes with @features tags
docs/
  documentation-guide.md               # This file — how the doc system works
  startup-simulator-game-brief.md      # Full game vision (the dream state)
  version-roadmap.md                   # v0.1 → v1.0 breakdown with scope per version
  architecture.md                      # Tech stack, system modules, data flow (created when building starts)
  workflows/
    building.md                        # Build conventions, coding patterns (created when building starts)
  game-design/
    mechanics/                         # Detailed mechanic specs, created per version as needed
  features/
    <feature-name>.md                  # Per-feature code index (created as features are built)
```

## Feature Doc Format

Feature docs are the core unit of documentation. Each one maps a single game feature to the code that implements it. They are created **before** building (as a plan) and updated **after** building (with actual code index).

### Template

```markdown
<!-- @version 0.1 -->
<!-- @systems movement rendering -->
<!-- @tags player-movement tile-map -->
# <Feature Name>

One-line description of what this feature does.

## Overview

- Key behavior or capability #1
- Key behavior or capability #2
- Important constraint or rule

## Design

How this feature works from the player's perspective. What they see, what they do, what happens.

## Implementation Plan

### Iteration 0
What's the smallest testable proof of this mechanic?

### Full Implementation
- Step 1: [what to build]
- Step 2: [what to build]
- Step 3: [what to build]

## Code Index

Organize by module/system. Only include functions/symbols relevant to this feature.

| Function/Symbol | File | Purpose |
|---|---|---|
| `PlayerController.move()` | `src/player/controller.ts` | Handle tile-based movement input |
| `TileMap.render()` | `src/world/tilemap.ts` | Render the tile map |

## Game Data

Any relevant data structures, configs, or constants.

```typescript
// Example: NPC dialogue structure
{
  id: string,
  name: string,
  dialogue: string[],
  problem: { description: string, category: string }
}
```

## Dependencies

- **Uses**: [other features or systems this depends on]
- **Used by**: [features that depend on this]

## Status

- [ ] Iteration 0 complete
- [ ] Full implementation complete
- [ ] Playtested
- [ ] Doc finalized with code index

## Changes

- YYYY-MM-DD: Initial documentation (pre-build)
```

### Section Guide

| Section | Purpose | When to include |
|---|---|---|
| **Overview** | Quick-scan bullet points | Always |
| **Design** | Player-facing behavior | Always |
| **Implementation Plan** | Build approach | Pre-build (update post-build) |
| **Code Index** | File/function reference | Post-build |
| **Game Data** | Data structures, configs | When feature has game data |
| **Dependencies** | What uses/is used by this | Always |
| **Status** | Build progress checklist | Always |
| **Changes** | Change history | Always |

### Tags

Tags appear as HTML comments at the top of each feature doc. They enable grep-based search across docs.

| Tag | Purpose | Example |
|---|---|---|
| `@version` | Which game version this feature belongs to | `<!-- @version 0.1 -->` |
| `@systems` | Which game systems are involved | `<!-- @systems movement rendering npc -->` |
| `@tags` | Freeform keywords for searchability | `<!-- @tags player-movement tile-map camera -->` |

## Changelog Format

The `CHANGELOG.md` file records changes chronologically. Each entry links to the feature doc (if one exists) and uses `@features` tags for searchability.

### Entry Format

```markdown
## YYYY-MM-DD

### <Category>

- **<Short description>** — <Details>. @features <feature-name>
  - Files changed: `path/to/file.ts`, `path/to/other.ts`
```

### Categories

- **Added** — new features or capabilities
- **Changed** — modifications to existing behavior
- **Fixed** — bug fixes
- **Removed** — removed features or deprecated code
- **Documented** — documentation-only changes (no code change)
- **Design** — game design decisions or changes to the brief/roadmap

## Workflows

### Workflow 1: Building a New Feature

1. **Write the feature doc** — `docs/features/<feature-name>.md` using the template above. Fill in Overview, Design, and Implementation Plan.
2. **Get alignment** — Review the doc. Is the scope right? Does it fit the current version?
3. **Build iteration 0** — Smallest testable proof.
4. **Build the full feature** — Logic → UI → polish.
5. **Update the feature doc** — Fill in Code Index with actual file/function references. Check off Status items.
6. **Append to CHANGELOG.md** — Add entry with `@features` tag.

### Workflow 2: Documenting a Design Decision

1. **Update the relevant doc** — game brief, version roadmap, or architecture.
2. **Append to CHANGELOG.md** — Category: "Design".

### When NOT to Create a Feature Doc

- Config changes, dependency updates, one-line fixes — these get a CHANGELOG entry but no feature doc.
- Design-only changes — these update existing docs (brief, roadmap) and get a CHANGELOG entry.

## Searching Docs

Feature docs are designed to be searchable with grep:

```bash
# Find all features in a specific version
grep -r "@version 0.1" docs/features/

# Find all features involving a system
grep -r "@systems movement" docs/features/

# Find features by keyword
grep -r "@tags hiring" docs/features/

# Find changelog entries for a feature
grep -r "@features player-movement" CHANGELOG.md
```

## Naming Conventions

| Item | Convention | Example |
|---|---|---|
| Feature doc filename | `kebab-case.md` | `docs/features/player-movement.md` |
| System names in tags | lowercase, no hyphens | `@systems movement rendering npc` |
| Version in tags | number only | `@version 0.1` |
| Keywords in tags | kebab-case | `@tags tile-map player-movement` |

## Guidelines

- **Keep feature docs accurate** — if you change code referenced in a feature doc, update the doc.
- **One feature per doc** — don't combine unrelated features. If a feature spans multiple systems, list all of them.
- **Code index over prose** — tables are the most valuable part. Prose is for context.
- **Tags are for grep** — keep them consistent, don't overthink them.
- **CHANGELOG is append-only** — don't rewrite history. Add new entries at the top.
- **Game brief is living** — update it as design decisions are made. Mark resolved questions.
