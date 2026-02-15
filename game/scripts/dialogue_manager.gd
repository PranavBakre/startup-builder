extends Node
class_name DialogueManager

## Emitted when a dialogue ends. Passes the NPC that was being talked to.
signal dialogue_ended(npc: NPC)

# Typewriter speed
const CHAR_DELAY = 0.03

# Dialogue state
var active_npc: NPC = null
var dialogue_lines: Array = []
var line_index: int = 0
var char_index: int = 0
var _timer: float = 0.0

# UI references — set by world after scene is ready
var dialogue_box: Panel
var npc_name_label: Label
var dialogue_text_label: Label

## Whether a dialogue is currently active.
func is_active() -> bool:
	return active_npc != null

## Start a dialogue with the given NPC using the provided lines.
func start(npc: NPC, lines: Array):
	active_npc = npc
	dialogue_lines = lines
	line_index = 0
	char_index = 0
	_timer = 0.0
	dialogue_box.visible = true
	npc_name_label.text = npc.npc_name
	dialogue_text_label.text = ""

## Advance to the next line, or skip the typewriter to show the full line.
func advance():
	if char_index < dialogue_lines[line_index].length():
		# Still typing — skip to end of current line
		char_index = dialogue_lines[line_index].length()
		dialogue_text_label.text = dialogue_lines[line_index]
		return

	# Move to next dialogue line
	line_index += 1
	if line_index < dialogue_lines.size():
		char_index = 0
		_timer = 0.0
		dialogue_text_label.text = ""
	else:
		_end()

## Call every frame to drive the typewriter effect.
func process_typewriter(delta: float):
	if active_npc == null:
		return
	if char_index >= dialogue_lines[line_index].length():
		return

	_timer += delta
	if _timer >= CHAR_DELAY:
		_timer = 0.0
		char_index += 1
		var full_text = dialogue_lines[line_index]
		dialogue_text_label.text = full_text.substr(0, char_index)

func _end():
	var npc = active_npc
	dialogue_box.visible = false
	active_npc = null
	line_index = 0
	dialogue_ended.emit(npc)
