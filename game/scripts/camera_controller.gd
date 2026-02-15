extends Camera2D
class_name CameraController

const ZOOM_MIN = 0.05
const ZOOM_MAX = 2.0
const ZOOM_STEP = 0.05
const ZOOM_SMOOTH_SPEED = 8.0

var target_zoom: float = 0.5

## Follow a target position and interpolate zoom. Call from _process().
func follow(target_pos: Vector2, delta: float):
	position = target_pos
	var current = zoom.x
	var new_zoom = lerpf(current, target_zoom, delta * ZOOM_SMOOTH_SPEED)
	zoom = Vector2(new_zoom, new_zoom)

## Handle zoom input events. Returns true if the event was consumed.
func handle_input(event: InputEvent) -> bool:
	# Mouse wheel
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			target_zoom = clampf(target_zoom + ZOOM_STEP, ZOOM_MIN, ZOOM_MAX)
			return true
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			target_zoom = clampf(target_zoom - ZOOM_STEP, ZOOM_MIN, ZOOM_MAX)
			return true

	# Trackpad pinch
	if event is InputEventMagnifyGesture:
		target_zoom = clampf(target_zoom * event.factor, ZOOM_MIN, ZOOM_MAX)
		return true

	# Keyboard: Cmd+/Cmd- / Cmd+0
	if event is InputEventKey and event.pressed:
		if event.ctrl_pressed or event.meta_pressed:
			if event.keycode == KEY_EQUAL or event.keycode == KEY_PLUS:
				target_zoom = clampf(target_zoom + ZOOM_STEP, ZOOM_MIN, ZOOM_MAX)
				return true
			elif event.keycode == KEY_MINUS:
				target_zoom = clampf(target_zoom - ZOOM_STEP, ZOOM_MIN, ZOOM_MAX)
				return true
			elif event.keycode == KEY_0:
				target_zoom = 0.5
				return true

	return false
