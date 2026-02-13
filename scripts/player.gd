extends Node2D
class_name Player

# Grid position
var grid_pos: Vector2i = Vector2i(5, 7)

# Tile size (must match world's TILE_SIZE)
const TILE_SIZE = 32

# Movement animation
var is_moving = false
const MOVE_DURATION = 0.15  # Seconds for smooth movement
const DIAGONAL_DURATION = 0.2  # Slightly slower for diagonal (longer distance)

# Facing direction
var last_direction = Vector2i(0, 1)  # Default facing down

@onready var sprite = $Sprite2D

func _ready():
	update_world_position()
	# Y-sort based on position
	z_index = 0
	y_sort_enabled = true

func set_grid_position(new_pos: Vector2i, animate: bool = true, direction: Vector2i = Vector2i(0, 0)):
	if direction != Vector2i(0, 0):
		last_direction = direction
		_update_sprite_direction()

	grid_pos = new_pos
	if animate and not is_moving:
		_animate_to_position()
	else:
		update_world_position()

func _update_sprite_direction():
	# Flip sprite horizontally for left/right movement
	if last_direction.x < 0:  # Moving left
		sprite.flip_h = true
	elif last_direction.x > 0:  # Moving right
		sprite.flip_h = false
	# Note: Up/down would need separate sprites in full implementation

func _animate_to_position():
	is_moving = true
	var target_pos = Vector2(grid_pos.x * TILE_SIZE + TILE_SIZE/2, grid_pos.y * TILE_SIZE + TILE_SIZE/2)

	# Diagonal movement is slightly slower (longer distance)
	var is_diagonal = abs(last_direction.x) + abs(last_direction.y) == 2
	var duration = DIAGONAL_DURATION if is_diagonal else MOVE_DURATION

	# Create tween for smooth movement
	var tween = create_tween()
	tween.tween_property(self, "position", target_pos, duration)
	tween.finished.connect(_on_move_finished)

func _on_move_finished():
	is_moving = false

func update_world_position():
	# Center sprite on tile (sprites are centered by default)
	position = Vector2(grid_pos.x * TILE_SIZE + TILE_SIZE/2, grid_pos.y * TILE_SIZE + TILE_SIZE/2)

func get_grid_position() -> Vector2i:
	return grid_pos
