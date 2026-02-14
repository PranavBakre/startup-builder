extends Area2D
class_name NPC

# NPC data
var npc_id: String
var npc_name: String
var grid_pos: Vector2i
var dialogue: Array  # Untyped array to avoid assignment errors
var problem: Dictionary

# Tile size (must match world's TILE_SIZE)
const TILE_SIZE = 320

func _ready():
	update_world_position()
	# Y-sort based on position
	z_index = 0
	y_sort_enabled = true

func setup(data: Dictionary):
	npc_id = data.get("id", "")
	npc_name = data.get("name", "Unknown")
	grid_pos = data.get("position", Vector2i(0, 0))
	dialogue = data.get("dialogue", [])
	problem = data.get("problem", {})

	# Load appropriate texture based on NPC ID
	var texture_path = "res://assets/characters/npc_" + npc_id + ".png"
	var texture = load(texture_path)
	var sprite = $Sprite2D
	if texture and sprite:
		sprite.texture = texture
		# Scale from source texture to TILE_SIZE
		var tex_size = texture.get_size()
		sprite.scale = Vector2(float(TILE_SIZE) * 0.6 / tex_size.x, float(TILE_SIZE) * 0.6 / tex_size.y)
	else:
		print("ERROR: Could not load texture or find sprite for NPC: ", npc_id)

	update_world_position()

func update_world_position():
	# Center sprite on tile (sprites are centered by default)
	position = Vector2(grid_pos.x * TILE_SIZE + TILE_SIZE / 2.0, grid_pos.y * TILE_SIZE + TILE_SIZE / 2.0)

func get_grid_position() -> Vector2i:
	return grid_pos
