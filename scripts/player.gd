extends Node2D
class_name Player

# Grid position
var grid_pos: Vector2i = Vector2i(5, 7)

# Tile size (must match world's TILE_SIZE)
const TILE_SIZE = 32

func _ready():
	update_world_position()

func set_grid_position(new_pos: Vector2i):
	grid_pos = new_pos
	update_world_position()

func update_world_position():
	position = Vector2(grid_pos.x * TILE_SIZE, grid_pos.y * TILE_SIZE)

func get_grid_position() -> Vector2i:
	return grid_pos
