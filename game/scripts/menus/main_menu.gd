## Main menu script
## Provides Play, Options, and Quit buttons

extends Control

@onready var play_button: Button = $VBoxContainer/PlayButton
@onready var options_button: Button = $VBoxContainer/OptionsButton
@onready var quit_button: Button = $VBoxContainer/QuitButton


func _ready() -> void:
	# Connect button signals
	play_button.pressed.connect(_on_play_pressed)
	options_button.pressed.connect(_on_options_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	# Set GameManager state
	GameManager.change_state(GameManager.GameState.MENU)

	# Focus first button
	play_button.grab_focus()


func _on_play_pressed() -> void:
	# Navigate to character select
	SceneManager.goto_scene("res://game/scenes/menus/character_select.tscn")


func _on_options_pressed() -> void:
	# Navigate to options menu
	SceneManager.goto_scene("res://game/scenes/menus/options_menu.tscn")


func _on_quit_pressed() -> void:
	# Quit the game
	get_tree().quit()
