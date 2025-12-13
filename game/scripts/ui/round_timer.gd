## Round Timer Display
## Shows remaining time in current round
## Flashes red when under 10 seconds
## Connects to GameManager battle signals

class_name RoundTimer
extends Control

## Properties
@export var warning_threshold: int = 10  # Seconds before flashing red
@export var flash_speed: float = 0.5  # Seconds per flash cycle

## Internal state
var remaining_seconds: int = 99
var is_warning: bool = false
var flash_timer: float = 0.0
var is_visible_in_flash: bool = true

## UI Components
@onready var timer_label: Label = $TimerLabel
@onready var warning_panel: Panel = $WarningPanel  # Optional warning background


func _ready() -> void:
	if timer_label:
		timer_label.text = "99"
		timer_label.add_theme_font_size_override("font_size", 48)

	if warning_panel:
		warning_panel.self_modulate = Color.TRANSPARENT

	# Connect to GameManager
	if GameManager:
		GameManager.battle_started.connect(_on_battle_started)
		GameManager.round_started.connect(_on_round_started)

	set_process(true)


func _process(delta: float) -> void:
	# Update remaining time from GameManager
	if GameManager and GameManager.current_state == GameManager.GameState.BATTLE:
		var remaining = GameManager.get_round_remaining_time()
		var new_seconds = int(ceil(remaining))

		if new_seconds != remaining_seconds:
			remaining_seconds = new_seconds
			update_display()

		# Handle warning state
		if remaining_seconds <= warning_threshold:
			if not is_warning:
				is_warning = true
				flash_timer = 0.0

			# Flash effect
			if is_warning:
				flash_timer += delta
				if flash_timer >= flash_speed:
					flash_timer = fmod(flash_timer, flash_speed)

				is_visible_in_flash = fmod(flash_timer, flash_speed) < flash_speed * 0.5
				update_warning_display()
		else:
			if is_warning:
				is_warning = false
				if timer_label:
					timer_label.modulate = Color.WHITE
				if warning_panel:
					warning_panel.self_modulate = Color.TRANSPARENT


func _on_battle_started() -> void:
	remaining_seconds = 99
	is_warning = false
	update_display()


func _on_round_started(_round_number: int) -> void:
	remaining_seconds = 99
	is_warning = false
	flash_timer = 0.0
	update_display()


func update_display() -> void:
	if timer_label:
		timer_label.text = str(remaining_seconds).pad_zeros(2)


func update_warning_display() -> void:
	if not is_warning:
		return

	if timer_label:
		if is_visible_in_flash:
			timer_label.modulate = Color.RED
		else:
			timer_label.modulate = Color(1.0, 0.5, 0.5)  # Dark red when hidden

	if warning_panel:
		var target_color = Color.RED if is_visible_in_flash else Color.TRANSPARENT
		target_color.a = 0.2 if is_visible_in_flash else 0.0
		warning_panel.self_modulate = warning_panel.self_modulate.lerp(target_color, 0.1)


## Manually set remaining time (for testing)
func set_remaining_time(seconds: int) -> void:
	remaining_seconds = clampi(seconds, 0, 99)
	update_display()
	is_warning = remaining_seconds <= warning_threshold


## Get current displayed time
func get_displayed_time() -> int:
	return remaining_seconds
