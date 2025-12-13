## Stage select screen script
## Allows players to select a stage/arena

extends Control

var available_stages: Array = []
var selected_stage: int = 0
var players_ready: bool = false

@onready var stage_name_label: Label = $VBoxContainer/StageNameLabel
@onready var stage_preview: ColorRect = $VBoxContainer/StagePreview
@onready var ready_label: Label = $VBoxContainer/ReadyLabel


func _ready() -> void:
	# Load available stages
	_load_stages()

	# Update initial display
	_update_display()


func _process(_delta: float) -> void:
	if not players_ready:
		# Any player can change stage selection
		if Input.is_action_just_pressed("p1_move_left") or Input.is_action_just_pressed("p2_move_left"):
			selected_stage = (selected_stage - 1 + available_stages.size()) % available_stages.size()
			_update_display()
		elif Input.is_action_just_pressed("p1_move_right") or Input.is_action_just_pressed("p2_move_right"):
			selected_stage = (selected_stage + 1) % available_stages.size()
			_update_display()

		# Any player can confirm
		if Input.is_action_just_pressed("p1_attack") or Input.is_action_just_pressed("p2_attack"):
			players_ready = true
			_update_display()
			_on_stage_confirmed()

	# Back button
	if Input.is_action_just_pressed("ui_cancel"):
		_on_back_pressed()


func _load_stages() -> void:
	# For now, hardcode available stages
	# Later this will load from stage definition files
	available_stages = [
		{
			"id": "arena_1",
			"name": "Political Arena",
			"scene_path": "res://game/scenes/stages/arena_1.tscn"
		}
	]

	# TODO: Load from stage directory when more stages exist
	# var stage_dir = "res://game/scenes/stages/"
	# Scan for stage scene files


func _update_display() -> void:
	if available_stages.is_empty():
		stage_name_label.text = "No stages available"
		return

	var stage = available_stages[selected_stage]
	stage_name_label.text = stage.get("name", "Unknown Stage")

	# Update preview (placeholder color for now)
	stage_preview.color = Color(0.2, 0.3, 0.4, 1.0)

	if players_ready:
		ready_label.text = "Loading..."
		ready_label.modulate = Color.GREEN
	else:
		ready_label.text = "Press SPACE or ENTER to continue"
		ready_label.modulate = Color.WHITE


func _on_stage_confirmed() -> void:
	# Proceed to battle scene
	if not available_stages.is_empty():
		var stage = available_stages[selected_stage]
		# For now, go directly to battle scene
		# TODO: Store stage selection in GameManager
		SceneManager.goto_scene("res://game/scenes/battle/battle_scene.tscn")


func _on_back_pressed() -> void:
	# Return to character select
	SceneManager.goto_scene("res://game/scenes/menus/character_select.tscn")
