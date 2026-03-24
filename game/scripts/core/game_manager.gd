## Global game manager (autoload/singleton)
## Manages game states: MENU, CHARACTER_SELECT, BATTLE, PAUSE, ROUND_END, MATCH_END
##
## Autoload this as "GameManager" in Project Settings > Autoload

extends Node

## Game state enumeration
enum GameState {
	MENU,
	CHARACTER_SELECT,
	BATTLE,
	PAUSE,
	ROUND_END,
	MATCH_END
}

## Signals
signal state_changed(old_state: int, new_state: int)
signal battle_started
signal battle_ended
signal round_started(round_number: int)
signal round_ended(winner_id: int)  # F58: Changed to int (player 1, 2, or 0 for draw)
signal round_won(player_id: int)  # F58: New signal for round wins
signal match_won(player_id: int)  # F58: New signal for match wins
signal match_ended(winner_id: int)  # F58: Changed to int
signal pause_toggled(is_paused: bool)

## Current game state
var current_state: int = GameState.MENU

## Battle-specific state
var current_round: int = 1
var max_rounds: int = 3
var is_paused: bool = false

## F58: Match flow tracking (best of N)
var rounds_won: Dictionary = {1: 0, 2: 0}  # {player_id: rounds_won}
var rounds_to_win: int = 2  # Best of 3 requires 2 wins
var match_winner: int = 0  # 0 = no winner yet, 1 = P1, 2 = P2

## Character/stage selection persistence (F44, F45)
var selected_characters: Dictionary = {1: "", 2: ""}  # {player_id: character_id}
var selected_stage: String = "arena_1"

## Deterministic frame counter for battle
var battle_frame: int = 0
var round_timer_frames: int = 0  # Frame-based timer

## Configuration
var round_duration_seconds: float = 99.0
var round_duration_frames: int = 0  # Calculated from 60 FPS


func _ready() -> void:
	# Calculate frame count for round duration at 60 FPS
	# Adjust if your game runs at different FPS
	round_duration_frames = int(round_duration_seconds * 60.0)
	set_process(true)
	set_physics_process(true)


func _process(_delta: float) -> void:
	# Process current state logic
	if current_state == GameState.BATTLE and not is_paused:
		battle_frame += 1
		round_timer_frames += 1


func _physics_process(_delta: float) -> void:
	# Physics-based state processing if needed
	pass


## Change game state
## Returns true if successful, false if state is same
func change_state(new_state: int) -> bool:
	if new_state == current_state:
		return false

	var old_state = current_state
	current_state = new_state

	match new_state:
		GameState.MENU:
			_on_enter_menu()
		GameState.CHARACTER_SELECT:
			_on_enter_character_select()
		GameState.BATTLE:
			_on_enter_battle()
		GameState.PAUSE:
			_on_enter_pause()
		GameState.ROUND_END:
			_on_enter_round_end()
		GameState.MATCH_END:
			_on_enter_match_end()

	state_changed.emit(old_state, new_state)
	return true


## Get current state as string (for debugging)
func get_current_state_name() -> String:
	match current_state:
		GameState.MENU:
			return "MENU"
		GameState.CHARACTER_SELECT:
			return "CHARACTER_SELECT"
		GameState.BATTLE:
			return "BATTLE"
		GameState.PAUSE:
			return "PAUSE"
		GameState.ROUND_END:
			return "ROUND_END"
		GameState.MATCH_END:
			return "MATCH_END"
		_:
			return "UNKNOWN"


## Toggle pause state during battle
func toggle_pause() -> bool:
	if current_state != GameState.BATTLE:
		return false

	is_paused = not is_paused
	pause_toggled.emit(is_paused)

	if is_paused:
		change_state(GameState.PAUSE)
	else:
		change_state(GameState.BATTLE)

	return is_paused


## Check if time is up in current round
## Returns true if round duration exceeded
func is_round_time_up() -> bool:
	return round_timer_frames >= round_duration_frames


## Get remaining time in round (in seconds)
func get_round_remaining_time() -> float:
	return max(0.0, (round_duration_frames - round_timer_frames) / 60.0)


## Get remaining frames in round
func get_round_remaining_frames() -> int:
	return max(0, round_duration_frames - round_timer_frames)


## F58: End current round and track wins
func end_round(winner_id: int) -> void:
	"""
	End the current round and track winner.
	winner_id: 1 = Player 1, 2 = Player 2, 0 = Draw
	"""
	round_ended.emit(winner_id)

	# Track round wins (F58)
	if winner_id > 0:
		rounds_won[winner_id] += 1
		round_won.emit(winner_id)

		print("[GameManager] Round %d won by Player %d (Score: P1=%d, P2=%d)" % [
			current_round, winner_id, rounds_won[1], rounds_won[2]
		])

		# Check if match is won (F58)
		if rounds_won[winner_id] >= rounds_to_win:
			match_winner = winner_id
			match_won.emit(winner_id)
			print("[GameManager] Match won by Player %d!" % winner_id)
			change_state(GameState.MATCH_END)
			return

	change_state(GameState.ROUND_END)


## Check if match should end (best of 3)
func should_end_match() -> bool:
	return current_round >= max_rounds


## Start new round
func start_new_round() -> void:
	current_round += 1
	battle_frame = 0
	round_timer_frames = 0
	round_started.emit(current_round)
	change_state(GameState.BATTLE)


## F58: Reset battle state for new match
func reset_battle() -> void:
	current_round = 1
	battle_frame = 0
	round_timer_frames = 0
	is_paused = false
	rounds_won = {1: 0, 2: 0}  # F58: Reset round wins
	match_winner = 0  # F58: Clear match winner


## F60: Reset match and return to battle (for rematch)
func reset_match() -> void:
	"""Reset match state and start new battle with same characters"""
	reset_battle()
	start_new_round()
	print("[GameManager] Match reset - Rematch started!")


# State entry callbacks
func _on_enter_menu() -> void:
	pass


func _on_enter_character_select() -> void:
	pass


func _on_enter_battle() -> void:
	battle_started.emit()
	round_timer_frames = 0
	is_paused = false


func _on_enter_pause() -> void:
	pass


func _on_enter_round_end() -> void:
	pass


func _on_enter_match_end() -> void:
	match_ended.emit(match_winner)  # F58: Emit actual winner ID
