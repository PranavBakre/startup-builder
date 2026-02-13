<!-- @version 0.2 -->
<!-- @systems problem-journal company-founding hud npc-dialogue -->
<!-- @tags problem-collection problem-selection company-naming economy hud -->
# The Idea

The player collects startup problems from NPC conversations and picks one to found a company.

## Overview

- Talking to an NPC for the first time auto-collects their problem into a problem journal
- Press Tab to open the journal and review collected problems
- Select a problem and name the company to found it
- A persistent HUD shows company name and starting capital ($100,000)
- Re-talking to an NPC gives a short follow-up instead of repeating the problem

## Design

### Problem Collection

When the player finishes an NPC's dialogue for the first time, their problem is automatically added to the journal. No explicit "collect" action — hearing about the problem IS collecting it.

Each problem entry stores:
- **Problem description** — one-sentence summary (from NPC's `problem.description`)
- **Category** — e.g. "productivity", "local-business", "education" (from NPC's `problem.category`)
- **Source NPC** — who told you about it
- **Discovered** — whether the player has heard this problem (persists across re-talks)

The player can collect 0–5 problems (one per NPC). There's no requirement to collect all before founding.

### Problem Journal (Tab)

Press Tab to open the journal panel. It shows:
- List of all discovered problems (or "No problems discovered yet" if empty)
- Each entry: NPC name, problem description, category
- A "Found Company" button next to each problem
- Close with Tab or Escape

The journal is a simple vertical list — no pagination, filtering, or sorting needed with 5 entries max.

### Company Founding

Selecting a problem and pressing "Found Company":
1. A text input appears for the company name
2. Player types a name and presses Enter (or cancels with Escape)
3. A brief "Founded!" confirmation appears on screen
4. The journal closes
5. The HUD activates with the company name and $100,000

Founding is a one-time action. Once founded, the journal shows which problem was selected but the "Found Company" buttons disappear. The player can still review their collected problems.

### HUD

A persistent bar at the top of the screen showing:
- Company name (left-aligned)
- Cash balance: $100,000 (right-aligned)

The HUD only appears after the company is founded. Before founding, no HUD is visible.

The cash balance is static in v0.2 — no income or expenses exist yet (v0.3 introduces the economy tick).

### Multi-layer NPC Dialogue

NPCs currently have a flat `dialogue` array that plays once. v0.2 changes this:

- **First talk:** Full dialogue plays (surfaces the problem). Problem auto-collected on completion.
- **Re-talk:** A short 1-line follow-up plays instead (e.g. "Any thoughts on that ordering problem?"). No re-collection.
- **After founding:** NPC acknowledges the player's company with a 1-line reaction (e.g. "Nice, you started a company! Good luck."). Same line every time.

This requires adding `follow_up` and `post_founding` fields to NPC data.

### Map Indicators

- NPCs whose problem has been collected show a small checkmark icon above their head (replaces the "Press C" prompt when adjacent and already collected)
- No other map changes in v0.2

## Implementation Plan

### Iteration 0 — Problem Collection + Founding Proof

**Core mechanic proof wired into the existing game.**

Integrate into the existing v0.1 game at its simplest:
1. Add a `discovered_problems: Array` to world.gd
2. On `_end_dialogue()`, if the NPC's problem hasn't been collected yet, add it to the array
3. Press Tab → show a simple Panel listing collected problems (plain Labels, no styling)
4. Each problem row has a "Found Company" button
5. Clicking it → hardcoded text input for company name → pressing Enter stores the name
6. Two Labels appear at the top of the screen: company name + "$100,000"
7. Re-talking to an NPC whose problem is already collected shows a hardcoded "We already talked about this" line

**What iteration 0 does NOT have:**
- No styled journal UI (plain Labels only)
- No categories displayed
- No "Founded!" animation or confirmation
- No post-founding NPC dialogue changes
- No checkmark indicators on NPCs
- No "close journal" polish

**Proves:** Problems collect from dialogue → journal displays them → player selects and founds → HUD shows result.

### Iteration 1 — Journal UI + NPC Dialogue Layers

1. Style the journal panel (dark background, problem cards, category labels, NPC source)
2. Add NPC `follow_up` dialogue for re-talks
3. Add NPC `post_founding` dialogue line
4. Track first-talk vs re-talk state per NPC
5. "Founded!" text confirmation on screen (brief, fades out)
6. Company name input with cancel support (Escape)

### Iteration 2 — HUD + Map Polish

1. Persistent HUD bar (top of screen, styled, company name + cash)
2. Checkmark icon above NPCs whose problem has been collected
3. Journal shows which problem was selected (highlight or label)
4. Disable "Found Company" buttons after founding
5. Journal accessible before and after founding (review-only after)

## Data Changes

### NPC Data (world.gd)

Current structure:
```gdscript
{
  "id": "alex",
  "name": "Alex",
  "position": Vector2i(25, 23),
  "dialogue": ["Line 1", "Line 2", ...],
  "problem": { "description": "...", "category": "productivity" }
}
```

v0.2 additions:
```gdscript
{
  ...
  "follow_up": "Any luck with that expense tracking idea?",
  "post_founding": "Nice, you started a company! Hope it works out."
}
```

### Game State (world.gd)

New state variables:
```gdscript
var discovered_problems: Array = []   # Array of problem dicts
var company_name: String = ""          # Empty until founded
var company_cash: int = 100000         # Starting capital
var selected_problem: Dictionary = {}  # The chosen problem
var talked_to: Dictionary = {}         # { npc_id: true } tracks first-talk
```

## Deferred / Cut

| Item | Reason | Where it lives |
|---|---|---|
| Problem categories/filtering | Only 5 problems — list is enough | Maybe v0.4+ |
| NPC reactions to company founding (beyond 1 line) | Scope creep | Maybe v0.3+ |
| Save/load game state | v0.3 core mechanic | v0.3 roadmap |
| Economy tick (burn rate, expenses) | v0.3 core mechanic | v0.3 roadmap |
| Animated founding sequence | Polish, not core | Later |
| Problem difficulty/complexity ratings | Not needed until product building (v0.6) | v0.6 roadmap |

## Acceptance Criteria (Full v0.2)

- [ ] Completing an NPC's dialogue for the first time adds their problem to the journal
- [ ] Re-talking to an NPC plays a follow-up line instead of repeating the problem
- [ ] Pressing Tab opens the problem journal panel
- [ ] Journal lists all collected problems with NPC name, description, and category
- [ ] Journal shows "No problems discovered yet" when empty
- [ ] Selecting a problem prompts for a company name
- [ ] Entering a name and confirming founds the company
- [ ] Cancel (Escape) aborts founding without side effects
- [ ] A "Founded!" confirmation appears briefly after founding
- [ ] HUD shows company name and $100,000 after founding
- [ ] HUD is not visible before founding
- [ ] After founding, journal still works but "Found Company" buttons are gone
- [ ] After founding, NPCs give a post-founding acknowledgment line
- [ ] Collected NPCs show a checkmark indicator on the map
- [ ] The game still runs and v0.1 features (movement, collision, zoom, dialogue) are unbroken

## Changes

- 2026-02-13: Initial documentation (pre-build)
- 2026-02-13: Design discussion — mobile controls (Tab to open journal) deferred to v0.3 which will add virtual joystick + on-screen buttons for all interactions
- 2026-02-13: Design discussion — company name accepts any input, no validation or profanity filter (profanity filter deferred to v2)
- 2026-02-13: Design discussion — founding is intentionally irreversible, no undo or confirmation dialog (undo deferred to v2)
- 2026-02-13: Design discussion — considering extracting game state from world.gd into a GameState autoload singleton to centralize persistent state and simplify v0.3 save/load (decision pending)
