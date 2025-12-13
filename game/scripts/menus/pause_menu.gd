## Pause menu script
## Activated during battle with ESC

extends Control

@onready var resume_button: Button = $Panel/VBoxContainer/ResumeButton
@onready var options_button: Button = $Panel/VBoxContainer/OptionsButton
@onready var quit_button: Button = $Panel/VBoxContainer/QuitButton


func _ready() -> void:
	# Connect button signals
	resume_button.pressed.connect(_on_resume_pressed)
	options_button.pressed.connect(_on_options_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	# Pause the game tree (except this menu)
	get_tree().paused = true

	# Set process mode to always so this menu still works
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Focus resume button
	resume_button.grab_focus()


func _process(_delta: float) -> void:
	# ESC also resumes
	if Input.is_action_just_pressed("ui_cancel"):
		_on_resume_pressed()


func _on_resume_pressed() -> void:
	# Unpause and remove menu
	get_tree().paused = false
	GameManager.toggle_pause()  # Returns to BATTLE state
	queue_free()


func _on_options_pressed() -> void:
	# TODO: Open options overlay (for now, just placeholder)
	print("Options not implemented in pause menu yet")


func _on_quit_pressed() -> void:
	# Unpause and return to main menu
	get_tree().paused = false
	GameManager.change_state(GameManager.GameState.MENU)
	SceneManager.goto_scene("res://game/scenes/menus/main_menu.tscn")
