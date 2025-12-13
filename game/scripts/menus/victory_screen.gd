## F59: Victory Screen
## Displays match winner, score, and navigation options
extends Control


## UI References
@onready var winner_label: Label = $VBoxContainer/WinnerLabel
@onready var score_label: Label = $VBoxContainer/ScoreLabel
@onready var winner_sprite: Sprite2D = $VBoxContainer/WinnerSprite
@onready var rematch_button: Button = $VBoxContainer/ButtonContainer/RematchButton
@onready var character_select_button: Button = $VBoxContainer/ButtonContainer/CharacterSelectButton
@onready var main_menu_button: Button = $VBoxContainer/ButtonContainer/MainMenuButton


## Match data
var winner_id: int = 0
var score_p1: int = 0
var score_p2: int = 0
var winner_character_name: String = ""


func _ready() -> void:
	# Connect buttons
	rematch_button.pressed.connect(_on_rematch_pressed)
	character_select_button.pressed.connect(_on_character_select_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)

	# Connect to GameManager
	GameManager.match_won.connect(_on_match_won)

	# Hide by default
	visible = false


## Display victory screen with match results
func show_victory(winner: int, rounds_p1: int, rounds_p2: int, winner_char_name: String = "") -> void:
	winner_id = winner
	score_p1 = rounds_p1
	score_p2 = rounds_p2
	winner_character_name = winner_char_name

	# Update winner label
	if winner_id == 1:
		winner_label.text = "PLAYER 1 WINS!"
		winner_label.add_theme_color_override("font_color", Color(0.2, 0.6, 1.0))  # Blue
	elif winner_id == 2:
		winner_label.text = "PLAYER 2 WINS!"
		winner_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.2))  # Red
	else:
		winner_label.text = "DRAW!"
		winner_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))  # Gray

	# Update score label
	score_label.text = "Score: %d - %d" % [score_p1, score_p2]

	# TODO: Load and display winner character sprite
	# For now, hide sprite placeholder
	if winner_sprite:
		winner_sprite.visible = false

	# Play victory music
	AudioManager.play_music("victory_theme")

	# Show the screen
	visible = true
	rematch_button.grab_focus()

	print("[VictoryScreen] Showing victory screen - Winner: Player %d (Score: %d-%d)" % [winner_id, score_p1, score_p2])


## F60: Rematch button handler
func _on_rematch_pressed() -> void:
	AudioManager.play_sfx("menu_confirm")
	print("[VictoryScreen] Rematch requested")
	visible = false
	GameManager.reset_match()


## Return to character select
func _on_character_select_pressed() -> void:
	AudioManager.play_sfx("menu_confirm")
	print("[VictoryScreen] Returning to character select")
	visible = false
	SceneManager.change_scene("res://game/scenes/menus/character_select.tscn")


## Return to main menu
func _on_main_menu_pressed() -> void:
	AudioManager.play_sfx("menu_confirm")
	print("[VictoryScreen] Returning to main menu")
	visible = false
	SceneManager.change_scene("res://game/scenes/menus/main_menu.tscn")


## Handle match_won signal from GameManager
func _on_match_won(player_id: int) -> void:
	# Get round scores from GameManager
	var p1_score = GameManager.rounds_won[1]
	var p2_score = GameManager.rounds_won[2]

	# Show victory screen
	show_victory(player_id, p1_score, p2_score)
