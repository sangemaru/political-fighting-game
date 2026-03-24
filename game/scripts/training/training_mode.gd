extends Node2D

## Training Mode (F68)
## Practice against a dummy opponent with training-specific tools
## Features: reset position, infinite health toggle, damage display
## Reuses existing battle/combat systems with training controls

class_name TrainingMode

## Training mode configuration
var training_config: Dictionary = {
	"infinite_health": true,
	"show_input_display": true,
	"show_frame_data": true,
	"show_hitboxes": false,
	"dummy_behavior": "stand",  # "stand", "jump", "crouch", "walk"
}

## Scene references
var stage: BaseStage = null
var fighters: Dictionary = {}  # {player_id: fighter_ref}
var camera: Camera2D = null
var screen_shake: ScreenShake = null

## UI references
var ui_layer: CanvasLayer = null
var training_menu_layer: CanvasLayer = null
var health_bars: Dictionary = {}
var input_displays: Dictionary = {}
var frame_data_display: FrameDataDisplay = null
var hitbox_visualizer: HitboxVisualizer = null
var damage_label: Label = null
var total_damage: int = 0
var combo_damage: int = 0
var combo_hits: int = 0

## Training state
var is_training_menu_open: bool = false
var dummy_player_id: int = 2  # P2 is the dummy by default

## Signals
signal training_reset
signal training_menu_toggled(is_open: bool)


func _ready() -> void:
	print("[TrainingMode] Initializing training mode...")

	_setup_scene_hierarchy()
	_setup_stage()
	_setup_camera()
	_setup_ui_layer()

	if not _spawn_fighters():
		push_error("[TrainingMode] Failed to spawn fighters")
		return

	_setup_training_tools()
	_setup_training_menu()
	_connect_signals()

	# Set game state
	GameManager.reset_battle()
	GameManager.change_state(GameManager.GameState.BATTLE)

	# Apply initial training config
	_apply_training_config()

	print("[TrainingMode] Training mode ready")


func _process(delta: float) -> void:
	# Check for training menu toggle (Escape or Start button)
	if Input.is_action_just_pressed("ui_cancel"):
		_toggle_training_menu()
		return

	if is_training_menu_open:
		return

	# Route P1 inputs
	_route_player_inputs()

	# Handle dummy behavior
	_update_dummy()

	# Restore health if infinite health is on
	if training_config["infinite_health"]:
		_restore_health()


func _physics_process(delta: float) -> void:
	if is_training_menu_open:
		return


## ============================================================================
## SCENE SETUP
## ============================================================================

func _setup_scene_hierarchy() -> void:
	self.name = "TrainingMode"

	var fighters_node = Node2D.new()
	fighters_node.name = "Fighters"
	add_child(fighters_node)


func _setup_stage() -> void:
	var stage_id = "arena_1"
	var stage_scene_path = "res://game/scenes/stages/%s.tscn" % stage_id
	var stage_scene = load(stage_scene_path)

	if stage_scene == null:
		push_error("[TrainingMode] Failed to load stage: %s" % stage_scene_path)
		return

	stage = stage_scene.instantiate()
	add_child(stage)
	move_child(stage, 0)


func _setup_camera() -> void:
	camera = Camera2D.new()
	camera.name = "TrainingCamera"
	camera.enabled = true
	add_child(camera)

	screen_shake = ScreenShake.new()
	screen_shake.name = "ScreenShake"
	camera.add_child(screen_shake)


func _setup_ui_layer() -> void:
	ui_layer = CanvasLayer.new()
	ui_layer.name = "UILayer"
	ui_layer.layer = 10
	add_child(ui_layer)

	# Health bars
	_create_health_bars()

	# Damage display label
	_create_damage_label()


func _create_health_bars() -> void:
	var health_bar_scene = load("res://game/scenes/ui/health_bar.tscn")
	if health_bar_scene == null:
		push_error("[TrainingMode] Failed to load health bar scene")
		return

	# P1 health bar
	var p1_hb = health_bar_scene.instantiate()
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

	# P2 health bar
	var p2_hb = health_bar_scene.instantiate()
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


func _create_damage_label() -> void:
	damage_label = Label.new()
	damage_label.name = "DamageLabel"
	damage_label.text = "Combo: 0 hits | 0 damage"
	damage_label.add_theme_font_size_override("font_size", 18)
	damage_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	damage_label.anchor_left = 0.3
	damage_label.anchor_top = 0.0
	damage_label.anchor_right = 0.7
	damage_label.anchor_bottom = 0.0
	damage_label.offset_top = 80.0
	damage_label.offset_bottom = 110.0
	damage_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3, 1.0))
	ui_layer.add_child(damage_label)


## ============================================================================
## FIGHTER SPAWNING
## ============================================================================

func _spawn_fighters() -> bool:
	var fighters_node = get_node("Fighters")

	# Get character selections from GameManager or use defaults
	var p1_char = "dictator_1"
	var p2_char = "demagogue_1"

	# Check if character select stored choices
	if GameManager.get("selected_characters") != null:
		var selections = GameManager.selected_characters
		if selections.has(1):
			p1_char = selections[1]
		if selections.has(2):
			p2_char = selections[2]

	if not _spawn_fighter(1, p1_char, fighters_node):
		return false

	if not _spawn_fighter(2, p2_char, fighters_node):
		return false

	# Set opponent references
	fighters[1].opponent_ref = fighters[2]
	fighters[2].opponent_ref = fighters[1]

	return true


func _spawn_fighter(player_id: int, character_id: String, parent: Node2D) -> bool:
	var scene_path = "res://game/scenes/characters/%s.tscn" % character_id
	var character_scene = load(scene_path)

	if character_scene == null:
		push_error("[TrainingMode] Failed to load character: %s" % scene_path)
		return false

	var fighter = character_scene.instantiate()

	if not (fighter is BaseFighter):
		push_error("[TrainingMode] Scene is not a BaseFighter: %s" % scene_path)
		fighter.queue_free()
		return false

	fighter.player_id = player_id
	fighter.name = "Player%d" % player_id

	if stage != null:
		fighter.global_position = stage.get_spawn_position(player_id)

	parent.add_child(fighter)
	fighters[player_id] = fighter

	print("[TrainingMode] Player %d spawned: %s" % [player_id, character_id])
	return true


## ============================================================================
## TRAINING TOOLS SETUP
## ============================================================================

func _setup_training_tools() -> void:
	# Input displays (F67) - positioned at bottom corners
	_setup_input_displays()

	# Frame data display (F69)
	_setup_frame_data_display()

	# Hitbox visualizer (F70)
	_setup_hitbox_visualizer()


func _setup_input_displays() -> void:
	var input_display_scene = load("res://game/scenes/ui/input_display.tscn")
	if input_display_scene == null:
		push_error("[TrainingMode] Failed to load input display scene")
		return

	# P1 input display (bottom-left)
	var p1_display = input_display_scene.instantiate()
	p1_display.name = "InputDisplay_P1"
	p1_display.player_id = 1
	p1_display.anchor_left = 0.0
	p1_display.anchor_top = 1.0
	p1_display.anchor_right = 0.0
	p1_display.anchor_bottom = 1.0
	p1_display.offset_left = 10.0
	p1_display.offset_top = -130.0
	p1_display.offset_right = 170.0
	p1_display.offset_bottom = -10.0
	ui_layer.add_child(p1_display)
	input_displays[1] = p1_display

	# P2 input display (bottom-right)
	var p2_display = input_display_scene.instantiate()
	p2_display.name = "InputDisplay_P2"
	p2_display.player_id = 2
	p2_display.anchor_left = 1.0
	p2_display.anchor_top = 1.0
	p2_display.anchor_right = 1.0
	p2_display.anchor_bottom = 1.0
	p2_display.offset_left = -170.0
	p2_display.offset_top = -130.0
	p2_display.offset_right = -10.0
	p2_display.offset_bottom = -10.0
	ui_layer.add_child(p2_display)
	input_displays[2] = p2_display


func _setup_frame_data_display() -> void:
	var frame_data_scene = load("res://game/scenes/training/frame_data_display.tscn")
	if frame_data_scene == null:
		push_error("[TrainingMode] Failed to load frame data display scene")
		return

	frame_data_display = frame_data_scene.instantiate()
	frame_data_display.name = "FrameDataDisplay"
	frame_data_display.anchor_left = 0.0
	frame_data_display.anchor_top = 0.5
	frame_data_display.anchor_right = 0.0
	frame_data_display.anchor_bottom = 0.5
	frame_data_display.offset_left = 10.0
	frame_data_display.offset_top = -90.0
	frame_data_display.offset_right = 230.0
	frame_data_display.offset_bottom = 90.0
	ui_layer.add_child(frame_data_display)

	# Track P1 fighter by default
	if fighters.has(1):
		frame_data_display.set_fighter(fighters[1])


func _setup_hitbox_visualizer() -> void:
	hitbox_visualizer = HitboxVisualizer.new()
	hitbox_visualizer.name = "HitboxVisualizer"
	add_child(hitbox_visualizer)

	var fighter_list: Array = []
	for player_id in fighters:
		fighter_list.append(fighters[player_id])
	hitbox_visualizer.set_fighters(fighter_list)


## ============================================================================
## TRAINING MENU
## ============================================================================

func _setup_training_menu() -> void:
	training_menu_layer = CanvasLayer.new()
	training_menu_layer.name = "TrainingMenuLayer"
	training_menu_layer.layer = 20
	training_menu_layer.visible = false
	add_child(training_menu_layer)

	# Background overlay
	var bg = ColorRect.new()
	bg.name = "MenuBG"
	bg.color = Color(0.0, 0.0, 0.0, 0.6)
	bg.anchor_left = 0.0
	bg.anchor_top = 0.0
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	training_menu_layer.add_child(bg)

	# Menu panel
	var panel = PanelContainer.new()
	panel.name = "MenuPanel"
	panel.anchor_left = 0.3
	panel.anchor_top = 0.15
	panel.anchor_right = 0.7
	panel.anchor_bottom = 0.85
	panel.offset_left = 0
	panel.offset_top = 0
	panel.offset_right = 0
	panel.offset_bottom = 0
	training_menu_layer.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.name = "MenuVBox"
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	# Title
	var title = Label.new()
	title.text = "TRAINING OPTIONS"
	title.add_theme_font_size_override("font_size", 22)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	# Spacer
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(spacer)

	# Toggle buttons
	_add_toggle_button(vbox, "Infinite Health", "infinite_health", training_config["infinite_health"])
	_add_toggle_button(vbox, "Input Display", "show_input_display", training_config["show_input_display"])
	_add_toggle_button(vbox, "Frame Data", "show_frame_data", training_config["show_frame_data"])
	_add_toggle_button(vbox, "Show Hitboxes", "show_hitboxes", training_config["show_hitboxes"])

	# Spacer
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 8)
	vbox.add_child(spacer2)

	# Dummy behavior selection
	var dummy_label = Label.new()
	dummy_label.text = "Dummy Behavior:"
	dummy_label.add_theme_font_size_override("font_size", 16)
	vbox.add_child(dummy_label)

	var dummy_options = OptionButton.new()
	dummy_options.name = "DummyBehavior"
	dummy_options.add_item("Stand", 0)
	dummy_options.add_item("Jump", 1)
	dummy_options.add_item("Crouch", 2)
	dummy_options.add_item("Walk Back", 3)
	dummy_options.custom_minimum_size = Vector2(0, 40)
	dummy_options.item_selected.connect(_on_dummy_behavior_changed)
	vbox.add_child(dummy_options)

	# Spacer
	var spacer3 = Control.new()
	spacer3.custom_minimum_size = Vector2(0, 8)
	vbox.add_child(spacer3)

	# Action buttons
	var reset_btn = Button.new()
	reset_btn.text = "Reset Positions"
	reset_btn.custom_minimum_size = Vector2(0, 40)
	reset_btn.pressed.connect(_on_reset_positions)
	vbox.add_child(reset_btn)

	var reset_damage_btn = Button.new()
	reset_damage_btn.text = "Reset Damage Counter"
	reset_damage_btn.custom_minimum_size = Vector2(0, 40)
	reset_damage_btn.pressed.connect(_on_reset_damage)
	vbox.add_child(reset_damage_btn)

	var back_btn = Button.new()
	back_btn.text = "Back to Main Menu"
	back_btn.custom_minimum_size = Vector2(0, 40)
	back_btn.pressed.connect(_on_back_to_menu)
	vbox.add_child(back_btn)

	var close_btn = Button.new()
	close_btn.text = "Resume Training"
	close_btn.custom_minimum_size = Vector2(0, 40)
	close_btn.pressed.connect(_toggle_training_menu)
	vbox.add_child(close_btn)


func _add_toggle_button(parent: VBoxContainer, label_text: String, config_key: String, initial_value: bool) -> void:
	var hbox = HBoxContainer.new()
	parent.add_child(hbox)

	var label = Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", 16)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(label)

	var toggle = CheckButton.new()
	toggle.name = config_key
	toggle.button_pressed = initial_value
	toggle.toggled.connect(_on_toggle_changed.bind(config_key))
	hbox.add_child(toggle)


func _toggle_training_menu() -> void:
	is_training_menu_open = not is_training_menu_open
	training_menu_layer.visible = is_training_menu_open
	get_tree().paused = is_training_menu_open
	training_menu_toggled.emit(is_training_menu_open)

	if is_training_menu_open:
		AudioManager.play_sfx("menu_confirm")


## ============================================================================
## SIGNAL HANDLERS
## ============================================================================

func _connect_signals() -> void:
	for player_id in fighters:
		var fighter = fighters[player_id]

		# Connect health bars
		if health_bars.has(player_id):
			var health_bar = health_bars[player_id]
			fighter.health_changed.connect(health_bar._on_health_changed)
			health_bar.connect_to_fighter(fighter)

		# Track damage on the dummy
		if player_id == dummy_player_id:
			fighter.health_changed.connect(_on_dummy_health_changed)


func _on_toggle_changed(toggled: bool, config_key: String) -> void:
	training_config[config_key] = toggled
	_apply_training_config()
	AudioManager.play_sfx("menu_select")


func _on_dummy_behavior_changed(index: int) -> void:
	match index:
		0:
			training_config["dummy_behavior"] = "stand"
		1:
			training_config["dummy_behavior"] = "jump"
		2:
			training_config["dummy_behavior"] = "crouch"
		3:
			training_config["dummy_behavior"] = "walk"
	AudioManager.play_sfx("menu_select")


func _on_reset_positions() -> void:
	_reset_fighter_positions()
	AudioManager.play_sfx("menu_confirm")


func _on_reset_damage() -> void:
	total_damage = 0
	combo_damage = 0
	combo_hits = 0
	_update_damage_display()
	AudioManager.play_sfx("menu_confirm")


func _on_back_to_menu() -> void:
	get_tree().paused = false
	AudioManager.play_sfx("menu_confirm")
	GameManager.change_state(GameManager.GameState.MENU)
	SceneManager.goto_scene("res://game/scenes/menus/main_menu.tscn")


func _on_dummy_health_changed(current: int, max_hp: int) -> void:
	var damage_dealt = max_hp - current
	if damage_dealt > 0:
		combo_hits += 1
		combo_damage += (max_hp - current) - (max_hp - fighters[dummy_player_id].health)
		total_damage = max_hp - current
		_update_damage_display()


## ============================================================================
## TRAINING LOGIC
## ============================================================================

func _apply_training_config() -> void:
	# Input display visibility
	for player_id in input_displays:
		input_displays[player_id].visible = training_config["show_input_display"]

	# Frame data display visibility
	if frame_data_display != null:
		frame_data_display.visible = training_config["show_frame_data"]

	# Hitbox visualizer
	if hitbox_visualizer != null:
		hitbox_visualizer.set_enabled(training_config["show_hitboxes"])


func _restore_health() -> void:
	for player_id in fighters:
		var fighter = fighters[player_id]
		if fighter.health < fighter.max_health:
			# Restore health gradually (not instantly, for visual feedback)
			if fighter.state_machine.current_state == FighterStateMachine.State.IDLE:
				fighter.health = fighter.max_health
				fighter.is_alive = true
				fighter.health_changed.emit(fighter.health, fighter.max_health)


func _update_dummy() -> void:
	if not fighters.has(dummy_player_id):
		return

	var dummy = fighters[dummy_player_id]
	if not dummy.is_alive:
		if training_config["infinite_health"]:
			dummy.health = dummy.max_health
			dummy.is_alive = true
			dummy.state_machine.change_state(FighterStateMachine.State.IDLE)
			dummy.health_changed.emit(dummy.health, dummy.max_health)
		return

	match training_config["dummy_behavior"]:
		"stand":
			# Dummy stands still
			if dummy.state_machine.current_state == FighterStateMachine.State.WALKING:
				dummy.state_machine.change_state(FighterStateMachine.State.IDLE)
			dummy.velocity.x = 0

		"jump":
			# Dummy jumps repeatedly
			if dummy.is_on_floor() and dummy.state_machine.current_state == FighterStateMachine.State.IDLE:
				dummy.state_machine.change_state(FighterStateMachine.State.JUMPING)

		"crouch":
			# Dummy crouches (move down)
			dummy.velocity.x = 0

		"walk":
			# Dummy walks away from P1
			if fighters.has(1) and dummy.state_machine.current_state == FighterStateMachine.State.IDLE:
				var direction = sign(dummy.global_position.x - fighters[1].global_position.x)
				if direction == 0:
					direction = -1
				dummy.velocity.x = direction * dummy.speed * 0.5
				dummy.state_machine.change_state(FighterStateMachine.State.WALKING)


func _reset_fighter_positions() -> void:
	for player_id in fighters:
		var fighter = fighters[player_id]
		if stage != null:
			fighter.global_position = stage.get_spawn_position(player_id)
		fighter.velocity = Vector2.ZERO
		fighter.knockback_velocity = Vector2.ZERO
		fighter.health = fighter.max_health
		fighter.is_alive = true
		fighter.state_machine.change_state(FighterStateMachine.State.IDLE)
		fighter.health_changed.emit(fighter.health, fighter.max_health)

	total_damage = 0
	combo_damage = 0
	combo_hits = 0
	_update_damage_display()
	training_reset.emit()


func _update_damage_display() -> void:
	if damage_label != null:
		damage_label.text = "Combo: %d hits | %d damage" % [combo_hits, total_damage]


## ============================================================================
## INPUT ROUTING (same as BattleScene but P2 is dummy-controlled)
## ============================================================================

func _route_player_inputs() -> void:
	# Player 1 movement
	if Input.is_action_pressed("p1_move_left"):
		_handle_player_input(1, "move_left")
	elif Input.is_action_pressed("p1_move_right"):
		_handle_player_input(1, "move_right")

	if Input.is_action_pressed("p1_move_up"):
		_handle_player_input(1, "move_up")
	elif Input.is_action_pressed("p1_move_down"):
		_handle_player_input(1, "move_down")

	# Player 1 attacks
	if Input.is_action_just_pressed("p1_attack"):
		_handle_player_input(1, "attack")

	if Input.is_action_just_pressed("p1_special"):
		_handle_player_input(1, "special")


func _handle_player_input(player_id: int, action: String) -> void:
	if not fighters.has(player_id):
		return

	var fighter = fighters[player_id]
	if not fighter.is_alive or fighter.state_machine.current_state != FighterStateMachine.State.IDLE:
		return

	match action:
		"move_left":
			fighter.facing_direction = -1
			fighter.state_machine.change_state(FighterStateMachine.State.WALKING)
			fighter.velocity.x = -fighter.speed

		"move_right":
			fighter.facing_direction = 1
			fighter.state_machine.change_state(FighterStateMachine.State.WALKING)
			fighter.velocity.x = fighter.speed

		"move_up":
			if fighter.is_on_floor():
				fighter.state_machine.change_state(FighterStateMachine.State.JUMPING)
				var jump_force = sqrt(2.0 * fighter.gravity * fighter.jump_height)
				fighter.velocity.y = -jump_force

		"move_down":
			fighter.velocity.y += fighter.gravity * 0.1

		"attack":
			fighter.state_machine.change_state(FighterStateMachine.State.ATTACKING)

		"special":
			fighter.state_machine.change_state(FighterStateMachine.State.ATTACKING)
