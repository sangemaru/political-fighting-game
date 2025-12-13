## InputManager - Singleton autoload for 2-player input handling
## Handles keyboard input for both players with input buffering for fighting game responsiveness
class_name InputManager
extends Node

# Input buffer constants
const BUFFER_FRAMES = 6  # ~100ms at 60fps
const MAX_PLAYERS = 2

# Input buffer: stores action press events with frame information
var input_buffer: Array[Dictionary] = []

# Frame counter for deterministic input tracking
var current_frame: int = 0

# Input action definitions - will be registered at startup
var player_actions: Dictionary = {
	1: {
		"move_left": "p1_left",
		"move_right": "p1_right",
		"move_up": "p1_up",
		"move_down": "p1_down",
		"attack": "p1_attack",
		"special": "p1_special"
	},
	2: {
		"move_left": "p2_left",
		"move_right": "p2_right",
		"move_up": "p2_up",
		"move_down": "p2_down",
		"attack": "p2_attack",
		"special": "p2_special"
	}
}

func _ready() -> void:
	## Initialize input actions at startup
	_register_input_actions()
	current_frame = 0


func _register_input_actions() -> void:
	## Register all input actions if they don't exist
	## This creates the actions at runtime if project.godot doesn't define them

	# Player 1 actions: WASD movement, JKL attacks
	_ensure_input_action("p1_left", [KEY_A])
	_ensure_input_action("p1_right", [KEY_D])
	_ensure_input_action("p1_up", [KEY_W])
	_ensure_input_action("p1_down", [KEY_S])
	_ensure_input_action("p1_attack", [KEY_J])
	_ensure_input_action("p1_special", [KEY_K])

	# Player 2 actions: Arrow keys movement, Numpad 1/2/3 attacks
	_ensure_input_action("p2_left", [KEY_LEFT])
	_ensure_input_action("p2_right", [KEY_RIGHT])
	_ensure_input_action("p2_up", [KEY_UP])
	_ensure_input_action("p2_down", [KEY_DOWN])
	_ensure_input_action("p2_attack", [KEY_KP_1])
	_ensure_input_action("p2_special", [KEY_KP_2])


func _ensure_input_action(action_name: String, keys: Array) -> void:
	## Helper to create input action if it doesn't exist
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
		for key in keys:
			var event = InputEventKey.new()
			event.keycode = key
			InputMap.action_add_event(action_name, event)


func _physics_process(_delta: float) -> void:
	## Called every physics frame to poll and buffer inputs
	## This is frame-synchronized and deterministic
	current_frame += 1

	# Poll inputs for both players
	_poll_player_input(1)
	_poll_player_input(2)

	# Clean up old buffer entries (older than BUFFER_FRAMES)
	_cleanup_buffer()


func _poll_player_input(player_id: int) -> void:
	## Poll all actions for a player and add pressed actions to buffer

	var actions = player_actions[player_id]

	for action_type in actions:
		var action_name = actions[action_type]

		# Check if action was just pressed this frame
		if Input.is_action_just_pressed(action_name):
			# Add to buffer with current frame information
			input_buffer.append({
				"player_id": player_id,
				"action": action_type,
				"action_name": action_name,
				"frame_pressed": current_frame,
				"consumed": false
			})


func _cleanup_buffer() -> void:
	## Remove buffer entries older than BUFFER_FRAMES
	var cutoff_frame = current_frame - BUFFER_FRAMES

	var i = 0
	while i < input_buffer.size():
		if input_buffer[i]["frame_pressed"] < cutoff_frame:
			input_buffer.remove_at(i)
		else:
			i += 1


func get_buffered_input(player_id: int, action: String) -> bool:
	## Check if an action was pressed within the buffer window
	## Returns true if action exists in buffer for this player, false otherwise
	## Does NOT consume the input - allows multiple checks

	var cutoff_frame = current_frame - BUFFER_FRAMES

	for entry in input_buffer:
		if entry["player_id"] == player_id and entry["action"] == action:
			# Only return true if within valid buffer window
			if entry["frame_pressed"] >= cutoff_frame:
				return true

	return false


func consume_buffered_input(player_id: int, action: String) -> bool:
	## Check and consume a buffered input
	## Returns true if input found and marked as consumed
	## Further calls for same input will fail until new frame press

	var cutoff_frame = current_frame - BUFFER_FRAMES

	for entry in input_buffer:
		if entry["player_id"] == player_id and entry["action"] == action:
			if entry["frame_pressed"] >= cutoff_frame and not entry["consumed"]:
				entry["consumed"] = true
				return true

	return false


func get_current_input(player_id: int, action: String) -> bool:
	## Get current frame input (held down)
	## Useful for continuous movement checking

	var action_name = player_actions[player_id][action]
	return Input.is_action_pressed(action_name)


func get_movement_input(player_id: int) -> Vector2:
	## Get movement direction for a player
	## Returns normalized direction vector based on current held inputs

	var direction = Vector2.ZERO

	if get_current_input(player_id, "move_left"):
		direction.x -= 1
	if get_current_input(player_id, "move_right"):
		direction.x += 1
	if get_current_input(player_id, "move_up"):
		direction.y -= 1
	if get_current_input(player_id, "move_down"):
		direction.y += 1

	return direction.normalized()


func get_buffer_status() -> Dictionary:
	## Debug function to inspect buffer state
	## Returns copy of current buffer for inspection

	return {
		"current_frame": current_frame,
		"buffer_size": input_buffer.size(),
		"buffer_frames": BUFFER_FRAMES,
		"entries": input_buffer.duplicate(true)
	}


func clear_buffer() -> void:
	## Clear all buffered inputs
	## Useful for scene transitions or special events

	input_buffer.clear()
