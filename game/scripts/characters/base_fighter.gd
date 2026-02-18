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

## Animation
var animation_player: AnimationPlayer = null
var _current_anim_state: int = -1   # Last state we called play() for
var _attack_phase: int = 0           # 0=startup 1=active 2=recovery

## References
@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	health = max_health
	_initialize_state_machine()
	_setup_physics_layer()
	_create_hurtbox()
	_create_placeholder_visual()
	_setup_animations()


func _process(delta: float) -> void:
	if state_machine:
		# Update blocking state based on current state
		is_blocking = (state_machine.current_state == FighterStateMachine.State.BLOCKING)
		state_machine.process_state(delta)
	_update_animation()


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


# ============================================================
# ANIMATION SYSTEM — 8 placeholder animations driven by state
# All animations use Sprite2D:modulate so they work on any
# character regardless of sprite color or scale.
# ============================================================

## Build AnimationLibrary and register all 8 animations
func _setup_animations() -> void:
	animation_player = get_node_or_null("AnimationPlayer")
	if animation_player == null:
		return

	var lib := AnimationLibrary.new()
	lib.add_animation("idle",            _make_idle_animation())
	lib.add_animation("walk",            _make_walk_animation())
	lib.add_animation("jump",            _make_jump_animation())
	lib.add_animation("attack_startup",  _make_attack_startup_animation())
	lib.add_animation("attack_active",   _make_attack_active_animation())
	lib.add_animation("attack_recovery", _make_attack_recovery_animation())
	lib.add_animation("hitstun",         _make_hitstun_animation())
	lib.add_animation("dead",            _make_dead_animation())

	animation_player.add_animation_library("", lib)
	animation_player.animation_finished.connect(_on_animation_finished)
	animation_player.play("idle")


## Switch animation when state machine changes state
func _update_animation() -> void:
	if animation_player == null or state_machine == null:
		return

	var sm_state := state_machine.current_state
	if sm_state == _current_anim_state:
		return  # Same state — let current animation keep playing

	_current_anim_state = sm_state
	_attack_phase = 0

	match sm_state:
		FighterStateMachine.State.IDLE:
			animation_player.play("idle")
		FighterStateMachine.State.WALKING:
			animation_player.play("walk")
		FighterStateMachine.State.JUMPING:
			animation_player.play("jump")
		FighterStateMachine.State.ATTACKING:
			animation_player.play("attack_startup")
		FighterStateMachine.State.HITSTUN, FighterStateMachine.State.KNOCKDOWN:
			animation_player.play("hitstun")
		FighterStateMachine.State.DEAD:
			animation_player.play("dead")
		FighterStateMachine.State.BLOCKING:
			# Blue tint already applied by _BlockingState; use idle timing
			animation_player.play("idle")


## Chain attack phases: startup → active → recovery → idle
func _on_animation_finished(anim_name: StringName) -> void:
	if state_machine == null or animation_player == null:
		return
	if state_machine.current_state != FighterStateMachine.State.ATTACKING:
		return

	if anim_name == &"attack_startup":
		_attack_phase = 1
		animation_player.play("attack_active")
	elif anim_name == &"attack_active":
		_attack_phase = 2
		animation_player.play("attack_recovery")
	elif anim_name == &"attack_recovery":
		_attack_phase = 0
		animation_player.play("idle")


## Helper: build a modulate Animation from keyframe list
## keyframes: [[time: float, Color], ...]
func _make_modulate_anim(
	keyframes: Array,
	length: float,
	loop: bool
) -> Animation:
	var anim := Animation.new()
	anim.length = length
	anim.loop_mode = Animation.LOOP_LINEAR if loop else Animation.LOOP_NONE
	var t := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(t, "Sprite2D:modulate")
	anim.track_set_interpolation_type(t, Animation.INTERPOLATION_LINEAR)
	for kf: Array in keyframes:
		anim.track_insert_key(t, kf[0], kf[1])
	return anim


## 1. IDLE — slow breathing pulse, loop 1.2 s
func _make_idle_animation() -> Animation:
	return _make_modulate_anim([
		[0.0,  Color(1.00, 1.00, 1.00, 1.0)],
		[0.6,  Color(0.88, 0.88, 0.88, 1.0)],
		[1.2,  Color(1.00, 1.00, 1.00, 1.0)],
	], 1.2, true)


## 2. WALK — quick brightness oscillation, loop 0.3 s
func _make_walk_animation() -> Animation:
	return _make_modulate_anim([
		[0.0,  Color(1.00, 1.00, 1.00, 1.0)],
		[0.15, Color(0.93, 0.93, 0.93, 1.0)],
		[0.3,  Color(1.00, 1.00, 1.00, 1.0)],
	], 0.3, true)


## 3. JUMP — cool blue-white flash on launch, 0.2 s no-loop
func _make_jump_animation() -> Animation:
	return _make_modulate_anim([
		[0.0,  Color(1.00, 1.00, 1.00, 1.0)],
		[0.05, Color(0.85, 0.90, 1.00, 1.0)],
		[0.2,  Color(1.00, 1.00, 1.00, 1.0)],
	], 0.2, false)


## 4. ATTACK_STARTUP — warm golden charge-up, 0.08 s no-loop
func _make_attack_startup_animation() -> Animation:
	return _make_modulate_anim([
		[0.0,  Color(1.00, 1.00, 1.00, 1.0)],
		[0.08, Color(1.00, 0.85, 0.35, 1.0)],
	], 0.08, false)


## 5. ATTACK_ACTIVE — bright white flash (hit window), 0.08 s no-loop
func _make_attack_active_animation() -> Animation:
	return _make_modulate_anim([
		[0.0,  Color(1.00, 0.85, 0.35, 1.0)],
		[0.04, Color(1.00, 1.00, 1.00, 1.0)],
		[0.08, Color(1.00, 0.85, 0.35, 1.0)],
	], 0.08, false)


## 6. ATTACK_RECOVERY — golden tint fades back to white, 0.15 s no-loop
func _make_attack_recovery_animation() -> Animation:
	return _make_modulate_anim([
		[0.0,  Color(1.00, 0.85, 0.35, 1.0)],
		[0.15, Color(1.00, 1.00, 1.00, 1.0)],
	], 0.15, false)


## 7. HITSTUN — rapid red flash, loop 0.12 s
func _make_hitstun_animation() -> Animation:
	return _make_modulate_anim([
		[0.0,  Color(1.00, 0.25, 0.25, 1.0)],
		[0.06, Color(1.00, 0.70, 0.70, 1.0)],
		[0.12, Color(1.00, 0.25, 0.25, 1.0)],
	], 0.12, true)


## 8. DEAD — fade to semi-transparent gray, 0.6 s no-loop
func _make_dead_animation() -> Animation:
	return _make_modulate_anim([
		[0.0,  Color(1.00, 1.00, 1.00, 1.0)],
		[0.3,  Color(0.60, 0.60, 0.60, 0.7)],
		[0.6,  Color(0.40, 0.40, 0.40, 0.3)],
	], 0.6, false)
