## Character select screen script
## Allows 2 players to select characters

extends Control

## Character data structure
var available_characters: Array = []
var selected_character_p1: int = 0
var selected_character_p2: int = 0
var p1_ready: bool = false
var p2_ready: bool = false

@onready var p1_name_label: Label = $HBoxContainer/P1Panel/VBoxContainer/NameLabel
@onready var p1_sprite: Sprite2D = $HBoxContainer/P1Panel/VBoxContainer/CharacterSprite
@onready var p1_ready_label: Label = $HBoxContainer/P1Panel/VBoxContainer/ReadyLabel

@onready var p2_name_label: Label = $HBoxContainer/P2Panel/VBoxContainer/NameLabel
@onready var p2_sprite: Sprite2D = $HBoxContainer/P2Panel/VBoxContainer/CharacterSprite
@onready var p2_ready_label: Label = $HBoxContainer/P2Panel/VBoxContainer/ReadyLabel


func _ready() -> void:
	# Load available characters
	_load_characters()

	# Update initial display
	_update_p1_display()
	_update_p2_display()

	# Set GameManager state
	GameManager.change_state(GameManager.GameState.CHARACTER_SELECT)


func _process(_delta: float) -> void:
	# Player 1 controls (WASD + Space)
	if not p1_ready:
		if Input.is_action_just_pressed("p1_move_left"):
			AudioManager.play_sfx("menu_select")
			selected_character_p1 = (selected_character_p1 - 1 + available_characters.size()) % available_characters.size()
			_update_p1_display()
		elif Input.is_action_just_pressed("p1_move_right"):
			AudioManager.play_sfx("menu_select")
			selected_character_p1 = (selected_character_p1 + 1) % available_characters.size()
			_update_p1_display()
		elif Input.is_action_just_pressed("p1_attack"):
			AudioManager.play_sfx("menu_confirm")
			p1_ready = true
			_update_p1_display()

	# Player 2 controls (Arrows + Enter)
	if not p2_ready:
		if Input.is_action_just_pressed("p2_move_left"):
			AudioManager.play_sfx("menu_select")
			selected_character_p2 = (selected_character_p2 - 1 + available_characters.size()) % available_characters.size()
			_update_p2_display()
		elif Input.is_action_just_pressed("p2_move_right"):
			AudioManager.play_sfx("menu_select")
			selected_character_p2 = (selected_character_p2 + 1) % available_characters.size()
			_update_p2_display()
		elif Input.is_action_just_pressed("p2_attack"):
			AudioManager.play_sfx("menu_confirm")
			p2_ready = true
			_update_p2_display()

	# Back button (ESC)
	if Input.is_action_just_pressed("ui_cancel"):
		AudioManager.play_sfx("menu_back")
		_on_back_pressed()

	# Both players ready - proceed to stage select
	if p1_ready and p2_ready:
		_on_both_ready()


func _load_characters() -> void:
	# Load character JSON files from resources/characters directory
	var character_dir = "res://game/resources/characters/"
	var dir = DirAccess.open(character_dir)

	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()

		while file_name != "":
			if file_name.ends_with(".json"):
				var file_path = character_dir + file_name
				var file = FileAccess.open(file_path, FileAccess.READ)
				if file:
					var json_text = file.get_as_text()
					var json = JSON.new()
					var parse_result = json.parse(json_text)

					if parse_result == OK:
						var character_data = json.get_data()
						available_characters.append(character_data)

					file.close()

			file_name = dir.get_next()

		dir.list_dir_end()

	# Ensure we have at least one character
	if available_characters.is_empty():
		push_error("No characters found!")


func _update_p1_display() -> void:
	if available_characters.is_empty():
		return

	var character = available_characters[selected_character_p1]
	p1_name_label.text = character.get("name", "Unknown")

	if p1_ready:
		p1_ready_label.text = "READY!"
		p1_ready_label.modulate = Color.GREEN
	else:
		p1_ready_label.text = "Select (SPACE)"
		p1_ready_label.modulate = Color.WHITE


func _update_p2_display() -> void:
	if available_characters.is_empty():
		return

	var character = available_characters[selected_character_p2]
	p2_name_label.text = character.get("name", "Unknown")

	if p2_ready:
		p2_ready_label.text = "READY!"
		p2_ready_label.modulate = Color.GREEN
	else:
		p2_ready_label.text = "Select (ENTER)"
		p2_ready_label.modulate = Color.WHITE


func _on_back_pressed() -> void:
	# Return to main menu
	SceneManager.goto_scene("res://game/scenes/menus/main_menu.tscn")


func _on_both_ready() -> void:
	# Store selected characters (for now, just proceed to stage select)
	# TODO: Store selections in GameManager for battle scene
	SceneManager.goto_scene("res://game/scenes/menus/stage_select.tscn")
