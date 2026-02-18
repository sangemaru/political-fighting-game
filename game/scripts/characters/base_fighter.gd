extends CharacterBody2D

## Base Fighter
## Base class for all playable and AI characters
## Handles health, knockback, and delegates state/movement to components

class_name BaseFighter

## Signals
signal health_changed(current: int, max: int)
signal died(player_id: int)

## Properties
@export var player_id: int = 1
@export var max_health: int = 100
@export var speed: float = 200.0
@export var weight: float = 1.0
@export var gravity: float = 800.0
@export var jump_height: float = 150.0

## State
var health: int
var is_alive: bool = true
var state_machine: FighterStateMachine
var knockback_velocity: Vector2 = Vector2.ZERO
var facing_direction: int = 1  # 1 for right, -1 for left
var opponent_ref: BaseFighter = null  # Reference to opponent (for blocking)
var is_blocking: bool = false  # Current blocking state

## Knockback physics
var knockback_friction: float = 0.85  # Decay rate per frame (0.85 = 15% reduction per frame)

## Combat components
var hurtbox: Hurtbox = null

## References
@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	health = max_health
	_initialize_state_machine()
	_setup_physics_layer()
	_create_hurtbox()
	_create_placeholder_visual()


func _process(delta: float) -> void:
	if state_machine:
		# Update blocking state based on current state
		is_blocking = (state_machine.current_state == FighterStateMachine.State.BLOCKING)
		state_machine.process_state(delta)


func _physics_process(delta: float) -> void:
	if not is_alive:
		return

	# Apply gravity
	if not is_on_floor():
		velocity.y += gravity * delta

	# Apply knockback with friction-based decay
	velocity += knockback_velocity
	knockback_velocity *= knockback_friction  # Decay per frame

	# Move the character
	move_and_slide()

	# Physics state processing
	if state_machine:
		state_machine.physics_process_state(delta)


## Initialize the state machine with all fighter states
func _initialize_state_machine() -> void:
	state_machine = FighterStateMachine.new(self)
	add_child(state_machine)
	state_machine.change_state(FighterStateMachine.State.IDLE)


## Setup physics layer (characters on layer 1)
func _setup_physics_layer() -> void:
	collision_layer = 1
	collision_mask = 1


## Create hurtbox so character can receive hits
func _create_hurtbox() -> void:
	hurtbox = Hurtbox.new()
	hurtbox.name = "Hurtbox"
	hurtbox.set_fighter_owner(self)

	var shape_node = CollisionShape2D.new()
	var rect_shape = RectangleShape2D.new()
	rect_shape.size = Vector2(50, 80)
	shape_node.shape = rect_shape
	hurtbox.add_child(shape_node)
	add_child(hurtbox)


## Create a colored placeholder texture if sprite has no texture assigned
func _create_placeholder_visual() -> void:
	if sprite == null or sprite.texture != null:
		return
	var img = Image.create(60, 80, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	sprite.texture = ImageTexture.create_from_image(img)


## Virtual: return move data dict for the current attack or special
## Subclasses override to provide JSON-loaded move data
func get_move_data(is_special: bool) -> Dictionary:
	return {}


## Take damage and update health
func take_damage(amount: int) -> void:
	if not is_alive:
		return

	# Reduce damage if blocking
	var damage = maxi(1, amount)
	if is_blocking:
		damage = int(damage * 0.25)  # 75% damage reduction while blocking

	health -= damage
	health_changed.emit(health, max_health)

	if health <= 0:
		die()


## Apply knockback force
func apply_knockback(direction: Vector2, force: float) -> void:
	if not is_alive:
		return

	# Weight affects knockback resistance
	var knockback_multiplier = 1.0 / weight
	var final_knockback = direction.normalized() * force * knockback_multiplier

	# Reduce knockback if blocking
	if is_blocking:
		final_knockback *= 0.25  # 75% knockback reduction while blocking

	knockback_velocity = final_knockback

	# Transition to hitstun state (or blockstun if blocking)
	if is_blocking:
		# Shorter stun when blocking
		state_machine.set_hitstun_frames(5)  # 5 frames of blockstun
		state_machine.change_state(FighterStateMachine.State.HITSTUN)
	else:
		state_machine.change_state(FighterStateMachine.State.HITSTUN)


## Character dies
func die() -> void:
	if not is_alive:
		return

	is_alive = false
	state_machine.change_state(FighterStateMachine.State.DEAD)
	died.emit(player_id)


## Set facing direction and flip sprite
func set_facing_direction(direction: int) -> void:
	if direction != 0:
		facing_direction = sign(direction)
		if sprite:
			sprite.flip_h = facing_direction < 0


## Get current state
func get_current_state() -> int:
	return state_machine.current_state if state_machine else -1


## Get current velocity (for external systems)
func get_current_velocity() -> Vector2:
	return velocity
