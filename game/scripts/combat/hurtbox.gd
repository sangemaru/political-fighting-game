extends Area2D

## Hurtbox System
## Vulnerable collision areas that receive damage
## Hurtboxes detect incoming hitboxes and process hits

class_name Hurtbox


## Reference to owner fighter
var owner_fighter: BaseFighter = null

## Signals
signal hit_received(damage: int, knockback_force: int, hitstun_frames: int)


func _ready() -> void:
	# Configure as hurtbox (layer 3)
	collision_layer = 4  # On layer 3
	collision_mask = 0  # Doesn't detect anything (hitboxes detect us)

	monitorable = true
	monitoring = false


## Set owner fighter reference
func set_owner(fighter: BaseFighter) -> void:
	owner_fighter = fighter


## Process incoming hit from hitbox
func receive_hit(
	damage: int,
	knockback_direction: Vector2,
	knockback_force: int,
	hitstun_frames: int
) -> void:
	if not owner_fighter:
		return

	# Apply damage to fighter
	owner_fighter.take_damage(damage)

	# Apply knockback
	owner_fighter.apply_knockback(knockback_direction, knockback_force)

	# Set hitstun
	if owner_fighter.state_machine:
		owner_fighter.state_machine.set_hitstun_frames(hitstun_frames)

	# Emit signal for external systems (sound, particles, etc.)
	hit_received.emit(damage, knockback_force, hitstun_frames)
