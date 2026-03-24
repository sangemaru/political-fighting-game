extends Node

## Deterministic Frame Manager (F91)
## Enforces fixed timestep simulation and collects per-frame inputs.
## Foundation for rollback netcode -- ensures both peers simulate identically.

class_name DeterministicFrame

## Signals
signal frame_advanced(frame_number: int)

## Constants
const FRAMES_PER_SECOND: int = 60
const FRAME_DURATION: float = 1.0 / FRAMES_PER_SECOND

## Frame tracking
var current_frame: int = 0
var is_running: bool = false

## Input history: frame_number -> {player_id: NetworkInput.FrameInput}
var input_history: Dictionary = {}

## Maximum input history to keep (matches rollback window)
var max_history_frames: int = 120  # 2 seconds at 60 FPS


func _ready() -> void:
	set_physics_process(false)


## Start the deterministic frame simulation.
func start() -> void:
	current_frame = 0
	is_running = true
	input_history.clear()
	set_physics_process(true)
	print("[DeterministicFrame] Started at frame 0")


## Stop the simulation.
func stop() -> void:
	is_running = false
	set_physics_process(false)
	print("[DeterministicFrame] Stopped at frame %d" % current_frame)


## Advance one frame. Called from _physics_process for fixed timestep.
func advance_frame() -> void:
	if not is_running:
		return

	current_frame += 1
	frame_advanced.emit(current_frame)

	# Prune old input history
	_prune_history()


func _physics_process(_delta: float) -> void:
	# _physics_process runs at the fixed tick rate (60 Hz from project.godot)
	# so each call = one deterministic frame
	if is_running:
		advance_frame()


## Record input for a specific player at a specific frame.
func record_input(frame: int, player_id: int, input_data: Dictionary) -> void:
	if not input_history.has(frame):
		input_history[frame] = {}
	input_history[frame][player_id] = input_data


## Get recorded input for a player at a specific frame.
## Returns empty Dictionary if no input recorded.
func get_input(frame: int, player_id: int) -> Dictionary:
	if input_history.has(frame) and input_history[frame].has(player_id):
		return input_history[frame][player_id]
	return {}


## Check if we have confirmed (non-predicted) input for a frame.
func has_confirmed_input(frame: int, player_id: int) -> bool:
	if not input_history.has(frame):
		return false
	if not input_history[frame].has(player_id):
		return false
	return input_history[frame][player_id].get("confirmed", false)


## Get the latest frame for which we have confirmed input from a player.
func get_latest_confirmed_frame(player_id: int) -> int:
	var latest: int = -1
	for frame in input_history:
		if input_history[frame].has(player_id):
			if input_history[frame][player_id].get("confirmed", false):
				if frame > latest:
					latest = frame
	return latest


## Reset frame state for a new match.
func reset() -> void:
	current_frame = 0
	input_history.clear()
	is_running = false
	set_physics_process(false)


## Prune input history older than max_history_frames.
func _prune_history() -> void:
	var cutoff: int = current_frame - max_history_frames
	if cutoff <= 0:
		return

	var frames_to_remove: Array = []
	for frame in input_history:
		if frame < cutoff:
			frames_to_remove.append(frame)

	for frame in frames_to_remove:
		input_history.erase(frame)
