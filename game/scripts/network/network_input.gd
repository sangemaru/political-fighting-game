extends Node

## Network Input (F92)
## Wraps local and remote inputs for network play.
## Provides input prediction, delay buffering, and input encoding.
## Architecture prep -- correct interfaces for future networking integration.

class_name NetworkInput

## Input actions tracked per frame (matches project.godot input map)
const INPUT_ACTIONS := [
	"move_left", "move_right", "move_up", "move_down",
	"attack", "special"
]

## Bitmask positions for compact encoding
const BIT_MOVE_LEFT: int  = 1 << 0
const BIT_MOVE_RIGHT: int = 1 << 1
const BIT_MOVE_UP: int    = 1 << 2
const BIT_MOVE_DOWN: int  = 1 << 3
const BIT_ATTACK: int     = 1 << 4
const BIT_SPECIAL: int    = 1 << 5

## Input delay configuration
var input_delay_frames: int = 2  # Default 2-frame input delay
var local_player_id: int = 1

## Input buffers: frame -> encoded input (int bitmask)
var _local_buffer: Dictionary = {}   # Confirmed local inputs
var _remote_buffer: Dictionary = {}  # Confirmed remote inputs
var _predicted_buffer: Dictionary = {} # Predicted remote inputs


## Encode the current local input state into a bitmask.
## Uses player-prefixed action names (e.g., "p1_move_left").
static func encode_local_input(player_id: int) -> int:
	var encoded: int = 0
	var prefix := "p%d_" % player_id

	if Input.is_action_pressed(prefix + "move_left"):
		encoded |= BIT_MOVE_LEFT
	if Input.is_action_pressed(prefix + "move_right"):
		encoded |= BIT_MOVE_RIGHT
	if Input.is_action_pressed(prefix + "move_up"):
		encoded |= BIT_MOVE_UP
	if Input.is_action_pressed(prefix + "move_down"):
		encoded |= BIT_MOVE_DOWN
	if Input.is_action_just_pressed(prefix + "attack"):
		encoded |= BIT_ATTACK
	if Input.is_action_just_pressed(prefix + "special"):
		encoded |= BIT_SPECIAL

	return encoded


## Decode a bitmask back into a Dictionary of action states.
static func decode_input(encoded: int) -> Dictionary:
	return {
		"move_left":  bool(encoded & BIT_MOVE_LEFT),
		"move_right": bool(encoded & BIT_MOVE_RIGHT),
		"move_up":    bool(encoded & BIT_MOVE_UP),
		"move_down":  bool(encoded & BIT_MOVE_DOWN),
		"attack":     bool(encoded & BIT_ATTACK),
		"special":    bool(encoded & BIT_SPECIAL),
	}


## Convert a frame input to a Dictionary suitable for DeterministicFrame storage.
static func to_frame_input(encoded: int, confirmed: bool) -> Dictionary:
	var decoded := decode_input(encoded)
	decoded["encoded"] = encoded
	decoded["confirmed"] = confirmed
	return decoded


## Record local input for a frame (applies input delay).
## The input captured at frame N is scheduled for execution at frame N + delay.
func record_local(frame: int, encoded_input: int) -> void:
	var execute_frame: int = frame + input_delay_frames
	_local_buffer[execute_frame] = encoded_input


## Record confirmed remote input for a frame.
func record_remote(frame: int, encoded_input: int) -> void:
	_remote_buffer[frame] = encoded_input


## Get local input for a frame. Returns 0 if not available.
func get_local(frame: int) -> int:
	return _local_buffer.get(frame, 0)


## Get remote input for a frame.
## If confirmed input is not available, returns a prediction.
func get_remote(frame: int) -> int:
	# Return confirmed input if available
	if _remote_buffer.has(frame):
		return _remote_buffer[frame]

	# Otherwise predict (repeat last known input)
	var predicted := _predict_input(frame)
	_predicted_buffer[frame] = predicted
	return predicted


## Check if remote input for a frame is confirmed (not predicted).
func is_remote_confirmed(frame: int) -> bool:
	return _remote_buffer.has(frame)


## Check if a prediction was wrong for a given frame.
## Returns true if the confirmed input differs from what was predicted.
func was_mispredicted(frame: int) -> bool:
	if not _remote_buffer.has(frame):
		return false  # No confirmed input yet, can't tell
	if not _predicted_buffer.has(frame):
		return false  # Was never predicted, no misprediction

	return _remote_buffer[frame] != _predicted_buffer[frame]


## Get the earliest frame with a misprediction.
## Returns -1 if no mispredictions detected.
func get_earliest_misprediction() -> int:
	var earliest: int = -1
	for frame in _predicted_buffer:
		if _remote_buffer.has(frame):
			if _remote_buffer[frame] != _predicted_buffer[frame]:
				if earliest < 0 or frame < earliest:
					earliest = frame
	return earliest


## Predict remote input for a frame.
## Default strategy: repeat the last confirmed remote input.
func _predict_input(frame: int) -> int:
	# Find the most recent confirmed remote input
	var latest_frame: int = -1
	for f in _remote_buffer:
		if f <= frame and f > latest_frame:
			latest_frame = f

	if latest_frame >= 0:
		return _remote_buffer[latest_frame]

	return 0  # No history, predict idle


## Clear prediction history for frames that are now confirmed.
## Call after rollback to clean up stale predictions.
func clear_predictions_from(frame: int) -> void:
	var to_remove: Array = []
	for f in _predicted_buffer:
		if f >= frame:
			to_remove.append(f)
	for f in to_remove:
		_predicted_buffer.erase(f)


## Prune buffers to prevent unbounded growth.
## Keeps only the last max_frames of input history.
func prune(current_frame: int, max_frames: int = 120) -> void:
	var cutoff: int = current_frame - max_frames
	if cutoff <= 0:
		return

	for buffer in [_local_buffer, _remote_buffer, _predicted_buffer]:
		var to_remove: Array = []
		for frame in buffer:
			if frame < cutoff:
				to_remove.append(frame)
		for frame in to_remove:
			buffer.erase(frame)


## Reset all buffers for a new match.
func reset() -> void:
	_local_buffer.clear()
	_remote_buffer.clear()
	_predicted_buffer.clear()
