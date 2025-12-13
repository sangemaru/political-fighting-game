extends Node

## Damage Calculator
## Calculates damage based on attacker stats, defender defense, and combo scaling

class_name DamageCalculator


## Combo tracking
var combo_count: int = 0
var combo_damage_scaling: float = 1.0  # 1.0 = 100%, 0.9 = 90%, etc.

## Signals
signal combo_updated(count: int, scaling: float)


## Calculate final damage
## base_damage * (attacker_power / defender_defense) * combo_scaling
func calculate_damage(
	base_damage: int,
	attacker_power: int,
	defender_defense: int,
	combo_count_in: int = 0
) -> int:
	# Prevent division by zero
	if defender_defense <= 0:
		defender_defense = 1

	# Base calculation
	var damage: float = float(base_damage) * (float(attacker_power) / float(defender_defense))

	# Apply combo scaling
	var scaling = get_combo_scaling(combo_count_in)
	damage *= scaling

	# Return as integer
	return maxi(1, int(damage))


## Get combo scaling multiplier
## Each hit reduces damage by 10% (0.9, 0.81, 0.729, etc.)
func get_combo_scaling(hit_number: int) -> float:
	if hit_number <= 0:
		return 1.0

	# 10% reduction per hit: 0.9^n
	return pow(0.9, float(hit_number))


## Increase combo counter and get new scaling
func add_combo_hit() -> float:
	combo_count += 1
	combo_damage_scaling = get_combo_scaling(combo_count)
	combo_updated.emit(combo_count, combo_damage_scaling)
	return combo_damage_scaling


## Reset combo counter
func reset_combo() -> void:
	combo_count = 0
	combo_damage_scaling = 1.0
	combo_updated.emit(combo_count, combo_damage_scaling)


## Get current combo information
func get_combo_info() -> Dictionary:
	return {
		"count": combo_count,
		"scaling": combo_damage_scaling,
		"damage_reduction": 1.0 - combo_damage_scaling
	}
