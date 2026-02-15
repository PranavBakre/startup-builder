class_name MapGenerator

# Tile types — mirrors TileType enum in world.gd
enum TileType {
	GROUND, GROUND_GRASS, GROUND_DIRT, GROUND_SAND,
	WALL, WALL_BRICK, WALL_WOOD, ROOF,
	WALL_SCHOOL, WALL_OFFICE, WALL_BUNGALOW, PARK_GROUND,
	TREE, TREE_PINE, BUSH, FLOWERS,
	BENCH, LAMP_POST, FENCE, FOUNTAIN, MAILBOX, TRASH_CAN, SIGN_SHOP
}

## Generate the full map and return {tile_map, buildings}.
## Pure computation — no node dependencies.
static func generate(map_width: int, map_height: int) -> Dictionary:
	var tile_map: Array = []
	var buildings: Array = []
	var rng = RandomNumberGenerator.new()
	rng.seed = 42

	# Initialize with grass
	for y in range(map_height):
		var row = []
		for x in range(map_width):
			row.append(TileType.GROUND_GRASS)
		tile_map.append(row)

	# ============================================================
	# ROAD NETWORK — Indiranagar street grid
	# ============================================================
	# E-W: 100 Feet Road — THE main artery (2 tiles wide)
	for x in range(map_width):
		tile_map[23][x] = TileType.GROUND
		tile_map[24][x] = TileType.GROUND
	# E-W: 80 Feet Road — secondary artery (2 tiles wide)
	for x in range(map_width):
		tile_map[40][x] = TileType.GROUND
		tile_map[41][x] = TileType.GROUND
	# N-S: CMH Road — major north-south (2 tiles wide)
	for y in range(map_height):
		tile_map[y][4] = TileType.GROUND
		tile_map[y][5] = TileType.GROUND
	# N-S: 12th Main — the famous cafe/commercial strip (2 tiles wide)
	for y in range(map_height):
		tile_map[y][42] = TileType.GROUND
		tile_map[y][43] = TileType.GROUND
	# Cross streets (E-W, 2 tiles each)
	var cross_ys = [7, 14, 19, 30, 36, 46]
	for ry in cross_ys:
		for x in range(map_width):
			tile_map[ry][x] = TileType.GROUND
			tile_map[ry + 1][x] = TileType.GROUND
	# Main roads (N-S, 2 tiles each)
	var main_xs = [12, 20, 28, 35, 50, 56]
	for rx in main_xs:
		for y in range(map_height):
			tile_map[y][rx] = TileType.GROUND
			tile_map[y][rx + 1] = TileType.GROUND

	# Border walls
	for x in range(map_width):
		tile_map[0][x] = TileType.WALL
		tile_map[49][x] = TileType.WALL
	for y in range(map_height):
		tile_map[y][0] = TileType.WALL
		tile_map[y][59] = TileType.WALL

	# ============================================================
	# BUILDINGS — zone-based placement in city blocks
	# ============================================================
	var x_blocks = [
		[1, 3], [6, 11], [14, 19], [22, 27],
		[30, 34], [37, 41], [44, 49], [52, 55], [58, 58]
	]
	var y_blocks = [
		[1, 6], [9, 13], [16, 18], [21, 22],
		[25, 29], [32, 35], [38, 39], [42, 45], [48, 48]
	]

	var park_block_keys = [
		Vector4i(6, 11, 32, 35),
		Vector4i(52, 55, 42, 45),
		Vector4i(6, 11, 9, 13)
	]

	var school_block_keys = [
		Vector4i(30, 34, 42, 45),
		Vector4i(22, 27, 16, 18),
	]

	for xr in x_blocks:
		for yr in y_blocks:
			var block_w = xr[1] - xr[0] + 1
			var block_h = yr[1] - yr[0] + 1
			if block_w < 3 or block_h < 3:
				continue

			var is_park = false
			for pk in park_block_keys:
				if xr[0] == pk.x and xr[1] == pk.y and yr[0] == pk.z and yr[1] == pk.w:
					is_park = true
					break
			if is_park:
				continue

			var is_school = false
			for sk in school_block_keys:
				if xr[0] == sk.x and xr[1] == sk.y and yr[0] == sk.z and yr[1] == sk.w:
					is_school = true
					break

			var is_commercial = false
			if yr[0] >= 20 and yr[1] <= 29:
				is_commercial = true
			if xr[0] >= 36 and xr[1] <= 49:
				is_commercial = true

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

			var bw = maxi(3, block_w - rng.randi_range(0, 1))
			var bh = maxi(3, block_h - rng.randi_range(0, 1))
			var bx = xr[0] + rng.randi_range(0, maxi(0, block_w - bw))
			var by = yr[0] + rng.randi_range(0, maxi(0, block_h - bh))

			var can_place = true
			for cy in range(by, by + bh):
				for cx in range(bx, bx + bw):
					if cx >= map_width or cy >= map_height:
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
	for x in range(2, map_width - 2, 2):
		var use_lamp = (x % 6 == 0)
		var tt = TileType.LAMP_POST if use_lamp else (TileType.TREE if rng.randf() < 0.7 else TileType.TREE_PINE)
		if tile_map[22][x] == TileType.GROUND_GRASS:
			tile_map[22][x] = tt
		if tile_map[25][x] == TileType.GROUND_GRASS:
			tile_map[25][x] = tt

	for y in range(2, map_height - 2, 2):
		var use_lamp = (y % 6 == 0)
		var tt = TileType.LAMP_POST if use_lamp else (TileType.TREE if rng.randf() < 0.7 else TileType.TREE_PINE)
		if tile_map[y][3] == TileType.GROUND_GRASS:
			tile_map[y][3] = tt
		if tile_map[y][6] == TileType.GROUND_GRASS:
			tile_map[y][6] = tt

	var all_ew_roads_top = [7, 14, 19, 30, 36, 40, 46]
	for ry in all_ew_roads_top:
		for x in range(2, map_width - 2, 3):
			if ry > 1 and tile_map[ry - 1][x] == TileType.GROUND_GRASS:
				tile_map[ry - 1][x] = TileType.TREE if rng.randf() < 0.7 else TileType.TREE_PINE
			if ry + 2 < map_height - 1 and tile_map[ry + 2][x] == TileType.GROUND_GRASS:
				tile_map[ry + 2][x] = TileType.TREE if rng.randf() < 0.7 else TileType.TREE_PINE
	var all_ns_roads_left = [12, 20, 28, 35, 42, 50, 56]
	for rx in all_ns_roads_left:
		for y in range(2, map_height - 2, 3):
			if rx > 1 and tile_map[y][rx - 1] == TileType.GROUND_GRASS:
				tile_map[y][rx - 1] = TileType.TREE if rng.randf() < 0.7 else TileType.TREE_PINE
			if rx + 2 < map_width - 1 and tile_map[y][rx + 2] == TileType.GROUND_GRASS:
				tile_map[y][rx + 2] = TileType.TREE if rng.randf() < 0.7 else TileType.TREE_PINE

	# ============================================================
	# STREET FURNITURE — benches, trash cans, signs along roads
	# ============================================================
	for _i in range(25):
		var fx = rng.randi_range(2, map_width - 3)
		var fy = rng.randi_range(2, map_height - 3)
		if tile_map[fy][fx] != TileType.GROUND_GRASS:
			continue
		var next_to_road = false
		for d in [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]:
			var nx = fx + d.x
			var ny = fy + d.y
			if nx >= 0 and nx < map_width and ny >= 0 and ny < map_height:
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
		var bx = rng.randi_range(2, map_width - 3)
		var by = rng.randi_range(2, map_height - 3)
		if tile_map[by][bx] != TileType.GROUND_GRASS:
			continue
		var near_tree = false
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				var nx = bx + dx
				var ny = by + dy
				if nx >= 0 and nx < map_width and ny >= 0 and ny < map_height:
					if tile_map[ny][nx] in [TileType.TREE, TileType.TREE_PINE]:
						near_tree = true
		if near_tree:
			tile_map[by][bx] = TileType.BUSH

	for _i in range(10):
		var fx = rng.randi_range(2, map_width - 3)
		var fy = rng.randi_range(2, map_height - 3)
		if tile_map[fy][fx] == TileType.GROUND_GRASS:
			tile_map[fy][fx] = TileType.FLOWERS

	for _i in range(8):
		var fx = rng.randi_range(2, map_width - 3)
		var fy = rng.randi_range(2, map_height - 3)
		if tile_map[fy][fx] != TileType.GROUND_GRASS:
			continue
		var near_building = false
		for d in [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]:
			var nx = fx + d.x
			var ny = fy + d.y
			if nx >= 0 and nx < map_width and ny >= 0 and ny < map_height:
				if tile_map[ny][nx] in [TileType.WALL, TileType.WALL_BRICK, TileType.WALL_WOOD, TileType.WALL_SCHOOL, TileType.WALL_OFFICE, TileType.WALL_BUNGALOW]:
					near_building = true
					break
		if near_building:
			tile_map[fy][fx] = TileType.FENCE

	# Dirt paths off roads
	for _i in range(6):
		var sx = rng.randi_range(3, map_width - 4)
		var sy = rng.randi_range(3, map_height - 4)
		if tile_map[sy][sx] == TileType.GROUND:
			var dx = rng.randi_range(-1, 1)
			var dy = 1 if dx == 0 else 0
			var cx = sx
			var cy = sy
			for _s in range(rng.randi_range(2, 4)):
				cx += dx
				cy += dy
				if cx > 1 and cx < map_width - 2 and cy > 1 and cy < map_height - 2:
					if tile_map[cy][cx] == TileType.GROUND_GRASS:
						tile_map[cy][cx] = TileType.GROUND_DIRT

	return {"tile_map": tile_map, "buildings": buildings}
