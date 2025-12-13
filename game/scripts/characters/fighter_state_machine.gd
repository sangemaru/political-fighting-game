extends Node

## Fighter State Machine
## Manages fighter states: IDLE, WALKING, JUMPING, ATTACKING, HITSTUN, KNOCKDOWN, DEAD
## Each state has enter/exit/update methods

class_name FighterStateMachine

## State enum
enum State {
	IDLE = 0,
	WALKING = 1,
	JUMPING = 2,
	ATTACKING = 3,
	HITSTUN = 4,
	KNOCKDOWN = 5,
	DEAD = 6,
	BLOCKING = 7
}

## References
var fighter: BaseFighter
var current_state: int = State.IDLE
var _state_objects: Dictionary = {}
var _hitstun_timer: float = 0.0
var _hitstun_frames: int = 0  # Frame-based hitstun
var _hitstun_frame_counter: int = 0
var _knockdown_timer: float = 0.0

## Constants
const HITSTUN_DURATION: float = 0.3
const KNOCKDOWN_DURATION: float = 0.5
const FRAMES_PER_SECOND: int = 60  # 60 FPS


func _init(fighter_ref: BaseFighter) -> void:
	fighter = fighter_ref
	_initialize_states()


## Initialize all state handlers
func _initialize_states() -> void:
	_state_objects[State.IDLE] = _IdleState.new(self)
	_state_objects[State.WALKING] = _WalkingState.new(self)
	_state_objects[State.JUMPING] = _JumpingState.new(self)
	_state_objects[State.ATTACKING] = _AttackingState.new(self)
	_state_objects[State.HITSTUN] = _HitstunState.new(self)
	_state_objects[State.KNOCKDOWN] = _KnockdownState.new(self)
	_state_objects[State.DEAD] = _DeadState.new(self)
	_state_objects[State.BLOCKING] = _BlockingState.new(self)


## Change to a new state
func change_state(new_state: int) -> bool:
	if new_state == current_state:
		return false

	# Exit current state
	if current_state in _state_objects:
		var state_obj = _state_objects[current_state]
		if state_obj.has_method("_exit_state"):
			state_obj._exit_state()

	# Enter new state
	current_state = new_state
	if current_state in _state_objects:
		var state_obj = _state_objects[current_state]
		if state_obj.has_method("_enter_state"):
			state_obj._enter_state()

	return true


## Process current state
func process_state(delta: float) -> void:
	if current_state in _state_objects:
		var state_obj = _state_objects[current_state]
		if state_obj.has_method("_process_state"):
			state_obj._process_state(delta)


## Physics process current state
func physics_process_state(delta: float) -> void:
	if current_state in _state_objects:
		var state_obj = _state_objects[current_state]
		if state_obj.has_method("_physics_process_state"):
			state_obj._physics_process_state(delta)


## Set hitstun duration in frames (called when hit)
func set_hitstun_frames(frames: int) -> void:
	_hitstun_frames = frames
	_hitstun_frame_counter = 0


# ============================================================
# STATE CLASSES
# ============================================================

class _IdleState:
	var fsm: FighterStateMachine

	func _init(fsm_ref: FighterStateMachine) -> void:
		fsm = fsm_ref

	func _enter_state() -> void:
		fsm.fighter.velocity.x = 0

	func _process_state(delta: float) -> void:
		# Check input for transitions
		var input_direction = Input.get_axis("ui_left", "ui_right")

		# Check for blocking first
		if _is_blocking_input(input_direction):
			fsm.change_state(FighterStateMachine.State.BLOCKING)
			return

		if input_direction != 0:
			fsm.change_state(FighterStateMachine.State.WALKING)

		if Input.is_action_just_pressed("ui_up"):
			fsm.change_state(FighterStateMachine.State.JUMPING)

	func _is_blocking_input(input_direction: float) -> bool:
		if fsm.fighter.opponent_ref == null or input_direction == 0:
			return false
		var to_opponent = fsm.fighter.opponent_ref.global_position - fsm.fighter.global_position
		var direction_to_opponent = sign(to_opponent.x)
		return sign(input_direction) == -direction_to_opponent

	func _physics_process_state(delta: float) -> void:
		# Maintain velocity on ground
		if fsm.fighter.is_on_floor():
			fsm.fighter.velocity.x = 0


class _WalkingState:
	var fsm: FighterStateMachine

	func _init(fsm_ref: FighterStateMachine) -> void:
		fsm = fsm_ref

	func _enter_state() -> void:
		pass

	func _process_state(delta: float) -> void:
		var input_direction = Input.get_axis("ui_left", "ui_right")

		# Check for blocking first
		if _is_blocking_input(input_direction):
			fsm.change_state(FighterStateMachine.State.BLOCKING)
			return

		# Handle movement
		if input_direction != 0:
			fsm.fighter.set_facing_direction(input_direction)
			fsm.fighter.velocity.x = input_direction * fsm.fighter.speed
		else:
			# Return to idle if no input
			fsm.change_state(FighterStateMachine.State.IDLE)

		# Jump transition
		if Input.is_action_just_pressed("ui_up"):
			fsm.change_state(FighterStateMachine.State.JUMPING)

	func _is_blocking_input(input_direction: float) -> bool:
		if fsm.fighter.opponent_ref == null or input_direction == 0:
			return false
		var to_opponent = fsm.fighter.opponent_ref.global_position - fsm.fighter.global_position
		var direction_to_opponent = sign(to_opponent.x)
		return sign(input_direction) == -direction_to_opponent

	func _physics_process_state(delta: float) -> void:
		pass


class _JumpingState:
	var fsm: FighterStateMachine
	var jump_velocity: float = 0.0

	func _init(fsm_ref: FighterStateMachine) -> void:
		fsm = fsm_ref

	func _enter_state() -> void:
		# Calculate jump velocity from jump height using v = sqrt(2 * g * h)
		# This gives DETERMINISTIC jump height independent of delta time
		jump_velocity = sqrt(2.0 * fsm.fighter.gravity * fsm.fighter.jump_height)
		fsm.fighter.velocity.y = -jump_velocity

	func _process_state(delta: float) -> void:
		# Handle air movement
		var input_direction = Input.get_axis("ui_left", "ui_right")
		if input_direction != 0:
			fsm.fighter.set_facing_direction(input_direction)
			fsm.fighter.velocity.x = input_direction * fsm.fighter.speed * 0.8  # 80% speed in air

	func _physics_process_state(delta: float) -> void:
		# Return to idle/walking when landing
		if fsm.fighter.is_on_floor():
			var input_direction = Input.get_axis("ui_left", "ui_right")
			if input_direction != 0:
				fsm.change_state(FighterStateMachine.State.WALKING)
			else:
				fsm.change_state(FighterStateMachine.State.IDLE)


class _AttackingState:
	var fsm: FighterStateMachine
	var attack_timer: float = 0.0
	var attack_duration: float = 0.5  # Will be set based on move data

	func _init(fsm_ref: FighterStateMachine) -> void:
		fsm = fsm_ref

	func _enter_state() -> void:
		attack_timer = 0.0
		fsm.fighter.velocity.x = 0

	func _process_state(delta: float) -> void:
		attack_timer += delta
		# Attack ends when timer exceeds duration
		if attack_timer >= attack_duration:
			_exit_attack()

	func _physics_process_state(delta: float) -> void:
		pass

	func _exit_attack() -> void:
		# Return to appropriate state based on ground status
		var input_direction = Input.get_axis("ui_left", "ui_right")
		if input_direction != 0:
			fsm.change_state(FighterStateMachine.State.WALKING)
		else:
			fsm.change_state(FighterStateMachine.State.IDLE)


class _HitstunState:
	var fsm: FighterStateMachine
	var hitstun_timer: float = 0.0

	func _init(fsm_ref: FighterStateMachine) -> void:
		fsm = fsm_ref

	func _enter_state() -> void:
		hitstun_timer = 0.0
		fsm.fighter.velocity.x = 0  # Stop movement during hitstun
		fsm._hitstun_frame_counter = 0

	func _process_state(delta: float) -> void:
		# Count frames instead of time for deterministic hitstun
		fsm._hitstun_frame_counter += 1
		hitstun_timer += delta

		# Use frame-based hitstun if set, otherwise fall back to time-based
		var frames_exceeded = false
		if fsm._hitstun_frames > 0:
			frames_exceeded = fsm._hitstun_frame_counter >= fsm._hitstun_frames
		else:
			frames_exceeded = hitstun_timer >= FighterStateMachine.HITSTUN_DURATION

		if frames_exceeded:
			_exit_hitstun()

	func _physics_process_state(delta: float) -> void:
		pass

	func _exit_hitstun() -> void:
		# Check if on ground
		if fsm.fighter.is_on_floor():
			fsm.change_state(FighterStateMachine.State.IDLE)
		else:
			fsm.change_state(FighterStateMachine.State.JUMPING)


class _KnockdownState:
	var fsm: FighterStateMachine
	var knockdown_timer: float = 0.0

	func _init(fsm_ref: FighterStateMachine) -> void:
		fsm = fsm_ref

	func _enter_state() -> void:
		knockdown_timer = 0.0
		fsm.fighter.velocity.x = 0

	func _process_state(delta: float) -> void:
		knockdown_timer += delta
		if knockdown_timer >= FighterStateMachine.KNOCKDOWN_DURATION:
			_exit_knockdown()

	func _physics_process_state(delta: float) -> void:
		pass

	func _exit_knockdown() -> void:
		if fsm.fighter.is_on_floor():
			fsm.change_state(FighterStateMachine.State.IDLE)
		else:
			fsm.change_state(FighterStateMachine.State.JUMPING)


class _DeadState:
	var fsm: FighterStateMachine

	func _init(fsm_ref: FighterStateMachine) -> void:
		fsm = fsm_ref

	func _enter_state() -> void:
		fsm.fighter.velocity = Vector2.ZERO

	func _process_state(delta: float) -> void:
		pass  # Dead state does nothing

	func _physics_process_state(delta: float) -> void:
		pass  # Dead state does nothing


class _BlockingState:
	var fsm: FighterStateMachine
	var block_timer: float = 0.0

	func _init(fsm_ref: FighterStateMachine) -> void:
		fsm = fsm_ref

	func _enter_state() -> void:
		block_timer = 0.0
		fsm.fighter.velocity.x = 0  # Can't move while blocking
		# Visual feedback (could modulate sprite color)
		if fsm.fighter.has_node("Sprite2D"):
			var sprite = fsm.fighter.get_node("Sprite2D")
			sprite.modulate = Color(0.7, 0.7, 1.0, 1.0)  # Blue tint

	func _exit_state() -> void:
		# Remove visual feedback
		if fsm.fighter.has_node("Sprite2D"):
			var sprite = fsm.fighter.get_node("Sprite2D")
			sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)  # Reset

	func _process_state(delta: float) -> void:
		block_timer += delta

		# Check if still holding block direction
		if not _is_blocking_input():
			# Stop blocking
			fsm.change_state(FighterStateMachine.State.IDLE)

	func _physics_process_state(delta: float) -> void:
		# Ensure no movement
		fsm.fighter.velocity.x = 0

	func _is_blocking_input() -> bool:
		# Blocking means holding away from opponent
		# For now, just check if holding left/right
		# (BaseFighter should set this properly based on opponent position)
		var input_direction = Input.get_axis("ui_left", "ui_right")

		# If no opponent ref, can't determine block direction
		if fsm.fighter.opponent_ref == null:
			return false

		# Calculate direction to opponent
		var to_opponent = fsm.fighter.opponent_ref.global_position - fsm.fighter.global_position
		var direction_to_opponent = sign(to_opponent.x)

		# Blocking if holding opposite direction
		return sign(input_direction) == -direction_to_opponent and input_direction != 0
