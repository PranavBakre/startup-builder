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

	# Movement (blocked during dialogue)
	if not dialogue_manager.is_active() and player and not player.is_moving:
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
	# Dialogue mode
	if dialogue_manager.is_active():
		if event.is_action_pressed("ui_accept") or event.is_action_pressed("interact"):
			dialogue_manager.advance()
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
		dialogue_manager.start(adjacent_npc, adjacent_npc.dialogue.duplicate())

func _on_dialogue_ended(_npc: NPC):
	_check_npc_proximity()
