## Player HUD
## Displays player name, health bar, and round wins
## Positioned at top corners (P1 left, P2 right)

class_name PlayerHUD
extends Control

## Properties
@export var player_id: int = 1
@export var character_name: String = "Player 1"

## Internal state
var round_wins: int = 0
var fighter_ref: BaseFighter = null

## UI Components
@onready var health_bar: HealthBar = $HealthBar
@onready var player_name_label: Label = $PlayerName
@onready var round_wins_container: HBoxContainer = $RoundWinsContainer
@onready var portrait_placeholder: Panel = $PortraitPlaceholder


func _ready() -> void:
	# Position HUD based on player ID
	if player_id == 1:
		anchor_left = 0.0
		anchor_top = 0.0
		anchor_right = 0.5
		anchor_bottom = 0.2
		offset_left = 10.0
		offset_top = 10.0
		offset_right = -10.0
		offset_bottom = -10.0
	else:
		anchor_left = 0.5
		anchor_top = 0.0
		anchor_right = 1.0
		anchor_bottom = 0.2
		offset_left = 10.0
		offset_top = 10.0
		offset_right = -10.0
		offset_bottom = -10.0

	if player_name_label:
		player_name_label.text = character_name

	if health_bar:
		health_bar.player_id = player_id

	if round_wins_container:
		round_wins_container.alignment = BoxContainer.ALIGNMENT_CENTER

	set_process(true)


## Connect this HUD to a fighter
func connect_to_fighter(fighter: BaseFighter) -> void:
	if fighter == null:
		push_error("PlayerHUD: fighter is null")
		return

	fighter_ref = fighter

	if health_bar:
		health_bar.connect_to_fighter(fighter)

	# Update name from character data if available
	if fighter.has_method("get_name"):
		character_name = fighter.get_name()
		if player_name_label:
			player_name_label.text = character_name


## Set character name
func set_character_name(name: String) -> void:
	character_name = name
	if player_name_label:
		player_name_label.text = name


## Add round win indicator
func add_round_win() -> void:
	round_wins += 1
	update_round_wins_display()


## Reset round wins
func reset_round_wins() -> void:
	round_wins = 0
	update_round_wins_display()


## Update the visual display of round wins
func update_round_wins_display() -> void:
	if not round_wins_container:
		return

	# Clear existing win indicators
	for child in round_wins_container.get_children():
		child.queue_free()

	# Add new win indicators (dots or icons)
	for i in range(round_wins):
		var win_dot = Panel.new()
		win_dot.custom_minimum_size = Vector2(20, 20)
		win_dot.modulate = Color.YELLOW
		round_wins_container.add_child(win_dot)


## Get current round wins
func get_round_wins() -> int:
	return round_wins


## Get the health bar component
func get_health_bar() -> HealthBar:
	return health_bar
