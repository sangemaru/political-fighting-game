extends Control
class_name ComboCounter

## Combo counter display
## Shows current combo count and resets on timeout or interrupt

## Combo state
var combo_count: int = 0
var reset_timer: float = 0.0

## Constants
@export var reset_timeout: float = 1.0  # Reset combo if no hit in 1 second
@export var min_combo_display: int = 2  # Only show combo at 2+ hits

## References
@onready var combo_label: Label = $ComboLabel

func _ready() -> void:
	hide()  # Hidden by default

func _process(delta: float) -> void:
	if combo_count > 0:
		reset_timer += delta
		if reset_timer >= reset_timeout:
			reset_combo()

## Increment combo count
func increment_combo() -> void:
	combo_count += 1
	reset_timer = 0.0

	# Only show combo if above minimum
	if combo_count >= min_combo_display:
		show()
		_update_display()
		_play_scale_animation()

## Reset combo to zero
func reset_combo() -> void:
	combo_count = 0
	reset_timer = 0.0
	hide()

## Update label text
func _update_display() -> void:
	if combo_count >= min_combo_display:
		combo_label.text = "%d HITS" % combo_count
	else:
		combo_label.text = ""

## Play scale animation on increment
func _play_scale_animation() -> void:
	# Simple scale pulse
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)

	# Scale up
	tween.tween_property(combo_label, "scale", Vector2(1.3, 1.3), 0.1)
	# Scale back down
	tween.tween_property(combo_label, "scale", Vector2(1.0, 1.0), 0.1)

	# Change color based on combo size
	if combo_count >= 10:
		combo_label.add_theme_color_override("font_color", Color(1.0, 0.0, 0.5, 1.0))  # Pink for big combos
	elif combo_count >= 5:
		combo_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.0, 1.0))  # Orange for medium
	else:
		combo_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.0, 1.0))  # Yellow for small
