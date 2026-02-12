# Ideation Rules

How to scope and plan before writing any code. This process runs at the start of every version.

## When This Applies

Before building any version (v0.1, v0.2, etc.), run through this process. The goal is to arrive at a clear, minimal scope and an iteration 0 — the smallest working proof of the version's core mechanic.

## Process

### 1. Identify the Core Mechanic

Every version has one core mechanic — the thing that makes it a distinct version. Ask:

- "What's the ONE new thing the player can do in this version?"
- "If I removed everything else from this version, what must survive?"
- "What would make someone say 'oh, that works' when they see it?"

The answer should be one sentence. If it's not, scope is too big.

### 2. Find Iteration 0

The most important question:

> "What is the smallest working proof of this version's core mechanic?"

Iteration 0 should be:
- **One sentence** to describe
- **Proves the core mechanic works**
- **Buildable in under an hour**

If you can't define iteration 0 clearly, the version scope is too broad — cut something.

**For the first version (v0.1):** There's no game yet. Iteration 0 is a standalone console/terminal proof — render a grid, move a symbol, detect adjacency, print text. No graphics, no engine, just proof of concept.

**For every version after that:** The previous version's game already exists. Iteration 0 is the new mechanic integrated into the existing game at its simplest — minimal UI, hardcoded data, no polish, but wired into what's already running.

**Example — v0.4 (The Team):**

The core mechanic is hiring. Here's how it breaks down:

- **v0.4.0 (iteration 0):** A hardcoded job posting and 2-3 hardcoded applicants appear in-game. Player picks one. Burn rate updates on the existing HUD. No job creation UI, no dynamic applicants — just proof that hiring connects to the economy system.
- **v0.4 (full version):** Player creates custom job postings with role and salary range. NPC applicants arrive dynamically over in-game time with randomized attributes. Full hire/reject flow. Employee roster panel.

Iteration 0 validates the mechanic with hardcoded data. The full version makes it dynamic and gives it a proper UI.

**Example — v0.1 (Walk & Talk):**

The core mechanic is exploration and NPC interaction. Since no game exists yet, iteration 0 is a standalone console proof:

- **v0.1.0 (iteration 0):** Console grid, move a text symbol with keyboard input, detect adjacency to an NPC tile, print their dialogue as text output.
- **v0.1 (full version):** Rendered tile map with sprites, animated player movement, camera follow, NPC sprites on the map, dialogue overlay UI.

**Red flag:** If your iteration 0 sounds like the full version, it's too big. Cut until there's a clear gap between the two.

### 3. Challenge Scope

For every bullet in the version's roadmap entry, ask:
- "Is this essential for the core mechanic, or is it polish?"
- "Can this be faked, hardcoded, or simplified for now?"
- "Would the version still make sense without this?"

If something isn't essential, push it to a later version or mark it as polish (built only if time allows).

### 4. Identify Shortcuts

Actively look for things to simplify:

- **Hardcode over dynamic** — Static NPC positions instead of a placement system. Fixed dialogue arrays instead of procedural generation.
- **Console over UI** — Prove logic works in the console before building a visual interface.
- **Fake over build** — Mock data instead of real systems. Placeholder art instead of final assets.
- **Single over multiple** — One NPC type before NPC variants. One map zone before multiple zones.
- **Manual over automatic** — Player triggers actions manually before building automation.

### 5. Write the Feature Doc

Once scope is clear, write the feature doc (`docs/features/<feature-name>.md`) with:
- What iteration 0 looks like
- What the full implementation includes
- What's been cut or deferred
- Acceptance criteria

This is the "contract" before building starts. Get alignment, then code.

## Scope Red Flags

If any of these appear in a version's scope, push back:

- Multiple new systems introduced at once (one system per version)
- "And also..." additions after the core mechanic is defined
- Features that require another unbuilt version's mechanics
- Anything described as "nice to have" or "while we're at it"
- UI polish before the core logic works

## Output

After running through this process, you should have:

1. **Core mechanic** — one sentence
2. **Iteration 0** — one sentence describing the smallest proof
3. **Scope** — clean bullet list (matches or trims the version roadmap entry)
4. **Cuts** — anything removed from the original roadmap entry for this version
5. **Feature doc** — written in `docs/features/` and ready for building
