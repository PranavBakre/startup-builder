# The Idea — Implementation Guide

> v0.2 idea-to-implementation document for Cortana (builder agent).
> Reference spec: [`the-idea.md`](the-idea.md)

---

## 1. Current State Analysis (v0.1 baseline)

### world.gd structure
- **Root node:** `Node2D` (World) with `y_sort_enabled = true`
- **Scene tree:** `World > Camera2D, TileMapLayer, CanvasLayer > {DialogueBox, InteractPrompt}`
- **Map:** 60×50 grid, `tile_map: Array` (2D), `TILE_SIZE = 320`
- **NPC data:** `npc_data: Array` of dicts with `id, name, position, dialogue, problem`
- **NPC refs:** `npcs: Array[NPC]` populated in `_spawn_npcs()`
- **Player ref:** `player: Player`

### Dialogue system
- **State vars:** `active_dialogue: NPC`, `dialogue_index: int`, `dialogue_char_index: int`, `dialogue_timer: float`
- **Flow:** `_try_interact()` → `_start_dialogue(npc)` → typewriter in `_process()` → `_advance_dialogue()` on input → `_end_dialogue()`
- **Input handling:** `_input()` checks `active_dialogue != null` to route to dialogue mode; returns early so movement is blocked
- **UI:** `DialogueBox` (Panel, bottom of screen), `NPCName` (Label), `DialogueText` (Label), `InteractPrompt` (Label, floating)

### NPC (npc.gd)
- `extends Area2D`, `class_name NPC`
- `setup(data)` stores `npc_id, npc_name, grid_pos, dialogue, problem`
- Loads texture from `res://assets/characters/npc_{id}.png`

### Player (player.gd)
- `extends Node2D`, `class_name Player`
- Grid movement with tween, `is_moving` flag, sprite flip

### Key observations
- **No game state singleton** — all state lives in world.gd
- **No `talked_to` tracking** — dialogue replays identically every time
- **`_end_dialogue()` does nothing** beyond hiding the box — perfect hook point
- **`_input()` has a clear modal pattern** — dialogue mode vs normal mode; journal will be a third mode
- **InteractPrompt is a CanvasLayer label** positioned in world coords — works but is hacky; the checkmark indicator will need a similar or better approach

---

## 2. Architecture Decisions

### GameState autoload: NO (defer to v0.3)
**Rationale:** v0.2 adds ~5 state variables. Extracting to an autoload now adds refactor risk with zero payoff — there's only one scene. v0.3 (save/load) is the natural extraction point. For now, all new state goes in `world.gd`.

### Journal UI: CanvasLayer child
The journal panel lives as a sibling to `DialogueBox` inside `CanvasLayer`. This keeps it screen-space and independent of camera zoom/position.

**Node path:** `World/CanvasLayer/JournalPanel`

### State location
All new state in `world.gd` top-level vars:
```gdscript
var discovered_problems: Array = []    # [{npc_id, npc_name, description, category}]
var talked_to: Dictionary = {}          # {npc_id: true}
var company_name: String = ""
var company_cash: int = 100000
var selected_problem: Dictionary = {}
var company_founded: bool = false
```

### Input mode pattern
`_input()` will use a priority chain:
1. If `active_dialogue != null` → dialogue mode (existing)
2. If `journal_open` → journal mode (new)
3. Else → normal mode (existing)

Journal is NOT a dialogue — it's a UI overlay with mouse interaction (buttons) + keyboard close (Tab/Escape).

---

## 3. Iteration 0 — Problem Collection + Founding Proof

**Goal:** Wire the core loop: dialogue → collect → journal → found → HUD. Plain UI, no polish.

### Step 0.1: Add state variables to world.gd

**File:** `game/scripts/world.gd`

Add after existing variable declarations (after `var prompt_bounce_time`):

```gdscript
# === v0.2 State ===
var discovered_problems: Array = []
var talked_to: Dictionary = {}
var company_name: String = ""
var company_cash: int = 100000
var selected_problem: Dictionary = {}
var company_founded: bool = false

# Journal state
var journal_open: bool = false
```

### Step 0.2: Collect problem on dialogue end

**File:** `game/scripts/world.gd`  
**Function:** `_end_dialogue()`

Replace the current `_end_dialogue()`:

```gdscript
func _end_dialogue():
	var npc = active_dialogue
	dialogue_box.visible = false
	active_dialogue = null
	dialogue_index = 0

	# Track that we've talked to this NPC
	if not talked_to.has(npc.npc_id):
		talked_to[npc.npc_id] = true
		# Collect problem
		if npc.problem.size() > 0:
			discovered_problems.append({
				"npc_id": npc.npc_id,
				"npc_name": npc.npc_name,
				"description": npc.problem.get("description", ""),
				"category": npc.problem.get("category", "")
			})

	_check_npc_proximity()
```

### Step 0.3: Re-talk shows short line

**File:** `game/scripts/world.gd`  
**Function:** `_start_dialogue()`

Replace current `_start_dialogue()`:

```gdscript
func _start_dialogue(npc: NPC):
	active_dialogue = npc
	dialogue_index = 0
	dialogue_char_index = 0
	dialogue_timer = 0.0
	interact_prompt.visible = false
	dialogue_box.visible = true
	npc_name_label.text = npc.npc_name

	# If already talked, show a short re-talk line
	if talked_to.has(npc.npc_id):
		# Temporarily override dialogue to single re-talk line
		active_dialogue_lines = ["We already talked about this."]
	else:
		active_dialogue_lines = npc.dialogue.duplicate()

	dialogue_text_label.text = ""
```

This requires a new variable and changes to how dialogue lines are accessed:

**Add variable** (near dialogue state vars):
```gdscript
var active_dialogue_lines: Array = []
```

**Update all references** from `active_dialogue.dialogue[dialogue_index]` to `active_dialogue_lines[dialogue_index]`:

1. In `_process()` typewriter section:
   - `active_dialogue.dialogue[dialogue_index].length()` → `active_dialogue_lines[dialogue_index].length()`
   - `active_dialogue.dialogue[dialogue_index]` → `active_dialogue_lines[dialogue_index]`

2. In `_advance_dialogue()`:
   - `active_dialogue.dialogue[dialogue_index].length()` → `active_dialogue_lines[dialogue_index].length()`
   - `active_dialogue.dialogue[dialogue_index]` → `active_dialogue_lines[dialogue_index]`
   - `active_dialogue.dialogue.size()` → `active_dialogue_lines.size()`

**Exact replacements in `_process()`:**
```
OLD: if active_dialogue != null and dialogue_char_index < active_dialogue.dialogue[dialogue_index].length():
NEW: if active_dialogue != null and dialogue_char_index < active_dialogue_lines[dialogue_index].length():

OLD: var full_text = active_dialogue.dialogue[dialogue_index]
NEW: var full_text = active_dialogue_lines[dialogue_index]
```

**Exact replacements in `_advance_dialogue()`:**
```
OLD: if dialogue_char_index < active_dialogue.dialogue[dialogue_index].length():
NEW: if dialogue_char_index < active_dialogue_lines[dialogue_index].length():

OLD: dialogue_text_label.text = active_dialogue.dialogue[dialogue_index]
NEW: dialogue_text_label.text = active_dialogue_lines[dialogue_index]

OLD: if dialogue_index < active_dialogue.dialogue.size():
NEW: if dialogue_index < active_dialogue_lines.size():
```

### Step 0.4: Journal UI (scene tree additions)

**File:** `game/scenes/world.tscn`

Add these nodes as children of `CanvasLayer` (can be done in code or .tscn — recommend **code** in `_ready()` for iteration speed).

**File:** `game/scripts/world.gd`

Add new `@onready` references at the top (won't use @onready since we're creating in code):

```gdscript
# Journal UI (created in _ready)
var journal_panel: Panel
var journal_vbox: VBoxContainer
var journal_title_label: Label
var journal_scroll: ScrollContainer
var journal_list: VBoxContainer
var company_name_input: LineEdit
var founding_npc_id: String = ""
```

**In `_ready()`**, after existing code, add:

```gdscript
	_create_journal_ui()
	_create_hud()
```

**New function `_create_journal_ui()`:**

```gdscript
func _create_journal_ui():
	# Main panel — full screen overlay with margin
	journal_panel = Panel.new()
	journal_panel.visible = false
	journal_panel.anchors_preset = Control.PRESET_FULL_RECT  # 15
	journal_panel.anchor_right = 1.0
	journal_panel.anchor_bottom = 1.0
	journal_panel.offset_left = 40.0
	journal_panel.offset_top = 40.0
	journal_panel.offset_right = -40.0
	journal_panel.offset_bottom = -40.0
	$CanvasLayer.add_child(journal_panel)

	var margin = MarginContainer.new()
	margin.anchors_preset = Control.PRESET_FULL_RECT
	margin.anchor_right = 1.0
	margin.anchor_bottom = 1.0
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	journal_panel.add_child(margin)

	journal_vbox = VBoxContainer.new()
	journal_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	journal_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(journal_vbox)

	# Title
	journal_title_label = Label.new()
	journal_title_label.text = "Problem Journal"
	journal_vbox.add_child(journal_title_label)

	# Scrollable list area
	journal_scroll = ScrollContainer.new()
	journal_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	journal_vbox.add_child(journal_scroll)

	journal_list = VBoxContainer.new()
	journal_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	journal_scroll.add_child(journal_list)

	# Company name input (hidden by default)
	company_name_input = LineEdit.new()
	company_name_input.visible = false
	company_name_input.placeholder_text = "Enter company name..."
	company_name_input.text_submitted.connect(_on_company_name_submitted)
	journal_vbox.add_child(company_name_input)
```

### Step 0.5: Journal open/close + population

**File:** `game/scripts/world.gd`

**In `_input()`**, add journal toggle BEFORE the dialogue check:

```gdscript
func _input(event):
	# Journal toggle (Tab key) — blocked during dialogue
	if event is InputEventKey and event.pressed and event.keycode == KEY_TAB:
		if active_dialogue == null:
			if journal_open:
				_close_journal()
			else:
				_open_journal()
			return

	# Close journal with Escape
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if journal_open:
			if company_name_input.visible:
				# Cancel naming
				company_name_input.visible = false
				company_name_input.text = ""
				founding_npc_id = ""
			else:
				_close_journal()
			return

	if active_dialogue != null:
		# ... existing dialogue input handling
```

**Important:** The existing `_input()` function's dialogue check and everything after it stays the same. We're inserting the journal checks at the top.

Also block movement when journal is open. In `_process()`, change the movement condition:

```
OLD: if active_dialogue == null and player and not player.is_moving:
NEW: if active_dialogue == null and not journal_open and player and not player.is_moving:
```

**New functions:**

```gdscript
func _open_journal():
	journal_open = true
	journal_panel.visible = true
	_populate_journal()

func _close_journal():
	journal_open = false
	journal_panel.visible = false
	company_name_input.visible = false
	company_name_input.text = ""
	founding_npc_id = ""

func _populate_journal():
	# Clear existing entries
	for child in journal_list.get_children():
		child.queue_free()

	if discovered_problems.size() == 0:
		var empty_label = Label.new()
		empty_label.text = "No problems discovered yet"
		journal_list.add_child(empty_label)
		return

	for problem in discovered_problems:
		var row = HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var text_label = Label.new()
		text_label.text = problem.npc_name + ": " + problem.description
		text_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(text_label)

		if not company_founded:
			var found_btn = Button.new()
			found_btn.text = "Found Company"
			found_btn.pressed.connect(_on_found_company_pressed.bind(problem.npc_id))
			row.add_child(found_btn)

		journal_list.add_child(row)

func _on_found_company_pressed(npc_id: String):
	founding_npc_id = npc_id
	company_name_input.visible = true
	company_name_input.text = ""
	company_name_input.grab_focus()

func _on_company_name_submitted(text: String):
	if text.strip_edges().length() == 0:
		return
	company_name = text.strip_edges()
	company_founded = true
	# Find the selected problem
	for p in discovered_problems:
		if p.npc_id == founding_npc_id:
			selected_problem = p
			break
	founding_npc_id = ""
	company_name_input.visible = false
	_close_journal()
	_update_hud()
```

### Step 0.6: Basic HUD

**File:** `game/scripts/world.gd`

```gdscript
# HUD references (created in _ready)
var hud_panel: Panel
var hud_company_label: Label
var hud_cash_label: Label
```

**New function `_create_hud()`:**

```gdscript
func _create_hud():
	hud_panel = Panel.new()
	hud_panel.visible = false
	hud_panel.anchors_preset = Control.PRESET_TOP_WIDE  # 10
	hud_panel.anchor_right = 1.0
	hud_panel.offset_bottom = 40.0
	$CanvasLayer.add_child(hud_panel)

	hud_company_label = Label.new()
	hud_company_label.anchors_preset = Control.PRESET_CENTER_LEFT
	hud_company_label.offset_left = 10.0
	hud_company_label.text = ""
	hud_panel.add_child(hud_company_label)

	hud_cash_label = Label.new()
	hud_cash_label.anchors_preset = Control.PRESET_CENTER_RIGHT
	hud_cash_label.offset_right = -10.0
	hud_cash_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hud_cash_label.text = ""
	hud_panel.add_child(hud_cash_label)

func _update_hud():
	if company_founded:
		hud_panel.visible = true
		hud_company_label.text = company_name
		hud_cash_label.text = "$" + str(company_cash)
	else:
		hud_panel.visible = false
```

### Step 0.7: Wire Tab input action

Godot needs the `Tab` key mapped. Since we're using raw `InputEventKey` checks (not action names), no project.godot change is needed — the `KEY_TAB` check in `_input()` handles it directly.

Similarly, the `interact` action must already be mapped to `C`. Verify in `project.godot` that `interact` action exists (it does from v0.1).

### Files modified summary (Iteration 0)

| File | Changes |
|---|---|
| `game/scripts/world.gd` | Add state vars, `active_dialogue_lines`, modify `_start_dialogue()`, `_end_dialogue()`, `_advance_dialogue()`, `_process()`, `_input()`. Add `_create_journal_ui()`, `_create_hud()`, `_open_journal()`, `_close_journal()`, `_populate_journal()`, `_on_found_company_pressed()`, `_on_company_name_submitted()`, `_update_hud()` |

No new files. No scene tree changes (all UI created in code).

### Iteration 0 Acceptance Criteria

- [ ] Talk to NPC → dialogue plays → problem added to `discovered_problems`
- [ ] Re-talk to same NPC → shows "We already talked about this." (single line)
- [ ] Press Tab → journal panel opens showing collected problems
- [ ] Journal shows "No problems discovered yet" when empty
- [ ] Press Tab or Escape → journal closes
- [ ] Movement blocked while journal is open
- [ ] Click "Found Company" → LineEdit appears for company name
- [ ] Type name + Enter → company founded, journal closes
- [ ] Escape while naming → cancels naming (doesn't close journal)
- [ ] Empty name rejected (nothing happens)
- [ ] HUD appears at top with company name + $100,000
- [ ] HUD hidden before founding
- [ ] v0.1 still works: movement, collision, zoom, dialogue, NPC proximity prompt

---

## 4. Iteration 1 — Journal UI + NPC Dialogue Layers

**Goal:** Styled journal, proper NPC follow-up/post-founding lines, "Founded!" confirmation.

### Step 1.1: Add NPC dialogue data

**File:** `game/scripts/world.gd`  
**In `npc_data` array**, add `follow_up` and `post_founding` to each NPC dict:

```gdscript
# Alex
"follow_up": "Any luck with that expense tracking idea?",
"post_founding": "Nice, you started a company! Hope it works out."

# Jordan
"follow_up": "Still thinking about that research notes problem?",
"post_founding": "Oh cool, you founded a company! Good luck with it."

# Maya
"follow_up": "I'm still waiting for a simple online ordering solution...",
"post_founding": "You started a company? That's exciting! Come back for cake."

# Sam
"follow_up": "Still looking for that affordable booking tool, you know anyone?",
"post_founding": "A startup, huh? Let me know if you need a haircut to celebrate."

# Priya
"follow_up": "The parent communication situation hasn't improved, sadly.",
"post_founding": "You founded a company! I hope it helps people like me."
```

### Step 1.2: Store follow_up/post_founding on NPC

**File:** `game/scripts/npc.gd`

Add new vars:
```gdscript
var follow_up: String = ""
var post_founding: String = ""
```

In `setup()`, add:
```gdscript
	follow_up = data.get("follow_up", "We already talked about this.")
	post_founding = data.get("post_founding", "Good luck with your company!")
```

### Step 1.3: Multi-layer dialogue logic

**File:** `game/scripts/world.gd`  
**Function:** `_start_dialogue()`

Replace the re-talk logic from iteration 0 with proper layers:

```gdscript
func _start_dialogue(npc: NPC):
	active_dialogue = npc
	dialogue_index = 0
	dialogue_char_index = 0
	dialogue_timer = 0.0
	interact_prompt.visible = false
	dialogue_box.visible = true
	npc_name_label.text = npc.npc_name

	if company_founded:
		# Post-founding: always show post_founding line
		active_dialogue_lines = [npc.post_founding]
	elif talked_to.has(npc.npc_id):
		# Re-talk: show follow_up line
		active_dialogue_lines = [npc.follow_up]
	else:
		# First talk: full dialogue
		active_dialogue_lines = npc.dialogue.duplicate()

	dialogue_text_label.text = ""
```

### Step 1.4: Style the journal panel

**File:** `game/scripts/world.gd`  
**Function:** `_create_journal_ui()`

Apply styling via `StyleBoxFlat` in code:

```gdscript
func _create_journal_ui():
	journal_panel = Panel.new()
	journal_panel.visible = false
	journal_panel.anchors_preset = Control.PRESET_FULL_RECT
	journal_panel.anchor_right = 1.0
	journal_panel.anchor_bottom = 1.0
	journal_panel.offset_left = 60.0
	journal_panel.offset_top = 60.0
	journal_panel.offset_right = -60.0
	journal_panel.offset_bottom = -60.0

	# Dark semi-transparent background
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.1, 0.15, 0.95)
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_left = 8
	panel_style.corner_radius_bottom_right = 8
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color(0.3, 0.3, 0.4)
	journal_panel.add_theme_stylebox_override("panel", panel_style)
	$CanvasLayer.add_child(journal_panel)

	# ... rest same as iteration 0 but with styled title
```

**Update `_populate_journal()` to show styled cards:**

```gdscript
func _populate_journal():
	for child in journal_list.get_children():
		child.queue_free()

	if discovered_problems.size() == 0:
		var empty_label = Label.new()
		empty_label.text = "No problems discovered yet"
		empty_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		journal_list.add_child(empty_label)
		return

	for problem in discovered_problems:
		var card = PanelContainer.new()
		var card_style = StyleBoxFlat.new()
		card_style.bg_color = Color(0.15, 0.15, 0.2, 0.9)
		card_style.corner_radius_top_left = 4
		card_style.corner_radius_top_right = 4
		card_style.corner_radius_bottom_left = 4
		card_style.corner_radius_bottom_right = 4
		card_style.content_margin_left = 12.0
		card_style.content_margin_top = 8.0
		card_style.content_margin_right = 12.0
		card_style.content_margin_bottom = 8.0

		# Highlight selected problem
		if company_founded and selected_problem.get("npc_id") == problem.npc_id:
			card_style.border_width_left = 2
			card_style.border_width_top = 2
			card_style.border_width_right = 2
			card_style.border_width_bottom = 2
			card_style.border_color = Color(0.2, 0.8, 0.4)

		card.add_theme_stylebox_override("panel", card_style)

		var row = HBoxContainer.new()

		var info_vbox = VBoxContainer.new()
		info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var name_label = Label.new()
		name_label.text = problem.npc_name
		name_label.add_theme_color_override("font_color", Color(0.9, 0.7, 0.3))
		info_vbox.add_child(name_label)

		var desc_label = Label.new()
		desc_label.text = problem.description
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		info_vbox.add_child(desc_label)

		var cat_label = Label.new()
		cat_label.text = "[" + problem.category + "]"
		cat_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.7))
		info_vbox.add_child(cat_label)

		row.add_child(info_vbox)

		if not company_founded:
			var found_btn = Button.new()
			found_btn.text = "Found Company"
			found_btn.pressed.connect(_on_found_company_pressed.bind(problem.npc_id))
			row.add_child(found_btn)

		card.add_child(row)
		journal_list.add_child(card)
```

### Step 1.5: "Founded!" confirmation text

**File:** `game/scripts/world.gd`

Add a Label for the confirmation, created in `_ready()`:

```gdscript
var founded_label: Label
```

In `_create_hud()` (or separate function):

```gdscript
	founded_label = Label.new()
	founded_label.visible = false
	founded_label.text = "Founded!"
	founded_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	founded_label.anchors_preset = Control.PRESET_CENTER
	founded_label.add_theme_font_size_override("font_size", 48)
	founded_label.add_theme_color_override("font_color", Color(0.2, 0.9, 0.4))
	$CanvasLayer.add_child(founded_label)
```

In `_on_company_name_submitted()`, after setting `company_founded = true`:

```gdscript
	# Show "Founded!" briefly
	founded_label.visible = true
	var tween = create_tween()
	tween.tween_interval(1.5)
	tween.tween_property(founded_label, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func(): founded_label.visible = false; founded_label.modulate.a = 1.0)
```

### Step 1.6: Company name input cancel support

Already handled in iteration 0's `_input()` Escape logic. Verify it works with the LineEdit having focus (LineEdit consumes Escape by default — may need `company_name_input.set_process_unhandled_key_input(false)` or handle via `gui_input` signal).

**Potential issue:** LineEdit may consume the Escape key before `_input()` sees it. Fix: connect to LineEdit's `gui_input` signal:

```gdscript
# In _create_journal_ui(), after creating company_name_input:
company_name_input.gui_input.connect(_on_name_input_gui)
```

```gdscript
func _on_name_input_gui(event: InputEvent):
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		company_name_input.visible = false
		company_name_input.text = ""
		founding_npc_id = ""
		get_viewport().set_input_as_handled()
```

### Files modified summary (Iteration 1)

| File | Changes |
|---|---|
| `game/scripts/world.gd` | Add follow_up/post_founding to npc_data, restyle journal, add founded_label, update `_start_dialogue()` layering, add `_on_name_input_gui()` |
| `game/scripts/npc.gd` | Add `follow_up`, `post_founding` vars, store in `setup()` |

### Iteration 1 Acceptance Criteria

- [ ] Journal has dark styled background with rounded corners
- [ ] Problem cards show NPC name (gold), description, category tag
- [ ] Re-talking NPC plays their specific `follow_up` line (not generic)
- [ ] After founding, talking to any NPC plays their `post_founding` line
- [ ] "Founded!" text appears center-screen after founding, fades out after ~2s
- [ ] Escape while in LineEdit cancels naming without closing journal
- [ ] Selected problem highlighted with green border in journal after founding
- [ ] "Found Company" buttons gone after founding

---

## 5. Iteration 2 — HUD + Map Polish

**Goal:** Styled HUD bar, checkmark indicators on collected NPCs, journal post-founding polish.

### Step 2.1: Style the HUD bar

**File:** `game/scripts/world.gd`  
**Function:** `_create_hud()` — replace with styled version:

```gdscript
func _create_hud():
	hud_panel = Panel.new()
	hud_panel.visible = false
	hud_panel.anchor_right = 1.0
	hud_panel.offset_bottom = 50.0

	var hud_style = StyleBoxFlat.new()
	hud_style.bg_color = Color(0.08, 0.08, 0.12, 0.9)
	hud_style.border_width_bottom = 2
	hud_style.border_color = Color(0.2, 0.2, 0.3)
	hud_panel.add_theme_stylebox_override("panel", hud_style)
	$CanvasLayer.add_child(hud_panel)

	var hbox = HBoxContainer.new()
	hbox.anchors_preset = Control.PRESET_FULL_RECT
	hbox.anchor_right = 1.0
	hbox.anchor_bottom = 1.0
	hbox.add_theme_constant_override("separation", 0)
	hud_panel.add_child(hbox)

	var left_margin = MarginContainer.new()
	left_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_margin.add_theme_constant_override("margin_left", 16)
	hbox.add_child(left_margin)

	hud_company_label = Label.new()
	hud_company_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hud_company_label.add_theme_font_size_override("font_size", 20)
	hud_company_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95))
	left_margin.add_child(hud_company_label)

	var right_margin = MarginContainer.new()
	right_margin.add_theme_constant_override("margin_right", 16)
	hbox.add_child(right_margin)

	hud_cash_label = Label.new()
	hud_cash_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hud_cash_label.add_theme_font_size_override("font_size", 20)
	hud_cash_label.add_theme_color_override("font_color", Color(0.3, 0.9, 0.4))
	right_margin.add_child(hud_cash_label)
```

### Step 2.2: Checkmark indicator on collected NPCs

**Approach:** Add a `Label` (or `Sprite2D`) child to each NPC node showing "✓" above their head. Managed from `world.gd` since world owns the `talked_to` state.

**File:** `game/scripts/npc.gd`

Add checkmark node:

```gdscript
var checkmark: Label = null

func show_checkmark():
	if checkmark != null:
		return
	checkmark = Label.new()
	checkmark.text = "✓"
	checkmark.add_theme_font_size_override("font_size", 64)
	checkmark.add_theme_color_override("font_color", Color(0.2, 0.9, 0.4))
	checkmark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	checkmark.position = Vector2(-20, -TILE_SIZE * 0.7)
	add_child(checkmark)
```

**File:** `game/scripts/world.gd`

Call `show_checkmark()` when a problem is collected. In `_end_dialogue()`, after adding to `discovered_problems`:

```gdscript
		# Show checkmark on NPC
		npc.show_checkmark()
```

Also update `_check_npc_proximity()` — if NPC already talked to, don't show "Press C to chat" (or change text). Actually per spec: "replaces the 'Press C' prompt when adjacent and already collected". Update:

```gdscript
func _check_npc_proximity():
	var adjacent_npc = _get_adjacent_npc()
	if adjacent_npc != null:
		if not interact_prompt.visible:
			prompt_bounce_time = 0.0
		# Change prompt text for already-talked NPCs
		if talked_to.has(adjacent_npc.npc_id):
			interact_prompt.text = "Press C to chat again"
		else:
			interact_prompt.text = "Press C to chat"
		interact_prompt.visible = true
		# ... existing positioning code unchanged
```

### Step 2.3: Journal post-founding behavior

Already handled in iteration 1's `_populate_journal()`:
- Selected problem has green border
- "Found Company" buttons removed when `company_founded`

Add a label at top of journal showing company info when founded:

In `_populate_journal()`, after clearing children, before the empty check:

```gdscript
	if company_founded:
		var company_info = Label.new()
		company_info.text = "Company: " + company_name + " | Problem: " + selected_problem.get("description", "")
		company_info.add_theme_color_override("font_color", Color(0.2, 0.9, 0.4))
		company_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		journal_list.add_child(company_info)

		var separator = HSeparator.new()
		journal_list.add_child(separator)
```

### Files modified summary (Iteration 2)

| File | Changes |
|---|---|
| `game/scripts/world.gd` | Restyle HUD, update `_check_npc_proximity()` prompt text, add company info to journal, call `npc.show_checkmark()` |
| `game/scripts/npc.gd` | Add `show_checkmark()` function, `checkmark` var |

### Iteration 2 Acceptance Criteria

- [ ] HUD bar at top: dark background, company name left, cash right (green), styled
- [ ] HUD only visible after founding
- [ ] Collected NPCs show green "✓" above their head on the map
- [ ] Checkmark persists (doesn't disappear when walking away)
- [ ] Adjacent to collected NPC shows "Press C to chat again" instead of "Press C to chat"
- [ ] Journal shows company info header when founded
- [ ] "Found Company" buttons absent after founding
- [ ] Selected problem card highlighted with green border
- [ ] All v0.1 features still work: movement, collision, zoom, dialogue, NPC interaction

---

## 6. Risk/Complexity Notes

### High Risk
1. **LineEdit focus/input stealing** — Godot's LineEdit captures keyboard input when focused. The Tab key, Escape key, and arrow keys may be consumed by the LineEdit instead of reaching `_input()`. **Mitigation:** Use `gui_input` signal on LineEdit for Escape handling. Test Tab behavior when LineEdit is focused.

2. **`active_dialogue_lines` refactor** — Changing from `active_dialogue.dialogue[i]` to `active_dialogue_lines[i]` touches the core dialogue loop. A typo breaks all dialogue. **Mitigation:** Test first-talk, re-talk, and post-founding talk for every NPC.

### Medium Risk
3. **Journal UI created in code** — No visual editor preview. Layout bugs won't be visible until runtime. **Mitigation:** Test at multiple window sizes. Consider moving to .tscn in a polish pass.

4. **Checkmark positioning** — The `Label` at `position = Vector2(-20, -TILE_SIZE * 0.7)` may look wrong at different zoom levels since it's a child of the NPC (world-space). **Mitigation:** Test at zoom 0.1, 0.5, 1.0.

5. **`_populate_journal()` rebuilds on every open** — `queue_free()` on old children is async. If journal is opened rapidly, stale children may appear briefly. **Mitigation:** Low risk with 5 items max. If flickering occurs, use `free()` instead or maintain children.

### Low Risk
6. **Button `pressed` signal with `bind()`** — Standard Godot pattern, but buttons are recreated each journal open. No cleanup needed since `queue_free()` handles disconnection.

7. **No save/load** — Game state resets on restart. Acceptable for v0.2; v0.3 addresses this.

### What could break v0.1
- Modifying `_input()` flow incorrectly could break dialogue or movement
- Changing dialogue line access pattern could break typewriter effect
- Adding children to CanvasLayer could affect DialogueBox/InteractPrompt z-ordering

### Testing checklist
- [ ] Walk around, collide with walls — movement unchanged
- [ ] Talk to each NPC — full dialogue plays, problem collected
- [ ] Re-talk each NPC — follow-up line plays (not full dialogue)
- [ ] Open journal before talking to anyone — "No problems discovered"
- [ ] Open journal after collecting — problems listed
- [ ] Found company — HUD appears, journal updates
- [ ] Talk to NPCs after founding — post-founding line
- [ ] Zoom in/out — HUD stays fixed, checkmarks visible
- [ ] Rapid Tab pressing — journal opens/closes cleanly

---

## 7. Full Acceptance Criteria Reference

### Iteration 0 — ✅ when:
- [ ] Problem auto-collected on first dialogue completion
- [ ] Re-talk shows generic "already talked" line
- [ ] Tab opens/closes plain journal
- [ ] Empty journal shows placeholder text
- [ ] "Found Company" button → name input → founding
- [ ] Basic HUD (company name + $100,000)
- [ ] Movement blocked during journal
- [ ] v0.1 features unbroken

### Iteration 1 — ✅ when:
- [ ] Styled dark journal with problem cards (name, desc, category)
- [ ] NPC-specific follow_up dialogue on re-talk
- [ ] NPC-specific post_founding dialogue after founding
- [ ] "Founded!" text with fade-out
- [ ] Escape cancels naming without closing journal
- [ ] Selected problem highlighted in journal

### Iteration 2 — ✅ when:
- [ ] Styled HUD bar (dark bg, white company name, green cash)
- [ ] Green checkmark above collected NPCs
- [ ] Prompt text changes for collected NPCs
- [ ] Journal shows company info header after founding
- [ ] All 15 acceptance criteria from the-idea.md spec pass

---

## Changes

- 2026-02-14: Initial implementation guide (pre-build)
