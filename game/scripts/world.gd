extends Node2D

# Tile types
enum TileType {
	GROUND, GROUND_GRASS, GROUND_DIRT, GROUND_SAND,
	WALL, WALL_BRICK, WALL_WOOD, ROOF,
	WALL_SCHOOL, WALL_OFFICE, WALL_BUNGALOW, PARK_GROUND,
	TREE, TREE_PINE, BUSH, FLOWERS,
	BENCH, LAMP_POST, FENCE, FOUNTAIN, MAILBOX, TRASH_CAN, SIGN_SHOP
}

# Tile size in pixels
const TILE_SIZE = 320

# Map dimensions — compact Indiranagar-inspired layout
const MAP_WIDTH = 60
const MAP_HEIGHT = 50

# The map (2D array of tile types)
var tile_map = []

# Building footprints: array of {x, y, w, h, wall_type}
var buildings = []

# Player reference
var player: Player

# NPCs list
var npcs: Array[NPC] = []

# NPC data — 5 NPCs placed around Indiranagar-inspired map
var npc_data = [
	{
		"id": "alex",
		"name": "Alex",
		"position": Vector2i(25, 23),  # 100 Feet Road, near cafes
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
		"position": Vector2i(12, 33),  # Main road near Indiranagar Park
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
		"position": Vector2i(42, 16),  # On 12th Main, bakery area
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
		"position": Vector2i(50, 36),  # Road intersection, east side
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
		"position": Vector2i(28, 46),  # Southern cross road, near school
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
const ZOOM_MIN = 0.05
const ZOOM_MAX = 2.0
const ZOOM_STEP = 0.05
const ZOOM_SMOOTH_SPEED = 8.0
var target_zoom = 0.5

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
	var rng = RandomNumberGenerator.new()
	rng.seed = 42

	# Initialize with grass
	for y in range(MAP_HEIGHT):
		var row = []
		for x in range(MAP_WIDTH):
			row.append(TileType.GROUND_GRASS)
		tile_map.append(row)

	# ============================================================
	# ROAD NETWORK — Indiranagar street grid
	# ============================================================
	# E-W: 100 Feet Road — THE main artery (2 tiles wide)
	for x in range(MAP_WIDTH):
		tile_map[23][x] = TileType.GROUND
		tile_map[24][x] = TileType.GROUND
	# E-W: 80 Feet Road — secondary artery (2 tiles wide)
	for x in range(MAP_WIDTH):
		tile_map[40][x] = TileType.GROUND
		tile_map[41][x] = TileType.GROUND
	# N-S: CMH Road — major north-south (2 tiles wide)
	for y in range(MAP_HEIGHT):
		tile_map[y][4] = TileType.GROUND
		tile_map[y][5] = TileType.GROUND
	# N-S: 12th Main — the famous cafe/commercial strip (2 tiles wide)
	for y in range(MAP_HEIGHT):
		tile_map[y][42] = TileType.GROUND
		tile_map[y][43] = TileType.GROUND
	# Cross streets (E-W, 2 tiles each)
	var cross_ys = [7, 14, 19, 30, 36, 46]
	for ry in cross_ys:
		for x in range(MAP_WIDTH):
			tile_map[ry][x] = TileType.GROUND
			tile_map[ry + 1][x] = TileType.GROUND
	# Main roads (N-S, 2 tiles each)
	var main_xs = [12, 20, 28, 35, 50, 56]
	for rx in main_xs:
		for y in range(MAP_HEIGHT):
			tile_map[y][rx] = TileType.GROUND
			tile_map[y][rx + 1] = TileType.GROUND

	# Border walls
	for x in range(MAP_WIDTH):
		tile_map[0][x] = TileType.WALL
		tile_map[49][x] = TileType.WALL
	for y in range(MAP_HEIGHT):
		tile_map[y][0] = TileType.WALL
		tile_map[y][59] = TileType.WALL

	# ============================================================
	# BUILDINGS — zone-based placement in city blocks
	# ============================================================
	# City blocks: grass rectangles between road lines
	var x_blocks = [
		[1, 3], [6, 11], [14, 19], [22, 27],
		[30, 34], [37, 41], [44, 49], [52, 55], [58, 58]
	]
	var y_blocks = [
		[1, 6], [9, 13], [16, 18], [21, 22],
		[25, 29], [32, 35], [38, 39], [42, 45], [48, 48]
	]

	# Blocks reserved for parks (exact match with x_blocks/y_blocks entries)
	var park_block_keys = [
		Vector4i(6, 11, 32, 35),   # Indiranagar Park
		Vector4i(52, 55, 42, 45),  # Defence Colony Playground
		Vector4i(6, 11, 9, 13)     # BDA Complex green / Metro area
	]

	# Blocks designated as schools (near Priya the teacher at 28,46)
	var school_block_keys = [
		Vector4i(30, 34, 42, 45),  # School near Defence Colony
		Vector4i(22, 27, 16, 18),  # School near 100 Feet Road
	]

	for xr in x_blocks:
		for yr in y_blocks:
			var block_w = xr[1] - xr[0] + 1
			var block_h = yr[1] - yr[0] + 1
			if block_w < 3 or block_h < 3:
				continue

			# Skip park blocks
			var is_park = false
			for pk in park_block_keys:
				if xr[0] == pk.x and xr[1] == pk.y and yr[0] == pk.z and yr[1] == pk.w:
					is_park = true
					break
			if is_park:
				continue

			# Check if this block is a school
			var is_school = false
			for sk in school_block_keys:
				if xr[0] == sk.x and xr[1] == sk.y and yr[0] == sk.z and yr[1] == sk.w:
					is_school = true
					break

			# Zone: commercial near 100ft Road or 12th Main
			var is_commercial = false
			if yr[0] >= 20 and yr[1] <= 29:
				is_commercial = true
			if xr[0] >= 36 and xr[1] <= 49:
				is_commercial = true

			# Wall type by zone and building purpose
			var wt
			if is_school:
				wt = TileType.WALL_SCHOOL
			elif is_commercial:
				var roll = rng.randf()
				if roll < 0.35:
					wt = TileType.WALL_OFFICE
				elif roll < 0.70:
					wt = TileType.WALL_BRICK
				else:
					wt = TileType.WALL
			else:
				var roll = rng.randf()
				if roll < 0.35:
					wt = TileType.WALL_BUNGALOW
				elif roll < 0.65:
					wt = TileType.WALL_WOOD
				else:
					wt = TileType.WALL_BRICK

			# Building fills most of block (1 tile grass buffer)
			var bw = maxi(3, block_w - rng.randi_range(0, 1))
			var bh = maxi(3, block_h - rng.randi_range(0, 1))
			var bx = xr[0] + rng.randi_range(0, maxi(0, block_w - bw))
			var by = yr[0] + rng.randi_range(0, maxi(0, block_h - bh))

			# Verify all tiles are grass
			var can_place = true
			for cy in range(by, by + bh):
				for cx in range(bx, bx + bw):
					if cx >= MAP_WIDTH or cy >= MAP_HEIGHT:
						can_place = false
						break
					if tile_map[cy][cx] != TileType.GROUND_GRASS:
						can_place = false
						break
				if not can_place:
					break
			if can_place:
				for cy in range(by, by + bh):
					for cx in range(bx, bx + bw):
						tile_map[cy][cx] = wt
				buildings.append({"x": bx, "y": by, "w": bw, "h": bh, "wall_type": wt})

	# ============================================================
	# PARKS — hand-placed Indiranagar landmarks
	# ============================================================
	# Fill park blocks with park ground texture
	for pk in park_block_keys:
		for py in range(pk.z, pk.w + 1):
			for px in range(pk.x, pk.y + 1):
				if tile_map[py][px] == TileType.GROUND_GRASS:
					tile_map[py][px] = TileType.PARK_GROUND

	# Park 1: Indiranagar Park (block x=6-11, y=31-35)
	var p1 = Vector2i(8, 33)
	tile_map[p1.y][p1.x] = TileType.FOUNTAIN
	for pos in [Vector2i(7, 32), Vector2i(9, 34)]:
		if tile_map[pos.y][pos.x] == TileType.PARK_GROUND:
			tile_map[pos.y][pos.x] = TileType.BENCH
	for pos in [Vector2i(10, 32), Vector2i(7, 34), Vector2i(9, 31)]:
		if tile_map[pos.y][pos.x] == TileType.PARK_GROUND:
			tile_map[pos.y][pos.x] = TileType.FLOWERS
	for _t in range(6):
		var px = p1.x + rng.randi_range(-2, 2)
		var py = p1.y + rng.randi_range(-2, 2)
		if px >= 6 and px <= 11 and py >= 31 and py <= 35:
			if tile_map[py][px] == TileType.PARK_GROUND:
				tile_map[py][px] = TileType.TREE if rng.randf() < 0.7 else TileType.TREE_PINE

	# Park 2: Defence Colony Playground (block x=51-55, y=41-45)
	var p2 = Vector2i(53, 43)
	tile_map[p2.y][p2.x] = TileType.FOUNTAIN
	if tile_map[42][52] == TileType.PARK_GROUND:
		tile_map[42][52] = TileType.BENCH
	if tile_map[44][54] == TileType.PARK_GROUND:
		tile_map[44][54] = TileType.FLOWERS
	for _t in range(4):
		var px = p2.x + rng.randi_range(-2, 2)
		var py = p2.y + rng.randi_range(-2, 2)
		if px >= 51 and px <= 55 and py >= 41 and py <= 45:
			if tile_map[py][px] == TileType.PARK_GROUND:
				tile_map[py][px] = TileType.TREE if rng.randf() < 0.7 else TileType.TREE_PINE

	# Park 3: BDA Complex / Metro green (block x=6-11, y=8-13)
	var p3 = Vector2i(8, 10)
	tile_map[p3.y][p3.x] = TileType.FOUNTAIN
	if tile_map[9][7] == TileType.PARK_GROUND:
		tile_map[9][7] = TileType.BENCH
	if tile_map[11][10] == TileType.PARK_GROUND:
		tile_map[11][10] = TileType.FLOWERS
	for _t in range(5):
		var px = p3.x + rng.randi_range(-2, 2)
		var py = p3.y + rng.randi_range(-2, 2)
		if px >= 6 and px <= 11 and py >= 8 and py <= 13:
			if tile_map[py][px] == TileType.PARK_GROUND:
				tile_map[py][px] = TileType.TREE if rng.randf() < 0.7 else TileType.TREE_PINE

	# ============================================================
	# TREE-LINED STREETS — Indiranagar's signature look
	# ============================================================
	# Major roads: trees + lamp posts alternating every 2 tiles
	# 100 Feet Road — trees on y=22 (north) and y=25 (south)
	for x in range(2, MAP_WIDTH - 2, 2):
		var use_lamp = (x % 6 == 0)
		var tt = TileType.LAMP_POST if use_lamp else (TileType.TREE if rng.randf() < 0.7 else TileType.TREE_PINE)
		if tile_map[22][x] == TileType.GROUND_GRASS:
			tile_map[22][x] = tt
		if tile_map[25][x] == TileType.GROUND_GRASS:
			tile_map[25][x] = tt

	# CMH Road — trees on x=3 (west) and x=6 (east)
	for y in range(2, MAP_HEIGHT - 2, 2):
		var use_lamp = (y % 6 == 0)
		var tt = TileType.LAMP_POST if use_lamp else (TileType.TREE if rng.randf() < 0.7 else TileType.TREE_PINE)
		if tile_map[y][3] == TileType.GROUND_GRASS:
			tile_map[y][3] = tt
		if tile_map[y][6] == TileType.GROUND_GRASS:
			tile_map[y][6] = tt

	# All other roads: trees on both sides every 3 tiles (roads are now 2 tiles wide)
	# E-W roads: top edge at ry, bottom edge at ry+1; trees at ry-1 and ry+2
	# 80 Feet Road: 40-41; Cross streets: each ry and ry+1
	var all_ew_roads_top = [7, 14, 19, 30, 36, 40, 46]
	for ry in all_ew_roads_top:
		for x in range(2, MAP_WIDTH - 2, 3):
			if ry > 1 and tile_map[ry - 1][x] == TileType.GROUND_GRASS:
				tile_map[ry - 1][x] = TileType.TREE if rng.randf() < 0.7 else TileType.TREE_PINE
			if ry + 2 < MAP_HEIGHT - 1 and tile_map[ry + 2][x] == TileType.GROUND_GRASS:
				tile_map[ry + 2][x] = TileType.TREE if rng.randf() < 0.7 else TileType.TREE_PINE
	# N-S roads: left edge at rx, right edge at rx+1; trees at rx-1 and rx+2
	# 12th Main: 42-43; Main roads: each rx and rx+1
	var all_ns_roads_left = [12, 20, 28, 35, 42, 50, 56]
	for rx in all_ns_roads_left:
		for y in range(2, MAP_HEIGHT - 2, 3):
			if rx > 1 and tile_map[y][rx - 1] == TileType.GROUND_GRASS:
				tile_map[y][rx - 1] = TileType.TREE if rng.randf() < 0.7 else TileType.TREE_PINE
			if rx + 2 < MAP_WIDTH - 1 and tile_map[y][rx + 2] == TileType.GROUND_GRASS:
				tile_map[y][rx + 2] = TileType.TREE if rng.randf() < 0.7 else TileType.TREE_PINE

	# ============================================================
	# STREET FURNITURE — benches, trash cans, signs along roads
	# ============================================================
	for _i in range(25):
		var fx = rng.randi_range(2, MAP_WIDTH - 3)
		var fy = rng.randi_range(2, MAP_HEIGHT - 3)
		if tile_map[fy][fx] != TileType.GROUND_GRASS:
			continue
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

	# ============================================================
	# VEGETATION — bushes, flowers, fences in remaining grass
	# ============================================================
	for _i in range(20):
		var bx = rng.randi_range(2, MAP_WIDTH - 3)
		var by = rng.randi_range(2, MAP_HEIGHT - 3)
		if tile_map[by][bx] != TileType.GROUND_GRASS:
			continue
		var near_tree = false
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				var nx = bx + dx
				var ny = by + dy
				if nx >= 0 and nx < MAP_WIDTH and ny >= 0 and ny < MAP_HEIGHT:
					if tile_map[ny][nx] in [TileType.TREE, TileType.TREE_PINE]:
						near_tree = true
		if near_tree:
			tile_map[by][bx] = TileType.BUSH

	for _i in range(10):
		var fx = rng.randi_range(2, MAP_WIDTH - 3)
		var fy = rng.randi_range(2, MAP_HEIGHT - 3)
		if tile_map[fy][fx] == TileType.GROUND_GRASS:
			tile_map[fy][fx] = TileType.FLOWERS

	for _i in range(8):
		var fx = rng.randi_range(2, MAP_WIDTH - 3)
		var fy = rng.randi_range(2, MAP_HEIGHT - 3)
		if tile_map[fy][fx] != TileType.GROUND_GRASS:
			continue
		var near_building = false
		for d in [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]:
			var nx = fx + d.x
			var ny = fy + d.y
			if nx >= 0 and nx < MAP_WIDTH and ny >= 0 and ny < MAP_HEIGHT:
				if tile_map[ny][nx] in [TileType.WALL, TileType.WALL_BRICK, TileType.WALL_WOOD, TileType.WALL_SCHOOL, TileType.WALL_OFFICE, TileType.WALL_BUNGALOW]:
					near_building = true
					break
		if near_building:
			tile_map[fy][fx] = TileType.FENCE

	# Dirt paths off roads
	for _i in range(6):
		var sx = rng.randi_range(3, MAP_WIDTH - 4)
		var sy = rng.randi_range(3, MAP_HEIGHT - 4)
		if tile_map[sy][sx] == TileType.GROUND:
			var dx = rng.randi_range(-1, 1)
			var dy = 1 if dx == 0 else 0
			var cx = sx
			var cy = sy
			for _s in range(rng.randi_range(2, 4)):
				cx += dx
				cy += dy
				if cx > 1 and cx < MAP_WIDTH - 2 and cy > 1 and cy < MAP_HEIGHT - 2:
					if tile_map[cy][cx] == TileType.GROUND_GRASS:
						tile_map[cy][cx] = TileType.GROUND_DIRT

# Walkable tile types
var walkable_tiles = [
	TileType.GROUND, TileType.GROUND_GRASS, TileType.GROUND_DIRT, TileType.GROUND_SAND,
	TileType.PARK_GROUND
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
		TileType.WALL_SCHOOL: load("res://assets/tiles/wall_school.png"),
		TileType.WALL_OFFICE: load("res://assets/tiles/wall_office.png"),
		TileType.WALL_BUNGALOW: load("res://assets/tiles/wall_bungalow.png"),
		TileType.PARK_GROUND: load("res://assets/tiles/park_ground.png"),
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
			var wall_types_set = [TileType.WALL, TileType.WALL_BRICK, TileType.WALL_WOOD, TileType.ROOF, TileType.WALL_SCHOOL, TileType.WALL_OFFICE, TileType.WALL_BUNGALOW]
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
	# Spawn at 100 Feet Road x CMH Road intersection (x=5, y=23)
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
				target_zoom = 0.5  # Reset to default

func _get_move_step() -> int:
	# Move more tiles per step when zoomed out
	# At default zoom (0.5) = 1 tile, scales up when zoomed out
	var current_zoom = camera.zoom.x if camera else 0.5
	return max(1, roundi(0.5 / current_zoom))

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
