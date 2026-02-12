extends Area2D
class_name NPC

# NPC data
var npc_id: String
var npc_name: String
var grid_pos: Vector2i
var dialogue: Array  # Untyped array to avoid assignment errors
var problem: Dictionary

# Tile size (must match world's TILE_SIZE)
const TILE_SIZE = 32

func _ready():
	update_world_position()

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
		# Scale down from 1024x1024 to 32x32
		sprite.scale = Vector2(0.03125, 0.03125)
	else:
		print("ERROR: Could not load texture or find sprite for NPC: ", npc_id)

	update_world_position()

func update_world_position():
	position = Vector2(grid_pos.x * TILE_SIZE, grid_pos.y * TILE_SIZE)

func get_grid_position() -> Vector2i:
	return grid_pos
