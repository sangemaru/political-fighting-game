## Match End Screen
## Shows final winner and options to rematch or return to main menu

class_name MatchEndScreen
extends Control

## Signals
signal rematch_requested
signal main_menu_requested

## Internal state
var final_winner: String = ""
var is_showing: bool = false

## UI Components
@onready var panel: Panel = $Panel
@onready var winner_label: Label = $Panel/VBoxContainer/WinnerLabel
@onready var rematch_button: Button = $Panel/VBoxContainer/ButtonContainer/RematchButton
@onready var menu_button: Button = $Panel/VBoxContainer/ButtonContainer/MenuButton


func _ready() -> void:
	# Start invisible
	if panel:
		panel.modulate.a = 0.0

	# Connect buttons
	if rematch_button:
		rematch_button.pressed.connect(_on_rematch_pressed)

	if menu_button:
		menu_button.pressed.connect(_on_menu_pressed)

	# Connect to GameManager
	if GameManager:
		GameManager.match_ended.connect(_on_match_ended)


## Called when match ends
func _on_match_ended(winner_id: int) -> void:
	var name := "DRAW"
	if winner_id == 1:
		name = "Player 1"
	elif winner_id == 2:
		name = "Player 2"
	show_screen(name)


## Show the match end screen
func show_screen(winner: String) -> void:
	final_winner = winner
	is_showing = true

	if winner_label:
		winner_label.text = "%s WINS THE MATCH!" % winner.to_upper()

	if panel:
		panel.modulate.a = 1.0

	if rematch_button:
		rematch_button.grab_focus()


## Hide the screen
func hide_screen() -> void:
	is_showing = false
	if panel:
		panel.modulate.a = 0.0


## Rematch button pressed
func _on_rematch_pressed() -> void:
	hide_screen()
	rematch_requested.emit()


## Main menu button pressed
func _on_menu_pressed() -> void:
	hide_screen()
	main_menu_requested.emit()
