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

NPCs have three dialogue layers:

- **First talk:** Full dialogue plays (surfaces the problem). Problem auto-collected on completion.
- **Re-talk:** A short 1-line follow-up plays instead (e.g. "Any thoughts on that ordering problem?"). No re-collection.
- **After founding:** NPC acknowledges the player's company with a 1-line reaction (e.g. "Nice, you started a company! Good luck."). Same line every time.

### Map Indicators

- NPCs whose problem has been collected show a green "✓" checkmark above their head
- Adjacent to collected NPCs, prompt reads "Press C to chat again" instead of "Press C to chat"
- Persistent controls hint at bottom-right: "C: Chat | Tab: Journal"

## Code Index

### Files Modified

| File | Changes |
|---|---|
| `game/scripts/world.gd` | State vars, journal UI, HUD, controls hint, problem collection, 3-layer dialogue, founding flow, prompt positioning fix |
| `game/scripts/npc.gd` | Added `follow_up`, `post_founding` vars + `show_checkmark()` |

### State Variables (world.gd)

```gdscript
var discovered_problems: Array = []    # [{npc_id, npc_name, description, category}]
var talked_to: Dictionary = {}          # {npc_id: true}
var company_name: String = ""
var company_cash: int = 100000
var selected_problem: Dictionary = {}
var company_founded: bool = false
var journal_open: bool = false
```

### NPC Data (world.gd npc_data)

Each NPC dict now includes:
```gdscript
"follow_up": "Any luck with that expense tracking idea?",
"post_founding": "Nice, you started a company! Hope it works out."
```

### NPC Script (npc.gd)

Added:
```gdscript
var follow_up: String = ""
var post_founding: String = ""
func show_checkmark()  # Adds green "✓" Label above NPC sprite
```

### Key Functions (world.gd)

| Function | Purpose |
|---|---|
| `_create_journal_ui()` | Builds styled journal panel in code (dark bg, rounded corners) |
| `_open_journal()` / `_close_journal()` | Toggle journal visibility + populate |
| `_populate_journal()` | Clears and rebuilds problem cards; shows company info header if founded |
| `_on_found_company_pressed(npc_id)` | Shows company name LineEdit |
| `_on_company_name_submitted(text)` | Founds company, closes journal, shows HUD + "Founded!" tween |
| `_on_name_input_gui(event)` | Handles Escape in LineEdit via gui_input signal |
| `_create_hud()` | Builds styled HUD bar + "Founded!" label |
| `_update_hud()` | Shows/hides HUD with company name and cash |
| `_create_controls_hint()` | Persistent bottom-right keybindings hint |
| `_on_dialogue_ended(npc)` | Tracks talked_to, collects problem, shows checkmark |
| `_try_interact()` | 3-layer dialogue selection (first talk / follow_up / post_founding) |
| `_check_npc_proximity()` | World-to-screen coordinate conversion for prompt; dynamic prompt text |

### Input Handling

`_input()` priority chain:
1. Tab → toggle journal (blocked during dialogue)
2. Escape → close journal or cancel naming
3. Dialogue active → advance dialogue
4. Journal open → block other input
5. Normal → interact, camera zoom

Movement blocked during both dialogue and journal (`_process()`).

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

- [x] Completing an NPC's dialogue for the first time adds their problem to the journal
- [x] Re-talking to an NPC plays a follow-up line instead of repeating the problem
- [x] Pressing Tab opens the problem journal panel
- [x] Journal lists all collected problems with NPC name, description, and category
- [x] Journal shows "No problems discovered yet" when empty
- [x] Selecting a problem prompts for a company name
- [x] Entering a name and confirming founds the company
- [x] Cancel (Escape) aborts founding without side effects
- [x] A "Founded!" confirmation appears briefly after founding
- [x] HUD shows company name and $100,000 after founding
- [x] HUD is not visible before founding
- [x] After founding, journal still works but "Found Company" buttons are gone
- [x] After founding, NPCs give a post-founding acknowledgment line
- [x] Collected NPCs show a checkmark indicator on the map
- [x] The game still runs and v0.1 features (movement, collision, zoom, dialogue) are unbroken

## Changes

- 2026-02-13: Initial documentation (pre-build)
- 2026-02-13: Design discussions — mobile controls deferred to v0.3, no name validation, founding irreversible, GameState autoload deferred to v0.3
- 2026-02-16: v0.2 implementation complete — all 3 iterations built, all acceptance criteria met
