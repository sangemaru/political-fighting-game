extends Node

## Input Manager
## Handles per-player input processing with input buffering system
## Tracks inputs for player 1 (p1_*) and player 2 (p2_*) separately


## Input buffer entry
class BufferedInput:
	var action: String
	var timestamp_ms: int
	var frame: int

	func _init(action: String, timestamp_ms: int, frame: int) -> void:
		self.action = action
		self.timestamp_ms = timestamp_ms
		self.frame = frame

## Per-player input state
var _movement: Dictionary = {1: Vector2.ZERO, 2: Vector2.ZERO}

## Input buffers per player
var _buffers: Dictionary = {1: [], 2: []}

## Buffer configuration
const BUFFER_WINDOW_FRAMES: int = 6  # ~100ms at 60fps
const BUFFER_MAX_SIZE: int = 16

## Current frame counter
var _current_frame: int = 0

## Player action prefixes
const PLAYER_PREFIXES = {1: "p1_", 2: "p2_"}

## Movement actions
const MOVE_ACTIONS = ["move_left", "move_right", "move_up", "move_down"]

## Attack actions (bufferable)
const ATTACK_ACTIONS = ["attack", "special"]


func _ready() -> void:
	set_process(true)


func _process(_delta: float) -> void:
	_current_frame += 1
	_update_movement_input()
	_update_buffered_input()
	_expire_old_buffer_entries()


## Update movement vectors for both players
func _update_movement_input() -> void:
	for player_id in [1, 2]:
		var prefix = PLAYER_PREFIXES[player_id]
		var movement = Vector2.ZERO

		if Input.is_action_pressed(prefix + "move_left"):
			movement.x -= 1.0
		if Input.is_action_pressed(prefix + "move_right"):
			movement.x += 1.0
		if Input.is_action_pressed(prefix + "move_up"):
			movement.y -= 1.0
		if Input.is_action_pressed(prefix + "move_down"):
			movement.y += 1.0

		_movement[player_id] = movement


## Check for new attack inputs and buffer them
func _update_buffered_input() -> void:
	var timestamp = Time.get_ticks_msec()

	for player_id in [1, 2]:
		var prefix = PLAYER_PREFIXES[player_id]
		for action in ATTACK_ACTIONS:
			if Input.is_action_just_pressed(prefix + action):
				var entry = BufferedInput.new(action, timestamp, _current_frame)
				_buffers[player_id].push_back(entry)
				# Keep buffer bounded
				if _buffers[player_id].size() > BUFFER_MAX_SIZE:
					_buffers[player_id].pop_front()


## Remove buffer entries older than the buffer window
func _expire_old_buffer_entries() -> void:
	for player_id in [1, 2]:
		var buffer: Array = _buffers[player_id]
		while buffer.size() > 0:
			var entry: BufferedInput = buffer[0]
			if _current_frame - entry.frame > BUFFER_WINDOW_FRAMES:
				buffer.pop_front()
			else:
				break


## Get the current movement input for a player as Vector2
func get_movement_input(player_id: int) -> Vector2:
	return _movement.get(player_id, Vector2.ZERO)


## Get the oldest buffered input for a player (peek, does not consume)
func get_buffered_input(player_id: int) -> String:
	var buffer: Array = _buffers.get(player_id, [])
	if buffer.is_empty():
		return ""
	return buffer[0].action


## Consume the oldest buffered input for a player (returns and removes it)
func consume_buffered_input(player_id: int) -> String:
	var buffer: Array = _buffers.get(player_id, [])
	if buffer.is_empty():
		return ""
	var entry: BufferedInput = buffer.pop_front()
	return entry.action


## Get buffer status for a player: {size, oldest_frame, newest_frame}
func get_buffer_status(player_id: int) -> Dictionary:
	var buffer: Array = _buffers.get(player_id, [])
	if buffer.is_empty():
		return {"size": 0, "oldest_frame": -1, "newest_frame": -1}
	return {
		"size": buffer.size(),
		"oldest_frame": buffer[0].frame,
		"newest_frame": buffer[buffer.size() - 1].frame
	}
