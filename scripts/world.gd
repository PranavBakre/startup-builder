extends Node2D

# Tile types
enum TileType { GROUND, WALL, PROP }

# Tile size in pixels
const TILE_SIZE = 32

# Map dimensions
const MAP_WIDTH = 20
const MAP_HEIGHT = 15

# The map (2D array of tile types)
var tile_map = []

# Player reference
var player: Player

# NPCs list
var npcs: Array[NPC] = []

# NPC data
var npc_data = [
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
var active_dialogue: NPC = null
var dialogue_index = 0

# UI references
@onready var dialogue_box = $CanvasLayer/DialogueBox
@onready var npc_name_label = $CanvasLayer/DialogueBox/MarginContainer/VBoxContainer/NPCName
@onready var dialogue_text_label = $CanvasLayer/DialogueBox/MarginContainer/VBoxContainer/DialogueText
@onready var interact_prompt = $CanvasLayer/InteractPrompt
@onready var tilemap_layer = $TileMapLayer

func _ready():
	_generate_map()
	_spawn_player()
	_spawn_npcs()
	queue_redraw()  # Trigger tile rendering

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

	# TODO: Replace with actual TileMapLayer painting once TileSet is configured

func _draw():
	# Temporary: Draw colored rectangles for tiles (like iteration 0)
	const COLOR_GROUND = Color(0.2, 0.6, 0.2)  # Green
	const COLOR_WALL = Color(0.3, 0.3, 0.3)     # Gray
	const COLOR_PROP = Color(0.5, 0.3, 0.1)     # Brown

	for y in range(MAP_HEIGHT):
		for x in range(MAP_WIDTH):
			var pos = Vector2(x * TILE_SIZE, y * TILE_SIZE)
			var color = COLOR_GROUND
			match tile_map[y][x]:
				TileType.GROUND:
					color = COLOR_GROUND
				TileType.WALL:
					color = COLOR_WALL
				TileType.PROP:
					color = COLOR_PROP

			draw_rect(Rect2(pos, Vector2(TILE_SIZE, TILE_SIZE)), color)
			# Draw grid lines
			draw_rect(Rect2(pos, Vector2(TILE_SIZE, TILE_SIZE)), Color.BLACK, false, 1.0)

func _spawn_player():
	var player_scene = preload("res://scenes/player.tscn")
	player = player_scene.instantiate()
	player.set_grid_position(Vector2i(5, 7))
	add_child(player)

func _spawn_npcs():
	var npc_scene = preload("res://scenes/npc.tscn")

	for data in npc_data:
		var npc = npc_scene.instantiate()
		npc.setup(data)
		npcs.append(npc)
		add_child(npc)

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
	var new_pos = player.get_grid_position() + direction

	# Check bounds
	if new_pos.x < 0 or new_pos.x >= MAP_WIDTH or new_pos.y < 0 or new_pos.y >= MAP_HEIGHT:
		return

	# Check collision with tiles
	if tile_map[new_pos.y][new_pos.x] != TileType.GROUND:
		return

	# Check collision with NPCs
	for npc in npcs:
		if npc.get_grid_position() == new_pos:
			return

	# Move is valid
	player.set_grid_position(new_pos)
	_check_npc_proximity()

func _check_npc_proximity():
	var adjacent_npc = _get_adjacent_npc()
	if adjacent_npc != null:
		interact_prompt.visible = true
		var npc_world_pos = adjacent_npc.position
		interact_prompt.position = Vector2(
			npc_world_pos.x + TILE_SIZE / 2 - 50,
			npc_world_pos.y - 30
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
		_start_dialogue(adjacent_npc)

func _start_dialogue(npc: NPC):
	active_dialogue = npc
	dialogue_index = 0
	interact_prompt.visible = false
	dialogue_box.visible = true
	npc_name_label.text = npc.npc_name
	dialogue_text_label.text = npc.dialogue[dialogue_index]

func _advance_dialogue():
	dialogue_index += 1
	if dialogue_index < active_dialogue.dialogue.size():
		dialogue_text_label.text = active_dialogue.dialogue[dialogue_index]
	else:
		_end_dialogue()

func _end_dialogue():
	dialogue_box.visible = false
	active_dialogue = null
	dialogue_index = 0
	_check_npc_proximity()
