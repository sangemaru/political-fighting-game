## Battle-specific state machine
## Handles round timers, win conditions, and pause logic
##
## Usage:
##   var battle_sm = BattleStateMachine.new()
##   battle_sm.initialize(player1, player2)
##   battle_sm.check_round_end_conditions()

class_name BattleStateMachine
extends Node

## Battle state enumeration
enum BattleState {
	INITIALIZING,
	ROUND_ACTIVE,
	ROUND_PAUSED,
	ROUND_ENDED,
	MATCH_ENDED
}

## Signals
signal round_started
signal round_ended(winner: String, reason: String)
signal match_ended(winner: String)
signal time_warning  # Emitted at ~10 seconds remaining
signal round_time_up

## Current battle state
var current_state: int = BattleState.INITIALIZING

## Player references
var player1: Node = null
var player2: Node = null

## Round configuration
var round_duration_frames: int = 5940  # 99 seconds at 60 FPS
var current_round: int = 1
var max_rounds: int = 3
var player1_round_wins: int = 0
var player2_round_wins: int = 0

## Round timers (deterministic, frame-based)
var round_elapsed_frames: int = 0
var time_warning_issued: bool = false

## Win condition thresholds
var ko_threshold: float = 0.0  # Health <= 0
var timeout_frames: int = 0  # Frame count when time runs out


func _ready() -> void:
	set_physics_process(true)


func _physics_process(_delta: float) -> void:
	if current_state == BattleState.ROUND_ACTIVE:
		round_elapsed_frames += 1

		# Check if time is up
		if round_elapsed_frames >= round_duration_frames and timeout_frames == 0:
			timeout_frames = round_elapsed_frames
			round_time_up.emit()

		# Check for time warning (10 seconds remaining)
		var remaining_frames = round_duration_frames - round_elapsed_frames
		if remaining_frames == 600 and not time_warning_issued:  # 10 seconds at 60 FPS
			time_warning_issued = true
			time_warning.emit()


## Initialize battle with player references
func initialize(p1: Node, p2: Node) -> void:
	player1 = p1
	player2 = p2
	reset_round()
	current_state = BattleState.ROUND_ACTIVE
	round_started.emit()


## Start a new round
func start_round() -> void:
	reset_round()
	current_state = BattleState.ROUND_ACTIVE
	round_started.emit()


## Reset round state but keep match score
func reset_round() -> void:
	round_elapsed_frames = 0
	timeout_frames = 0
	time_warning_issued = false
	current_state = BattleState.ROUND_ACTIVE


## Check win conditions
## Returns the winner ("player1", "player2", or "") if round should end
func check_round_end_conditions() -> String:
	if current_state != BattleState.ROUND_ACTIVE:
		return ""

	# Check KO conditions (health-based)
	if player1 != null and player2 != null:
		var p1_health = _get_player_health(player1)
		var p2_health = _get_player_health(player2)

		if p1_health <= ko_threshold:
			return "player2"  # Player 2 wins (player 1 KO'd)
		if p2_health <= ko_threshold:
			return "player1"  # Player 1 wins (player 2 KO'd)

	# Check timeout condition
	if timeout_frames > 0:
		# Determine winner by remaining health
		return _get_winner_by_health()

	return ""


## Get player health value
## Assumes player has health property/method
func _get_player_health(player: Node) -> float:
	if player == null:
		return 0.0

	if "health" in player:
		return player.health
	elif player.has_method("get_health"):
		return player.get_health()
	else:
		push_warning("Player node has no health property/method")
		return 0.0


## Determine winner by remaining health (for timeout)
func _get_winner_by_health() -> String:
	if player1 == null or player2 == null:
		return ""

	var p1_health = _get_player_health(player1)
	var p2_health = _get_player_health(player2)

	if p1_health > p2_health:
		return "player1"
	elif p2_health > p1_health:
		return "player2"
	else:
		return "draw"  # Same health = draw


## End current round
func end_round(winner: String, reason: String = "") -> void:
	if current_state == BattleState.ROUND_ENDED or current_state == BattleState.MATCH_ENDED:
		return

	current_state = BattleState.ROUND_ENDED

	# Update round wins
	if winner == "player1":
		player1_round_wins += 1
	elif winner == "player2":
		player2_round_wins += 1

	round_ended.emit(winner, reason)

	# Check if match should end
	if _should_end_match():
		var match_winner = "player1" if player1_round_wins > player2_round_wins else "player2"
		end_match(match_winner)
	else:
		# Prepare for next round
		current_round += 1


## Check if match should end (best of 3)
func _should_end_match() -> bool:
	# First to 2 wins
	return player1_round_wins >= 2 or player2_round_wins >= 2


## End the match
func end_match(winner: String) -> void:
	current_state = BattleState.MATCH_ENDED
	match_ended.emit(winner)


## Pause the round (freeze timers)
func pause_round() -> void:
	if current_state == BattleState.ROUND_ACTIVE:
		current_state = BattleState.ROUND_PAUSED


## Resume the round
func resume_round() -> void:
	if current_state == BattleState.ROUND_PAUSED:
		current_state = BattleState.ROUND_ACTIVE


## Get remaining time in seconds
func get_remaining_time() -> float:
	var remaining_frames = round_duration_frames - round_elapsed_frames
	return max(0.0, remaining_frames / 60.0)


## Get remaining time as formatted string (MM:SS)
func get_remaining_time_formatted() -> String:
	var remaining = get_remaining_time()
	var minutes = int(remaining) / 60
	var seconds = int(remaining) % 60
	return "%02d:%02d" % [minutes, seconds]


## Get current state name (for debugging)
func get_state_name() -> String:
	match current_state:
		BattleState.INITIALIZING:
			return "INITIALIZING"
		BattleState.ROUND_ACTIVE:
			return "ROUND_ACTIVE"
		BattleState.ROUND_PAUSED:
			return "ROUND_PAUSED"
		BattleState.ROUND_ENDED:
			return "ROUND_ENDED"
		BattleState.MATCH_ENDED:
			return "MATCH_ENDED"
		_:
			return "UNKNOWN"


## Get match score as string (player1 wins / player2 wins)
func get_match_score() -> String:
	return "%d/%d" % [player1_round_wins, player2_round_wins]
