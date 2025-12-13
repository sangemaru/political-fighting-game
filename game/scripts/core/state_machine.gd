## Generic state machine for managing state transitions
## Can be used for game states, character states, etc.
##
## Usage:
##   var state_machine = StateMachine.new()
##   state_machine.add_state("idle", IdleState.new())
##   state_machine.change_state("idle")

class_name StateMachine
extends Node

## Emitted when state changes (old_state, new_state)
signal state_changed(old_state: String, new_state: String)

## Current state enum value
var current_state: int = -1

## Dictionary of state names to state objects
var _states: Dictionary = {}

## Current state object reference
var _current_state_obj: Object = null


## Add a state to the state machine
func add_state(state_name: String, state_obj: Object) -> void:
	_states[state_name] = state_obj


## Change to a new state
## Returns true if successful, false if state doesn't exist
func change_state(new_state: int) -> bool:
	if new_state == current_state:
		return false

	var old_state = current_state

	# Exit current state
	if _current_state_obj != null and _current_state_obj.has_method("_exit_state"):
		_current_state_obj._exit_state()

	# Set new state
	current_state = new_state
	_current_state_obj = null

	# Enter new state
	if _current_state_obj != null and _current_state_obj.has_method("_enter_state"):
		_current_state_obj._enter_state()

	state_changed.emit(old_state, new_state)
	return true


## Get the current state object
func get_current_state() -> Object:
	return _current_state_obj


## Get the current state enum value
func get_current_state_value() -> int:
	return current_state


## Process the current state
func process_state(delta: float) -> void:
	if _current_state_obj != null and _current_state_obj.has_method("_process_state"):
		_current_state_obj._process_state(delta)


## Physics process the current state
func physics_process_state(delta: float) -> void:
	if _current_state_obj != null and _current_state_obj.has_method("_physics_process_state"):
		_current_state_obj._physics_process_state(delta)
