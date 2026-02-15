class_name TileRenderer

const TileType = MapGenerator.TileType

static var _tile_textures: Dictionary = {}

static func _ensure_textures():
	if _tile_textures.size() > 0:
		return
	_tile_textures = {
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

## Render all tiles and buildings as Sprite2D children of parent_node.
static func render(tile_map: Array, buildings: Array, walkable_tiles: Array,
		tile_size: int, map_width: int, map_height: int, parent_node: Node):
	_ensure_textures()

	# Track which tiles belong to a building (skip per-tile rendering for these)
	var building_tiles = {}
	for b in buildings:
		for cy in range(b.y, b.y + b.h):
			for cx in range(b.x, b.x + b.w):
				building_tiles[Vector2i(cx, cy)] = true

	var wall_types = [
		TileType.WALL, TileType.WALL_BRICK, TileType.WALL_WOOD, TileType.ROOF,
		TileType.WALL_SCHOOL, TileType.WALL_OFFICE, TileType.WALL_BUNGALOW
	]

	# Render ground and prop tiles (skip building cells)
	for y in range(map_height):
		for x in range(map_width):
			var tile_type = tile_map[y][x]
			var pos = Vector2(x * tile_size + tile_size / 2.0, y * tile_size + tile_size / 2.0)

			# Skip tiles that belong to a building — rendered separately
			if Vector2i(x, y) in building_tiles:
				# Still render grass underneath the building
				var grass_tex = _tile_textures.get(TileType.GROUND_GRASS)
				if grass_tex:
					var bg = Sprite2D.new()
					bg.texture = grass_tex
					bg.position = pos
					var gs = grass_tex.get_size()
					bg.scale = Vector2(float(tile_size) / gs.x, float(tile_size) / gs.y)
					bg.z_index = -2
					parent_node.add_child(bg)
				continue

			var texture = _tile_textures.get(tile_type)
			if texture:
				var sprite = Sprite2D.new()
				sprite.texture = texture
				sprite.position = pos
				var tex_size = texture.get_size()
				sprite.scale = Vector2(float(tile_size) / tex_size.x, float(tile_size) / tex_size.y)
				sprite.z_index = -1
				parent_node.add_child(sprite)

			# Props sit on grass — render grass underneath
			if tile_type not in walkable_tiles and tile_type not in wall_types:
				var grass_tex = _tile_textures.get(TileType.GROUND_GRASS)
				if grass_tex:
					var bg = Sprite2D.new()
					bg.texture = grass_tex
					bg.position = pos
					var gs = grass_tex.get_size()
					bg.scale = Vector2(float(tile_size) / gs.x, float(tile_size) / gs.y)
					bg.z_index = -2
					parent_node.add_child(bg)

	# Render each building as ONE sprite scaled to cover the full footprint
	for b in buildings:
		var texture = _tile_textures.get(b.wall_type)
		if texture:
			var pixel_w = b.w * tile_size
			var pixel_h = b.h * tile_size
			var center_x = b.x * tile_size + pixel_w / 2.0
			var center_y = b.y * tile_size + pixel_h / 2.0

			var sprite = Sprite2D.new()
			sprite.texture = texture
			sprite.position = Vector2(center_x, center_y)
			var tex_size = texture.get_size()
			sprite.scale = Vector2(float(pixel_w) / tex_size.x, float(pixel_h) / tex_size.y)
			sprite.z_index = -1
			parent_node.add_child(sprite)
