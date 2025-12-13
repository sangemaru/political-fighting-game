## Health Bar UI Component
## Displays current health / max health with smooth animation
## Animates when damage is taken
## Different colors for P1 (blue) and P2 (red)

class_name HealthBar
extends Control

## Signals
signal health_depleted

## Properties
@export var player_id: int = 1
@export var animate_speed: float = 0.2  # Seconds for animation
@export var p1_color: Color = Color.BLUE
@export var p2_color: Color = Color.RED

## Internal state
var max_health: int = 100
var current_health: int = 100
var target_health: int = 100
var is_animating: bool = false
var animation_progress: float = 0.0
var fighter_ref: BaseFighter = null

## UI Components
@onready var health_bar: ProgressBar = $HealthBar
@onready var damage_bar: ProgressBar = $DamageBar  # Shows health loss with delay
@onready var health_label: Label = $HealthLabel


func _ready() -> void:
	if health_bar:
		health_bar.min_value = 0
		health_bar.max_value = 100
		health_bar.value = 100
		health_bar.modulate = p1_color if player_id == 1 else p2_color

	if damage_bar:
		damage_bar.min_value = 0
		damage_bar.max_value = 100
		damage_bar.value = 100
		damage_bar.modulate = Color.DARK_RED
		damage_bar.z_index = -1  # Behind health bar

	if health_label:
		health_label.text = "%d / %d" % [current_health, max_health]

	set_process(true)


func _process(delta: float) -> void:
	if is_animating:
		animation_progress += delta / animate_speed

		if animation_progress >= 1.0:
			animation_progress = 1.0
			is_animating = false
			current_health = target_health
		else:
			current_health = int(lerp(float(current_health), float(target_health), animation_progress))

		update_display()


## Connect this health bar to a fighter
func connect_to_fighter(fighter: BaseFighter) -> void:
	if fighter == null:
		push_error("HealthBar: fighter is null")
		return

	fighter_ref = fighter
	max_health = fighter.max_health
	current_health = fighter.health
	target_health = fighter.health

	fighter.health_changed.connect(_on_health_changed)
	fighter.died.connect(_on_fighter_died)

	update_display()


## Called when fighter takes damage
func _on_health_changed(health: int, max_hp: int) -> void:
	max_health = max_hp
	target_health = health
	is_animating = true
	animation_progress = 0.0


## Called when fighter dies
func _on_fighter_died(_player_id: int) -> void:
	target_health = 0
	is_animating = true
	animation_progress = 0.0
	health_depleted.emit()


## Update the display based on current health
func update_display() -> void:
	if health_bar:
		var bar_percentage = float(current_health) / float(max_health) * 100.0
		health_bar.value = bar_percentage

	if damage_bar and not is_animating:
		# Damage bar catches up slowly after animation ends
		var current_bar = damage_bar.value
		var target_bar = float(current_health) / float(max_health) * 100.0
		damage_bar.value = lerp(current_bar, target_bar, 0.05)

	if health_label:
		health_label.text = "%d / %d" % [current_health, max_health]


## Set health directly (useful for testing)
func set_health(health: int) -> void:
	target_health = clampi(health, 0, max_health)
	is_animating = true
	animation_progress = 0.0


## Get current displayed health
func get_displayed_health() -> int:
	return current_health


## Get target health (actual value)
func get_target_health() -> int:
	return target_health if fighter_ref else target_health
