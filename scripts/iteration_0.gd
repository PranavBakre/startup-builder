extends Node2D

# Tile types
enum TileType { GROUND, WALL, PROP }

# Tile size in pixels
const TILE_SIZE = 40

# Map dimensions
const MAP_WIDTH = 20
const MAP_HEIGHT = 15

# Colors for each tile type
const COLOR_GROUND = Color(0.2, 0.6, 0.2)  # Green
const COLOR_WALL = Color(0.3, 0.3, 0.3)     # Gray
const COLOR_PROP = Color(0.5, 0.3, 0.1)     # Brown
const COLOR_PLAYER = Color(0.2, 0.4, 0.8)   # Blue
const COLOR_NPC = Color(0.9, 0.7, 0.2)      # Yellow

# Player state
var player_pos = Vector2i(5, 7)

# NPC data
var npcs = [
	{
		"id": "alex",
		"name": "Alex",
		"position": Vector2i(10, 5),
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
		"position": Vector2i(15, 10),
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
	}
]

# Dialogue state
var active_dialogue = null
var dialogue_index = 0

# The map (2D array of tile types)
var tile_map = []

# UI references
@onready var dialogue_box = $CanvasLayer/DialogueBox
@onready var npc_name_label = $CanvasLayer/DialogueBox/MarginContainer/VBoxContainer/NPCName
@onready var dialogue_text_label = $CanvasLayer/DialogueBox/MarginContainer/VBoxContainer/DialogueText
@onready var interact_prompt = $CanvasLayer/InteractPrompt

func _ready():
	_generate_map()
	# Center the camera on the map
	var map_center = Vector2(MAP_WIDTH * TILE_SIZE / 2, MAP_HEIGHT * TILE_SIZE / 2)
	position = -map_center + get_viewport_rect().size / 2
	queue_redraw()

func _generate_map():
	# Initialize with ground tiles
	for y in range(MAP_HEIGHT):
		var row = []
		for x in range(MAP_WIDTH):
			row.append(TileType.GROUND)
		tile_map.append(row)

	# Add walls around the border
	for x in range(MAP_WIDTH):
		tile_map[0][x] = TileType.WALL
		tile_map[MAP_HEIGHT - 1][x] = TileType.WALL
	for y in range(MAP_HEIGHT):
		tile_map[y][0] = TileType.WALL
		tile_map[y][MAP_WIDTH - 1] = TileType.WALL

	# Add some buildings (walls)
	for x in range(3, 6):
		for y in range(3, 6):
			tile_map[y][x] = TileType.WALL

	for x in range(12, 15):
		for y in range(8, 11):
			tile_map[y][x] = TileType.WALL

	# Add some props (trees, benches)
	tile_map[7][8] = TileType.PROP
	tile_map[4][12] = TileType.PROP
	tile_map[11][4] = TileType.PROP

func _draw():
	# Draw the tile map
	for y in range(MAP_HEIGHT):
		for x in range(MAP_WIDTH):
			var pos = Vector2(x * TILE_SIZE, y * TILE_SIZE)
			var color = _get_tile_color(tile_map[y][x])
			draw_rect(Rect2(pos, Vector2(TILE_SIZE, TILE_SIZE)), color)
			# Draw grid lines
			draw_rect(Rect2(pos, Vector2(TILE_SIZE, TILE_SIZE)), Color.BLACK, false, 1.0)

	# Draw NPCs
	for npc in npcs:
		var npc_pos = npc["position"]
		var pos = Vector2(npc_pos.x * TILE_SIZE, npc_pos.y * TILE_SIZE)
		draw_rect(Rect2(pos, Vector2(TILE_SIZE, TILE_SIZE)), COLOR_NPC)
		draw_rect(Rect2(pos, Vector2(TILE_SIZE, TILE_SIZE)), Color.BLACK, false, 2.0)

	# Draw player
	var player_screen_pos = Vector2(player_pos.x * TILE_SIZE, player_pos.y * TILE_SIZE)
	draw_rect(Rect2(player_screen_pos, Vector2(TILE_SIZE, TILE_SIZE)), COLOR_PLAYER)
	draw_rect(Rect2(player_screen_pos, Vector2(TILE_SIZE, TILE_SIZE)), Color.WHITE, false, 2.0)

func _get_tile_color(tile_type: TileType) -> Color:
	match tile_type:
		TileType.GROUND:
			return COLOR_GROUND
		TileType.WALL:
			return COLOR_WALL
		TileType.PROP:
			return COLOR_PROP
	return Color.WHITE

func _input(event):
	if active_dialogue != null:
		# In dialogue mode
		if event.is_action_pressed("ui_accept") or event.is_action_pressed("interact"):
			_advance_dialogue()
		return

	# Movement input
	var direction = Vector2i.ZERO
	if event.is_action_pressed("ui_up"):
		direction = Vector2i(0, -1)
	elif event.is_action_pressed("ui_down"):
		direction = Vector2i(0, 1)
	elif event.is_action_pressed("ui_left"):
		direction = Vector2i(-1, 0)
	elif event.is_action_pressed("ui_right"):
		direction = Vector2i(1, 0)

	if direction != Vector2i.ZERO:
		_try_move(direction)

	# Interact input
	if event.is_action_pressed("interact"):
		_try_interact()

func _try_move(direction: Vector2i):
	var new_pos = player_pos + direction

	# Check bounds
	if new_pos.x < 0 or new_pos.x >= MAP_WIDTH or new_pos.y < 0 or new_pos.y >= MAP_HEIGHT:
		return

	# Check collision with tiles
	if tile_map[new_pos.y][new_pos.x] != TileType.GROUND:
		return

	# Check collision with NPCs
	for npc in npcs:
		if npc["position"] == new_pos:
			return

	# Move is valid
	player_pos = new_pos
	queue_redraw()
	_check_npc_proximity()

func _check_npc_proximity():
	var adjacent_npc = _get_adjacent_npc()
	if adjacent_npc != null:
		interact_prompt.visible = true
		interact_prompt.position = Vector2(
			adjacent_npc["position"].x * TILE_SIZE + TILE_SIZE / 2 - interact_prompt.size.x / 2,
			adjacent_npc["position"].y * TILE_SIZE - 30
		)
	else:
		interact_prompt.visible = false

func _get_adjacent_npc():
	var adjacent_positions = [
		player_pos + Vector2i(0, -1),
		player_pos + Vector2i(0, 1),
		player_pos + Vector2i(-1, 0),
		player_pos + Vector2i(1, 0)
	]

	for npc in npcs:
		if npc["position"] in adjacent_positions:
			return npc

	return null

func _try_interact():
	var adjacent_npc = _get_adjacent_npc()
	if adjacent_npc != null:
		_start_dialogue(adjacent_npc)

func _start_dialogue(npc):
	active_dialogue = npc
	dialogue_index = 0
	interact_prompt.visible = false
	dialogue_box.visible = true
	npc_name_label.text = npc["name"]
	dialogue_text_label.text = npc["dialogue"][dialogue_index]

func _advance_dialogue():
	dialogue_index += 1
	if dialogue_index < active_dialogue["dialogue"].size():
		dialogue_text_label.text = active_dialogue["dialogue"][dialogue_index]
	else:
		_end_dialogue()

func _end_dialogue():
	dialogue_box.visible = false
	active_dialogue = null
	dialogue_index = 0
	_check_npc_proximity()
