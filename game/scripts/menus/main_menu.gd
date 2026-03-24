## Main menu script
## Provides Play, Options, and Quit buttons

extends Control

const Version = preload("res://game/scripts/core/version.gd")

@onready var play_button: Button = $VBoxContainer/PlayButton
@onready var training_button: Button = $VBoxContainer/TrainingButton
@onready var options_button: Button = $VBoxContainer/OptionsButton
@onready var quit_button: Button = $VBoxContainer/QuitButton
@onready var version_label: Label = $VersionLabel


func _ready() -> void:
	print("[MainMenu] _ready() called")
	# Connect button signals
	play_button.pressed.connect(_on_play_pressed)
	training_button.pressed.connect(_on_training_pressed)
	options_button.pressed.connect(_on_options_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	# Connect menu sound effects
	_connect_menu_sounds(play_button)
	_connect_menu_sounds(training_button)
	_connect_menu_sounds(options_button)
	_connect_menu_sounds(quit_button)

	# Set GameManager state
	print("[MainMenu] Setting GameManager state to MENU")
	GameManager.change_state(GameManager.GameState.MENU)

	# Focus first button
	print("[MainMenu] Grabbing focus on play_button")
	play_button.grab_focus()

	# Play menu music
	print("[MainMenu] Playing menu music")
	AudioManager.play_music("menu_theme")

	# Display version
	version_label.text = Version.get_version_string()
	print("[MainMenu] _ready() complete, version: %s" % version_label.text)


func _on_play_pressed() -> void:
	AudioManager.play_sfx("menu_confirm")
	# Navigate to character select
	SceneManager.goto_scene("res://game/scenes/menus/character_select.tscn")


func _on_training_pressed() -> void:
	AudioManager.play_sfx("menu_confirm")
	# Navigate to training mode
	SceneManager.goto_scene("res://game/scenes/training/training_mode.tscn")


func _on_options_pressed() -> void:
	AudioManager.play_sfx("menu_confirm")
	# Navigate to options menu
	SceneManager.goto_scene("res://game/scenes/menus/options_menu.tscn")


func _on_quit_pressed() -> void:
	print("[MainMenu] QUIT PRESSED!")
	AudioManager.play_sfx("menu_confirm")
	# Quit the game
	get_tree().quit()


var _frame_count: int = 0
func _process(_delta: float) -> void:
	_frame_count += 1
	if _frame_count <= 5 or _frame_count % 60 == 0:
		print("[MainMenu] Frame %d" % _frame_count)


## Connect menu sound effects to button
func _connect_menu_sounds(button: Button) -> void:
	button.mouse_entered.connect(func(): AudioManager.play_sfx("menu_hover"))
	button.focus_entered.connect(func(): AudioManager.play_sfx("menu_select"))
