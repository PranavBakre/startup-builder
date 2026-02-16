extends Node2D

const TileType = MapGenerator.TileType

# Tile size in pixels
const TILE_SIZE = 320

# Map dimensions
const MAP_WIDTH = 60
const MAP_HEIGHT = 50

# The map (2D array of tile types)
var tile_map: Array = []

# Building footprints
var buildings: Array = []

# Walkable tile types
var walkable_tiles = [
	TileType.GROUND, TileType.GROUND_GRASS, TileType.GROUND_DIRT, TileType.GROUND_SAND,
	TileType.PARK_GROUND
]

# Player reference
var player: Player

# NPCs list
var npcs: Array[NPC] = []

# NPC data — 5 NPCs placed around Indiranagar-inspired map
var npc_data = [
	{
		"id": "alex",
		"name": "Alex",
		"position": Vector2i(25, 23),
		"dialogue": [
			"Hey there! I'm a freelancer and I'm so frustrated...",
			"Every expense tracking app I've tried is way too complex.",
			"I just want something simple to track my business expenses.",
			"Is that too much to ask?!"
		],
		"problem": {
			"description": "Expense tracking apps too complex for freelancers",
			"category": "productivity"
		}
	},
	{
		"id": "jordan",
		"name": "Jordan",
		"position": Vector2i(12, 33),
		"dialogue": [
			"I'm doing research for my thesis...",
			"My team needs to share notes and references.",
			"But everything we've tried is either too rigid or too messy.",
			"There has to be a better way to organize research collaboratively."
		],
		"problem": {
			"description": "No good way to organize and share research notes with team",
			"category": "education"
		}
	},
	{
		"id": "maya",
		"name": "Maya",
		"position": Vector2i(42, 16),
		"dialogue": [
			"I run a small bakery and want to sell online...",
			"But setting up e-commerce is so complicated!",
			"Shopify is too expensive, and building my own site is overwhelming.",
			"I just want customers to order my cakes online. Why is this so hard?"
		],
		"problem": {
			"description": "Small business needs simple, affordable online ordering",
			"category": "local-business"
		}
	},
	{
		"id": "sam",
		"name": "Sam",
		"position": Vector2i(50, 36),
		"dialogue": [
			"I run a barbershop down the street.",
			"People keep calling to book appointments and I'm always cutting hair!",
			"I tried those booking apps but they take a huge cut of every appointment.",
			"All I need is a simple calendar my customers can book from. That's it."
		],
		"problem": {
			"description": "Small service businesses need affordable appointment booking",
			"category": "local-business"
		}
	},
	{
		"id": "priya",
		"name": "Priya",
		"position": Vector2i(28, 46),
		"dialogue": [
			"I'm a teacher at the school nearby.",
			"Communicating with parents is a nightmare right now.",
			"Email gets lost, the school app is clunky, and group chats are chaos.",
			"I just want one place where I can share updates and parents actually see them."
		],
		"problem": {
			"description": "Teachers need a simple way to communicate with parents",
			"category": "education"
		}
	}
]

# Interaction prompt animation
var prompt_bounce_time: float = 0.0
const BOUNCE_SPEED = 3.0
const BOUNCE_AMOUNT = 5.0

# === v0.2 State ===
var discovered_problems: Array = []
var talked_to: Dictionary = {}
var company_name: String = ""
var company_cash: int = 100000
var selected_problem: Dictionary = {}
var company_founded: bool = false

# Journal state
var journal_open: bool = false

# Journal UI (created in _ready)
var journal_panel: Panel
var journal_vbox: VBoxContainer
var journal_title_label: Label
var journal_scroll: ScrollContainer
var journal_list: VBoxContainer
var company_name_input: LineEdit
var founding_npc_id: String = ""

# HUD references (created in _ready)
var hud_panel: Panel
var hud_company_label: Label
var hud_cash_label: Label

# Subsystem references
@onready var dialogue_manager: DialogueManager = $DialogueManager
@onready var camera: CameraController = $Camera2D
@onready var interact_prompt: Label = $CanvasLayer/InteractPrompt

func _ready():
	# Generate map
	var result = MapGenerator.generate(MAP_WIDTH, MAP_HEIGHT)
	tile_map = result.tile_map
	buildings = result.buildings

	# Render tiles
	TileRenderer.render(tile_map, buildings, walkable_tiles, TILE_SIZE, MAP_WIDTH, MAP_HEIGHT, self)

	# Spawn entities
	_spawn_player()
	_spawn_npcs()

	# Wire up dialogue manager UI references
	dialogue_manager.dialogue_box = $CanvasLayer/DialogueBox
	dialogue_manager.npc_name_label = $CanvasLayer/DialogueBox/MarginContainer/VBoxContainer/NPCName
	dialogue_manager.dialogue_text_label = $CanvasLayer/DialogueBox/MarginContainer/VBoxContainer/DialogueText
	dialogue_manager.dialogue_ended.connect(_on_dialogue_ended)

	_create_journal_ui()
	_create_hud()

func _spawn_player():
	var player_scene = preload("res://scenes/player.tscn")
	player = player_scene.instantiate()
	var spawn = _find_nearest_walkable(Vector2i(5, 23))
	player.set_grid_position(spawn, false)
	add_child(player)

func _find_nearest_walkable(pos: Vector2i) -> Vector2i:
	if pos.x >= 0 and pos.x < MAP_WIDTH and pos.y >= 0 and pos.y < MAP_HEIGHT:
		if tile_map[pos.y][pos.x] in walkable_tiles:
			return pos
	for r in range(1, 20):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				var cx = pos.x + dx
				var cy = pos.y + dy
				if cx >= 0 and cx < MAP_WIDTH and cy >= 0 and cy < MAP_HEIGHT:
					if tile_map[cy][cx] in walkable_tiles:
						return Vector2i(cx, cy)
	return pos

func _spawn_npcs():
	var npc_scene = preload("res://scenes/npc.tscn")
	for data in npc_data:
		data.position = _find_nearest_walkable(data.position)
		var npc = npc_scene.instantiate()
		npc.setup(data)
		npcs.append(npc)
		add_child(npc)

# === Per-frame updates ===

func _process(delta):
	# Camera follow + zoom
	if player and camera:
		camera.follow(player.position, delta)

	# Dialogue typewriter
	dialogue_manager.process_typewriter(delta)

	# Movement (blocked during dialogue and journal)
	if not dialogue_manager.is_active() and not journal_open and player and not player.is_moving:
		var direction = Vector2i.ZERO
		if Input.is_action_pressed("ui_up"):
			direction.y = -1
		elif Input.is_action_pressed("ui_down"):
			direction.y = 1
		if Input.is_action_pressed("ui_left"):
			direction.x = -1
		elif Input.is_action_pressed("ui_right"):
			direction.x = 1
		if direction != Vector2i.ZERO:
			_try_move(direction)

	# Animate interaction prompt
	if interact_prompt.visible:
		prompt_bounce_time += delta * BOUNCE_SPEED
		var bounce_offset = sin(prompt_bounce_time) * BOUNCE_AMOUNT
		interact_prompt.position.y = interact_prompt.position.y - bounce_offset + bounce_offset

# === Input ===

func _input(event):
	# Journal toggle (Tab key) — blocked during dialogue
	if event is InputEventKey and event.pressed and event.keycode == KEY_TAB:
		if not dialogue_manager.is_active():
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

	# Dialogue mode
	if dialogue_manager.is_active():
		if event.is_action_pressed("ui_accept") or event.is_action_pressed("interact"):
			dialogue_manager.advance()
		return

	# Block other input while journal is open
	if journal_open:
		return

	# Interact
	if event.is_action_pressed("interact"):
		_try_interact()

	# Camera zoom
	camera.handle_input(event)

# === Movement & Collision ===

func _get_move_step() -> int:
	var current_zoom = camera.zoom.x if camera else 0.5
	return max(1, roundi(0.5 / current_zoom))

func _try_move(direction: Vector2i):
	var step = _get_move_step()
	var current_pos = player.get_grid_position()
	var final_pos = current_pos

	for i in range(1, step + 1):
		var check_pos = current_pos + direction * i
		if check_pos.x < 0 or check_pos.x >= MAP_WIDTH or check_pos.y < 0 or check_pos.y >= MAP_HEIGHT:
			break
		if tile_map[check_pos.y][check_pos.x] not in walkable_tiles:
			break
		var npc_blocking = false
		for npc in npcs:
			if npc.get_grid_position() == check_pos:
				npc_blocking = true
				break
		if npc_blocking:
			break
		final_pos = check_pos

	if final_pos != current_pos:
		player.set_grid_position(final_pos, true, direction)
		_check_npc_proximity()

# === NPC Interaction ===

func _check_npc_proximity():
	var adjacent_npc = _get_adjacent_npc()
	if adjacent_npc != null:
		if not interact_prompt.visible:
			prompt_bounce_time = 0.0
		interact_prompt.visible = true
		var npc_world_pos = adjacent_npc.position
		var base_y = npc_world_pos.y - TILE_SIZE * 0.6
		var bounce_offset = sin(prompt_bounce_time) * BOUNCE_AMOUNT
		interact_prompt.position = Vector2(
			npc_world_pos.x + TILE_SIZE / 2.0 - 50,
			base_y + bounce_offset
		)
	else:
		interact_prompt.visible = false

func _get_adjacent_npc() -> NPC:
	var player_pos = player.get_grid_position()
	var adjacent_positions = [
		player_pos + Vector2i(0, -1),
		player_pos + Vector2i(0, 1),
		player_pos + Vector2i(-1, 0),
		player_pos + Vector2i(1, 0)
	]
	for npc in npcs:
		if npc.get_grid_position() in adjacent_positions:
			return npc
	return null

func _try_interact():
	var adjacent_npc = _get_adjacent_npc()
	if adjacent_npc != null:
		interact_prompt.visible = false
		# Pick dialogue lines based on state
		var lines: Array
		if talked_to.has(adjacent_npc.npc_id):
			lines = ["We already talked about this."]
		else:
			lines = adjacent_npc.dialogue.duplicate()
		dialogue_manager.start(adjacent_npc, lines)

func _on_dialogue_ended(npc: NPC):
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

# === Journal ===

func _create_journal_ui():
	# Main panel — full screen overlay with margin
	journal_panel = Panel.new()
	journal_panel.visible = false
	journal_panel.anchors_preset = Control.PRESET_FULL_RECT
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

# === HUD ===

func _create_hud():
	hud_panel = Panel.new()
	hud_panel.visible = false
	hud_panel.anchors_preset = Control.PRESET_TOP_WIDE
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
