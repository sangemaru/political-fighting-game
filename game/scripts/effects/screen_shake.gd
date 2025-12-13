extends Node
class_name ScreenShake

## Screen shake effect manager
## Attach to Camera2D node to enable shake on hit

## Shake intensity (pixels)
var shake_amount: float = 0.0

## How fast shake decays (higher = faster decay)
@export var shake_decay: float = 5.0

## Camera reference
var camera: Camera2D = null

## Original camera offset
var original_offset: Vector2 = Vector2.ZERO

func _ready() -> void:
	# Get parent Camera2D
	if get_parent() is Camera2D:
		camera = get_parent() as Camera2D
		original_offset = camera.offset
	else:
		push_error("ScreenShake must be child of Camera2D")

func _process(delta: float) -> void:
	if camera == null:
		return

	if shake_amount > 0:
		# Apply random offset
		camera.offset = original_offset + Vector2(
			randf_range(-1, 1),
			randf_range(-1, 1)
		) * shake_amount

		# Decay shake
		shake_amount = lerp(shake_amount, 0.0, shake_decay * delta)

		# Clamp to zero when very small
		if shake_amount < 0.01:
			shake_amount = 0.0
			camera.offset = original_offset
	else:
		# Ensure offset is reset
		camera.offset = original_offset

## Trigger screen shake with given intensity
func shake(intensity: float) -> void:
	shake_amount = intensity

## Shake based on damage amount
func shake_from_damage(damage: float) -> void:
	# Scale: 5 damage = 2 pixels, 20 damage = 8 pixels
	var intensity = clamp(damage * 0.4, 1.0, 10.0)
	shake(intensity)

## Shake based on knockback
func shake_from_knockback(knockback: Vector2) -> void:
	# Use knockback magnitude
	var intensity = clamp(knockback.length() * 0.02, 1.0, 10.0)
	shake(intensity)
