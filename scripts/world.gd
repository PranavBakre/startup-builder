extends Node2D

# Tile types
enum TileType { GROUND, GROUND_GRASS, WALL, PROP }

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
	},
	{
		"id": "maya",
		"name": "Maya",
		"position": Vector2i(8, 12),
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
	}
]

# Dialogue state
var active_dialogue: NPC = null
var dialogue_index = 0
var dialogue_char_index = 0
var dialogue_timer = 0.0
const CHAR_DELAY = 0.03  # Seconds between each character (typewriter effect)

# Interaction prompt animation
var prompt_bounce_time = 0.0
const BOUNCE_SPEED = 3.0
const BOUNCE_AMOUNT = 5.0

# UI references
@onready var dialogue_box = $CanvasLayer/DialogueBox
@onready var npc_name_label = $CanvasLayer/DialogueBox/MarginContainer/VBoxContainer/NPCName
@onready var dialogue_text_label = $CanvasLayer/DialogueBox/MarginContainer/VBoxContainer/DialogueText
@onready var interact_prompt = $CanvasLayer/InteractPrompt
@onready var tilemap_layer = $TileMapLayer
@onready var camera = $Camera2D

func _ready():
	_generate_map()
	_render_tiles()  # Render actual tile sprites
	_spawn_player()
	_spawn_npcs()

func _generate_map():
	# Initialize with grass as default
	for y in range(MAP_HEIGHT):
		var row = []
		for x in range(MAP_WIDTH):
			row.append(TileType.GROUND_GRASS)
		tile_map.append(row)

	# Create pavement paths (horizontal and vertical)
	# Horizontal path through middle
	for x in range(MAP_WIDTH):
		tile_map[7][x] = TileType.GROUND

	# Vertical path through middle
	for y in range(MAP_HEIGHT):
		tile_map[y][10] = TileType.GROUND

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

	# Add some props (trees, benches) on grass areas
	tile_map[3][8] = TileType.PROP   # Tree
	tile_map[4][15] = TileType.PROP  # Tree
	tile_map[11][4] = TileType.PROP  # Tree
	tile_map[9][16] = TileType.PROP  # Tree

func _render_tiles():
	# Load tile textures
	var tile_textures = {
		TileType.GROUND: load("res://assets/tiles/ground.png"),        # Gray pavement
		TileType.GROUND_GRASS: load("res://assets/tiles/ground_grass.png"),  # Green grass
		TileType.WALL: load("res://assets/tiles/wall.png"),
		TileType.PROP: load("res://assets/tiles/tree.png")
	}

	# Create Sprite2D nodes for each tile
	for y in range(MAP_HEIGHT):
		for x in range(MAP_WIDTH):
			var tile_type = tile_map[y][x]
			var texture = tile_textures.get(tile_type)

			if texture:
				var sprite = Sprite2D.new()
				sprite.texture = texture
				sprite.position = Vector2(x * TILE_SIZE + TILE_SIZE/2, y * TILE_SIZE + TILE_SIZE/2)
				# Scale from 1024x1024 to 32x32
				sprite.scale = Vector2(0.03125, 0.03125)
				sprite.z_index = -1  # Render tiles behind characters
				add_child(sprite)

func _spawn_player():
	var player_scene = preload("res://scenes/player.tscn")
	player = player_scene.instantiate()
	player.set_grid_position(Vector2i(5, 7), false)  # No animation on spawn
	add_child(player)
	_update_camera()

func _update_camera():
	if player and camera:
		camera.position = player.position

func _spawn_npcs():
	var npc_scene = preload("res://scenes/npc.tscn")

	for data in npc_data:
		var npc = npc_scene.instantiate()
		npc.setup(data)
		npcs.append(npc)
		add_child(npc)

func _process(delta):
	# Smooth camera follow
	if player and camera:
		camera.position = camera.position.lerp(player.position, 0.1)

	# Continuous movement when holding keys (only if not in dialogue and not moving)
	if active_dialogue == null and player and not player.is_moving:
		var direction = Vector2i.ZERO

		# Check vertical input
		if Input.is_action_pressed("ui_up"):
			direction.y = -1
		elif Input.is_action_pressed("ui_down"):
			direction.y = 1

		# Check horizontal input
		if Input.is_action_pressed("ui_left"):
			direction.x = -1
		elif Input.is_action_pressed("ui_right"):
			direction.x = 1

		# Move if any direction is pressed (supports diagonals)
		if direction != Vector2i.ZERO:
			_try_move(direction)

	# Typewriter effect for dialogue
	if active_dialogue != null and dialogue_char_index < active_dialogue.dialogue[dialogue_index].length():
		dialogue_timer += delta
		if dialogue_timer >= CHAR_DELAY:
			dialogue_timer = 0.0
			dialogue_char_index += 1
			var full_text = active_dialogue.dialogue[dialogue_index]
			dialogue_text_label.text = full_text.substr(0, dialogue_char_index)

	# Animate interaction prompt (subtle bounce)
	if interact_prompt.visible:
		prompt_bounce_time += delta * BOUNCE_SPEED
		var bounce_offset = sin(prompt_bounce_time) * BOUNCE_AMOUNT
		interact_prompt.position.y = interact_prompt.position.y - bounce_offset + bounce_offset

func _input(event):
	if active_dialogue != null:
		# In dialogue mode
		if event.is_action_pressed("ui_accept") or event.is_action_pressed("interact"):
			_advance_dialogue()
		return

	# Interact input (still uses _input for single press)
	if event.is_action_pressed("interact"):
		_try_interact()

func _try_move(direction: Vector2i):
	var new_pos = player.get_grid_position() + direction

	# Check bounds
	if new_pos.x < 0 or new_pos.x >= MAP_WIDTH or new_pos.y < 0 or new_pos.y >= MAP_HEIGHT:
		print("Move blocked: out of bounds")
		return

	# Check collision with tiles (both ground types are walkable)
	var tile_type = tile_map[new_pos.y][new_pos.x]
	if tile_type != TileType.GROUND and tile_type != TileType.GROUND_GRASS:
		print("Move blocked: tile type ", tile_type, " at ", new_pos)
		return

	# Check collision with NPCs
	for npc in npcs:
		if npc.get_grid_position() == new_pos:
			print("Move blocked: NPC at ", new_pos)
			return

	# Move is valid
	print("Moving to ", new_pos)
	player.set_grid_position(new_pos, true, direction)  # Animate movement with direction
	_update_camera()
	_check_npc_proximity()

func _check_npc_proximity():
	var adjacent_npc = _get_adjacent_npc()
	if adjacent_npc != null:
		if not interact_prompt.visible:
			prompt_bounce_time = 0.0  # Reset animation when showing
		interact_prompt.visible = true
		var npc_world_pos = adjacent_npc.position
		var base_y = npc_world_pos.y - 30
		var bounce_offset = sin(prompt_bounce_time) * BOUNCE_AMOUNT
		interact_prompt.position = Vector2(
			npc_world_pos.x + TILE_SIZE / 2 - 50,
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
		_start_dialogue(adjacent_npc)

func _start_dialogue(npc: NPC):
	active_dialogue = npc
	dialogue_index = 0
	dialogue_char_index = 0
	dialogue_timer = 0.0
	interact_prompt.visible = false
	dialogue_box.visible = true
	npc_name_label.text = npc.npc_name
	dialogue_text_label.text = ""  # Start empty for typewriter effect

func _advance_dialogue():
	# If still typing, skip to end of current line
	if dialogue_char_index < active_dialogue.dialogue[dialogue_index].length():
		dialogue_char_index = active_dialogue.dialogue[dialogue_index].length()
		dialogue_text_label.text = active_dialogue.dialogue[dialogue_index]
		return

	# Move to next dialogue line
	dialogue_index += 1
	if dialogue_index < active_dialogue.dialogue.size():
		dialogue_char_index = 0
		dialogue_timer = 0.0
		dialogue_text_label.text = ""
	else:
		_end_dialogue()

func _end_dialogue():
	dialogue_box.visible = false
	active_dialogue = null
	dialogue_index = 0
	_check_npc_proximity()
