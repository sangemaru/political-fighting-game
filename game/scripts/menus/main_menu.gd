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

	# Connect menu sound effects
	_connect_menu_sounds(play_button)
	_connect_menu_sounds(options_button)
	_connect_menu_sounds(quit_button)

	# Set GameManager state
	GameManager.change_state(GameManager.GameState.MENU)

	# Focus first button
	play_button.grab_focus()

	# Play menu music
	AudioManager.play_music("menu_theme")


func _on_play_pressed() -> void:
	AudioManager.play_sfx("menu_confirm")
	# Navigate to character select
	SceneManager.goto_scene("res://game/scenes/menus/character_select.tscn")


func _on_options_pressed() -> void:
	AudioManager.play_sfx("menu_confirm")
	# Navigate to options menu
	SceneManager.goto_scene("res://game/scenes/menus/options_menu.tscn")


func _on_quit_pressed() -> void:
	AudioManager.play_sfx("menu_confirm")
	# Quit the game
	get_tree().quit()


## Connect menu sound effects to button
func _connect_menu_sounds(button: Button) -> void:
	button.mouse_entered.connect(func(): AudioManager.play_sfx("menu_hover"))
	button.focus_entered.connect(func(): AudioManager.play_sfx("menu_select"))
