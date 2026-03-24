extends Node2D

## Battle Scene Manager
## Orchestrates the complete battle flow:
## - F39: Battle scene setup and instantiation
## - F40: Player spawning and character loading
## - F41: Win condition integration (health monitoring)
## - F42: Input routing to correct players

class_name BattleScene

## Configuration
@export var battle_config_path: String = "res://game/resources/battle_configs/default_battle.json"

## Scene node references
var stage: BaseStage = null
var fighters: Dictionary = {}  # {player_id: fighter_ref}
var ui_layer: CanvasLayer = null
var health_bars: Dictionary = {}  # {player_id: health_bar_ref}
var round_timer_label: Label = null
var camera: Camera2D = null
var screen_shake: ScreenShake = null
var combo_counters: Dictionary = {}  # {player_id: combo_counter_ref}

## Battle state tracking
var battle_active: bool = false
var round_active: bool = false
var battle_config: Dictionary = {}
var player_configs: Dictionary = {}

## Round reset state (F57)
var is_resetting_round: bool = false
var countdown_label: Label = null


func _ready() -> void:
	print("[BattleScene] Initializing battle...")

	# Initialize GameManager state
	if not is_instance_valid(GameManager):
		push_error("GameManager autoload not configured")
		return

	# Load battle configuration
	if not _load_battle_config():
		push_error("Failed to load battle configuration")
		return

	# Setup scene hierarchy (F39)
	_setup_scene_hierarchy()

	# Setup stage
	_setup_stage()

	# Setup camera with screen shake (F52)
	_setup_camera()

	# Setup UI layer
	_setup_ui_layer()

	# Spawn players (F40)
	if not _spawn_players():
		push_error("Failed to spawn players")
		return

	# Connect all signals
	_connect_signals()

	# Initialize GameManager for battle
	GameManager.reset_battle()
	GameManager.change_state(GameManager.GameState.BATTLE)

	battle_active = true
	round_active = true

	# Play battle music
	AudioManager.play_music("battle_theme")

	print("[BattleScene] Battle initialized successfully")
	print("  P1: %s (Health: %d)" % [fighters[1].name, fighters[1].health])
	print("  P2: %s (Health: %d)" % [fighters[2].name, fighters[2].health])


func _process(delta: float) -> void:
	if not battle_active or not round_active:
		return

	# Check win conditions (F41)
	_check_win_conditions()

	# Update UI
	_update_round_timer()


func _physics_process(delta: float) -> void:
	# Input routing (F42) - route InputManager signals to correct fighters
	if battle_active and round_active:
		_route_player_inputs()


## ============================================================================
## F39: BATTLE SCENE SETUP
## ============================================================================

func _load_battle_config() -> bool:
	var file = FileAccess.open(battle_config_path, FileAccess.READ)
	if file == null:
		push_error("Failed to load battle config: %s" % battle_config_path)
		return false

	var json = JSON.new()
	var error = json.parse(file.get_as_text())

	if error != OK:
		push_error("Failed to parse battle config JSON: %s" % battle_config_path)
		return false

	battle_config = json.get_data()
	if battle_config == null or battle_config.is_empty():
		push_error("Invalid battle configuration data")
		return false

	player_configs = battle_config.get("players", {})
	return true


func _setup_scene_hierarchy() -> void:
	"""Setup the battle scene tree structure"""
	# Main root (this node) is already setup as Node2D
	self.name = "Battle"
	# Fighters node already exists in the .tscn scene tree


func _setup_stage() -> void:
	"""Load and initialize the stage"""
	# Prefer GameManager selection over config file default (F45)
	var stage_id = GameManager.selected_stage if GameManager.selected_stage != "" else battle_config.get("stage", "arena_1")
	var stage_scene_path = "res://game/scenes/stages/%s.tscn" % stage_id

	# Load stage scene
	var stage_scene = load(stage_scene_path)
	if stage_scene == null:
		push_error("Failed to load stage scene: %s" % stage_scene_path)
		return

	stage = stage_scene.instantiate()
	add_child(stage)
	move_child(stage, 0)  # Move to front in scene tree

	print("[BattleScene] Stage loaded: %s" % stage_id)


func _setup_camera() -> void:
	"""Setup camera with screen shake effect (F52)"""
	camera = Camera2D.new()
	camera.name = "BattleCamera"
	camera.enabled = true
	add_child(camera)

	# Add screen shake component
	screen_shake = ScreenShake.new()
	screen_shake.name = "ScreenShake"
	camera.add_child(screen_shake)

	print("[BattleScene] Camera with screen shake initialized")


func _setup_ui_layer() -> void:
	"""Setup UI canvas layer with health bars and timer"""
	ui_layer = CanvasLayer.new()
	ui_layer.name = "UILayer"
	ui_layer.layer = 10
	add_child(ui_layer)

	# Create health bars for both players (F40 - part of UI setup)
	_create_player_ui()

	# Create combo counters for both players (F55)
	_create_combo_counters()

	# Create round timer
	_create_round_timer()

	# Create countdown overlay (F57)
	_create_countdown_overlay()

	# Create victory screen (F59)
	_create_victory_screen()


func _create_player_ui() -> void:
	"""Create health bar UI for both players"""

	# Player 1 Health Bar (left side, blue)
	var p1_health_bar_scene = load("res://game/scenes/ui/health_bar.tscn")
	if p1_health_bar_scene == null:
		push_error("Failed to load health bar scene")
		return

	var p1_hb = p1_health_bar_scene.instantiate()
	p1_hb.name = "PlayerHUD_P1"
	p1_hb.player_id = 1
	p1_hb.anchors_left = 0.0
	p1_hb.anchors_top = 0.0
	p1_hb.anchors_right = 0.35
	p1_hb.anchors_bottom = 0.15
	p1_hb.offset_left = 20.0
	p1_hb.offset_top = 20.0
	p1_hb.offset_right = -20.0
	p1_hb.offset_bottom = -20.0
	ui_layer.add_child(p1_hb)
	health_bars[1] = p1_hb

	# Player 2 Health Bar (right side, red)
	var p2_health_bar_scene = load("res://game/scenes/ui/health_bar.tscn")
	var p2_hb = p2_health_bar_scene.instantiate()
	p2_hb.name = "PlayerHUD_P2"
	p2_hb.player_id = 2
	p2_hb.anchors_left = 0.65
	p2_hb.anchors_top = 0.0
	p2_hb.anchors_right = 1.0
	p2_hb.anchors_bottom = 0.15
	p2_hb.offset_left = 20.0
	p2_hb.offset_top = 20.0
	p2_hb.offset_right = -20.0
	p2_hb.offset_bottom = -20.0
	ui_layer.add_child(p2_hb)
	health_bars[2] = p2_hb

	print("[BattleScene] Health bars created for both players")


func _create_combo_counters() -> void:
	"""Create combo counter UI for both players (F55)"""
	var combo_counter_scene = load("res://game/scenes/ui/combo_counter.tscn")
	if combo_counter_scene == null:
		push_error("Failed to load combo counter scene")
		return

	# Player 1 combo counter (below health bar)
	var p1_combo = combo_counter_scene.instantiate()
	p1_combo.name = "ComboCounter_P1"
	p1_combo.anchors_left = 0.0
	p1_combo.anchors_top = 0.15
	p1_combo.anchors_right = 0.35
	p1_combo.anchors_bottom = 0.25
	p1_combo.offset_left = 20.0
	p1_combo.offset_top = 0.0
	p1_combo.offset_right = -20.0
	p1_combo.offset_bottom = 0.0
	ui_layer.add_child(p1_combo)
	combo_counters[1] = p1_combo

	# Player 2 combo counter (below health bar)
	var p2_combo = combo_counter_scene.instantiate()
	p2_combo.name = "ComboCounter_P2"
	p2_combo.anchors_left = 0.65
	p2_combo.anchors_top = 0.15
	p2_combo.anchors_right = 1.0
	p2_combo.anchors_bottom = 0.25
	p2_combo.offset_left = 20.0
	p2_combo.offset_top = 0.0
	p2_combo.offset_right = -20.0
	p2_combo.offset_bottom = 0.0
	ui_layer.add_child(p2_combo)
	combo_counters[2] = p2_combo

	print("[BattleScene] Combo counters created for both players")


func _create_round_timer() -> void:
	"""Create round timer label"""
	var timer_control = Control.new()
	timer_control.name = "RoundTimerContainer"
	timer_control.anchors_left = 0.5
	timer_control.anchors_top = 0.0
	timer_control.anchors_right = 0.5
	timer_control.anchors_bottom = 0.0
	timer_control.offset_left = -50
	timer_control.offset_top = 20
	timer_control.offset_right = 50
	timer_control.offset_bottom = 80
	ui_layer.add_child(timer_control)

	round_timer_label = Label.new()
	round_timer_label.name = "RoundTimer"
	round_timer_label.text = "99"
	round_timer_label.add_theme_font_size_override("font_size", 48)
	round_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	round_timer_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	timer_control.add_child(round_timer_label)

	print("[BattleScene] Round timer created")


func _create_countdown_overlay() -> void:
	"""Create countdown overlay for round start (F57)"""
	var countdown_control = Control.new()
	countdown_control.name = "CountdownContainer"
	countdown_control.anchors_left = 0.0
	countdown_control.anchors_top = 0.0
	countdown_control.anchors_right = 1.0
	countdown_control.anchors_bottom = 1.0
	ui_layer.add_child(countdown_control)

	countdown_label = Label.new()
	countdown_label.name = "CountdownLabel"
	countdown_label.text = ""
	countdown_label.add_theme_font_size_override("font_size", 96)
	countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	countdown_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	countdown_label.anchor_left = 0.0
	countdown_label.anchor_top = 0.0
	countdown_label.anchor_right = 1.0
	countdown_label.anchor_bottom = 1.0
	countdown_label.visible = false
	countdown_control.add_child(countdown_label)

	print("[BattleScene] Countdown overlay created")


func _create_victory_screen() -> void:
	"""Create victory screen overlay (F59)"""
	var victory_screen_scene = load("res://game/scenes/menus/victory_screen.tscn")
	if victory_screen_scene == null:
		push_error("Failed to load victory screen scene")
		return

	var victory_screen = victory_screen_scene.instantiate()
	victory_screen.name = "VictoryScreen"
	ui_layer.add_child(victory_screen)

	print("[BattleScene] Victory screen created")


## ============================================================================
## F40: PLAYER SPAWNING & CHARACTER LOADING
## ============================================================================

func _spawn_players() -> bool:
	"""Spawn both players with characters loaded from config"""
	var fighters_node = get_node("Fighters")

	# Spawn Player 1
	if not _spawn_player(1, fighters_node):
		push_error("Failed to spawn Player 1")
		return false

	# Spawn Player 2
	if not _spawn_player(2, fighters_node):
		push_error("Failed to spawn Player 2")
		return false

	# Set opponent references for blocking (F54)
	fighters[1].opponent_ref = fighters[2]
	fighters[2].opponent_ref = fighters[1]

	return true


func _spawn_player(player_id: int, parent_node: Node2D) -> bool:
	"""Spawn a single player character at the correct spawn point"""

	var player_key = "player_%d" % player_id
	if not player_configs.has(player_key):
		push_error("Player config not found: %s" % player_key)
		return false

	var player_config = player_configs[player_key]

	# Prefer GameManager selection over config file defaults (F44)
	var gm_character = GameManager.selected_characters.get(player_id, "")
	var character_id = gm_character if gm_character != "" else player_config.get("character", "")
	var spawn_point_key = player_config.get("spawn_point", player_key)

	if character_id.is_empty():
		push_error("Character ID not specified for %s" % player_key)
		return false

	# Load character scene
	var character_scene_path = "res://game/scenes/characters/%s.tscn" % character_id
	var character_scene = load(character_scene_path)

	if character_scene == null:
		push_error("Failed to load character scene: %s" % character_scene_path)
		return false

	# Instantiate character
	var fighter = character_scene.instantiate()

	# Ensure it's a BaseFighter
	if not (fighter is BaseFighter):
		push_error("Character scene is not a BaseFighter: %s" % character_scene_path)
		fighter.queue_free()
		return false

	# Set player_id
	fighter.player_id = player_id
	fighter.name = "%sCharacter" % player_key.to_upper()

	# Get spawn position from stage
	if stage == null:
		push_error("Stage not initialized")
		fighter.queue_free()
		return false

	var spawn_pos = stage.get_spawn_position(player_id)
	fighter.global_position = spawn_pos

	# Add to scene
	parent_node.add_child(fighter)

	# Store reference
	fighters[player_id] = fighter

	print("[BattleScene] Player %d spawned at position %s" % [player_id, spawn_pos])
	print("  Character: %s" % character_id)
	print("  Max Health: %d" % fighter.max_health)

	return true


## ============================================================================
## F41: WIN CONDITION INTEGRATION
## ============================================================================

func _connect_signals() -> void:
	"""Connect all signals between systems"""

	for player_id in fighters:
		var fighter = fighters[player_id]

		# Connect fighter health signals to UI
		if health_bars.has(player_id):
			var health_bar = health_bars[player_id]
			fighter.health_changed.connect(health_bar._on_health_changed)
			fighter.died.connect(health_bar._on_fighter_died)
			health_bar.connect_to_fighter(fighter)

		# Connect fighter died signal to battle manager
		fighter.died.connect(_on_player_died.bindv([player_id]))

	# Connect GameManager signals
	GameManager.round_started.connect(_on_round_started)
	GameManager.battle_started.connect(_on_battle_started)

	print("[BattleScene] All signals connected")


func _check_win_conditions() -> void:
	"""Monitor both fighters' health and determine round winner"""

	if not round_active or not battle_active:
		return

	# Check if time is up
	if GameManager.is_round_time_up():
		_end_round_by_timeout()
		return


func _end_round_by_timeout() -> void:
	"""End round by timeout - higher health wins"""
	round_active = false

	var p1_health = fighters[1].health
	var p2_health = fighters[2].health

	var winner_id = 0  # 0 = draw
	if p1_health > p2_health:
		winner_id = 1
	elif p2_health > p1_health:
		winner_id = 2

	print("[BattleScene] Round ended by timeout - Winner: Player %d (P1: %d HP, P2: %d HP)" % [winner_id, p1_health, p2_health])
	GameManager.end_round(winner_id)


func _on_player_died(player_id: int) -> void:
	"""Called when a fighter's health reaches 0"""
	round_active = false

	var opponent_id = 3 - player_id  # 1->2, 2->1

	print("[BattleScene] Player %d died - Round won by Player %d" % [player_id, opponent_id])

	# Signal to GameManager to track the win (F58)
	GameManager.end_round(opponent_id)


## ============================================================================
## F42: INPUT ROUTING
## ============================================================================

func _route_player_inputs() -> void:
	"""Route per-player input to fighter state machines via set_input()"""

	for player_id in fighters:
		var fighter = fighters[player_id]
		if not fighter.is_alive:
			fighter.state_machine.clear_input()
			continue

		var prefix = "p%d_" % player_id

		# Build movement direction
		var direction: float = 0.0
		if Input.is_action_pressed(prefix + "move_left"):
			direction -= 1.0
		if Input.is_action_pressed(prefix + "move_right"):
			direction += 1.0

		var vertical: float = 0.0
		if Input.is_action_pressed(prefix + "move_up"):
			vertical -= 1.0  # Up is negative in Godot
		if Input.is_action_pressed(prefix + "move_down"):
			vertical += 1.0

		var attack = Input.is_action_just_pressed(prefix + "attack")
		var special = Input.is_action_just_pressed(prefix + "special")

		# Push input to the fighter's state machine (handles all states)
		fighter.state_machine.set_input(direction, vertical, attack, special)


## ============================================================================
## F57: ROUND RESET LOGIC
## ============================================================================

func reset_round() -> void:
	"""Reset round with countdown (F57)"""
	if is_resetting_round:
		return

	is_resetting_round = true
	round_active = false

	print("[BattleScene] Resetting round...")

	# Reset fighter positions and state
	for player_id in fighters:
		var fighter = fighters[player_id]
		var spawn_pos = stage.get_spawn_position(player_id)

		# Reset position
		fighter.global_position = spawn_pos

		# Reset health
		fighter.health = fighter.max_health
		fighter.is_alive = true

		# Reset state
		fighter.state_machine.change_state(FighterStateMachine.State.IDLE)
		fighter.velocity = Vector2.ZERO

	# Show countdown: 3, 2, 1, FIGHT!
	await _show_countdown()

	# Reset game manager timer
	GameManager.round_timer_frames = 0

	# Resume battle
	round_active = true
	is_resetting_round = false

	print("[BattleScene] Round reset complete - FIGHT!")


func _show_countdown() -> void:
	"""Display countdown: 3, 2, 1, FIGHT!"""
	if countdown_label == null:
		return

	countdown_label.visible = true

	for i in range(3, 0, -1):
		countdown_label.text = str(i)
		countdown_label.add_theme_color_override("font_color", Color.YELLOW)
		await get_tree().create_timer(1.0).timeout

	countdown_label.text = "FIGHT!"
	countdown_label.add_theme_color_override("font_color", Color.GREEN)
	await get_tree().create_timer(0.5).timeout

	countdown_label.visible = false


## ============================================================================
## BATTLE STATE CALLBACKS
## ============================================================================

func _on_battle_started() -> void:
	"""Called when GameManager enters BATTLE state"""
	print("[BattleScene] Battle started signal received")
	battle_active = true
	round_active = true


func _on_round_started(round_number: int) -> void:
	"""Called when a new round starts"""
	print("[BattleScene] Round %d started" % round_number)

	# Use F57 round reset logic with countdown
	reset_round()


func _update_round_timer() -> void:
	"""Update the round timer display"""
	if round_timer_label == null:
		return

	var remaining_time = GameManager.get_round_remaining_time()
	round_timer_label.text = "%.1f" % max(0.0, remaining_time)
