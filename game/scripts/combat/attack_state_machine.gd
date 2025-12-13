extends Node

## Attack State Machine
## Manages attack states: IDLE, STARTUP, ACTIVE, RECOVERY
## Frame-based timing for deterministic combat

class_name AttackStateMachine


## Attack states
enum State {
	IDLE,       # Not attacking
	STARTUP,    # Before hitbox active (vulnerable)
	ACTIVE,     # Hitbox is active (can hit)
	RECOVERY    # After attack (vulnerable)
}

## Current attack state
var current_state: int = State.IDLE

## Frame counters
var frame_counter: int = 0

## Attack frame data
var startup_frames: int = 0
var active_frames: int = 0
var recovery_frames: int = 0

## Attack hitbox reference
var attack_hitbox: Hitbox = null

## Owner fighter
var owner_fighter: BaseFighter = null

## Signals
signal state_changed(new_state: int)
signal attack_started(state_name: String)
signal attack_ended()


## Initialize state machine
func _ready() -> void:
	change_state(State.IDLE)


## Change attack state
func change_state(new_state: int) -> void:
	if new_state == current_state:
		return

	# Exit current state
	_exit_state(current_state)

	current_state = new_state
	frame_counter = 0

	# Enter new state
	_enter_state(new_state)
	state_changed.emit(new_state)


## Process frame (called from owner)
func process_frame() -> void:
	frame_counter += 1

	match current_state:
		State.IDLE:
			# Waiting for attack input
			pass

		State.STARTUP:
			# Before hitbox active
			if frame_counter >= startup_frames:
				change_state(State.ACTIVE)

		State.ACTIVE:
			# Hitbox is active
			if frame_counter >= active_frames:
				change_state(State.RECOVERY)

		State.RECOVERY:
			# After attack
			if frame_counter >= recovery_frames:
				change_state(State.IDLE)


## Start an attack with frame data
func start_attack(
	p_startup: int,
	p_active: int,
	p_recovery: int,
	p_hitbox: Hitbox
) -> void:
	if current_state != State.IDLE:
		return

	startup_frames = p_startup
	active_frames = p_active
	recovery_frames = p_recovery
	attack_hitbox = p_hitbox

	change_state(State.STARTUP)
	attack_started.emit("STARTUP")


## Cancel current attack and return to idle
func cancel_attack() -> void:
	if current_state != State.IDLE:
		change_state(State.IDLE)
		attack_ended.emit()


## Check if can attack (only when idle)
func can_attack() -> bool:
	return current_state == State.IDLE


## Get current state name (for debugging)
func get_state_name() -> String:
	match current_state:
		State.IDLE:
			return "IDLE"
		State.STARTUP:
			return "STARTUP"
		State.ACTIVE:
			return "ACTIVE"
		State.RECOVERY:
			return "RECOVERY"
		_:
			return "UNKNOWN"


## Get current frame in attack window
func get_attack_frame() -> int:
	return frame_counter


## Check if hitbox is currently active
func is_hitbox_active() -> bool:
	return current_state == State.ACTIVE


# State entry/exit callbacks
func _enter_state(state: int) -> void:
	match state:
		State.IDLE:
			if attack_hitbox:
				attack_hitbox.deactivate()

		State.STARTUP:
			# Hitbox not active yet, but created
			if attack_hitbox:
				attack_hitbox.deactivate()

		State.ACTIVE:
			# Activate hitbox for damage
			if attack_hitbox:
				attack_hitbox.activate()

		State.RECOVERY:
			# Deactivate hitbox, character recovering
			if attack_hitbox:
				attack_hitbox.deactivate()


func _exit_state(state: int) -> void:
	match state:
		State.IDLE:
			pass
		State.STARTUP:
			pass
		State.ACTIVE:
			pass
		State.RECOVERY:
			attack_ended.emit()
