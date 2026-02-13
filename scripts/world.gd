extends Node2D

# Tile types
enum TileType {
	GROUND, GROUND_GRASS, GROUND_DIRT, GROUND_SAND,
	WALL, WALL_BRICK, WALL_WOOD, ROOF,
	TREE, TREE_PINE, BUSH, FLOWERS,
	BENCH, LAMP_POST, FENCE, FOUNTAIN, MAILBOX, TRASH_CAN, SIGN_SHOP
}

# Tile size in pixels
const TILE_SIZE = 320

# Map dimensions (10x original: was 20x15)
const MAP_WIDTH = 200
const MAP_HEIGHT = 150

# The map (2D array of tile types)
var tile_map = []

# Building footprints: array of {x, y, w, h, wall_type}
var buildings = []

# Player reference
var player: Player

# NPCs list
var npcs: Array[NPC] = []

# NPC data — 5 NPCs with distinct problems
var npc_data = [
	{
		"id": "alex",
		"name": "Alex",
		"position": Vector2i(51, 41),  # Near park (northwest)
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
		"position": Vector2i(131, 71),  # Near central park
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
		"position": Vector2i(41, 111),  # Near south park
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
		"position": Vector2i(161, 91),  # Near east park
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
		"position": Vector2i(86, 131),  # Near south-center park
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

# Camera zoom
const ZOOM_MIN = 0.02
const ZOOM_MAX = 2.0
const ZOOM_STEP = 0.05
const ZOOM_SMOOTH_SPEED = 8.0
var target_zoom = 0.3

# UI references
@onready var dialogue_box = $CanvasLayer/DialogueBox
@onready var npc_name_label = $CanvasLayer/DialogueBox/MarginContainer/VBoxContainer/NPCName
@onready var dialogue_text_label = $CanvasLayer/DialogueBox/MarginContainer/VBoxContainer/DialogueText
@onready var interact_prompt = $CanvasLayer/InteractPrompt
@onready var tilemap_layer = $TileMapLayer
@onready var camera = $Camera2D

func _ready():
	_generate_map()
	_render_tiles()
	_spawn_player()
	_spawn_npcs()

func _generate_map():
	# Seeded RNG for reproducible maps
	var rng = RandomNumberGenerator.new()
	rng.seed = 42

	# Wall type options for buildings
	var wall_types = [TileType.WALL, TileType.WALL_BRICK, TileType.WALL_WOOD]
	# Tree type options
	var tree_types = [TileType.TREE, TileType.TREE_PINE]

	# Initialize with grass
	for y in range(MAP_HEIGHT):
		var row = []
		for x in range(MAP_WIDTH):
			row.append(TileType.GROUND_GRASS)
		tile_map.append(row)

	# --- Major roads (2 tiles wide) ---
	var h_roads = [25, 50, 75, 100, 125]
	var v_roads = [30, 60, 100, 140, 170]

	for ry in h_roads:
		if ry + 1 < MAP_HEIGHT:
			for x in range(MAP_WIDTH):
				tile_map[ry][x] = TileType.GROUND
				tile_map[ry + 1][x] = TileType.GROUND

	for rx in v_roads:
		if rx + 1 < MAP_WIDTH:
			for y in range(MAP_HEIGHT):
				tile_map[y][rx] = TileType.GROUND
				tile_map[y][rx + 1] = TileType.GROUND

	# --- Border walls ---
	for x in range(MAP_WIDTH):
		tile_map[0][x] = TileType.WALL
		tile_map[MAP_HEIGHT - 1][x] = TileType.WALL
	for y in range(MAP_HEIGHT):
		tile_map[y][0] = TileType.WALL
		tile_map[y][MAP_WIDTH - 1] = TileType.WALL

	# --- Buildings FIRST (before minor roads so they don't block placement) ---
	for bi in range(len(h_roads) + 1):
		var y_start = 3 if bi == 0 else h_roads[bi - 1] + 3
		var y_end = (h_roads[bi] - 2) if bi < len(h_roads) else MAP_HEIGHT - 3
		for bj in range(len(v_roads) + 1):
			var x_start = 3 if bj == 0 else v_roads[bj - 1] + 3
			var x_end = (v_roads[bj] - 2) if bj < len(v_roads) else MAP_WIDTH - 3
			var block_w = x_end - x_start
			var block_h = y_end - y_start
			if block_w < 12 or block_h < 10:
				continue
			# 1-2 large buildings per block
			var num_buildings = rng.randi_range(1, 2)
			for _b in range(num_buildings):
				var bw = rng.randi_range(8, min(16, block_w - 6))
				var bh = rng.randi_range(6, min(12, block_h - 6))
				if bw < 4 or bh < 4:
					continue
				var bx = rng.randi_range(x_start + 2, max(x_start + 2, x_end - bw - 2))
				var by = rng.randi_range(y_start + 2, max(y_start + 2, y_end - bh - 2))
				# Check area is only grass (no overlap with roads or other buildings)
				var can_place = true
				for cy in range(by - 1, by + bh + 1):
					for cx in range(bx - 1, bx + bw + 1):
						if cy < 0 or cy >= MAP_HEIGHT or cx < 0 or cx >= MAP_WIDTH:
							can_place = false
							break
						if tile_map[cy][cx] != TileType.GROUND_GRASS:
							can_place = false
							break
					if not can_place:
						break
				if can_place:
					var wt = wall_types[rng.randi_range(0, wall_types.size() - 1)]
					# Mark all tiles as wall (for collision)
					for cy in range(by, by + bh):
						for cx in range(bx, bx + bw):
							tile_map[cy][cx] = wt
					# Store building rect for single-sprite rendering
					buildings.append({"x": bx, "y": by, "w": bw, "h": bh, "wall_type": wt})

	# --- Minor roads AFTER buildings ---
	var minor_h = [12, 37, 63, 88, 112, 138]
	for ry in minor_h:
		if ry < MAP_HEIGHT:
			for x in range(MAP_WIDTH):
				if tile_map[ry][x] == TileType.GROUND_GRASS:
					tile_map[ry][x] = TileType.GROUND

	var minor_v = [15, 45, 80, 120, 155, 185]
	for rx in minor_v:
		if rx < MAP_WIDTH:
			for y in range(MAP_HEIGHT):
				if tile_map[y][rx] == TileType.GROUND_GRASS:
					tile_map[y][rx] = TileType.GROUND

	# Dirt paths branching off roads
	for _i in range(30):
		var start_x = rng.randi_range(5, MAP_WIDTH - 5)
		var start_y = rng.randi_range(5, MAP_HEIGHT - 5)
		if tile_map[start_y][start_x] == TileType.GROUND:
			var dx = rng.randi_range(-1, 1)
			var dy = 1 if dx == 0 else 0
			var cx = start_x
			var cy = start_y
			var path_len = rng.randi_range(5, 15)
			for _s in range(path_len):
				cx += dx
				cy += dy
				if cx > 1 and cx < MAP_WIDTH - 2 and cy > 1 and cy < MAP_HEIGHT - 2:
					if tile_map[cy][cx] == TileType.GROUND_GRASS:
						tile_map[cy][cx] = TileType.GROUND_DIRT

	# --- Lamp posts along major roads ---
	for ry in h_roads:
		for x in range(5, MAP_WIDTH - 5, 8):
			if ry - 1 > 0 and tile_map[ry - 1][x] == TileType.GROUND_GRASS:
				tile_map[ry - 1][x] = TileType.LAMP_POST
	for rx in v_roads:
		for y in range(5, MAP_HEIGHT - 5, 8):
			if rx - 1 > 0 and tile_map[y][rx - 1] == TileType.GROUND_GRASS:
				tile_map[y][rx - 1] = TileType.LAMP_POST

	# --- Street furniture along roads ---
	for _i in range(40):
		var fx = rng.randi_range(3, MAP_WIDTH - 4)
		var fy = rng.randi_range(3, MAP_HEIGHT - 4)
		if tile_map[fy][fx] != TileType.GROUND_GRASS:
			continue
		# Check if adjacent to a road
		var next_to_road = false
		for d in [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]:
			var nx = fx + d.x
			var ny = fy + d.y
			if nx >= 0 and nx < MAP_WIDTH and ny >= 0 and ny < MAP_HEIGHT:
				if tile_map[ny][nx] == TileType.GROUND:
					next_to_road = true
					break
		if next_to_road:
			var furniture = [TileType.TRASH_CAN, TileType.MAILBOX, TileType.SIGN_SHOP, TileType.BENCH]
			tile_map[fy][fx] = furniture[rng.randi_range(0, furniture.size() - 1)]

	# --- Park areas ---
	var park_centers = [
		Vector2i(50, 40), Vector2i(110, 35), Vector2i(160, 90),
		Vector2i(40, 110), Vector2i(130, 70), Vector2i(85, 130),
		Vector2i(170, 40), Vector2i(25, 70), Vector2i(90, 15),
		Vector2i(150, 130)
	]
	for pc in park_centers:
		var park_radius = rng.randi_range(5, 8)
		# Clear area for park
		for dy in range(-park_radius, park_radius + 1):
			for dx in range(-park_radius, park_radius + 1):
				var px = pc.x + dx
				var py = pc.y + dy
				if px > 1 and px < MAP_WIDTH - 2 and py > 1 and py < MAP_HEIGHT - 2:
					if tile_map[py][px] in [TileType.WALL, TileType.WALL_BRICK, TileType.WALL_WOOD, TileType.ROOF]:
						tile_map[py][px] = TileType.GROUND_GRASS
		# Fountain at center
		if pc.x > 0 and pc.x < MAP_WIDTH - 1 and pc.y > 0 and pc.y < MAP_HEIGHT - 1:
			if tile_map[pc.y][pc.x] == TileType.GROUND_GRASS:
				tile_map[pc.y][pc.x] = TileType.FOUNTAIN
		# Trees around edge
		for _t in range(12):
			var dx = rng.randi_range(-park_radius, park_radius)
			var dy = rng.randi_range(-park_radius, park_radius)
			var px = pc.x + dx
			var py = pc.y + dy
			if px > 1 and px < MAP_WIDTH - 2 and py > 1 and py < MAP_HEIGHT - 2:
				if tile_map[py][px] == TileType.GROUND_GRASS:
					tile_map[py][px] = tree_types[rng.randi_range(0, tree_types.size() - 1)]
		# Benches
		for _b in range(3):
			var dx = rng.randi_range(-3, 3)
			var dy = rng.randi_range(-3, 3)
			var px = pc.x + dx
			var py = pc.y + dy
			if px > 1 and px < MAP_WIDTH - 2 and py > 1 and py < MAP_HEIGHT - 2:
				if tile_map[py][px] == TileType.GROUND_GRASS:
					tile_map[py][px] = TileType.BENCH
		# Flowers near benches
		for _f in range(4):
			var dx = rng.randi_range(-park_radius, park_radius)
			var dy = rng.randi_range(-park_radius, park_radius)
			var px = pc.x + dx
			var py = pc.y + dy
			if px > 1 and px < MAP_WIDTH - 2 and py > 1 and py < MAP_HEIGHT - 2:
				if tile_map[py][px] == TileType.GROUND_GRASS:
					tile_map[py][px] = TileType.FLOWERS

	# --- Scattered trees across open grass ---
	for _i in range(600):
		var tx = rng.randi_range(2, MAP_WIDTH - 3)
		var ty = rng.randi_range(2, MAP_HEIGHT - 3)
		if tile_map[ty][tx] != TileType.GROUND_GRASS:
			continue
		# Don't place adjacent to roads
		var near_road = false
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				var nx = tx + dx
				var ny = ty + dy
				if nx >= 0 and nx < MAP_WIDTH and ny >= 0 and ny < MAP_HEIGHT:
					if tile_map[ny][nx] == TileType.GROUND:
						near_road = true
		if not near_road:
			tile_map[ty][tx] = tree_types[rng.randi_range(0, tree_types.size() - 1)]

	# --- Bushes scattered in grass near trees ---
	for _i in range(300):
		var bx = rng.randi_range(2, MAP_WIDTH - 3)
		var by = rng.randi_range(2, MAP_HEIGHT - 3)
		if tile_map[by][bx] != TileType.GROUND_GRASS:
			continue
		# Prefer near existing trees
		var near_tree = false
		for dy in range(-2, 3):
			for dx in range(-2, 3):
				var nx = bx + dx
				var ny = by + dy
				if nx >= 0 and nx < MAP_WIDTH and ny >= 0 and ny < MAP_HEIGHT:
					if tile_map[ny][nx] in [TileType.TREE, TileType.TREE_PINE]:
						near_tree = true
		if near_tree:
			tile_map[by][bx] = TileType.BUSH

	# --- Fences around some buildings ---
	for _i in range(20):
		var fx = rng.randi_range(5, MAP_WIDTH - 5)
		var fy = rng.randi_range(5, MAP_HEIGHT - 5)
		if tile_map[fy][fx] != TileType.GROUND_GRASS:
			continue
		# Check if near a building wall
		var near_building = false
		for d in [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]:
			var nx = fx + d.x
			var ny = fy + d.y
			if nx >= 0 and nx < MAP_WIDTH and ny >= 0 and ny < MAP_HEIGHT:
				if tile_map[ny][nx] in [TileType.WALL, TileType.WALL_BRICK, TileType.WALL_WOOD]:
					near_building = true
					break
		if near_building:
			tile_map[fy][fx] = TileType.FENCE

# Walkable tile types
var walkable_tiles = [
	TileType.GROUND, TileType.GROUND_GRASS, TileType.GROUND_DIRT, TileType.GROUND_SAND
]

func _render_tiles():
	var tile_textures = {
		TileType.GROUND: load("res://assets/tiles/ground.png"),
		TileType.GROUND_GRASS: load("res://assets/tiles/ground_grass.png"),
		TileType.GROUND_DIRT: load("res://assets/tiles/ground_dirt.png"),
		TileType.GROUND_SAND: load("res://assets/tiles/ground_sand.png"),
		TileType.WALL: load("res://assets/tiles/wall.png"),
		TileType.WALL_BRICK: load("res://assets/tiles/wall_brick.png"),
		TileType.WALL_WOOD: load("res://assets/tiles/wall_wood.png"),
		TileType.ROOF: load("res://assets/tiles/roof.png"),
		TileType.TREE: load("res://assets/tiles/tree.png"),
		TileType.TREE_PINE: load("res://assets/tiles/tree_pine.png"),
		TileType.BUSH: load("res://assets/tiles/bush.png"),
		TileType.FLOWERS: load("res://assets/tiles/flowers.png"),
		TileType.BENCH: load("res://assets/tiles/bench.png"),
		TileType.LAMP_POST: load("res://assets/tiles/lamp_post.png"),
		TileType.FENCE: load("res://assets/tiles/fence.png"),
		TileType.FOUNTAIN: load("res://assets/tiles/fountain.png"),
		TileType.MAILBOX: load("res://assets/tiles/mailbox.png"),
		TileType.TRASH_CAN: load("res://assets/tiles/trash_can.png"),
		TileType.SIGN_SHOP: load("res://assets/tiles/sign_shop.png"),
	}

	# Track which tiles belong to a building (skip per-tile rendering for these)
	var building_tiles = {}
	for b in buildings:
		for cy in range(b.y, b.y + b.h):
			for cx in range(b.x, b.x + b.w):
				building_tiles[Vector2i(cx, cy)] = true

	# Render ground and prop tiles (skip building cells)
	for y in range(MAP_HEIGHT):
		for x in range(MAP_WIDTH):
			var tile_type = tile_map[y][x]
			var pos = Vector2(x * TILE_SIZE + TILE_SIZE / 2.0, y * TILE_SIZE + TILE_SIZE / 2.0)

			# Skip tiles that belong to a building — rendered separately
			if Vector2i(x, y) in building_tiles:
				# Still render grass underneath the building
				var grass_tex = tile_textures.get(TileType.GROUND_GRASS)
				if grass_tex:
					var bg = Sprite2D.new()
					bg.texture = grass_tex
					bg.position = pos
					var gs = grass_tex.get_size()
					bg.scale = Vector2(float(TILE_SIZE) / gs.x, float(TILE_SIZE) / gs.y)
					bg.z_index = -2
					add_child(bg)
				continue

			var texture = tile_textures.get(tile_type)
			if texture:
				var sprite = Sprite2D.new()
				sprite.texture = texture
				sprite.position = pos
				var tex_size = texture.get_size()
				sprite.scale = Vector2(float(TILE_SIZE) / tex_size.x, float(TILE_SIZE) / tex_size.y)
				sprite.z_index = -1
				add_child(sprite)

			# Props sit on grass — render grass underneath
			var wall_types_set = [TileType.WALL, TileType.WALL_BRICK, TileType.WALL_WOOD, TileType.ROOF]
			if tile_type not in walkable_tiles and tile_type not in wall_types_set:
				var grass_tex = tile_textures.get(TileType.GROUND_GRASS)
				if grass_tex:
					var bg = Sprite2D.new()
					bg.texture = grass_tex
					bg.position = pos
					var gs = grass_tex.get_size()
					bg.scale = Vector2(float(TILE_SIZE) / gs.x, float(TILE_SIZE) / gs.y)
					bg.z_index = -2
					add_child(bg)

	# Render each building as ONE sprite scaled to cover the full footprint
	for b in buildings:
		var texture = tile_textures.get(b.wall_type)
		if texture:
			var pixel_w = b.w * TILE_SIZE
			var pixel_h = b.h * TILE_SIZE
			var center_x = b.x * TILE_SIZE + pixel_w / 2.0
			var center_y = b.y * TILE_SIZE + pixel_h / 2.0

			var sprite = Sprite2D.new()
			sprite.texture = texture
			sprite.position = Vector2(center_x, center_y)
			var tex_size = texture.get_size()
			sprite.scale = Vector2(float(pixel_w) / tex_size.x, float(pixel_h) / tex_size.y)
			sprite.z_index = -1
			add_child(sprite)

func _spawn_player():
	var player_scene = preload("res://scenes/player.tscn")
	player = player_scene.instantiate()
	# Spawn at major road intersection (v_road 100 x h_road 75), with fallback
	var spawn = _find_nearest_walkable(Vector2i(100, 75))
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
		# Ensure NPC spawns on a walkable tile
		data.position = _find_nearest_walkable(data.position)
		var npc = npc_scene.instantiate()
		npc.setup(data)
		npcs.append(npc)
		add_child(npc)

func _process(delta):
	# Camera follows player and smooth zoom
	if player and camera:
		camera.position = player.position
		var current_zoom = camera.zoom.x
		var new_zoom = lerpf(current_zoom, target_zoom, delta * ZOOM_SMOOTH_SPEED)
		camera.zoom = Vector2(new_zoom, new_zoom)

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

	# Camera zoom — trackpad scroll / mouse wheel
	if event is InputEventMouseButton:
		if event.pressed:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				target_zoom = clampf(target_zoom + ZOOM_STEP, ZOOM_MIN, ZOOM_MAX)
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				target_zoom = clampf(target_zoom - ZOOM_STEP, ZOOM_MIN, ZOOM_MAX)

	# Camera zoom — trackpad pinch gesture
	if event is InputEventMagnifyGesture:
		target_zoom = clampf(target_zoom * event.factor, ZOOM_MIN, ZOOM_MAX)

	# Camera zoom — Cmd+/Cmd- (keyboard)
	if event is InputEventKey and event.pressed:
		if event.ctrl_pressed or event.meta_pressed:
			if event.keycode == KEY_EQUAL or event.keycode == KEY_PLUS:
				target_zoom = clampf(target_zoom + ZOOM_STEP, ZOOM_MIN, ZOOM_MAX)
			elif event.keycode == KEY_MINUS:
				target_zoom = clampf(target_zoom - ZOOM_STEP, ZOOM_MIN, ZOOM_MAX)
			elif event.keycode == KEY_0:
				target_zoom = 0.3  # Reset to default

func _get_move_step() -> int:
	# Move more tiles per step when zoomed out
	# At default zoom (0.3) = 1 tile, at full zoom out (0.02) = ~15 tiles
	var current_zoom = camera.zoom.x if camera else 0.3
	return max(1, roundi(0.3 / current_zoom))

func _try_move(direction: Vector2i):
	var step = _get_move_step()
	var current_pos = player.get_grid_position()
	var final_pos = current_pos

	# Walk forward tile by tile up to step count, stopping at first obstacle
	for i in range(1, step + 1):
		var check_pos = current_pos + direction * i

		# Check bounds
		if check_pos.x < 0 or check_pos.x >= MAP_WIDTH or check_pos.y < 0 or check_pos.y >= MAP_HEIGHT:
			break

		# Check collision with tiles
		if tile_map[check_pos.y][check_pos.x] not in walkable_tiles:
			break

		# Check collision with NPCs
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
		_start_dialogue(adjacent_npc)

func _start_dialogue(npc: NPC):
	active_dialogue = npc
	dialogue_index = 0
	dialogue_char_index = 0
	dialogue_timer = 0.0
	interact_prompt.visible = false
	dialogue_box.visible = true
	npc_name_label.text = npc.npc_name
	dialogue_text_label.text = ""

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
