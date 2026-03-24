extends CPUParticles2D
class_name HitEffect

## Hit particle effect
## Spawns burst of particles on hit, then auto-frees

## Color presets for different hit types
const LIGHT_HIT_COLOR := Color(1.0, 0.8, 0.0, 1.0)  # Yellow-orange
const HEAVY_HIT_COLOR := Color(1.0, 0.3, 0.0, 1.0)  # Red-orange
const CRITICAL_HIT_COLOR := Color(1.0, 0.0, 0.5, 1.0)  # Pink-red

func _ready() -> void:
	# Start emitting
	emitting = true

	# Auto-free after lifetime
	var timer = get_tree().create_timer(lifetime + 0.1)
	timer.timeout.connect(_on_lifetime_complete)

func _on_lifetime_complete() -> void:
	queue_free()

## Set color based on hit type
func set_hit_type(is_heavy: bool = false, is_critical: bool = false) -> void:
	if is_critical:
		color = CRITICAL_HIT_COLOR
		amount = 25  # More particles for critical
	elif is_heavy:
		color = HEAVY_HIT_COLOR
		amount = 20
	else:
		color = LIGHT_HIT_COLOR
		amount = 15

## Set color based on damage amount
func set_damage_color(damage: float) -> void:
	if damage >= 20.0:
		set_hit_type(false, true)  # Critical
	elif damage >= 10.0:
		set_hit_type(true, false)  # Heavy
	else:
		set_hit_type(false, false)  # Light

## Spawn hit effect at position
static func spawn_at(scene_root: Node, pos: Vector2, damage: float = 10.0) -> HitEffect:
	var effect_scene = preload("res://game/scenes/effects/hit_effect.tscn")
	var effect = effect_scene.instantiate() as HitEffect
	scene_root.add_child(effect)
	effect.global_position = pos
	effect.set_damage_color(damage)
	return effect
