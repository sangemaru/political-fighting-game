extends Node

## Rollback Manager (F92)
## Manages state snapshots for rollback netcode.
## Provides a ring buffer of game state snapshots and rollback/resimulation.
## This is architecture prep -- stubs with correct interfaces, not full networking.

class_name RollbackManager

## Signals
signal rollback_started(from_frame: int, to_frame: int)
signal rollback_completed(frames_resimulated: int)

## Configuration
const MAX_ROLLBACK_FRAMES: int = 8  # Maximum frames to roll back
const RING_BUFFER_SIZE: int = 10    # Slightly larger than max rollback

## State snapshot ring buffer
## Array of {frame: int, state: Dictionary}
var _snapshots: Array = []
var _write_index: int = 0

## Rollback tracking
var _is_rolling_back: bool = false
var rollback_count: int = 0  # Total rollbacks this match (for stats)
var frames_resimulated: int = 0  # Total frames resimulated (for stats)

## References (set by battle scene during initialization)
var game_manager: Node = null
var fighters: Dictionary = {}


func _ready() -> void:
	# Pre-allocate ring buffer
	_snapshots.resize(RING_BUFFER_SIZE)
	for i in RING_BUFFER_SIZE:
		_snapshots[i] = {"frame": -1, "state": {}}


## Initialize with references to game state holders.
func initialize(gm: Node, fighter_refs: Dictionary) -> void:
	game_manager = gm
	fighters = fighter_refs
	_write_index = 0
	rollback_count = 0
	frames_resimulated = 0
	for i in RING_BUFFER_SIZE:
		_snapshots[i] = {"frame": -1, "state": {}}
	print("[RollbackManager] Initialized with %d snapshot slots" % RING_BUFFER_SIZE)


## Save a snapshot of the current game state.
## Should be called once per frame before input processing.
func save_snapshot(frame: int) -> void:
	if game_manager == null:
		return

	var state := NetworkState.capture_state(game_manager, fighters)
	_snapshots[_write_index] = {"frame": frame, "state": state}
	_write_index = (_write_index + 1) % RING_BUFFER_SIZE


## Get the snapshot for a specific frame.
## Returns empty Dictionary if the frame is not in the buffer.
func get_snapshot(frame: int) -> Dictionary:
	for i in RING_BUFFER_SIZE:
		if _snapshots[i]["frame"] == frame:
			return _snapshots[i]["state"]
	return {}


## Check if a snapshot exists for a given frame.
func has_snapshot(frame: int) -> bool:
	for i in RING_BUFFER_SIZE:
		if _snapshots[i]["frame"] == frame:
			return true
	return false


## Get the oldest frame still in the ring buffer.
func get_oldest_snapshot_frame() -> int:
	var oldest: int = -1
	for i in RING_BUFFER_SIZE:
		var f: int = _snapshots[i]["frame"]
		if f >= 0 and (oldest < 0 or f < oldest):
			oldest = f
	return oldest


## Get the newest frame in the ring buffer.
func get_newest_snapshot_frame() -> int:
	var newest: int = -1
	for i in RING_BUFFER_SIZE:
		var f: int = _snapshots[i]["frame"]
		if f > newest:
			newest = f
	return newest


## Perform a rollback to the specified frame.
## Returns the number of frames that need resimulation, or -1 on failure.
##
## The caller is responsible for resimulating frames after this call:
##   1. Call rollback(target_frame)
##   2. For each frame from target_frame+1 to current_frame:
##      a. Apply corrected inputs
##      b. Advance simulation one frame
##      c. Save new snapshot
##   3. Call finish_rollback()
func rollback(target_frame: int) -> int:
	if _is_rolling_back:
		push_warning("[RollbackManager] Already rolling back, ignoring nested rollback")
		return -1

	if game_manager == null:
		push_error("[RollbackManager] No game_manager reference set")
		return -1

	# Check if we have the snapshot
	var snapshot := get_snapshot(target_frame)
	if snapshot.is_empty():
		push_warning("[RollbackManager] No snapshot for frame %d" % target_frame)
		return -1

	# Check rollback distance
	var current_frame: int = game_manager.battle_frame
	var distance: int = current_frame - target_frame
	if distance > MAX_ROLLBACK_FRAMES:
		push_warning("[RollbackManager] Rollback distance %d exceeds max %d" % [distance, MAX_ROLLBACK_FRAMES])
		return -1

	if distance <= 0:
		return 0  # Nothing to roll back

	# Perform the rollback
	_is_rolling_back = true
	rollback_count += 1

	print("[RollbackManager] Rolling back from frame %d to %d (%d frames)" % [
		current_frame, target_frame, distance
	])

	rollback_started.emit(target_frame, current_frame)

	# Restore state
	NetworkState.restore_state(snapshot, game_manager, fighters)

	return distance


## Call after resimulation is complete.
func finish_rollback(frames_count: int) -> void:
	_is_rolling_back = false
	frames_resimulated += frames_count
	rollback_completed.emit(frames_count)
	print("[RollbackManager] Rollback complete, resimulated %d frames" % frames_count)


## Whether we are currently in a rollback.
func is_rolling_back() -> bool:
	return _is_rolling_back


## Reset for a new match.
func reset() -> void:
	_write_index = 0
	_is_rolling_back = false
	rollback_count = 0
	frames_resimulated = 0
	for i in RING_BUFFER_SIZE:
		_snapshots[i] = {"frame": -1, "state": {}}


## Get rollback statistics for debugging/analytics.
func get_stats() -> Dictionary:
	return {
		"rollback_count": rollback_count,
		"frames_resimulated": frames_resimulated,
		"avg_resim_per_rollback": float(frames_resimulated) / max(rollback_count, 1),
		"buffer_oldest_frame": get_oldest_snapshot_frame(),
		"buffer_newest_frame": get_newest_snapshot_frame(),
	}
