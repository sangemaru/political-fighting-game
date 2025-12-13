extends Area2D

## Hitbox System
## Attack collision areas that deal damage
## Hitboxes are active during the attack window (ACTIVE frames)
## Parent must set hitbox data via set_hitbox_data()

class_name Hitbox


## Hitbox properties
var damage: int = 0
var knockback_force: int = 0
var hitstun_frames: int = 0
var owner_fighter: BaseFighter = null
var attack_id: String = ""  # Unique identifier to prevent hitting twice

## Hit tracking (prevent same attack hitting multiple times)
var targets_hit: Array[BaseFighter] = []

## Signals
signal hit_connected(target: BaseFighter, damage: int)


func _ready() -> void:
	# Configure as hitbox (layer 2)
	collision_layer = 0
	collision_mask = 4  # Only detect hurtboxes on layer 3

	area_entered.connect(_on_area_entered)

	# Hitbox starts inactive
	monitorable = true
	monitoring = true


## Set hitbox data from attack definition
func set_hitbox_data(
	p_damage: int,
	p_knockback_force: int,
	p_hitstun_frames: int,
	p_owner: BaseFighter,
	p_attack_id: String
) -> void:
	damage = p_damage
	knockback_force = p_knockback_force
	hitstun_frames = p_hitstun_frames
	owner_fighter = p_owner
	attack_id = p_attack_id


## Activate hitbox (called during ACTIVE frames of attack)
func activate() -> void:
	targets_hit.clear()
	monitoring = true


## Deactivate hitbox (called after attack window ends)
func deactivate() -> void:
	monitoring = false
	targets_hit.clear()


## Check if target has already been hit by this attack
func has_hit_target(target: BaseFighter) -> bool:
	return target in targets_hit


## Record hit on target (prevents duplicate hits)
func mark_target_hit(target: BaseFighter) -> void:
	targets_hit.append(target)


## Handle hitbox collision
func _on_area_entered(area: Area2D) -> void:
	# Only detect hurtboxes
	if not area is Hurtbox:
		return

	var hurtbox: Hurtbox = area
	var target: BaseFighter = hurtbox.owner_fighter

	# Don't hit self or already-hit targets
	if target == owner_fighter or has_hit_target(target):
		return

	# Mark as hit and deal damage
	mark_target_hit(target)

	# Calculate knockback direction
	var knockback_direction: Vector2 = Vector2.RIGHT
	if owner_fighter:
		knockback_direction = (target.global_position - owner_fighter.global_position).normalized()

	# Apply damage through hurtbox
	hurtbox.receive_hit(damage, knockback_direction, knockback_force, hitstun_frames)

	# Emit signal
	hit_connected.emit(target, damage)
