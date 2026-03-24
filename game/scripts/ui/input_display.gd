extends Control

## Input Display Overlay (F67)
## Shows real-time button presses for each player as visual icons
## Can be toggled on/off, positioned at bottom corners of screen

class_name InputDisplay

## Which player this display tracks
@export var player_id: int = 1

## Input history settings
var max_history: int = 8
var input_history: Array[Dictionary] = []
var history_fade_time: float = 1.5

## Input state tracking
var current_inputs: Dictionary = {
	"left": false,
	"right": false,
	"up": false,
	"down": false,
	"attack": false,
	"special": false,
}

## Visual settings
var direction_size: float = 32.0
var button_size: float = 24.0
var padding: float = 8.0
var history_spacing: float = 28.0

## Colors
var active_color: Color = Color(1.0, 1.0, 0.2, 1.0)
var inactive_color: Color = Color(0.3, 0.3, 0.3, 0.5)
var attack_color: Color = Color(1.0, 0.3, 0.3, 1.0)
var special_color: Color = Color(0.3, 0.5, 1.0, 1.0)
var history_color: Color = Color(0.8, 0.8, 0.8, 0.7)


func _ready() -> void:
	# Set minimum size for the control
	custom_minimum_size = Vector2(160, 120)


func _process(delta: float) -> void:
	_poll_inputs()
	_update_history(delta)
	queue_redraw()


func _poll_inputs() -> void:
	var prefix = "p%d_" % player_id
	var prev_inputs = current_inputs.duplicate()

	current_inputs["left"] = Input.is_action_pressed(prefix + "move_left")
	current_inputs["right"] = Input.is_action_pressed(prefix + "move_right")
	current_inputs["up"] = Input.is_action_pressed(prefix + "move_up")
	current_inputs["down"] = Input.is_action_pressed(prefix + "move_down")
	current_inputs["attack"] = Input.is_action_pressed(prefix + "attack")
	current_inputs["special"] = Input.is_action_pressed(prefix + "special")

	# Record to history when inputs change
	var any_active = false
	for key in current_inputs:
		if current_inputs[key]:
			any_active = true
			break

	if any_active:
		var changed = false
		for key in current_inputs:
			if current_inputs[key] != prev_inputs[key]:
				changed = true
				break

		if changed:
			_add_to_history(current_inputs.duplicate())


func _add_to_history(inputs: Dictionary) -> void:
	input_history.push_front({"inputs": inputs, "age": 0.0})
	if input_history.size() > max_history:
		input_history.pop_back()


func _update_history(delta: float) -> void:
	var i = input_history.size() - 1
	while i >= 0:
		input_history[i]["age"] += delta
		if input_history[i]["age"] > history_fade_time:
			input_history.remove_at(i)
		i -= 1


func _draw() -> void:
	# Draw background panel
	var bg_rect = Rect2(Vector2.ZERO, size)
	draw_rect(bg_rect, Color(0.0, 0.0, 0.0, 0.4))

	# Draw directional pad (left side)
	var dpad_center = Vector2(direction_size + padding * 2, size.y * 0.4)
	_draw_dpad(dpad_center)

	# Draw action buttons (right of dpad)
	var button_start_x = dpad_center.x + direction_size + padding * 3
	_draw_action_buttons(Vector2(button_start_x, dpad_center.y))

	# Draw input history (below)
	var history_y = dpad_center.y + direction_size + padding * 2
	_draw_input_history(Vector2(padding, history_y))


func _draw_dpad(center: Vector2) -> void:
	var half = direction_size * 0.4

	# Up
	var up_color = active_color if current_inputs["up"] else inactive_color
	_draw_arrow(center + Vector2(0, -half * 1.5), Vector2.UP, half, up_color)

	# Down
	var down_color = active_color if current_inputs["down"] else inactive_color
	_draw_arrow(center + Vector2(0, half * 1.5), Vector2.DOWN, half, down_color)

	# Left
	var left_color = active_color if current_inputs["left"] else inactive_color
	_draw_arrow(center + Vector2(-half * 1.5, 0), Vector2.LEFT, half, left_color)

	# Right
	var right_color = active_color if current_inputs["right"] else inactive_color
	_draw_arrow(center + Vector2(half * 1.5, 0), Vector2.RIGHT, half, right_color)

	# Center dot
	draw_circle(center, 3.0, inactive_color)


func _draw_arrow(pos: Vector2, direction: Vector2, sz: float, color: Color) -> void:
	var rect = Rect2(pos - Vector2(sz * 0.5, sz * 0.5), Vector2(sz, sz))
	draw_rect(rect, color)


func _draw_action_buttons(pos: Vector2) -> void:
	var half = button_size * 0.5

	# Attack button (red circle)
	var atk_pos = pos + Vector2(0, -half - 2)
	var atk_color = attack_color if current_inputs["attack"] else inactive_color
	draw_circle(atk_pos, half, atk_color)
	_draw_button_label(atk_pos, "A")

	# Special button (blue circle)
	var spc_pos = pos + Vector2(0, half + 2)
	var spc_color = special_color if current_inputs["special"] else inactive_color
	draw_circle(spc_pos, half, spc_color)
	_draw_button_label(spc_pos, "S")


func _draw_button_label(pos: Vector2, text: String) -> void:
	# Simple label offset for centering
	draw_string(ThemeDB.fallback_font, pos + Vector2(-4, 5), text, HORIZONTAL_ALIGNMENT_CENTER, -1, 12, Color.WHITE)


func _draw_input_history(start_pos: Vector2) -> void:
	for i in range(input_history.size()):
		var entry = input_history[i]
		var alpha = 1.0 - (entry["age"] / history_fade_time)
		alpha = clampf(alpha, 0.0, 1.0)

		var y_offset = i * history_spacing * 0.6
		var pos = start_pos + Vector2(0, y_offset)

		var inputs = entry["inputs"]
		var notation = _inputs_to_notation(inputs)

		var color = history_color
		color.a = alpha
		draw_string(ThemeDB.fallback_font, pos, notation, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, color)


func _inputs_to_notation(inputs: Dictionary) -> String:
	var parts: PackedStringArray = []

	# Direction notation (numpad style)
	var h = 0
	var v = 0
	if inputs.get("left", false):
		h = -1
	elif inputs.get("right", false):
		h = 1
	if inputs.get("up", false):
		v = -1
	elif inputs.get("down", false):
		v = 1

	# Numpad notation: 5=neutral, 8=up, 2=down, 4=left, 6=right, etc.
	var numpad = 5 + h + (v * -3)
	if numpad != 5:
		parts.append(str(numpad))

	if inputs.get("attack", false):
		parts.append("A")
	if inputs.get("special", false):
		parts.append("S")

	return "+".join(parts) if parts.size() > 0 else ""
