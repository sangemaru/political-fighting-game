## Battle HUD Manager
## Coordinates all UI elements during battle
## Manages player HUDs, timers, overlays, and end screens

class_name BattleHUDManager
extends CanvasLayer

## Signals
signal ui_ready

## Configuration
@export var p1_fighter_path: NodePath = ""
@export var p2_fighter_path: NodePath = ""

## Internal references
var p1_fighter: BaseFighter = null
var p2_fighter: BaseFighter = null
var p1_round_wins: int = 0
var p2_round_wins: int = 0

## UI Components
@onready var p1_hud: PlayerHUD = $P1HUD
@onready var p2_hud: PlayerHUD = $P2HUD
@onready var round_timer: RoundTimer = $RoundTimer
@onready var round_end_overlay: RoundEndOverlay = $RoundEndOverlay
@onready var match_end_screen: MatchEndScreen = $MatchEndScreen


func _ready() -> void:
	# Get fighter references from paths or scene
	if p1_fighter_path:
		p1_fighter = get_node(p1_fighter_path)
	if p2_fighter_path:
		p2_fighter = get_node(p2_fighter_path)

	# Connect HUDs to fighters if available
	if p1_fighter and p1_hud:
		p1_hud.connect_to_fighter(p1_fighter)
	if p2_fighter and p2_hud:
		p2_hud.connect_to_fighter(p2_fighter)

	# Connect GameManager signals
	if GameManager:
		GameManager.round_started.connect(_on_round_started)
		GameManager.round_ended.connect(_on_round_ended)
		GameManager.match_ended.connect(_on_match_ended)

	# Connect overlay and screen signals
	if round_end_overlay:
		round_end_overlay.overlay_finished.connect(_on_round_overlay_finished)

	if match_end_screen:
		match_end_screen.rematch_requested.connect(_on_rematch_requested)
		match_end_screen.main_menu_requested.connect(_on_main_menu_requested)

	ui_ready.emit()


## Initialize HUD for battle
func initialize_battle(p1: BaseFighter, p2: BaseFighter) -> void:
	p1_fighter = p1
	p2_fighter = p2
	p1_round_wins = 0
	p2_round_wins = 0

	if p1_hud:
		p1_hud.connect_to_fighter(p1)
	if p2_hud:
		p2_hud.connect_to_fighter(p2)


## Called when round starts
func _on_round_started(round_number: int) -> void:
	print("BattleHUD: Round %d started" % round_number)
	if round_end_overlay:
		round_end_overlay.hide_overlay()


## Called when round ends
func _on_round_ended(winner: String) -> void:
	print("BattleHUD: Round ended - %s wins" % winner)

	# Update round wins
	if winner == "Player 1" and p1_hud:
		p1_round_wins += 1
		p1_hud.add_round_win()
	elif winner == "Player 2" and p2_hud:
		p2_round_wins += 1
		p2_hud.add_round_win()

	# Determine win condition
	var win_condition = "K.O."
	if GameManager.is_round_time_up():
		win_condition = "TIME!"

	# Show overlay
	if round_end_overlay:
		round_end_overlay.show_overlay(winner, win_condition, p1_round_wins, p2_round_wins)


## Called when round overlay finishes
func _on_round_overlay_finished() -> void:
	print("BattleHUD: Round overlay finished")

	# Check if match should end
	if GameManager.should_end_match():
		# Match ends
		var final_winner = "Player 1" if p1_round_wins > p2_round_wins else "Player 2"
		GameManager.change_state(GameManager.GameState.MATCH_END)
		if match_end_screen:
			match_end_screen.show_screen(final_winner)
	else:
		# Start next round
		GameManager.start_new_round()


## Called when match ends
func _on_match_ended(winner: String) -> void:
	print("BattleHUD: Match ended - %s wins" % winner)


## Called when rematch is requested
func _on_rematch_requested() -> void:
	print("BattleHUD: Rematch requested")
	GameManager.reset_battle()
	p1_round_wins = 0
	p2_round_wins = 0

	if p1_hud:
		p1_hud.reset_round_wins()
	if p2_hud:
		p2_hud.reset_round_wins()

	GameManager.change_state(GameManager.GameState.BATTLE)


## Called when main menu is requested
func _on_main_menu_requested() -> void:
	print("BattleHUD: Main menu requested")
	GameManager.change_state(GameManager.GameState.MENU)
	get_tree().change_scene_to_file("res://game/scenes/main.tscn")


## Get player HUD
func get_player_hud(player_id: int) -> PlayerHUD:
	return p1_hud if player_id == 1 else p2_hud


## Get round wins
func get_round_wins(player_id: int) -> int:
	return p1_round_wins if player_id == 1 else p2_round_wins
