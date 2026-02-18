extends Node

## Fighter State Machine
## Manages fighter states: IDLE, WALKING, JUMPING, ATTACKING, HITSTUN, KNOCKDOWN, DEAD
## Each state has enter/exit/update methods
## Input is provided externally via set_input() - do NOT read Input directly

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

## External input state (set by battle_scene via set_input)
var input_direction: float = 0.0
var input_vertical: float = 0.0
var input_attack: bool = false
var input_special: bool = false

## Constants
const HITSTUN_DURATION: float = 0.3
const KNOCKDOWN_DURATION: float = 0.5
const FRAMES_PER_SECOND: int = 60  # 60 FPS


func _init(fighter_ref: BaseFighter) -> void:
	fighter = fighter_ref
	_initialize_states()


## Set input externally (called by battle_scene each frame)
func set_input(direction: float, vertical: float, attack: bool, special: bool) -> void:
	input_direction = direction
	input_vertical = vertical
	input_attack = attack
	input_special = special


## Clear input (called after processing or when fighter shouldn't receive input)
func clear_input() -> void:
	input_direction = 0.0
	input_vertical = 0.0
	input_attack = false
	input_special = false


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
# STATE CLASSES - All read input from fsm.input_* fields
# ============================================================

class _IdleState:
	var fsm: FighterStateMachine

	func _init(fsm_ref: FighterStateMachine) -> void:
		fsm = fsm_ref

	func _enter_state() -> void:
		fsm.fighter.velocity.x = 0

	func _process_state(delta: float) -> void:
		# Check for blocking first
		if _is_blocking_input(fsm.input_direction):
			fsm.change_state(FighterStateMachine.State.BLOCKING)
			return

		if fsm.input_direction != 0:
			fsm.change_state(FighterStateMachine.State.WALKING)

		if fsm.input_vertical < 0:  # Up
			fsm.change_state(FighterStateMachine.State.JUMPING)

		if fsm.input_attack or fsm.input_special:
			fsm.change_state(FighterStateMachine.State.ATTACKING)

	func _is_blocking_input(direction: float) -> bool:
		if fsm.fighter.opponent_ref == null or direction == 0:
			return false
		var to_opponent = fsm.fighter.opponent_ref.global_position - fsm.fighter.global_position
		var direction_to_opponent = sign(to_opponent.x)
		return sign(direction) == -direction_to_opponent

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
		# Check for blocking first
		if _is_blocking_input(fsm.input_direction):
			fsm.change_state(FighterStateMachine.State.BLOCKING)
			return

		# Handle movement
		if fsm.input_direction != 0:
			fsm.fighter.set_facing_direction(fsm.input_direction)
			fsm.fighter.velocity.x = fsm.input_direction * fsm.fighter.speed
		else:
			# Return to idle if no input
			fsm.change_state(FighterStateMachine.State.IDLE)

		# Jump transition
		if fsm.input_vertical < 0:  # Up
			fsm.change_state(FighterStateMachine.State.JUMPING)

		if fsm.input_attack or fsm.input_special:
			fsm.change_state(FighterStateMachine.State.ATTACKING)

	func _is_blocking_input(direction: float) -> bool:
		if fsm.fighter.opponent_ref == null or direction == 0:
			return false
		var to_opponent = fsm.fighter.opponent_ref.global_position - fsm.fighter.global_position
		var direction_to_opponent = sign(to_opponent.x)
		return sign(direction) == -direction_to_opponent

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
		if fsm.input_direction != 0:
			fsm.fighter.set_facing_direction(fsm.input_direction)
			fsm.fighter.velocity.x = fsm.input_direction * fsm.fighter.speed * 0.8  # 80% speed in air

	func _physics_process_state(delta: float) -> void:
		# Return to idle/walking when landing
		if fsm.fighter.is_on_floor():
			if fsm.input_direction != 0:
				fsm.change_state(FighterStateMachine.State.WALKING)
			else:
				fsm.change_state(FighterStateMachine.State.IDLE)


class _AttackingState:
	var fsm: FighterStateMachine
	var attack_timer: float = 0.0
	var attack_duration: float = 0.5
	var is_special: bool = false
	var frame_counter: int = 0
	var startup_frames: int = 3
	var active_frames: int = 3
	var recovery_frames: int = 5
	var current_hitbox: Hitbox = null

	func _init(fsm_ref: FighterStateMachine) -> void:
		fsm = fsm_ref

	func _enter_state() -> void:
		attack_timer = 0.0
		frame_counter = 0
		fsm.fighter.velocity.x = 0
		is_special = fsm.input_special

		# Get move data from character
		var move_data = fsm.fighter.get_move_data(is_special)
		startup_frames = move_data.get("startup_frames", 3)
		active_frames = move_data.get("active_frames", 3)
		recovery_frames = move_data.get("recovery_frames", 5)
		attack_duration = (startup_frames + active_frames + recovery_frames) / 60.0

		# Create hitbox (inactive until startup completes)
		_create_hitbox(move_data)

	func _create_hitbox(move_data: Dictionary) -> void:
		if move_data.is_empty():
			return

		current_hitbox = Hitbox.new()
		current_hitbox.name = "AttackHitbox"

		var shape_node = CollisionShape2D.new()
		var rect_shape = RectangleShape2D.new()
		var hitbox_def = move_data.get("hitbox", {})
		rect_shape.size = Vector2(
			hitbox_def.get("width", 60),
			hitbox_def.get("height", 60)
		)
		shape_node.shape = rect_shape

		# Offset hitbox in the direction the fighter is facing
		var offset_x = hitbox_def.get("offset_x", 40) * fsm.fighter.facing_direction
		var offset_y = hitbox_def.get("offset_y", 0)
		shape_node.position = Vector2(offset_x, offset_y)
		current_hitbox.add_child(shape_node)

		var damage = move_data.get("damage", 8)
		var knockback = move_data.get("knockback", 100)
		var hitstun = move_data.get("active_frames", 10)
		var attack_id = "atk_%d_%d" % [fsm.fighter.player_id, frame_counter]
		current_hitbox.set_hitbox_data(damage, knockback, hitstun, fsm.fighter, attack_id)

		fsm.fighter.add_child(current_hitbox)
		# Starts inactive; activated once startup window elapses

	func _process_state(delta: float) -> void:
		attack_timer += delta
		frame_counter += 1

		# Activate hitbox when startup window ends
		if frame_counter == startup_frames and current_hitbox != null:
			current_hitbox.activate()

		# Deactivate hitbox when active window ends
		if frame_counter == startup_frames + active_frames and current_hitbox != null:
			current_hitbox.deactivate()

		if attack_timer >= attack_duration:
			_exit_attack()

	func _physics_process_state(delta: float) -> void:
		pass

	func _exit_state() -> void:
		# Clean up hitbox if interrupted (e.g. by hitstun)
		if current_hitbox != null:
			current_hitbox.queue_free()
			current_hitbox = null

	func _exit_attack() -> void:
		# Clean up hitbox
		if current_hitbox != null:
			current_hitbox.queue_free()
			current_hitbox = null
		# Return to appropriate state
		if fsm.input_direction != 0:
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
		# If no opponent ref, can't determine block direction
		if fsm.fighter.opponent_ref == null:
			return false

		# Calculate direction to opponent
		var to_opponent = fsm.fighter.opponent_ref.global_position - fsm.fighter.global_position
		var direction_to_opponent = sign(to_opponent.x)

		# Blocking if holding opposite direction
		return sign(fsm.input_direction) == -direction_to_opponent and fsm.input_direction != 0
