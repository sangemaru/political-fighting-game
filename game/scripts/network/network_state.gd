extends Node

## Network State (F91)
## Serializable game state for rollback netcode.
## Captures the full game state into a Dictionary and restores it.
## No actual networking -- this is the state serialization foundation.

class_name NetworkState


## Capture the full game state from the battle scene.
## Returns a Dictionary representing the complete deterministic state.
static func capture_state(game_manager: Node, fighters: Dictionary) -> Dictionary:
	var state := {}

	# Game-level state
	state["frame_number"] = game_manager.battle_frame
	state["round_timer_frames"] = game_manager.round_timer_frames
	state["current_round"] = game_manager.current_round
	state["rounds_won"] = game_manager.rounds_won.duplicate()

	# Fighter states
	var fighter_states := {}
	for player_id in fighters:
		var fighter: BaseFighter = fighters[player_id]
		fighter_states[player_id] = _capture_fighter_state(fighter)

	state["fighters"] = fighter_states
	return state


## Restore the full game state from a previously captured snapshot.
static func restore_state(state: Dictionary, game_manager: Node, fighters: Dictionary) -> void:
	if state.is_empty():
		return

	# Restore game-level state
	game_manager.battle_frame = state["frame_number"]
	game_manager.round_timer_frames = state["round_timer_frames"]
	game_manager.current_round = state["current_round"]
	game_manager.rounds_won = state["rounds_won"].duplicate()

	# Restore fighter states
	var fighter_states: Dictionary = state.get("fighters", {})
	for player_id in fighters:
		if fighter_states.has(player_id):
			_restore_fighter_state(fighters[player_id], fighter_states[player_id])


## Capture a single fighter's state.
static func _capture_fighter_state(fighter: BaseFighter) -> Dictionary:
	var fs := {}
	fs["position_x"] = fighter.global_position.x
	fs["position_y"] = fighter.global_position.y
	fs["velocity_x"] = fighter.velocity.x
	fs["velocity_y"] = fighter.velocity.y
	fs["health"] = fighter.health
	fs["max_health"] = fighter.max_health
	fs["is_alive"] = fighter.is_alive
	fs["facing_direction"] = fighter.facing_direction
	fs["is_blocking"] = fighter.is_blocking
	fs["knockback_velocity_x"] = fighter.knockback_velocity.x
	fs["knockback_velocity_y"] = fighter.knockback_velocity.y

	# State machine
	if fighter.state_machine:
		fs["state_machine_state"] = fighter.state_machine.current_state
		fs["hitstun_frames"] = fighter.state_machine._hitstun_frames
		fs["hitstun_frame_counter"] = fighter.state_machine._hitstun_frame_counter
	else:
		fs["state_machine_state"] = FighterStateMachine.State.IDLE
		fs["hitstun_frames"] = 0
		fs["hitstun_frame_counter"] = 0

	return fs


## Restore a single fighter's state.
static func _restore_fighter_state(fighter: BaseFighter, fs: Dictionary) -> void:
	fighter.global_position = Vector2(fs["position_x"], fs["position_y"])
	fighter.velocity = Vector2(fs["velocity_x"], fs["velocity_y"])
	fighter.health = fs["health"]
	fighter.max_health = fs["max_health"]
	fighter.is_alive = fs["is_alive"]
	fighter.facing_direction = fs["facing_direction"]
	fighter.is_blocking = fs["is_blocking"]
	fighter.knockback_velocity = Vector2(fs["knockback_velocity_x"], fs["knockback_velocity_y"])

	# Restore state machine
	if fighter.state_machine:
		fighter.state_machine.current_state = fs["state_machine_state"]
		fighter.state_machine._hitstun_frames = fs["hitstun_frames"]
		fighter.state_machine._hitstun_frame_counter = fs["hitstun_frame_counter"]

	# Emit health changed signal so UI updates
	fighter.health_changed.emit(fighter.health, fighter.max_health)


## Compare two states and return whether they differ.
## Used to detect mispredictions during rollback.
static func states_differ(state_a: Dictionary, state_b: Dictionary) -> bool:
	if state_a.is_empty() or state_b.is_empty():
		return true

	if state_a["frame_number"] != state_b["frame_number"]:
		return true

	if state_a["round_timer_frames"] != state_b["round_timer_frames"]:
		return true

	var fighters_a: Dictionary = state_a.get("fighters", {})
	var fighters_b: Dictionary = state_b.get("fighters", {})

	for player_id in fighters_a:
		if not fighters_b.has(player_id):
			return true
		var fa: Dictionary = fighters_a[player_id]
		var fb: Dictionary = fighters_b[player_id]

		# Check position (integer comparison for determinism)
		if int(fa["position_x"]) != int(fb["position_x"]):
			return true
		if int(fa["position_y"]) != int(fb["position_y"]):
			return true
		if fa["health"] != fb["health"]:
			return true
		if fa["is_alive"] != fb["is_alive"]:
			return true
		if fa["state_machine_state"] != fb["state_machine_state"]:
			return true

	return false
