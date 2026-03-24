extends Control

## Frame Data Display (F69)
## Shows frame data for the current move being performed
## Displays startup, active, recovery, and total frames
## Pulls data from character JSON move definitions

class_name FrameDataDisplay

## The fighter to monitor
var tracked_fighter: BaseFighter = null

## Current move data being displayed
var current_move_data: Dictionary = {}
var current_attack_state: String = "IDLE"
var current_frame: int = 0

## Visual settings
var panel_width: float = 220.0
var panel_height: float = 180.0
var line_height: float = 20.0
var font_size: int = 13
var title_font_size: int = 15

## Colors
var bg_color: Color = Color(0.0, 0.0, 0.0, 0.7)
var title_color: Color = Color(1.0, 0.9, 0.3, 1.0)
var label_color: Color = Color(0.8, 0.8, 0.8, 1.0)
var value_color: Color = Color(1.0, 1.0, 1.0, 1.0)
var startup_color: Color = Color(0.3, 0.8, 1.0, 1.0)
var active_color: Color = Color(1.0, 0.3, 0.3, 1.0)
var recovery_color: Color = Color(0.5, 1.0, 0.5, 1.0)
var bar_bg_color: Color = Color(0.2, 0.2, 0.2, 0.8)


func _ready() -> void:
	custom_minimum_size = Vector2(panel_width, panel_height)


func _process(_delta: float) -> void:
	if tracked_fighter == null:
		return

	_update_attack_info()
	queue_redraw()


func set_fighter(fighter: BaseFighter) -> void:
	tracked_fighter = fighter


func _update_attack_info() -> void:
	if tracked_fighter == null:
		return

	# Check if fighter has an attack state machine
	var attack_sm = _find_attack_state_machine()
	if attack_sm == null:
		current_attack_state = "IDLE"
		current_frame = 0
		return

	current_attack_state = attack_sm.get_state_name()
	current_frame = attack_sm.get_attack_frame()

	# Update move data when a new attack starts
	if attack_sm.current_state != AttackStateMachine.State.IDLE:
		current_move_data = {
			"startup_frames": attack_sm.startup_frames,
			"active_frames": attack_sm.active_frames,
			"recovery_frames": attack_sm.recovery_frames,
			"total_frames": attack_sm.startup_frames + attack_sm.active_frames + attack_sm.recovery_frames,
		}


func _find_attack_state_machine() -> AttackStateMachine:
	if tracked_fighter == null:
		return null

	# Search children for AttackStateMachine
	for child in tracked_fighter.get_children():
		if child is AttackStateMachine:
			return child

	return null


func _draw() -> void:
	# Background panel
	var panel_rect = Rect2(Vector2.ZERO, Vector2(panel_width, panel_height))
	draw_rect(panel_rect, bg_color)

	# Border
	draw_rect(panel_rect, Color(0.4, 0.4, 0.4, 0.6), false, 1.0)

	var y = 8.0
	var x_pad = 8.0

	# Title
	draw_string(ThemeDB.fallback_font, Vector2(x_pad, y + title_font_size),
		"FRAME DATA", HORIZONTAL_ALIGNMENT_LEFT, -1, title_font_size, title_color)
	y += title_font_size + 8

	# Separator line
	draw_line(Vector2(x_pad, y), Vector2(panel_width - x_pad, y), Color(0.4, 0.4, 0.4, 0.6), 1.0)
	y += 6

	if current_move_data.is_empty():
		draw_string(ThemeDB.fallback_font, Vector2(x_pad, y + font_size),
			"No move active", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, label_color)
		return

	# Attack state
	var state_color = _get_state_color(current_attack_state)
	draw_string(ThemeDB.fallback_font, Vector2(x_pad, y + font_size),
		"State: %s (F%d)" % [current_attack_state, current_frame],
		HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, state_color)
	y += line_height + 2

	# Frame data values
	var startup = current_move_data.get("startup_frames", 0)
	var active = current_move_data.get("active_frames", 0)
	var recovery = current_move_data.get("recovery_frames", 0)
	var total = current_move_data.get("total_frames", 0)

	_draw_frame_row(Vector2(x_pad, y), "Startup:", startup, startup_color)
	y += line_height

	_draw_frame_row(Vector2(x_pad, y), "Active:", active, active_color)
	y += line_height

	_draw_frame_row(Vector2(x_pad, y), "Recovery:", recovery, recovery_color)
	y += line_height

	_draw_frame_row(Vector2(x_pad, y), "Total:", total, value_color)
	y += line_height + 4

	# Frame timeline bar
	_draw_frame_bar(Vector2(x_pad, y), panel_width - x_pad * 2, startup, active, recovery)


func _draw_frame_row(pos: Vector2, label: String, value: int, color: Color) -> void:
	draw_string(ThemeDB.fallback_font, pos + Vector2(0, font_size),
		label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, label_color)
	draw_string(ThemeDB.fallback_font, pos + Vector2(100, font_size),
		"%d" % value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


func _draw_frame_bar(pos: Vector2, width: float, startup: int, active: int, recovery: int) -> void:
	var total = startup + active + recovery
	if total == 0:
		return

	var bar_height = 12.0

	# Background
	draw_rect(Rect2(pos, Vector2(width, bar_height)), bar_bg_color)

	# Startup segment
	var startup_width = (float(startup) / total) * width
	draw_rect(Rect2(pos, Vector2(startup_width, bar_height)), startup_color)

	# Active segment
	var active_width = (float(active) / total) * width
	draw_rect(Rect2(pos + Vector2(startup_width, 0), Vector2(active_width, bar_height)), active_color)

	# Recovery segment
	var recovery_width = (float(recovery) / total) * width
	draw_rect(Rect2(pos + Vector2(startup_width + active_width, 0), Vector2(recovery_width, bar_height)), recovery_color)

	# Current frame indicator
	if current_frame > 0:
		var frame_in_total = current_frame
		match current_attack_state:
			"ACTIVE":
				frame_in_total = startup + current_frame
			"RECOVERY":
				frame_in_total = startup + active + current_frame

		var indicator_x = (float(frame_in_total) / total) * width
		indicator_x = clampf(indicator_x, 0, width)
		draw_line(
			pos + Vector2(indicator_x, -2),
			pos + Vector2(indicator_x, bar_height + 2),
			Color.WHITE, 2.0
		)


func _get_state_color(state_name: String) -> Color:
	match state_name:
		"STARTUP":
			return startup_color
		"ACTIVE":
			return active_color
		"RECOVERY":
			return recovery_color
		_:
			return label_color
