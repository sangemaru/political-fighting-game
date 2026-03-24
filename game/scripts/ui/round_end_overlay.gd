## Round End Overlay
## Displays round result (winner and condition)
## Shows briefly before next round

class_name RoundEndOverlay
extends CanvasLayer

## Properties
@export var display_duration: float = 3.0  # Seconds to show overlay
@export var fade_out_duration: float = 0.5  # Seconds to fade out

## Signals
signal overlay_finished

## Internal state
var is_displaying: bool = false
var display_timer: float = 0.0
var winner_name: String = ""
var win_condition: String = ""

## UI Components
@onready var panel: Panel = $Panel
@onready var winner_label: Label = $Panel/VBoxContainer/WinnerLabel
@onready var condition_label: Label = $Panel/VBoxContainer/ConditionLabel
@onready var round_score_label: Label = $Panel/VBoxContainer/RoundScoreLabel


func _ready() -> void:
	# Start invisible
	if panel:
		panel.modulate.a = 0.0

	# Connect to GameManager
	if GameManager:
		GameManager.round_ended.connect(_on_round_ended)

	set_process(true)


func _process(delta: float) -> void:
	if not is_displaying:
		return

	display_timer += delta

	# Fade out near the end
	if display_timer >= display_duration - fade_out_duration:
		var fade_progress = (display_timer - (display_duration - fade_out_duration)) / fade_out_duration
		if panel:
			panel.modulate.a = lerp(1.0, 0.0, fade_progress)
	else:
		# Full opacity while displaying
		if panel:
			panel.modulate.a = 1.0

	# End overlay when timer expires
	if display_timer >= display_duration:
		is_displaying = false
		overlay_finished.emit()


## Called when round ends
func _on_round_ended(winner_id: int) -> void:
	var name := "DRAW"
	if winner_id == 1:
		name = "Player 1"
	elif winner_id == 2:
		name = "Player 2"
	winner_name = name
	show_overlay(name)


## Show the overlay with result
func show_overlay(winner: String, condition: String = "K.O.", p1_wins: int = 0, p2_wins: int = 0) -> void:
	winner_name = winner
	win_condition = condition

	if winner_label:
		winner_label.text = "%s WINS!" % winner.to_upper()

	if condition_label:
		condition_label.text = win_condition

	if round_score_label:
		round_score_label.text = "Round Score: %d - %d" % [p1_wins, p2_wins]

	is_displaying = true
	display_timer = 0.0

	if panel:
		panel.modulate.a = 1.0


## Hide overlay immediately
func hide_overlay() -> void:
	is_displaying = false
	if panel:
		panel.modulate.a = 0.0


## Set win condition text
func set_win_condition(condition: String) -> void:
	win_condition = condition
	if condition_label:
		condition_label.text = condition
